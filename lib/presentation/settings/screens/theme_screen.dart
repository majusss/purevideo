import 'package:flutter/material.dart';
import 'package:purevideo/core/services/settings_service.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/settings/widgets/settings_item.dart';
import 'package:purevideo/presentation/settings/widgets/settings_section.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  final SettingsService _settingsService = getIt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motyw'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(children: [
                SettingsSection(
                  title: 'Opcje motywu',
                  items: [
                    SettingsItem(
                      icon: Icons.dark_mode_outlined,
                      title: 'Tryb ciemny',
                      subtitle: 'Włącz lub wyłącz tryb ciemny',
                      onTap: () {
                        if (_settingsService.isSystemBrightness) return;
                        setState(() {
                          _settingsService.setDarkMode(
                            !_settingsService.isDarkMode,
                          );
                        });
                      },
                      trailing: Switch(
                        value: _settingsService.isDarkMode,
                        activeColor: _settingsService.isSystemBrightness
                            ? Colors.grey
                            : null,
                        onChanged: (value) {
                          if (_settingsService.isSystemBrightness) return;
                          setState(() {
                            _settingsService.setDarkMode(value);
                          });
                        },
                      ),
                    ),
                    SettingsItem(
                      icon: Icons.dark_mode_outlined,
                      title: 'Tryb systemowy',
                      subtitle: 'Użyj motywu systemowego',
                      onTap: () {
                        setState(() {
                          _settingsService.setSystemBrightness(
                            !_settingsService.isSystemBrightness,
                          );
                        });
                      },
                      trailing: Switch(
                        value: _settingsService.isSystemBrightness,
                        onChanged: (value) {
                          setState(() {
                            _settingsService.setSystemBrightness(value);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ])
            ],
          ),
        ),
      ),
    );
  }
}
