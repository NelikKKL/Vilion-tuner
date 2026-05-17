import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'yin_pitch_detector.dart';
import 'instrument_service.dart';

class NoteResult {
  final String noteName;
  final double frequency;
  final double centsDiff;
  final bool isInTune;

  const NoteResult({
    required this.noteName,
    required this.frequency,
    required this.centsDiff,
    required this.isInTune,
  });
}

// ── Isolate messages ──────────────────────────────────────────────────────────

class _PitchRequest {
  final Uint8List pcmBytes;
  final SendPort replyPort;
  const _PitchRequest(this.pcmBytes, this.replyPort);
}

void _pitchIsolateMain(SendPort mainSendPort) {
  final recv = ReceivePort();
  mainSendPort.send(recv.sendPort);

  final detector = YinPitchDetector(
    sampleRate: 44100,
    threshold: 0.15,
    bufferSize: 2048,
  );

  recv.listen((msg) {
    if (msg is _PitchRequest) {
      final floats = YinPitchDetector.pcmBytesToFloat32(msg.pcmBytes);

      if (YinPitchDetector.rms(floats) < 0.01) {
        msg.replyPort.send(-1.0);
        return;
      }

      const step = 2048;
      double result = -1.0;
      for (int offset = 0; offset + step <= floats.length; offset += step ~/ 2) {
        final chunk = Float32List.sublistView(floats, offset, offset + step);
        final freq = detector.getPitch(chunk);
        if (freq > 180 && freq < 1400) {
          result = freq;
          break;
        }
      }
      msg.replyPort.send(result);
    }
  });
}

// ── TunerService ─────────────────────────────────────────────────────────────

class TunerService extends ChangeNotifier {
  bool _isListening = false;
  bool _hasPermission = false;
  NoteResult? _currentNote;
  String? _selectedStringId;   // id from InstrumentString
  bool _autoMode = true;
  double _needlePosition = 0.0;
  double _currentFrequency = 0.0;
  String _error = '';

  double _referencePitch = 440.0;
  Map<String, double> _customStringFrequencies = {};

  final List<double> _freqHistory = [];
  static const _smoothing = 5;

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSub;

  Isolate? _isolate;
  SendPort? _toIsolate;
  ReceivePort? _fromIsolate;
  bool _busy = false;

  static const List<String> noteNames = [
    'C', 'C#', 'D', 'D#', 'E',
    'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  bool get isListening => _isListening;
  bool get hasPermission => _hasPermission;
  NoteResult? get currentNote => _currentNote;
  String? get selectedStringId => _selectedStringId;
  bool get autoMode => _autoMode;
  double get needlePosition => _needlePosition;
  double get referencePitch => _referencePitch;
  double get currentFrequency => _currentFrequency;
  String get error => _error;
  Map<String, double> get customStringFrequencies => Map.unmodifiable(_customStringFrequencies);

  TunerService() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _referencePitch = prefs.getDouble('referencePitch') ?? 440.0;
    final keys = prefs.getKeys().where((k) => k.startsWith('stringFreq_'));
    for (final key in keys) {
      final id = key.replaceFirst('stringFreq_', '');
      final val = prefs.getDouble(key);
      if (val != null) _customStringFrequencies[id] = val;
    }
    notifyListeners();
  }

  Future<void> setReferencePitch(double hz) async {
    _referencePitch = hz;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('referencePitch', hz);
  }

  Future<void> setStringFrequency(String id, double hz) async {
    _customStringFrequencies[id] = hz;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('stringFreq_$id', hz);
  }

