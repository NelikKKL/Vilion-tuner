import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'main_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
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

              // Theme section
              _SectionHeader('Appearance', colorScheme),
              const SizedBox(height: 12),

              _SettingsTile(
                icon: Icons.brightness_6_outlined,
                title: 'Theme',
                colorScheme: colorScheme,
                trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode, size: 18),
                    ),
                  ],
                  selected: {themeProvider.themeMode},
                  onSelectionChanged: (modes) {
                    themeProvider.setThemeMode(modes.first);
                  },
                  style: ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),

              const SizedBox(height: 32),
              _SectionHeader('Tuner', colorScheme),
              const SizedBox(height: 12),

              _SettingsTile(
                icon: Icons.tune,
                title: 'Reference pitch (A4)',
                subtitle: '440 Hz',
                colorScheme: colorScheme,
                onTap: () {},
              ),

              const SizedBox(height: 32),
              _SectionHeader('Metronome', colorScheme),
              const SizedBox(height: 12),

              _SettingsTile(
                icon: Icons.volume_up_outlined,
                title: 'Click sound',
                subtitle: 'Wood block',
                colorScheme: colorScheme,
                onTap: () {},
              ),

              _SettingsTile(
                icon: Icons.vibration,
                title: 'Vibrate on beat',
                colorScheme: colorScheme,
                trailing: Switch(
                  value: false,
                  onChanged: (_) {},
                ),
              ),

              const Spacer(),

              // App icon + version footer
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
                      child: Center(
                        child: _ViolinIcon(
                          color: const Color(0xFFDCE0E8),
                          size: 44,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Violin Tuner',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v1.1.0',
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
}

class _ViolinIcon extends StatelessWidget {
  final Color color;
  final double size;
  const _ViolinIcon({required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ViolinIconPainter(color: color),
    );
  }
}

class _ViolinIconPainter extends CustomPainter {
  final Color color;
  const _ViolinIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final s = size.width / 24.0;

    final neckPath = Path();
    neckPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(10.5 * s, 1 * s, 3 * s, 10 * s),
      Radius.circular(1.5 * s),
    ));
    canvas.drawPath(neckPath, paint);

    canvas.drawOval(Rect.fromCenter(
      center: Offset(12 * s, 13 * s),
      width: 7 * s,
      height: 6 * s,
    ), paint);

    canvas.drawRect(Rect.fromLTWH(9 * s, 15 * s, 6 * s, 3 * s), paint);

    canvas.drawOval(Rect.fromCenter(
      center: Offset(12 * s, 20 * s),
      width: 8.5 * s,
      height: 7 * s,
    ), paint);

    canvas.drawOval(Rect.fromCenter(
      center: Offset(12 * s, 1.5 * s),
      width: 3 * s,
      height: 2.5 * s,
    ), paint);
  }

  @override
  bool shouldRepaint(covariant _ViolinIconPainter old) => old.color != color;
}

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
        title: Text(
          title,
          style: TextStyle(color: colorScheme.onSurface),
        ),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: TextStyle(color: colorScheme.onSurfaceVariant))
            : null,
        trailing: trailing ??
            (onTap != null
                ? Icon(Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant)
                : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
