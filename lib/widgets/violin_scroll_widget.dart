import 'package:flutter/material.dart';

class ViolinScrollWidget extends StatelessWidget {
  const ViolinScrollWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 280,
      child: Image.asset(
        'assets/images/icon_violin_head.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