  double getEffectiveStringFrequency(InstrumentService instrument, String id) {
    if (_customStringFrequencies.containsKey(id)) {
      return _customStringFrequencies[id]!;
    }
    final ratio = _referencePitch / 440.0;
    final baseFreq = instrument.strings
        .firstWhere((s) => s.id == id, orElse: () => instrument.strings.first)
        .freq;
    return baseFreq * ratio;
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  Future<void> requestPermission() async {
    final status = await Permission.microphone.request();
    _hasPermission = status.isGranted;
    notifyListeners();
  }

  Future<void> startListening() async {
    if (_isListening) return;

    if (!_hasPermission) {
      await requestPermission();
      if (!_hasPermission) {
        _error = 'Нет разрешения на микрофон';
        notifyListeners();
        return;
      }
    }

    try {
      await _spawnIsolate();
      await _startMic();
      _isListening = true;
      _error = '';
    } catch (e) {
      _error = 'Ошибка запуска: $e';
    }
    notifyListeners();
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _audioSub?.cancel();
    _audioSub = null;
    await _recorder.stop();
    _killIsolate();
    _currentNote = null;
    _needlePosition = 0.0;
    _currentFrequency = 0.0;
    _freqHistory.clear();
    notifyListeners();
  }

  void setAutoMode(bool auto) {
    _autoMode = auto;
    if (auto) _selectedStringId = null;
    notifyListeners();
  }

  void selectString(String? id) {
    _selectedStringId = id;
    _autoMode = id == null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  // ── Isolate ─────────────────────────────────────────────────────────────────

  Future<void> _spawnIsolate() async {
    _fromIsolate = ReceivePort();
    _isolate = await Isolate.spawn(
      _pitchIsolateMain,
      _fromIsolate!.sendPort,
    );
    _toIsolate = await _fromIsolate!.first as SendPort;
  }

  void _killIsolate() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _fromIsolate?.close();
    _fromIsolate = null;
    _toIsolate = null;
    _busy = false;
  }

  // ── Audio recording ─────────────────────────────────────────────────────────

  Future<void> _startMic() async {
    const cfg = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 44100,
      numChannels: 1,
    );

    final stream = await _recorder.startStream(cfg);

    final List<int> accumulator = [];
    const chunkSamples = 4096;
    const chunkBytes = chunkSamples * 2;

    _audioSub = stream.listen((data) {
      accumulator.addAll(data);
      while (accumulator.length >= chunkBytes) {
        final chunk = Uint8List.fromList(accumulator.sublist(0, chunkBytes));
        accumulator.removeRange(0, chunkBytes);
        _submitChunk(chunk);
      }
    });
  }

  void _submitChunk(Uint8List chunk) {
    if (_busy || _toIsolate == null || !_isListening) return;
    _busy = true;

    final reply = ReceivePort();
    reply.first.then((value) {
      _busy = false;
      _onPitch(value as double);
      reply.close();
    });

    _toIsolate!.send(_PitchRequest(chunk, reply.sendPort));
  }

  // ── Pitch processing ────────────────────────────────────────────────────────

  void _onPitch(double freq) {
    if (!_isListening) return;

    if (freq > 0) {
      _freqHistory.add(freq);
      if (_freqHistory.length > _smoothing) _freqHistory.removeAt(0);
      final smoothed = _median(_freqHistory);
      _currentFrequency = smoothed;
      _processFrequency(smoothed);
    } else {
      _needlePosition *= 0.75;
      if (_needlePosition.abs() < 0.01) _needlePosition = 0;
      notifyListeners();
    }
  }

  void _processFrequency(double freq) {
    final midiNote = 12 * log(freq / 440.0) / log(2) + 69;
    final roundedMidi = midiNote.round();
    final centsDiff = (midiNote - roundedMidi) * 100;
    final octave = (roundedMidi / 12).floor() - 1;
    final noteIndex = roundedMidi % 12;

    _needlePosition = (centsDiff / 50).clamp(-1.0, 1.0);
    _currentNote = NoteResult(
      noteName: '${noteNames[noteIndex]}$octave',
      frequency: freq,
      centsDiff: centsDiff,
      isInTune: centsDiff.abs() < 5,
    );
    notifyListeners();
  }

  double _median(List<double> list) {
    final s = List<double>.from(list)..sort();
    return s[s.length ~/ 2];
  }
}
