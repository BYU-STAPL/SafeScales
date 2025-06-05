import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/themes/theme_provider.dart'; // Add this import

class SettingsDrawer extends StatelessWidget {
  final String username;
  final String email;
  final VoidCallback onTutorial;
  final VoidCallback onHelp;
  final VoidCallback onLogout;

  const SettingsDrawer({
    super.key,
    required this.username,
    required this.email,
    required this.onTutorial,
    required this.onHelp,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final themeNotifier = ThemeProvider.of(context);

    return Drawer(
      elevation: 16,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                username,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.1,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              Divider(height: 32, color: colorScheme.outlineVariant),


              // Font size control
              Container(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                child: Column(
                  children: [
                    Text(
                      'Font Size',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    Row(
                      children: [
                        Text(
                          'A',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: themeNotifier.fontSize,
                            min: 0.8,
                            max: 1.4,
                            divisions: 6,
                            onChanged: (value) {
                              AppTheme.setFontSizeScale(value);
                              themeNotifier.updateFontSize(value);
                            },
                            activeColor: colorScheme.primary,
                          ),
                        ),
                        Text(
                          'A',
                          style: TextStyle(
                            fontSize: 28,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Color mode toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        themeNotifier.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appearance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            themeNotifier.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: themeNotifier.isDarkMode,
                      onChanged: (value) => themeNotifier.updateTheme(value),
                      activeColor: colorScheme.primary,
                      activeTrackColor: colorScheme.primaryContainer,
                      inactiveThumbColor: colorScheme.outline,
                      inactiveTrackColor: colorScheme.surfaceVariant,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              // Tutorial
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                leading: Icon(
                  FontAwesomeIcons.graduationCap,
                  color: colorScheme.primary,
                ),
                title: Text(
                  'Tutorial',
                  style: TextStyle(fontSize: 18, color: colorScheme.onSurface),
                ),
                onTap: onTutorial,
              ),
              // Help
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                leading: Icon(
                  FontAwesomeIcons.circleQuestion,
                  color: colorScheme.primary,
                ),
                title: Text(
                  'Help',
                  style: TextStyle(fontSize: 18, color: colorScheme.onSurface),
                ),
                onTap: onHelp,
              ),
              const Spacer(),


              // Logout
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                leading: Icon(
                  FontAwesomeIcons.rightFromBracket,
                  color: colorScheme.error,
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(fontSize: 18, color: colorScheme.error),
                ),
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}