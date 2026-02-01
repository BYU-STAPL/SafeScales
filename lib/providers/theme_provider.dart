import 'package:flutter/cupertino.dart';
import '../services/user_state_service.dart';
import '../themes/app_theme.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 1.0;
  double _readingFontSize = 1.0;
  double _readingSpeed =
      1.0; // Default speed (displays as 1.0, backend receives 0.5)
  AppThemeType _themeType = AppThemeType.classicBlue;
  final UserStateService _userState;

  // Constructor now takes UserStateService as dependency
  ThemeNotifier({required UserStateService userStateService})
    : _userState = userStateService;

  // Getters to access the private variables
  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  double get readingFontSize => _readingFontSize;
  double get readingSpeed => _readingSpeed;
  AppThemeType get themeType => _themeType;

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

  // Update reading font size
  void updateReadingFontSize(double fontSize) {
    if (_readingFontSize != fontSize) {
      _readingFontSize = fontSize;
      notifyListeners(); // This triggers UI updates
      _saveSettings(); // Persist the change
    }
  }

  // Update reading speed
  void updateReadingSpeed(double speed) {
    if (_readingSpeed != speed) {
      _readingSpeed = speed;
      notifyListeners(); // This triggers UI updates
      _saveSettings(); // Persist the change
    }
  }

  // Update theme type
  void updateThemeType(AppThemeType themeType) {
    if (_themeType != themeType) {
      _themeType = themeType;
      AppTheme.setThemeType(themeType);
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
      _readingFontSize =
          (settings['readingFontSize'] != null)
              ? (settings['readingFontSize'] as num).toDouble()
              : 1.0;
      _readingSpeed =
          (settings['readingSpeed'] != null)
              ? (settings['readingSpeed'] as num).toDouble()
              : 1.0; // Default to 1.0 if not set (displays as 1.0, backend receives 0.5)

      // Migrate old values (< 1.0) to new display format by adding 0.5
      if (_readingSpeed < 1.0) {
        _readingSpeed = _readingSpeed + 0.5;
      }

      // Load theme type
      if (settings['themeType'] != null) {
        final themeTypeString = settings['themeType'] as String;
        _themeType = AppThemeType.values.firstWhere(
          (e) => e.name == themeTypeString,
          orElse: () => AppThemeType.classicBlue,
        );
      }

      // Font scale is only applied in the reading activity (readingFontSize).
      // Global app theme always uses 1.0 so font adjustment only affects reading.
      AppTheme.setFontSizeScale(1.0);
      AppTheme.setThemeType(
        _themeType,
      ); // Ensure theme type is applied globally
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
        readingFontSize: _readingFontSize,
        readingSpeed: _readingSpeed,
        themeType: _themeType,
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
