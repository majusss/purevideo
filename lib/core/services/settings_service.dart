import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

class SettingsService {
  static const String _isDeveloperModeKey = 'isDeveloperMode';
  static const String _isDebugVisibleKey = 'isDebugVisible';
  static const String _isDarkModeKey = 'isDarkMode';
  static const String _isSystemBrightnessKey = 'isSystemBrightness';

  late final Box box;

  Future<void> init() async {
    box = await Hive.openBox('settings');
  }

  bool get isDeveloperMode =>
      bool.parse(box.get(_isDeveloperModeKey) ?? "false");

  void setDeveloperMode(bool value) {
    box.put(_isDeveloperModeKey, value.toString());
  }

  bool get isDebugVisible => bool.parse(box.get(_isDebugVisibleKey) ?? "false");

  void setDebugVisible(bool value) {
    box.put(_isDebugVisibleKey, value.toString());
  }

  bool get isDarkMode => bool.parse(box.get(_isDarkModeKey) ?? "false");

  void setDarkMode(bool value) {
    debugPrint('Setting dark mode to $value');
    box.put(_isDarkModeKey, value.toString());
  }

  bool get isSystemBrightness =>
      bool.parse(box.get(_isSystemBrightnessKey) ?? "true");

  void setSystemBrightness(bool value) {
    box.put(_isSystemBrightnessKey, value.toString());
  }

  ThemeMode get theme {
    if (isSystemBrightness) {
      return ThemeMode.system;
    } else if (isDarkMode) {
      return ThemeMode.dark;
    } else {
      return ThemeMode.light;
    }
  }
}
