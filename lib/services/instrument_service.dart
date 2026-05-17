import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Instrument { violin, flute, guitar }

extension InstrumentExt on Instrument {
  String get displayName {
    switch (this) {
      case Instrument.violin: return 'Violin';
      case Instrument.flute:  return 'Flute';
      case Instrument.guitar: return 'Guitar';
    }
  }

  String get iconAsset {
    switch (this) {
      case Instrument.violin: return 'assets/images/icon_violin_head.png';
      case Instrument.flute:  return 'assets/images/icon_Flute_head.png';
      case Instrument.guitar: return 'assets/images/icon_guitar_head.png';
    }
  }

  // Standard open strings / notes for each instrument
  List<InstrumentString> get strings {
    switch (this) {
      case Instrument.violin:
        return const [
          InstrumentString(id: 'g3', label: 'G₃', freq: 196.00),
          InstrumentString(id: 'd4', label: 'D₄', freq: 293.66),
          InstrumentString(id: 'a4', label: 'A₄', freq: 440.00),
          InstrumentString(id: 'e5', label: 'E₅', freq: 659.25),
        ];
      case Instrument.flute:
        return const [
          InstrumentString(id: 'c4', label: 'C₄', freq: 261.63),
          InstrumentString(id: 'd4', label: 'D₄', freq: 293.66),
          InstrumentString(id: 'g4', label: 'G₄', freq: 392.00),
          InstrumentString(id: 'a4', label: 'A₄', freq: 440.00),
        ];
      case Instrument.guitar:
        // Standard guitar tuning: E2 A2 D3 G3 B3 E4 (all 6 strings)
        return const [
          InstrumentString(id: 'e2', label: 'E₂', freq: 82.41),
          InstrumentString(id: 'a2', label: 'A₂', freq: 110.00),
          InstrumentString(id: 'd3', label: 'D₃', freq: 146.83),
          InstrumentString(id: 'g3', label: 'G₃', freq: 196.00),
          InstrumentString(id: 'b3', label: 'B₃', freq: 246.94),
          InstrumentString(id: 'e4', label: 'E₄', freq: 329.63),
        ];
    }
  }
}

class InstrumentString {
  final String id;
  final String label;
  final double freq;
  const InstrumentString({required this.id, required this.label, required this.freq});
}

class InstrumentService extends ChangeNotifier {
  Instrument _instrument = Instrument.violin;

  Instrument get instrument => _instrument;

  InstrumentService() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt('instrument') ?? 0;
    _instrument = Instrument.values[idx.clamp(0, Instrument.values.length - 1)];
    notifyListeners();
  }

  Future<void> setInstrument(Instrument inst) async {
    _instrument = inst;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('instrument', inst.index);
  }

  List<InstrumentString> get strings => _instrument.strings;
  String get iconAsset => _instrument.iconAsset;
  String get displayName => _instrument.displayName;
}
