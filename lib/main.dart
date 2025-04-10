import 'package:flutter/material.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupInjection();
  runApp(const PureVideoApp());
}
