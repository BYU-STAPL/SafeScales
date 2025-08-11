import 'package:flutter/cupertino.dart';
import '../services/user_state_service.dart';
import '../themes/app_theme.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 1.0;
  final UserStateService _userState;

  // Constructor now takes UserStateService as dependency
  ThemeNotifier({required UserStateService userStateService})
      : _userState = userStateService;

  // Getters to access the private variables
  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;

  // Update theme
  void updateTheme(bool isDarkMode) {
    if (_isDarkMode != isDarkMode) {
      _isDarkMode = isDarkMode;
      notifyListeners(); // This triggers UI updates
      _saveSettings(); // Persist the change
    }
  }

  // Update font size
  void updateFontSize(double fontSize) {
    if (_fontSize != fontSize) {
      _fontSize = fontSize;
      notifyListeners(); // This triggers UI updates
      _saveSettings(); // Persist the change
    }
  }

  // Load settings from persistent storage
  Future<void> loadSettings() async {
    try {
      final settings = await _userState.getUserSettings();
      _isDarkMode = settings['isDarkMode'] ?? false;
      _fontSize =
      (settings['fontSize'] != null)
          ? (settings['fontSize'] as num).toDouble()
          : 1.0;
      AppTheme.setFontSizeScale(
        _fontSize,
      ); // Ensure font size is applied globally
      notifyListeners();
    } catch (e) {
      // Handle any loading errors
      print('❌Error loading settings: $e');
    }
  }

  // Save settings to persistent storage
  Future<void> _saveSettings() async {
    try {
      await _userState.saveUserSettings(
        isDarkMode: _isDarkMode,
        fontSize: _fontSize,
      );
    } catch (e) {
      // Handle any saving errors
      print('❌Error saving settings: $e');
    }
  }

  // Convenience method to toggle dark mode
  void toggleDarkMode() {
    updateTheme(!_isDarkMode);
  }
}