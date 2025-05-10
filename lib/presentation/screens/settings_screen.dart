import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:purevideo/core/services/settings_service.dart';
import 'package:purevideo/di/injection_container.dart';

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
          _SettingsSection(
            title: 'Konta',
            items: [
              _SettingsItem(
                icon: Icons.person_outline,
                title: 'Zarządzanie kontami',
                subtitle: 'Dodaj lub usuń konta serwisów',
                onTap: () => context.pushNamed('accounts'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Aplikacja',
            items: [
              _SettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Powiadomienia',
                subtitle: 'Ustawienia powiadomień',
                onTap: () {
                  // TODO: Implement notifications settings
                },
              ),
              _SettingsItem(
                icon: Icons.dark_mode_outlined,
                title: 'Motyw',
                subtitle: 'Wygląd aplikacji',
                onTap: () {
                  // TODO: Implement theme settings
                },
              ),
              _SettingsItem(
                icon: Icons.info_outline,
                title: 'O aplikacji',
                subtitle: 'Informacje o wersji',
                onTap: () {
                  context.pushNamed('about');
                },
              ),
            ],
          ),
          ValueListenableBuilder(
            valueListenable: Hive.box('settings').listenable(),
            builder: (context, value, child) {
              if (_settingsService.isDeveloperMode == false) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: 'Opcje deweloperskie',
                    items: [
                      _SettingsItem(
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
                      _SettingsItem(
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

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(32),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(153),
                          ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing!,
              ],
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
