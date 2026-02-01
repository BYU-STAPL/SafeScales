import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:safe_scales/themes/app_theme.dart';
import 'package:safe_scales/providers/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsDrawer extends StatelessWidget {
  SettingsDrawer({
    super.key,
    required this.username,
    required this.email,
    required this.onTutorial,
    required this.onHelp,
    required this.onLogout,
  });

  final String username;
  final String email;
  final VoidCallback onTutorial;
  final VoidCallback onHelp;
  final VoidCallback onLogout;

  // String _version = '';
  //
  // _getVersionInfo() async {
  //   PackageInfo packageInfo = await PackageInfo.fromPlatform();
  //   _version = 'v${packageInfo.version} (${packageInfo.buildNumber})';
  // }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
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
                      fontSize: 25,
                      letterSpacing: 1.1,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 20,
                    ),
                  ),
                  Divider(height: 32, color: colorScheme.outlineVariant),

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
                                  fontSize: 12,
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
                          inactiveTrackColor: colorScheme.surfaceContainerHigh,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),

                  // App Theme Selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Theme',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 80,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildThemeOption(
                                context,
                                colorScheme,
                                themeNotifier,
                                AppThemeType.classicBlue,
                                'Classic Blue',
                                [const Color(0xff2E83E8), const Color(0xff0DB563)],
                              ),
                              const SizedBox(width: 12),
                              _buildThemeOption(
                                context,
                                colorScheme,
                                themeNotifier,
                                AppThemeType.forestGreen,
                                'Forest Green',
                                [const Color(0xff059669), const Color(0xff10B981)],
                              ),
                              const SizedBox(width: 12),
                              _buildThemeOption(
                                context,
                                colorScheme,
                                themeNotifier,
                                AppThemeType.sunsetOrange,
                                'Sunset Orange',
                                [const Color(0xffEA580C), const Color(0xffF97316)],
                              ),
                              const SizedBox(width: 12),
                              _buildThemeOption(
                                context,
                                colorScheme,
                                themeNotifier,
                                AppThemeType.oceanTeal,
                                'Ocean Teal',
                                [const Color(0xff0891B2), const Color(0xff06B6D4)],
                              ),
                              const SizedBox(width: 12),
                              _buildThemeOption(
                                context,
                                colorScheme,
                                themeNotifier,
                                AppThemeType.royalPurple,
                                'Royal Purple',
                                [const Color(0xff7C3AED), const Color(0xff8B5CF6)],
                              ),
                              const SizedBox(width: 12),
                              _buildThemeOption(
                                context,
                                colorScheme,
                                themeNotifier,
                                AppThemeType.rosePink,
                                'Rose Pink',
                                [const Color(0xffE11D48), const Color(0xffF43F5E)],
                              ),
                              const SizedBox(width: 12),
                              _buildThemeOption(
                                context,
                                colorScheme,
                                themeNotifier,
                                AppThemeType.indigoNavy,
                                'Indigo Navy',
                                [const Color(0xff4338CA), const Color(0xff4F46E5)],
                              ),
                              const SizedBox(width: 12),
                              _buildThemeOption(
                                context,
                                colorScheme,
                                themeNotifier,
                                AppThemeType.amberGold,
                                'Amber Gold',
                                [const Color(0xffD97706), const Color(0xffF59E0B)],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // TODO: If we build a tutorial or help resources then we can add these back in
                  // // Tutorial
                  // ListTile(
                  //   contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  //   leading: Icon(
                  //     FontAwesomeIcons.graduationCap,
                  //     color: colorScheme.primary,
                  //   ),
                  //   title: Text(
                  //     'Tutorial',
                  //     style: TextStyle(fontSize: 18, color: colorScheme.onSurface),
                  //   ),
                  //   onTap: onTutorial,
                  // ),
                  // // Help
                  // ListTile(
                  //   contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  //   leading: Icon(
                  //     FontAwesomeIcons.circleQuestion,
                  //     color: colorScheme.primary,
                  //   ),
                  //   title: Text(
                  //     'Help',
                  //     style: TextStyle(fontSize: 18, color: colorScheme.onSurface),
                  //   ),
                  //   onTap: onHelp,
                  // ),
                  const Spacer(),

                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                          child: Text(
                            'App Version: ${snapshot.data!.version} + ${snapshot.data!.buildNumber}',
                            style: Theme.of(context).textTheme.labelLarge,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),

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
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeNotifier themeNotifier,
    AppThemeType themeType,
    String themeName,
    List<Color> previewColors,
  ) {
    final isSelected = themeNotifier.themeType == themeType;
    
    return GestureDetector(
      onTap: () {
        themeNotifier.updateThemeType(themeType);
      },
      child: Container(
        width: 70,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Color preview swatches
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: previewColors.map((color) {
                return Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 0.5,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            // Theme name
            Text(
              themeName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Selected indicator
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}