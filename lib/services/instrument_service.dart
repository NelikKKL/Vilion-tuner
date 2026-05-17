import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Instrument { violin, flute }

extension InstrumentExt on Instrument {
  String get displayName {
    switch (this) {
      case Instrument.violin: return 'Violin';
      case Instrument.flute:  return 'Flute';
    }
  }

  String get iconAsset {
    switch (this) {
      case Instrument.violin: return 'assets/images/icon_violin_head.png';
      case Instrument.flute:  return 'assets/images/icon_Flute_head.png';
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
        // Flute reference notes: C4 middle C, D4, G4, A4 (common tuning refs)
        return const [
          InstrumentString(id: 'c4', label: 'C₄', freq: 261.63),
          InstrumentString(id: 'd4', label: 'D₄', freq: 293.66),
          InstrumentString(id: 'g4', label: 'G₄', freq: 392.00),
          InstrumentString(id: 'a4', label: 'A₄', freq: 440.00),
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
