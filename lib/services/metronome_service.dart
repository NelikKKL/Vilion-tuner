import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class MetronomeService extends ChangeNotifier {
  bool _isPlaying = false;
  int _bpm = 70;
  int _beatsPerMeasure = 3;
  int _beatUnit = 4;
  int _currentBeat = 0;
  bool _isAccent = false;
  NoteValue _noteValue = NoteValue.quarter;
  bool _vibrate = true;

  Timer? _timer;
  final List<DateTime> _tapTimes = [];

  // Two players: accent (beat 1) and regular click
  final AudioPlayer _accentPlayer = AudioPlayer();
  final AudioPlayer _clickPlayer = AudioPlayer();
  bool _soundReady = false;

  static const List<_TempoMark> tempoMarks = [
    _TempoMark(20, 40, 'Larghissimo'),
    _TempoMark(40, 60, 'Largo'),
    _TempoMark(60, 66, 'Larghetto'),
    _TempoMark(66, 76, 'Adagio'),
    _TempoMark(76, 108, 'Andante'),
    _TempoMark(108, 120, 'Moderato'),
    _TempoMark(120, 156, 'Allegro'),
    _TempoMark(156, 176, 'Vivace'),
    _TempoMark(176, 200, 'Presto'),
    _TempoMark(200, 300, 'Prestissimo'),
  ];

  MetronomeService() {
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _accentPlayer.setReleaseMode(ReleaseMode.stop);
    await _clickPlayer.setReleaseMode(ReleaseMode.stop);
    // Pre-load sounds from assets
    await _accentPlayer.setSource(AssetSource('sounds/click_accent.wav'));
    await _clickPlayer.setSource(AssetSource('sounds/click_normal.wav'));
    _soundReady = true;
  }

  bool get isPlaying => _isPlaying;
  int get bpm => _bpm;
  int get beatsPerMeasure => _beatsPerMeasure;
  int get beatUnit => _beatUnit;
  int get currentBeat => _currentBeat;
  bool get isAccent => _isAccent;
  NoteValue get noteValue => _noteValue;
  bool get vibrate => _vibrate;

  String get tempoName {
    for (final mark in tempoMarks) {
      if (_bpm >= mark.min && _bpm < mark.max) return mark.name;
    }
    return 'Prestissimo';
  }

  String get timeSignature => '$_beatsPerMeasure/$_beatUnit';

  void setBpm(int bpm) {
    _bpm = bpm.clamp(20, 300);
    if (_isPlaying) {
      _stopTimer();
      _startTimer();
    }
    notifyListeners();
  }

  void setBeatsPerMeasure(int beats) {
    _beatsPerMeasure = beats.clamp(1, 12);
    _currentBeat = 0;
    notifyListeners();
  }

  void setBeatUnit(int unit) {
    _beatUnit = unit;
    notifyListeners();
  }

  void setNoteValue(NoteValue value) {
    _noteValue = value;
    notifyListeners();
  }

  void setVibrate(bool v) {
    _vibrate = v;
    notifyListeners();
  }

  void togglePlay() {
    if (_isPlaying) {
      _stopTimer();
      _isPlaying = false;
      _currentBeat = 0;
      _isAccent = false;
    } else {
      _isPlaying = true;
      _currentBeat = 0;
      _startTimer();
    }
    notifyListeners();
  }

  void tap() {
    final now = DateTime.now();
    _tapTimes.add(now);
    if (_tapTimes.length > 8) _tapTimes.removeAt(0);

    if (_tapTimes.length >= 2) {
      double totalMs = 0;
      for (int i = 1; i < _tapTimes.length; i++) {
        totalMs += _tapTimes[i]
            .difference(_tapTimes[i - 1])
            .inMilliseconds
            .toDouble();
      }
      final avgMs = totalMs / (_tapTimes.length - 1);
      setBpm((60000 / avgMs).round());
    }
    notifyListeners();
  }

  void _startTimer() {
    final intervalMs = (60000 / _bpm).round();
    // Fire immediately for first beat
    _tick();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) => _tick());
  }

  void _tick() {
    _currentBeat = (_currentBeat % _beatsPerMeasure) + 1;
    _isAccent = _currentBeat == 1;

    if (_soundReady) {
      if (_isAccent) {
        _accentPlayer.seek(Duration.zero);
        _accentPlayer.resume();
      } else {
        _clickPlayer.seek(Duration.zero);
        _clickPlayer.resume();
      }
    }

    notifyListeners();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    _accentPlayer.dispose();
    _clickPlayer.dispose();
    super.dispose();
  }
}

enum NoteValue { whole, half, quarter, eighth }

class _TempoMark {
  final int min;
  final int max;
  final String name;
  const _TempoMark(this.min, this.max, this.name);
}
