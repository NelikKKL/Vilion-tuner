import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tuner_service.dart';
import '../services/instrument_service.dart';
import '../widgets/tuner_needle.dart';
import '../widgets/violin_scroll_widget.dart';
import '../widgets/string_button.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TunerService>().startListening();
    });
  }

  void _showInstrumentPicker(BuildContext context) {
    final instrument = context.read<InstrumentService>();
    final tuner = context.read<TunerService>();
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Instrument',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ...Instrument.values.map((inst) {
                final selected = instrument.instrument == inst;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      inst.iconAsset,
                      fit: BoxFit.contain,
                      color: selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(
                    inst.displayName,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: selected
                      ? Icon(Icons.check_circle, color: colorScheme.primary)
                      : null,
                  onTap: () async {
                    await instrument.setInstrument(inst);
                    tuner.selectString(null); // reset to AUTO
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tuner = context.watch<TunerService>();
    final instrument = context.watch<InstrumentService>();
    final colorScheme = Theme.of(context).colorScheme;
    final strings = instrument.strings;

    // Split strings: left half, right half (supports 4 or 6 strings)
    final half = (strings.length / 2).ceil();
    final leftStrings  = strings.sublist(0, half);
    final rightStrings = strings.length > half ? strings.sublist(half) : <InstrumentString>[];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Instrument selector button ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: GestureDetector(
                onTap: () => _showInstrumentPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Image.asset(
                          instrument.iconAsset,
                          fit: BoxFit.contain,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        instrument.displayName,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.expand_more,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Error banner ──────────────────────────────────────────────
            if (tuner.error.isNotEmpty)
              Material(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: colorScheme.onErrorContainer, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(tuner.error,
                            style: TextStyle(color: colorScheme.onErrorContainer)),
                      ),
                      TextButton(
                        onPressed: tuner.startListening,
                        child: Text('Retry',
                            style: TextStyle(color: colorScheme.onErrorContainer)),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Needle area ───────────────────────────────────────────────
            Expanded(
              flex: 5,
              child: TunerNeedle(
                position: tuner.needlePosition,
                noteResult: tuner.currentNote,
                colorScheme: colorScheme,
              ),
            ),

            Container(height: 1, color: colorScheme.outlineVariant.withOpacity(0.3)),

            // ── Instrument image + string buttons + bottom controls ────────
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: first 2 strings
                        Column(
                          children: [
                            for (int i = 0; i < leftStrings.length; i++) ...[
                              if (i > 0) const SizedBox(height: 10),
                              StringButton(
                                label: leftStrings[i].label,
                                isSelected: tuner.selectedStringId == leftStrings[i].id,
                                onTap: () => tuner.selectString(
                                  tuner.selectedStringId == leftStrings[i].id
                                      ? null
                                      : leftStrings[i].id,
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Center: instrument head image
                        const Expanded(
                          child: Center(child: ViolinScrollWidget()),
                        ),

                        // Right: last 2 strings
                        Column(
                          children: [
                            for (int i = 0; i < rightStrings.length; i++) ...[
                              if (i > 0) const SizedBox(height: 10),
                              StringButton(
                                label: rightStrings[i].label,
                                isSelected: tuner.selectedStringId == rightStrings[i].id,
                                onTap: () => tuner.selectString(
                                  tuner.selectedStringId == rightStrings[i].id
                                      ? null
                                      : rightStrings[i].id,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom: mic button + AUTO button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Mic button
                        GestureDetector(
                          onTap: () {
                            if (tuner.isListening) {
                              tuner.stopListening();
                            } else {
                              tuner.startListening();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tuner.isListening
                                  ? colorScheme.primary
                                  : Color.alphaBlend(
                                      Colors.white.withOpacity(0.08),
                                      colorScheme.surface,
                                    ),
                              boxShadow: tuner.isListening
                                  ? [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(0.45),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Icon(
                              tuner.isListening ? Icons.mic : Icons.mic_off,
                              color: tuner.isListening
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface.withOpacity(0.6),
                              size: 24,
                            ),
                          ),
                        ),

                        // AUTO button
                        GestureDetector(
                          onTap: () => tuner.setAutoMode(!tuner.autoMode),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: tuner.autoMode
                                  ? colorScheme.primary
                                  : Color.alphaBlend(
                                      Colors.white.withOpacity(0.08),
                                      colorScheme.surface,
                                    ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: tuner.autoMode
                                  ? [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(0.35),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Text(
                              'AUTO',
                              style: TextStyle(
                                color: tuner.autoMode
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
