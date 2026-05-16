import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'yin_pitch_detector.dart';

enum TunerString { g3, d4, a4, e5 }

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

class _IsolateInit {
  final SendPort replyPort;
  const _IsolateInit(this.replyPort);
}

class _PitchRequest {
  final Uint8List pcmBytes;
  final SendPort replyPort;
  const _PitchRequest(this.pcmBytes, this.replyPort);
}

/// Runs in a background isolate — no Flutter framework access allowed.
void _pitchIsolateMain(SendPort mainSendPort) {
  final recv = ReceivePort();
  mainSendPort.send(recv.sendPort); // handshake

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
  TunerString? _selectedString;
  bool _autoMode = true;
  double _needlePosition = 0.0;
  double _currentFrequency = 0.0;
  String _error = '';

  final List<double> _freqHistory = [];
  static const _smoothing = 5;

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSub;

  Isolate? _isolate;
  SendPort? _toIsolate;
  ReceivePort? _fromIsolate;
  bool _busy = false;

  // ── Public API ──────────────────────────────────────────────────────────────

  static const Map<TunerString, double> stringFrequencies = {
    TunerString.g3: 196.00,
    TunerString.d4: 293.66,
    TunerString.a4: 440.00,
    TunerString.e5: 659.25,
  };

  static const Map<TunerString, String> stringNames = {
    TunerString.g3: 'G₃',
    TunerString.d4: 'D₄',
    TunerString.a4: 'A₄',
    TunerString.e5: 'E₅',
  };

  static const List<String> noteNames = [
    'C', 'C#', 'D', 'D#', 'E',
    'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  bool get isListening => _isListening;
  bool get hasPermission => _hasPermission;
  NoteResult? get currentNote => _currentNote;
  TunerString? get selectedString => _selectedString;
  bool get autoMode => _autoMode;
  double get needlePosition => _needlePosition;
  double get currentFrequency => _currentFrequency;
  String get error => _error;
  String get stringLabel =>
      (_autoMode || _selectedString == null) ? 'AUTO' : stringNames[_selectedString]!;

  static String getStringName(TunerString s) => stringNames[s]!;
  static double getStringFreq(TunerString s) => stringFrequencies[s]!;

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
    if (auto) _selectedString = null;
    notifyListeners();
  }

  void selectString(TunerString? string) {
    _selectedString = string;
    _autoMode = string == null;
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

    // First message = isolate's SendPort (handshake)
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
    const chunkSamples = 4096;         // ~93 ms @ 44100 Hz
    const chunkBytes = chunkSamples * 2; // int16 → 2 bytes each

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
      // Silence — drift needle back to centre
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
