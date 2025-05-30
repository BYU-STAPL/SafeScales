
import 'package:flutter/cupertino.dart';

import '../services/user_state_service.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 1.0;
  final _userState = UserStateService();

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
      // TODO: Add methods to UserStateService to get these values
      // _isDarkMode = await _userState.getDarkMode() ?? false;
      // _fontSize = await _userState.getFontSize() ?? 1.0;
      notifyListeners();
    } catch (e) {
      // Handle any loading errors
      print('Error loading settings: $e');
    }
  }

  // Save settings to persistent storage
  Future<void> _saveSettings() async {
    try {
      // TODO: Add methods to UserStateService to get these values
      // await _userState.saveDarkMode(_isDarkMode);
      // await _userState.saveFontSize(_fontSize);
    } catch (e) {
      // Handle any saving errors
      print('Error saving settings: $e');
    }
  }

  // Convenience method to toggle dark mode
  void toggleDarkMode() {
    updateTheme(!_isDarkMode);
  }
}