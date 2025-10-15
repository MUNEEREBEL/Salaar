// lib/screens/citizen/home_screen_fixed.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider_complete.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/issues_provider.dart';
import '../../providers/announcements_provider.dart';
import '../../services/geoapify_service.dart';
import '../../theme/app_theme.dart';
import 'report_issue_screen_new.dart';
import 'reports_screen_fixed.dart';
import 'community_screen_fixed.dart';
import 'profile_screen_fixed.dart';
import 'map_screen_enhanced.dart';

class HomeScreenFixed extends StatefulWidget {
  const HomeScreenFixed({Key? key}) : super(key: key);

  @override
  State<HomeScreenFixed> createState() => _HomeScreenFixedState();
}

class _HomeScreenFixedState extends State<HomeScreenFixed> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    final announcementsProvider = Provider.of<AnnouncementsProvider>(context, listen: false);
    
    await issuesProvider.fetchAllIssues();
    // announcementsProvider.fetchAnnouncements(); // Method doesn't exist
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderComplete>(context);
    final issuesProvider = Provider.of<IssuesProvider>(context);
    final announcementsProvider = Provider.of<AnnouncementsProvider>(context);

    if (authProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: AppTheme.bodyLarge.copyWith(color: AppTheme.whiteColor),
              ),
            ],
          ),
        ),
      );
    }

    final user = authProvider.currentUser!;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.darkBackground,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      ),
                    ),
                    child: Icon(
                      Icons.verified_user,
                      color: AppTheme.whiteColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SALAAR',
                        style: AppTheme.headlineMedium.copyWith(
                          color: AppTheme.whiteColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Welcome back, ${user.fullName ?? user.username ?? 'User'}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.greyColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Provider.of<NavigationProvider>(context, listen: false).setCurrentIndex(4);
                },
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  child: Text(
                    (user.fullName ?? user.username ?? 'U').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),

          // Weather Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildWeatherCard(),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildQuickActions(),
            ),
          ),

          // Announcements
          if (announcementsProvider.announcements.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildAnnouncementsSection(announcementsProvider),
              ),
            ),

          // Recent Reports
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildRecentReportsSection(issuesProvider),
            ),
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildStatsSection(issuesProvider),
            ),
          ),

          // Bottom Spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.wb_sunny,
              color: AppTheme.accentColor,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vizianagaram, India',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '25°C • Sunny',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.greyColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Good Day',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle_outline,
                title: 'Report Issue',
                subtitle: 'Report a civic issue',
                color: AppTheme.primaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportIssueScreenNew()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.assignment_outlined,
                title: 'My Reports',
                subtitle: 'View your reports',
                color: AppTheme.successColor,
                onTap: () {
                  Provider.of<NavigationProvider>(context, listen: false).setCurrentIndex(1);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.people_outline,
                title: 'Community',
                subtitle: 'Join discussions',
                color: AppTheme.accentColor,
                onTap: () {
                  Provider.of<NavigationProvider>(context, listen: false).setCurrentIndex(3);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.map_outlined,
                title: 'Map View',
                subtitle: 'See all issues',
                color: AppTheme.secondaryColor,
                onTap: () {
                  // Navigate to map view
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MapScreenEnhanced(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.greyColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsSection(AnnouncementsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Announcements',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...provider.announcements.take(3).map((announcement) => Card(
          color: AppTheme.darkSurface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  announcement.content,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.greyColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildRecentReportsSection(IssuesProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Reports',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Provider.of<NavigationProvider>(context, listen: false).setCurrentIndex(1);
              },
              child: Text(
                'View All',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (provider.issues.isEmpty)
          Card(
            color: AppTheme.darkSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    color: AppTheme.greyColor,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reports yet',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.whiteColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by reporting your first issue',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.greyColor,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...provider.issues.take(3).map((issue) => Card(
            color: AppTheme.darkSurface,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(issue.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.issueType.toUpperCase(),
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.whiteColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          issue.description,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.greyColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _getStatusText(issue.status),
                    style: AppTheme.bodySmall.copyWith(
                      color: _getStatusColor(issue.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )),
      ],
    );
  }

  Widget _buildStatsSection(IssuesProvider issuesProvider) {
    final totalReports = issuesProvider.issues.length;
    final completedReports = issuesProvider.issues.where((issue) => issue.status == 'completed').length;
    final successRate = totalReports > 0 ? ((completedReports / totalReports) * 100).round() : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Local Community Stats',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total',
                value: totalReports.toString(),
                icon: Icons.report_problem,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Solved',
                value: completedReports.toString(),
                icon: Icons.check_circle,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Success Rate',
                value: '$successRate%',
                icon: Icons.trending_up,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Location',
                value: 'Vizianagaram',
                icon: Icons.location_on,
                color: AppTheme.accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.greyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.accentColor;
      case 'in_progress':
        return AppTheme.primaryColor;
      case 'completed':
        return AppTheme.successColor;
      case 'rejected':
        return AppTheme.errorColor;
      default:
        return AppTheme.greyColor;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}
