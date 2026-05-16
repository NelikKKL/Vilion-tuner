import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/metronome_service.dart';

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

              // Appearance
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
                  style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
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
                subtitle: '440 Hz',
                colorScheme: colorScheme,
                onTap: () {},
              ),

              const SizedBox(height: 32),
              _SectionHeader('Metronome', colorScheme),
              const SizedBox(height: 12),

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

              // Footer
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
                          'assets/images/icon_violin_head.png',
                          color: const Color(0xFFDCE0E8),
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
