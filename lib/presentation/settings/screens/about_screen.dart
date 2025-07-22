import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:purevideo/core/services/settings_service.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'PureVideo',
    packageName: 'io.github.majusss.purevideo',
    version: '0.0.0',
    buildNumber: '0',
  );
  int _versionClickCount = 0;
  final int _requiredClicks = 7;
  final SettingsService _settingsService = getIt();

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  void _handleVersionTap() {
    setState(() {
      _versionClickCount++;
      if (_versionClickCount >= _requiredClicks) {
        _versionClickCount = 0;
        _toggleDeveloperMode();
      }
    });
  }

  Future<void> _toggleDeveloperMode() async {
    final currentValue = _settingsService.isDeveloperMode;
    _settingsService.setDeveloperMode(!currentValue);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Tryb deweloperski ${!currentValue ? 'włączony' : 'wyłączony'}!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (mounted) {
      GoRouter.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('O aplikacji'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Hero(
                tag: 'app_logo',
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      size: 64,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _packageInfo.appName,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _handleVersionTap,
                child: Text(
                  'Wersja ${_packageInfo.version} (${_packageInfo.buildNumber})',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildInfoSection(context),
              const SizedBox(height: 24),
              _buildLicenseSection(context),
              const SizedBox(height: 24),
              _buildSocialSection(context),
              const SizedBox(height: 24),
              _buildCreatorsSection(context),
              const SizedBox(height: 24),
              Text(
                'majusss 2025',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O PureVideo',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'PureVideo to wieloplatformowa aplikacja mobilna do streamingu filmów i seriali, zbudowana przy użyciu frameworka Flutter.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Aplikacja agreguje treści z różnych źródeł internetowych, zapewniając bogaty wybór filmów i seriali w jednym miejscu.',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Społeczność',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Dołącz do naszej społeczności i wspieraj projekt.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialIcon(
                  context,
                  Icons.discord,
                  'Discord',
                  () async {
                    if (!await launchUrl(
                        Uri.parse('https://discord.gg/vjtkqAMQdn'))) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nie można otworzyć Discorda'),
                        ),
                      );
                    }
                  },
                ),
                _buildSocialIcon(
                  context,
                  Icons.code,
                  'GitHub',
                  () async {
                    if (!await launchUrl(
                        Uri.parse('https://github.com/majusss/purevideo'))) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nie można otworzyć GitHuba'),
                        ),
                      );
                    }
                  },
                ),
                _buildSocialIcon(
                  context,
                  Icons.coffee,
                  'Buy Me a Coffee',
                  () async {
                    if (!await launchUrl(
                        Uri.parse('https://www.buymeacoffee.com/majusss'))) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nie można otworzyć Buy Me a Coffee'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Licencja',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'PureVideo jest aplikacją open source udostępnioną na licencji GPL v3 (GNU General Public License version 3).',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Kod źródłowy jest dostępny na GitHub. Możesz używać, modyfikować i rozpowszechniać tę aplikację zgodnie z warunkami licencji GPL v3.',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Twórcy',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildCreatorItem(
                context, 'majusss', 'Główny developer', Icons.man),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorItem(
      BuildContext context, String name, String role, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.titleMedium,
                ),
                Text(
                  role,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
