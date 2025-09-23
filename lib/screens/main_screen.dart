import 'package:flutter/material.dart';
import 'package:apuesto_club/screens/home_screen.dart';
import 'package:apuesto_club/screens/add_event_screen.dart';
import 'package:apuesto_club/screens/favorites_screen.dart';
import 'package:apuesto_club/screens/statistics_screen.dart';
import 'package:apuesto_club/screens/settings_screen.dart';
import 'package:apuesto_club/screens/templates_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomeScreen(key: _homeScreenKey),
      // Instead of AddEventScreen directly, navigate to it and refresh on pop
      // This is a placeholder; actual navigation will be in _onItemTapped
      Container(), // Placeholder for AddEventScreen tab
      Container(), // Placeholder for Templates tab
      const FavoritesScreen(),
      const StatisticsScreen(),
      const SettingsScreen(),
    ];
  }

  // Remove _refreshHomeScreen as it's no longer needed for direct callback
  // void _refreshHomeScreen() {
  //   _homeScreenKey.currentState?.loadEvents();
  // }

  void _onItemTapped(int index) async {
    if (index == 1) { // 'Add' tab
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddEventScreen(),
        ),
      );
      if (result == true) { // If an event was saved/updated
        // Refresh HomeScreen state if it's currently selected
        if (_selectedIndex == 0) {
          _homeScreenKey.currentState?.loadEvents();
        } else {
          // If another tab is selected, simply rebuild MainScreen to refresh UI
          setState(() {});
        }
      }
    } else if (index == 2) { // 'Templates' tab
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const TemplatesScreen(),
        ),
      );
      if (result != null) {
        // If a template was selected, navigate to AddEventScreen with the template
        final eventResult = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddEventScreen(template: result),
          ),
        );
        if (eventResult == true) {
          // Refresh HomeScreen state if it's currently selected
          if (_selectedIndex == 0) {
            _homeScreenKey.currentState?.loadEvents();
          } else {
            setState(() {});
          }
        }
      }
    } else {
      // For tabs that have actual widgets (Home, Favorites, Statistics, Settings)
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Te Apuesto Club')),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.content_copy), label: 'Templates'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favorites'),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
