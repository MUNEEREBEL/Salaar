// lib/screens/main_app_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/auth_provider_complete.dart';
import '../../providers/issues_provider.dart';
import '../../providers/announcements_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/worker_assignment_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/success_card.dart';
import 'home_screen_fixed.dart';
import 'home_screen_simple.dart';
import 'reports_screen_fixed.dart';
import 'report_issue_screen_new.dart';
import 'community_screen_fixed.dart';
import 'profile_screen_fixed.dart';
import 'map_screen_enhanced.dart';
import 'notifications_screen.dart';
import '../admin/admin_dashboard_complete.dart';
import '../admin/admin_dashboard_focused.dart';
import '../worker/worker_dashboard_complete.dart';
import '../worker/worker_dashboard_ai_enhanced.dart';
import '../worker/worker_dashboard_modern.dart';
import '../developer/developer_dashboard_complete.dart';
import '../auth/user_setup_screen.dart';
import '../auth/auth_screen_fixed.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _initializeRealtimeUpdates();
    });
  }

  void _initializeRealtimeUpdates() {
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    issuesProvider.initializeRealtimeUpdates();
  }

  Future<void> _loadData() async {
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    final announcementsProvider = Provider.of<AnnouncementsProvider>(context, listen: false);
    final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
    
    await Future.wait([
      issuesProvider.fetchAllIssues(),
      // announcementsProvider.fetchAnnouncements(), // Method doesn't exist
      communityProvider.fetchLeaderboard(),
      communityProvider.fetchDiscussions(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return _buildMainContent(context);
  }

  Widget _buildMainContent(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final authProvider = Provider.of<AuthProviderComplete>(context);

    // Show loading screen while auth is initializing
    if (authProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: AppTheme.whiteColor,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Initializing Salaar...',
                style: TextStyle(
                  color: AppTheme.greyColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If not authenticated, show auth screen
    if (!authProvider.isAuthenticated) {
      return AuthScreenFixed();
    }

    // Check if user needs to complete setup
    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      final user = authProvider.currentUser!;
      if (user.fullName == null || user.fullName!.isEmpty || 
          user.username == null || user.username!.isEmpty) {
        return const UserSetupScreen();
      }
    }

    // Role-based screens
    List<Widget> _userScreens = [
      const HomeScreenSimple(),           // Home
      const ReportsScreenFixed(),         // Reports
      const ReportIssueScreenNew(),       // Report Issue
      const CommunityScreenFixed(),       // Community
      const ProfileScreenFixed(),         // Profile
    ];

    List<Widget> _workerScreens = [
      const WorkerDashboardModern(),
    ];

    List<Widget> _adminScreens = [
      const AdminDashboardFocused(),
      const MapScreenEnhanced(), // Admins get map view
      const CommunityScreenFixed(),
      const ProfileScreenFixed(),
    ];

    List<Widget> _developerScreens = [
      const DeveloperDashboardComplete(),
      const MapScreenEnhanced(), // Developers get map view
      const ProfileScreenFixed(),
    ];

    final List<Widget> _screens = authProvider.isAdmin
        ? _adminScreens
        : authProvider.isWorker
            ? _workerScreens
            : authProvider.isDeveloper
                ? _developerScreens
                : _userScreens;

    return Scaffold(
      body: _screens[navProvider.currentIndex.clamp(0, _screens.length - 1)],
      bottomNavigationBar: authProvider.isWorker 
          ? null // No bottom navigation for workers
          : Container(
              decoration: BoxDecoration(
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFD4AF37).withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: BottomNavigationBar(
                  currentIndex: navProvider.currentIndex.clamp(0, _screens.length - 1),
                  onTap: (index) {
                    navProvider.setCurrentIndexSafe(index, _screens.length - 1);
                    // Refresh data when switching tabs
                    _loadData();
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.black,
                  selectedItemColor: const Color(0xFFD4AF37),
                  unselectedItemColor: Colors.grey,
                  selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 10),
                  items: _getNavigationItems(authProvider),
                ),
              ),
            ),
    );
  }


  List<BottomNavigationBarItem> _getNavigationItems(AuthProviderComplete authProvider) {
    if (authProvider.isAdmin) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Community',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else if (authProvider.isWorker) {
      return const []; // No bottom navigation for workers
    } else if (authProvider.isDeveloper) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.code_outlined),
          activeIcon: Icon(Icons.code),
          label: 'Dev Tools',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      return [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined, size: 32),
          activeIcon: Icon(Icons.home, size: 32),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt_outlined, size: 32),
          activeIcon: Icon(Icons.list_alt, size: 32),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline, size: 32),
          activeIcon: Icon(Icons.add_circle, size: 32),
          label: 'Report',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outlined, size: 32),
          activeIcon: Icon(Icons.people, size: 32),
          label: 'Community',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined, size: 32),
          activeIcon: Icon(Icons.person, size: 32),
          label: 'Profile',
        ),
      ];
    }
  }
}