import 'package:hive/hive.dart';

class SettingsService {
  static const String _isDeveloperModeKey = 'isDeveloperMode';
  static const String _isDebugVisibleKey = 'isDebugVisible';

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
}
