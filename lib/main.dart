// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider_complete.dart';
import 'providers/navigation_provider.dart';
import 'providers/issues_provider.dart';
import 'providers/announcements_provider.dart';
import 'providers/community_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/ai_home_provider.dart';
import 'providers/worker_assignment_provider.dart';
import 'screens/citizen/main_app_screen.dart';
import 'screens/auth/auth_screen_fixed.dart';
import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/citizen/report_issue_screen_new.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/realtime_service.dart';
import 'services/background_service.dart';
import 'services/comprehensive_permission_service.dart';
import 'services/app_initialization_service.dart';
import 'services/maintenance_service.dart';

// Expose a global supabase client if legacy services import it
late final SupabaseClient supabase;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the entire app
  final success = await AppInitializationService.initializeApp();
  if (!success) {
    print('❌ App initialization failed. Some features may not work properly.');
  }
  
  // Set global supabase client for legacy services
  supabase = Supabase.instance.client;
  
  // Auto-disable maintenance mode if it's enabled
  try {
    final isMaintenance = await MaintenanceService.isMaintenanceMode();
    if (isMaintenance) {
      print('🔧 Maintenance mode detected, disabling automatically...');
      await MaintenanceService.setMaintenanceMode(false, 'Server is under maintenance. Please try again later.');
      print('✅ Maintenance mode disabled automatically');
    }
  } catch (e) {
    print('⚠️ Could not check maintenance mode: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProviderComplete>(create: (_) => AuthProviderComplete()),
        ChangeNotifierProvider<NavigationProvider>(create: (_) => NavigationProvider()),
        ChangeNotifierProvider<IssuesProvider>(create: (_) => IssuesProvider()),
        ChangeNotifierProvider<AnnouncementsProvider>(create: (_) => AnnouncementsProvider()),
        ChangeNotifierProvider<CommunityProvider>(create: (_) => CommunityProvider()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AIHomeProvider>(create: (_) => AIHomeProvider()),
        ChangeNotifierProvider<WorkerAssignmentProvider>(create: (_) => WorkerAssignmentProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Salaar Reporter',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: AuthWrapper(),
            debugShowCheckedModeBanner: false,
            routes: {
              '/settings': (context) => const SettingsScreen(),
              '/login': (context) => const AuthScreenFixed(),
              '/report-issue': (context) => const ReportIssueScreenNew(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // All initialization is now handled by AppInitializationService
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderComplete>(context);

    if (authProvider.isLoading) {
      return const SplashScreen();
    }

    // If user is authenticated, show main app regardless of profile loading errors
    if (authProvider.isAuthenticated) {
      return MainAppScreen();
    }

    // If there's an error and user is not authenticated, show auth screen
    if (authProvider.error != null && !authProvider.isAuthenticated) {
      return AuthScreenFixed();
    }

    // Default: show auth screen if not authenticated and no error
    return AuthScreenFixed();
  }

  @override
  void dispose() {
    // Cleanup is handled by AppInitializationService
    super.dispose();
  }
}