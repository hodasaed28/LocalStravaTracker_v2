import 'package:flutter/material.dart';

import 'screens/activities_screen.dart';
import 'screens/home_screen.dart';
import 'screens/record_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'services/settings_service.dart';
import 'services/tracking_service.dart';

class StrideApp extends StatefulWidget {
  const StrideApp({super.key});

  @override
  State<StrideApp> createState() => _StrideAppState();
}

class _StrideAppState extends State<StrideApp> {
  final TrackingService _tracker = TrackingService();
  ThemeMode _themeMode = ThemeMode.system;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final theme = await SettingsService.instance.getTheme();
    if (!mounted) return;
    setState(() {
      _themeMode = switch (theme) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };
    });
  }

  @override
  void dispose() {
    _tracker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stride Local',
      themeMode: _themeMode,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: _HomeShell(
        index: _index,
        tracker: _tracker,
        onIndexChanged: (value) => setState(() => _index = value),
        onThemeRefresh: _loadTheme,
      ),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF5B5CE2), brightness: brightness);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withOpacity(.4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.index, required this.tracker, required this.onIndexChanged, required this.onThemeRefresh});
  final int index;
  final TrackingService tracker;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onThemeRefresh;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onStart: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecordScreen(tracker: tracker, autoStart: true)))),
      const ActivitiesScreen(),
      StatsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onIndexChanged,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history_rounded), label: 'Activities'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
      floatingActionButton: index == 0 && !tracker.isRecording
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecordScreen(tracker: tracker, autoStart: false))),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Record'),
            )
          : null,
    );
  }
}
