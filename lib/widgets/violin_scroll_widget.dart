import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/instrument_service.dart';

class ViolinScrollWidget extends StatelessWidget {
  const ViolinScrollWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final instrument = context.watch<InstrumentService>();
    return SizedBox(
      width: 140,
      height: 200,
      child: Image.asset(
        instrument.iconAsset,
        fit: BoxFit.contain,
      ),
    );
  }
}
