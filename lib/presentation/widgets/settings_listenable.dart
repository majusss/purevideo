import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsListenable extends StatelessWidget {
  const SettingsListenable({super.key, required this.builder});

  final Widget Function(BuildContext, Box, Widget?) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: Hive.box('settings').listenable(), builder: builder);
  }
}
