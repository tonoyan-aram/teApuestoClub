import 'package:flutter/material.dart';
import 'package:apuesto_club/main.dart'; // Import main.dart to access themeNotifier
import 'package:package_info_plus/package_info_plus.dart'; // Import package_info_plus
import 'package:apuesto_club/screens/export_import_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40.0, // Reduced height
        title: const Text('Settings'), // Added title back
      ),
      body: ListView(
        children: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, child) {
              return SwitchListTile(
                title: Text(currentMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode'),
                value: currentMode == ThemeMode.dark,
                onChanged: (value) {
                  themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                  debugPrint('Theme changed to: ${themeNotifier.value}');
                },
              );
            },
          ),
          ListTile(
            title: const Text('Export/Import Data'),
            subtitle: const Text('Backup and restore your events'),
            leading: const Icon(Icons.backup),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ExportImportScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('App Version'),
            subtitle: Text(_appVersion),
          ),
          AboutListTile(
            icon: const Icon(Icons.info_outline),
            applicationName: 'Te Apuesto Club',
            applicationVersion: _appVersion,
            applicationLegalese: '© 2023 Te Apuesto Club',
            aboutBoxChildren: const [
              Text(
                  'Te Apuesto Club is your ultimate companion for tracking and managing sports events. Organize your favorite matches, record important notes, and relive memorable moments with ease.'),
              SizedBox(height: 10),
              Text(
                  'Stay updated with event details, personalize your experience with ratings and images, and keep a comprehensive diary of your sports journey.'),
            ],
          ),
        ],
      ),
    );
  }
}
