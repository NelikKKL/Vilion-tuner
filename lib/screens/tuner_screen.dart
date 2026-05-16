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

            // ── Violin image + string buttons + bottom controls ───────────
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  // String buttons row (верхний ряд над картинкой)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: D4, G3
                        Column(
                          children: [
                            StringButton(
                              label: 'D₄',
                              isSelected: tuner.selectedString == TunerString.d4,
                              onTap: () => tuner.selectString(
                                tuner.selectedString == TunerString.d4 ? null : TunerString.d4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            StringButton(
                              label: 'G₃',
                              isSelected: tuner.selectedString == TunerString.g3,
                              onTap: () => tuner.selectString(
                                tuner.selectedString == TunerString.g3 ? null : TunerString.g3,
                              ),
                            ),
                          ],
                        ),

                        // Center: violin head image
                        Expanded(
                          child: Center(
                            child: const ViolinScrollWidget(),
                          ),
                        ),

                        // Right: A4, E5
                        Column(
                          children: [
                            StringButton(
                              label: 'A₄',
                              isSelected: tuner.selectedString == TunerString.a4,
                              onTap: () => tuner.selectString(
                                tuner.selectedString == TunerString.a4 ? null : TunerString.a4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            StringButton(
                              label: 'E₅',
                              isSelected: tuner.selectedString == TunerString.e5,
                              onTap: () => tuner.selectString(
                                tuner.selectedString == TunerString.e5 ? null : TunerString.e5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom: mic button (left) + AUTO button (right)
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
