import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'services/preferences_service.dart';
import 'services/api_client.dart';
import 'providers/settings_provider.dart';
import 'providers/sensor_provider.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/analytics/screens/analytics_screen.dart';
import 'features/ai_insights/screens/ai_insights_screen.dart';
import 'features/alerts/screens/alerts_screen.dart';
import 'features/settings/screens/settings_screen.dart';

class AgriSenseApp extends StatelessWidget {
  final PreferencesService prefs;

  const AgriSenseApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(baseUrl: prefs.apiBaseUrl);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs, apiClient)),
        ChangeNotifierProxyProvider<SettingsProvider, SensorProvider>(
          create: (ctx) => SensorProvider(apiClient, ctx.read<SettingsProvider>()),
          update: (_, settings, previous) => previous ?? SensorProvider(apiClient, settings),
        ),
      ],
      child: MaterialApp(
        title: 'AgriSense',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainNavigationShell(),
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _navigateToIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openAlertsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AlertsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onNavigateToAlerts: _openAlertsScreen,
        onNavigateToInsights: () => _navigateToIndex(2),
        onNavigateToSettings: () => _navigateToIndex(3),
      ),
      const AnalyticsScreen(),
      const AiInsightsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _navigateToIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            selectedIcon: Icon(Icons.show_chart_rounded),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop_rounded),
            label: 'Irrigation',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
