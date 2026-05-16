import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

enum MetronomeSound {
  woodBlock,
  drum,
  digital,
  digital2,
  clav,
}

extension MetronomeSoundExt on MetronomeSound {
  String get label {
    switch (this) {
      case MetronomeSound.woodBlock:
        return 'Wood Block';
      case MetronomeSound.drum:
        return 'Drum';
      case MetronomeSound.digital:
        return 'Digital';
      case MetronomeSound.digital2:
        return 'Digital 2';
      case MetronomeSound.clav:
        return 'Clav';
    }
  }

  String get accentAsset {
    switch (this) {
      case MetronomeSound.woodBlock:
        return 'sounds/click_accent.wav';
      case MetronomeSound.drum:
        return 'sounds/beat_drum_high.wav';
      case MetronomeSound.digital:
        return 'sounds/beat_digital_high.wav';
      case MetronomeSound.digital2:
        return 'sounds/beat_digital_2_high.wav';
      case MetronomeSound.clav:
        return 'sounds/beat_clav_high.wav';
    }
  }

  String get clickAsset {
    switch (this) {
      case MetronomeSound.woodBlock:
        return 'sounds/click_normal.wav';
      case MetronomeSound.drum:
        return 'sounds/beat_drum_high.wav';
      case MetronomeSound.digital:
        return 'sounds/beat_digital_high.wav';
      case MetronomeSound.digital2:
        return 'sounds/beat_digital_2_high.wav';
      case MetronomeSound.clav:
        return 'sounds/beat_clav_high.wav';
    }
  }
}

class MetronomeService extends ChangeNotifier {
  bool _isPlaying = false;
  int _bpm = 70;
  int _beatsPerMeasure = 3;
  int _beatUnit = 4;
  int _currentBeat = 0;
  bool _isAccent = false;
  NoteValue _noteValue = NoteValue.quarter;
  bool _vibrate = true;
  MetronomeSound _sound = MetronomeSound.woodBlock;

  Timer? _timer;

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
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _vibrate = prefs.getBool('metronome_vibrate') ?? false;
    notifyListeners();
  }

  Future<void> _initAudio() async {
    await _accentPlayer.setReleaseMode(ReleaseMode.stop);
    await _clickPlayer.setReleaseMode(ReleaseMode.stop);
    await _loadSounds();
  }

  Future<void> _loadSounds() async {
    _soundReady = false;
    await _accentPlayer.setSource(AssetSource(_sound.accentAsset));
    await _clickPlayer.setSource(AssetSource(_sound.clickAsset));
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
  MetronomeSound get sound => _sound;

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

  Future<void> setVibrate(bool v) async {
    _vibrate = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('metronome_vibrate', v);
  }

  Future<void> setSound(MetronomeSound s) async {
    _sound = s;
    await _loadSounds();
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

  void _startTimer() {
    final intervalMs = (60000 / _bpm).round();
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

    if (_vibrate) {
      Vibration.vibrate(duration: _isAccent ? 60 : 30, amplitude: _isAccent ? 200 : 100);
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

enum NoteValue { whole, half, quarter, eighth, sixteenth, thirtySecond }

class _TempoMark {
  final int min;
  final int max;
  final String name;
  const _TempoMark(this.min, this.max, this.name);
}

extension NoteValueExt on NoteValue {
  String get label {
    switch (this) {
      case NoteValue.whole: return 'Whole';
      case NoteValue.half: return 'Half';
      case NoteValue.quarter: return 'Quarter';
      case NoteValue.eighth: return 'Eighth';
      case NoteValue.sixteenth: return 'Sixteenth';
      case NoteValue.thirtySecond: return '32nd';
    }
  }

  String get description {
    switch (this) {
      case NoteValue.whole: return '1 beat per measure';
      case NoteValue.half: return '2 subdivisions';
      case NoteValue.quarter: return '4 subdivisions';
      case NoteValue.eighth: return '8 subdivisions';
      case NoteValue.sixteenth: return '16 subdivisions';
      case NoteValue.thirtySecond: return '32 subdivisions';
    }
  }
}
