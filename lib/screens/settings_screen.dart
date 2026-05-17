import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/metronome_service.dart';
import '../services/tuner_service.dart';
import '../services/instrument_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final metronome = context.watch<MetronomeService>();
    final tuner = context.watch<TunerService>();
    final instrument = context.watch<InstrumentService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 32),

              _SectionHeader('Appearance', colorScheme),
              const SizedBox(height: 12),

              _SettingsTile(
                icon: Icons.brightness_6_outlined,
                title: 'Theme',
                colorScheme: colorScheme,
                trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode, size: 18)),
                    ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto, size: 18)),
                    ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode, size: 18)),
                  ],
                  selected: {themeProvider.themeMode},
                  onSelectionChanged: (modes) => themeProvider.setThemeMode(modes.first),
                  style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              ),

              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Material You',
                subtitle: themeProvider.useMaterialYou
                    ? 'Dynamic colors from wallpaper'
                    : 'Classic dark grey theme',
                colorScheme: colorScheme,
                trailing: Switch(
                  value: themeProvider.useMaterialYou,
                  onChanged: (v) => themeProvider.setUseMaterialYou(v),
                ),
              ),

              const SizedBox(height: 32),
              _SectionHeader('Tuner', colorScheme),
              const SizedBox(height: 12),

              _SettingsTile(
                icon: Icons.tune,
                title: 'Reference pitch (A4)',
                subtitle: '${tuner.referencePitch.toStringAsFixed(1)} Hz',
                colorScheme: colorScheme,
                onTap: () => _showReferencePitchDialog(context, tuner, instrument),
              ),

              const SizedBox(height: 32),
              _SectionHeader('Metronome', colorScheme),
              const SizedBox(height: 12),

              _SettingsTile(
                icon: Icons.vibration,
                title: 'Vibrate on beat',
                colorScheme: colorScheme,
                trailing: Switch(
                  value: metronome.vibrate,
                  onChanged: (v) => metronome.setVibrate(v),
                ),
              ),

              const Spacer(),

              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          instrument.iconAsset,
                          color: const Color(0xFFDCE0E8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tuner',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v1.2.0',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showReferencePitchDialog(
      BuildContext context, TunerService tuner, InstrumentService instrument) {
    showDialog(
      context: context,
      builder: (ctx) => _ReferencePitchDialog(tuner: tuner, instrument: instrument),
    );
  }
}

// ── Reference Pitch Dialog ────────────────────────────────────────────────────

class _ReferencePitchDialog extends StatefulWidget {
  final TunerService tuner;
  final InstrumentService instrument;
  const _ReferencePitchDialog({required this.tuner, required this.instrument});

  @override
  State<_ReferencePitchDialog> createState() => _ReferencePitchDialogState();
}

class _ReferencePitchDialogState extends State<_ReferencePitchDialog> {
  late double _a4Hz;
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _a4Hz = widget.tuner.referencePitch;
    _controllers = {
      for (final s in widget.instrument.strings)
        s.id: TextEditingController(
          text: widget.tuner.getEffectiveStringFrequency(widget.instrument, s.id)
              .toStringAsFixed(2),
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  void _updateFromA4(double hz) {
    setState(() {
      _a4Hz = hz;
      final ratio = hz / 440.0;
      for (final s in widget.instrument.strings) {
        if (!widget.tuner.customStringFrequencies.containsKey(s.id)) {
          _controllers[s.id]!.text = (s.freq * ratio).toStringAsFixed(2);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = widget.instrument.strings;

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      title: Text('Reference Pitch', style: TextStyle(color: colorScheme.onSurface)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A4 = ${_a4Hz.toStringAsFixed(1)} Hz',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Slider(
              value: _a4Hz,
              min: 415.0,
              max: 466.0,
              divisions: 102,
              label: '${_a4Hz.toStringAsFixed(1)} Hz',
              onChanged: _updateFromA4,
            ),
            Wrap(
              spacing: 8,
              children: [415.3, 432.0, 440.0, 442.0, 443.0, 444.0, 466.2]
                  .map((hz) => ActionChip(
                        label: Text('${hz.toStringAsFixed(0)} Hz'),
                        onPressed: () => _updateFromA4(hz),
                        backgroundColor: (_a4Hz - hz).abs() < 0.5
                            ? colorScheme.primaryContainer
                            : null,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text(
              '${widget.instrument.displayName} note frequencies',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...strings.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text(
                          s.label,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controllers[s.id],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            suffixText: 'Hz',
                            suffixStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.refresh, size: 18, color: colorScheme.onSurfaceVariant),
                        tooltip: 'Reset to auto',
                        onPressed: () {
                          final ratio = _a4Hz / 440.0;
                          setState(() {
                            _controllers[s.id]!.text = (s.freq * ratio).toStringAsFixed(2);
                          });
                        },
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await widget.tuner.setReferencePitch(_a4Hz);
            for (final s in strings) {
              final val = double.tryParse(_controllers[s.id]!.text);
              if (val != null && val > 50 && val < 2000) {
                await widget.tuner.setStringFrequency(s.id, val);
              }
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  final ColorScheme colorScheme;
  const _SectionHeader(this.text, this.colorScheme);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final ColorScheme colorScheme;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.colorScheme,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.onSurfaceVariant),
        title: Text(title, style: TextStyle(color: colorScheme.onSurface)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: TextStyle(color: colorScheme.onSurfaceVariant))
            : null,
        trailing: trailing ??
            (onTap != null
                ? Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant)
                : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
