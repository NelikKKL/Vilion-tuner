import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tuner_service.dart';
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

  @override
  void dispose() {
    // Don't stop listening — screen is kept alive in IndexedStack
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tuner = context.watch<TunerService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Error banner ──────────────────────────────────────────────
            if (tuner.error.isNotEmpty)
              Material(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: colorScheme.onErrorContainer, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tuner.error,
                          style:
                              TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                      TextButton(
                        onPressed: tuner.startListening,
                        child: Text('Retry',
                            style:
                                TextStyle(color: colorScheme.onErrorContainer)),
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

            Container(
              height: 1,
              color: colorScheme.outlineVariant.withOpacity(0.3),
            ),

            // ── Violin scroll + string buttons ────────────────────────────
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const ViolinScrollWidget(),

                  // Left strings: D4, G3
                  Positioned(
                    left: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StringButton(
                          label: 'D₄',
                          isSelected:
                              tuner.selectedString == TunerString.d4,
                          onTap: () => tuner.selectString(
                            tuner.selectedString == TunerString.d4
                                ? null
                                : TunerString.d4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StringButton(
                          label: 'G₃',
                          isSelected:
                              tuner.selectedString == TunerString.g3,
                          onTap: () => tuner.selectString(
                            tuner.selectedString == TunerString.g3
                                ? null
                                : TunerString.g3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right strings: A4, E5
                  Positioned(
                    right: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StringButton(
                          label: 'A₄',
                          isSelected:
                              tuner.selectedString == TunerString.a4,
                          onTap: () => tuner.selectString(
                            tuner.selectedString == TunerString.a4
                                ? null
                                : TunerString.a4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StringButton(
                          label: 'E₅',
                          isSelected:
                              tuner.selectedString == TunerString.e5,
                          onTap: () => tuner.selectString(
                            tuner.selectedString == TunerString.e5
                                ? null
                                : TunerString.e5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom row: instrument + mic toggle + AUTO
                  Positioned(
                    bottom: 16,
                    left: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'Violin',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  // Mic on/off button
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          if (tuner.isListening) {
                            tuner.stopListening();
                          } else {
                            tuner.startListening();
                          }
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tuner.isListening
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest,
                          ),
                          child: Icon(
                            tuner.isListening ? Icons.mic : Icons.mic_off,
                            color: tuner.isListening
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 16,
                    right: 24,
                    child: GestureDetector(
                      onTap: () => tuner.setAutoMode(!tuner.autoMode),
                      child: Row(
                        children: [
                          Checkbox(
                            value: tuner.autoMode,
                            onChanged: (v) => tuner.setAutoMode(v ?? true),
                            activeColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                          Text(
                            'AUTO',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
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
