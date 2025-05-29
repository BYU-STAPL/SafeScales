import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safe_scales/themes/app_theme.dart';

class SettingsDrawer extends StatefulWidget {
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final String username;
  final String email;
  final VoidCallback onTutorial;
  final VoidCallback onHelp;
  final VoidCallback onLogout;

  const SettingsDrawer({
    super.key,
    required this.fontSize,
    required this.onFontSizeChanged,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.username,
    required this.email,
    required this.onTutorial,
    required this.onHelp,
    required this.onLogout,
  });

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  late double _fontSize;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.fontSize;
    _isDarkMode = widget.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 16,
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
              const Text(
                'Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.username,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              Text(
                widget.email,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const Divider(height: 32),
              // Font size control
              Row(
                children: [
                  const Text('A', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 0.8,
                      max: 1.4,
                      divisions: 6,
                      onChanged: (value) {
                        setState(() {
                          _fontSize = value;
                        });
                        AppTheme.setFontSizeScale(value);
                        widget.onFontSizeChanged(value);
                      },
                      activeColor: Colors.blue,
                    ),
                  ),
                  const Text('A', style: TextStyle(fontSize: 28)),
                ],
              ),
              const SizedBox(height: 8),
              // Color mode toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: _isDarkMode ? Colors.amber : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isDarkMode ? 'Dark Mode' : 'Light Mode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          _isDarkMode = value;
                        });
                        widget.onDarkModeChanged(value);
                      },
                      activeColor: Colors.amber,
                      activeTrackColor: Colors.amber.withOpacity(0.5),
                      inactiveThumbColor: Colors.grey[300],
                      inactiveTrackColor: Colors.grey[400],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Tutorial
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  FontAwesomeIcons.graduationCap,
                  color: Colors.lightBlue,
                ),
                title: const Text('Tutorial', style: TextStyle(fontSize: 18)),
                onTap: widget.onTutorial,
              ),
              // Help
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  FontAwesomeIcons.circleQuestion,
                  color: Colors.lightBlue,
                ),
                title: const Text('Help', style: TextStyle(fontSize: 18)),
                onTap: widget.onHelp,
              ),
              const Spacer(),
              // Logout
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  FontAwesomeIcons.rightFromBracket,
                  color: Colors.red,
                ),
                title: const Text('Logout', style: TextStyle(fontSize: 18)),
                onTap: widget.onLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
