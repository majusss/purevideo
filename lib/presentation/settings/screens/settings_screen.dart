import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purevideo/core/services/settings_service.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/settings/widgets/settings_item.dart';
import 'package:purevideo/presentation/settings/widgets/settings_listenable.dart';
import 'package:purevideo/presentation/settings/widgets/settings_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = getIt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsSection(
            title: 'Konta',
            items: [
              SettingsItem(
                icon: Icons.person_outline,
                title: 'Zarządzanie kontami',
                subtitle: 'Dodaj lub usuń konta serwisów',
                onTap: () => context.pushNamed('accounts'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SettingsSection(
            title: 'Aplikacja',
            items: [
              SettingsItem(
                icon: Icons.dark_mode_outlined,
                title: 'Motyw',
                subtitle: 'Wygląd aplikacji',
                onTap: () {
                  context.pushNamed('theme');
                },
              ),
              SettingsItem(
                icon: Icons.info_outline,
                title: 'O aplikacji',
                subtitle: 'Informacje o wersji',
                onTap: () {
                  context.pushNamed('about');
                },
              ),
            ],
          ),
          SettingsListenable(
            builder: (context, value, child) {
              if (_settingsService.isDeveloperMode == false) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  const SizedBox(height: 24),
                  SettingsSection(
                    title: 'Opcje deweloperskie',
                    items: [
                      SettingsItem(
                        icon: Icons.bug_report_outlined,
                        title: 'Debugowanie',
                        subtitle: 'Pokaż debugowanie filmów i seriali',
                        onTap: () {
                          setState(() {
                            _settingsService.setDebugVisible(
                                !_settingsService.isDebugVisible);
                          });
                        },
                        trailing: Switch(
                          value: _settingsService.isDebugVisible,
                          onChanged: (value) {
                            setState(() {
                              _settingsService.setDebugVisible(value);
                            });
                          },
                        ),
                      ),
                      SettingsItem(
                        icon: Icons.developer_mode,
                        title: 'Tryb deweloperski',
                        subtitle: 'Wyłącz tryb deweloperski',
                        onTap: () {
                          setState(() {
                            _settingsService.setDeveloperMode(false);
                          });
                        },
                        trailing: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          )
        ],
      ),
    );
  }
}
