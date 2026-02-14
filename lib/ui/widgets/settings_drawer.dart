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
                        _buildThemeGrid(
                          context,
                          colorScheme,
                          themeNotifier,
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

  static final List<({AppThemeType type, String name, List<Color> colors})> _themeOptions = [
    (type: AppThemeType.classicBlue, name: 'Classic', colors: [const Color(0xff2E83E8), const Color(0xff0DB563), const Color(0xff93C5FD), const Color(0xffDBEAFE)]),
    (type: AppThemeType.forestGreen, name: 'Forest Green', colors: [const Color(0xff059669), const Color(0xff10B981), const Color(0xffD1FAE5), const Color(0xffA7F3D0)]),
    (type: AppThemeType.sunsetOrange, name: 'Sunset Orange', colors: [const Color(0xffEA580C), const Color(0xffF97316), const Color(0xffFED7AA), const Color(0xffFEF9C3)]),
    (type: AppThemeType.oceanTeal, name: 'Ocean Teal', colors: [const Color(0xff0891B2), const Color(0xff06B6D4), const Color(0xffCFFAFE), const Color(0xffA5F3FC)]),
    (type: AppThemeType.royalPurple, name: 'Royal Purple', colors: [const Color(0xff7C3AED), const Color(0xff8B5CF6), const Color(0xffEDE9FE), const Color(0xffDDD6FE)]),
    (type: AppThemeType.rosePink, name: 'Rose Pink', colors: [const Color(0xffE11D48), const Color(0xffF43F5E), const Color(0xffFCE7F3), const Color(0xffFDF2F8)]),
    (type: AppThemeType.sepiaNeutral, name: 'Sepia', colors: [const Color(0xff6B5B4F), const Color(0xff8B7355), const Color(0xffE8E2DB), const Color(0xffDED6CC)]),
  ];

  Widget _buildThemeGrid(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeNotifier themeNotifier,
  ) {
    const int columns = 2;
    final rows = <Widget>[];
    for (var i = 0; i < _themeOptions.length; i += columns) {
      final rowChildren = <Widget>[];
      for (var j = 0; j < columns; j++) {
        final index = i + j;
        if (index < _themeOptions.length) {
          final opt = _themeOptions[index];
          rowChildren.add(
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: j == 0 ? 6 : 0, left: j == 1 ? 6 : 0),
                child: _buildThemeOption(context, colorScheme, themeNotifier, opt.type, opt.name, opt.colors),
              ),
            ),
          );
        } else {
          rowChildren.add(const Expanded(child: SizedBox.shrink()));
        }
      }
      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowChildren));
      if (i + columns < _themeOptions.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Color preview swatches (2x2 grid)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSwatch(colorScheme, previewColors.length > 0 ? previewColors[0] : colorScheme.primary),
                    _buildSwatch(colorScheme, previewColors.length > 1 ? previewColors[1] : colorScheme.secondary),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSwatch(colorScheme, previewColors.length > 2 ? previewColors[2] : colorScheme.primary),
                    _buildSwatch(colorScheme, previewColors.length > 3 ? previewColors[3] : colorScheme.secondary),
                  ],
                ),
              ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildSwatch(ColorScheme colorScheme, Color color) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
    );
  }
}