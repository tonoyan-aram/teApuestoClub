import 'package:flutter/material.dart';
import 'package:apuesto_club/theme/app_theme.dart';
import 'package:apuesto_club/screens/wrapper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import local notifications

// Global instance for notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // Your app icon
  const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
    // Handle notification tap
    // You might want to navigate to a specific screen or show an alert
    debugPrint('notification payload: ${notificationResponse.payload}');
  });

  runApp(const SportsEventDiaryApp());
}

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class SportsEventDiaryApp extends StatefulWidget {
  const SportsEventDiaryApp({super.key});

  @override
  State<SportsEventDiaryApp> createState() => _SportsEventDiaryAppState();
}

class _SportsEventDiaryAppState extends State<SportsEventDiaryApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        debugPrint('MaterialApp rebuilding with themeMode: $mode');
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Te Apuesto Club',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme, // Add dark theme
          themeMode: mode, // Use the theme mode from ValueNotifier
          home: const Wrapper(),
        );
      },
    );
  }
}
