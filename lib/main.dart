import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:media_kit/media_kit.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/app.dart';
import 'package:purevideo/core/services/settings_service.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  Hive.init((await getApplicationDocumentsDirectory()).path);

  setupInjection();
  await getIt<SettingsService>().init();

  runApp(const PureVideoApp());
}
