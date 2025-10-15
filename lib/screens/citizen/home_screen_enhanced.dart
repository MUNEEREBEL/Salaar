// lib/screens/citizen/home_screen_enhanced.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider_complete.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/issues_provider.dart';
import '../../providers/announcements_provider.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import 'report_issue_screen_new.dart';
import 'reports_screen_fixed.dart';
import 'community_screen_fixed.dart';
import 'profile_screen_fixed.dart';
import 'map_screen_enhanced.dart';

class HomeScreenEnhanced extends StatefulWidget {
  const HomeScreenEnhanced({Key? key}) : super(key: key);

  @override
  State<HomeScreenEnhanced> createState() => _HomeScreenEnhancedState();
}

class _HomeScreenEnhancedState extends State<HomeScreenEnhanced>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.darkBackground,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        AppTheme.secondaryColor.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: AppTheme.bodyLarge.copyWith(
                                    color: AppTheme.greyColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.fullName ?? user.username ?? 'User',
                                  style: AppTheme.headlineMedium.copyWith(
                                    color: AppTheme.whiteColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Provider.of<NavigationProvider>(context, listen: false).setCurrentIndex(4);
                            },
                            icon: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
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
                    ),
                  ),
                ),
              ),
            ),

            // Weather Card
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildWeatherCard(),
                  ),
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildQuickActions(),
                  ),
                ),
              ),
            ),

            // Report Analytics
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildReportAnalytics(issuesProvider, user),
                  ),
                ),
              ),
            ),

            // Database Insights
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildDatabaseInsights(issuesProvider),
                  ),
                ),
              ),
            ),

            // Recent Reports
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildRecentReportsSection(issuesProvider),
                  ),
                ),
              ),
            ),

            // Bottom Spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.secondaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.wb_sunny,
                color: AppTheme.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Weather for Reporting',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Perfect conditions to report issues in your area',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.greyColor,
                    ),
                  ),
                ],
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
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.0, // Increased to prevent overflow
          children: [
            _buildActionCard(
              icon: Icons.report_problem,
              title: 'Report Issue',
              subtitle: 'New Report',
              color: AppTheme.primaryColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportIssueScreenNew()),
              ),
            ),
            _buildActionCard(
              icon: Icons.visibility,
              title: 'View Reports',
              subtitle: 'My Reports',
              color: AppTheme.secondaryColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsScreenFixed()),
              ),
            ),
            _buildActionCard(
              icon: Icons.map,
              title: 'Map View',
              subtitle: 'All Issues',
              color: AppTheme.infoColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapScreenEnhanced()),
              ),
            ),
            _buildActionCard(
              icon: Icons.people,
              title: 'Community',
              subtitle: 'Discussions',
              color: AppTheme.accentColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CommunityScreenFixed()),
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
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTheme.titleSmall.copyWith(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.greyColor,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportAnalytics(IssuesProvider issuesProvider, user) {
    final totalReports = user.issuesReported ?? 0;
    final verifiedReports = user.issuesVerified ?? 0;
    final pendingReports = totalReports - verifiedReports;
    
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Report Analytics',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsItem(
                    'Total Reports',
                    totalReports.toString(),
                    Icons.assignment,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildAnalyticsItem(
                    'Verified',
                    verifiedReports.toString(),
                    Icons.verified,
                    AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _buildAnalyticsItem(
                    'Pending',
                    pendingReports.toString(),
                    Icons.pending,
                    AppTheme.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            LinearProgressIndicator(
              value: totalReports > 0 ? verifiedReports / totalReports : 0,
              backgroundColor: AppTheme.darkBackground,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.successColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Verification Rate: ${totalReports > 0 ? ((verifiedReports / totalReports) * 100).toStringAsFixed(1) : 0}%',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.greyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, String value, IconData icon, Color color) {
    return Column(
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
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.greyColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDatabaseInsights(IssuesProvider issuesProvider) {
    final allIssues = issuesProvider.issues;
    final totalIssues = allIssues.length;
    final pendingIssues = allIssues.where((issue) => issue.status == 'pending').length;
    final inProgressIssues = allIssues.where((issue) => issue.status == 'in_progress').length;
    final completedIssues = allIssues.where((issue) => issue.status == 'completed').length;
    
    // Category breakdown
    final categoryCount = <String, int>{};
    for (var issue in allIssues) {
      categoryCount[issue.issueType] = (categoryCount[issue.issueType] ?? 0) + 1;
    }
    
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Insights',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Status Overview
            Row(
              children: [
                Expanded(
                  child: _buildInsightItem(
                    'Total Issues',
                    totalIssues.toString(),
                    Icons.assignment,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildInsightItem(
                    'Pending',
                    pendingIssues.toString(),
                    Icons.pending,
                    AppTheme.accentColor,
                  ),
                ),
                Expanded(
                  child: _buildInsightItem(
                    'In Progress',
                    inProgressIssues.toString(),
                    Icons.work,
                    AppTheme.secondaryColor,
                  ),
                ),
                Expanded(
                  child: _buildInsightItem(
                    'Completed',
                    completedIssues.toString(),
                    Icons.check_circle,
                    AppTheme.successColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Top Categories
            Text(
              'Most Reported Categories',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            ...(categoryCount.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
                .take(3)
                .map((entry) => _buildCategoryItem(entry.key, entry.value, totalIssues))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.greyColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String category, int count, int total) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category.toUpperCase(),
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$count ($percentage%)',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReportsSection(IssuesProvider issuesProvider) {
    final recentIssues = issuesProvider.issues.take(3).toList();
    
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
        
        if (recentIssues.isEmpty)
          _buildEmptyState()
        else
          ...recentIssues.map((issue) => _buildReportCard(issue)).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              'No Recent Reports',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildReportCard(issue) {
    return Card(
      color: AppTheme.darkSurface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to report detail
        },
        borderRadius: BorderRadius.circular(12),
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
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.greyColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (issue.imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: issue.imageUrls.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  issue.imageUrls[index],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 40,
                                      height: 40,
                                      color: AppTheme.darkCard,
                                      child: Icon(
                                        Icons.broken_image,
                                        color: AppTheme.greyColor,
                                        size: 16,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(issue.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(issue.status),
                  style: AppTheme.bodySmall.copyWith(
                    color: _getStatusColor(issue.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
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
