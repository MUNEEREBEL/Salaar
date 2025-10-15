// lib/screens/citizen/home_screen_simple.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_complete.dart';
import '../../providers/issues_provider.dart';
import '../../theme/app_theme.dart';
import 'report_issue_screen_new.dart';
import 'reports_screen_fixed.dart';
import 'map_screen_enhanced.dart';
import 'community_screen_fixed.dart';

class HomeScreenSimple extends StatefulWidget {
  const HomeScreenSimple({Key? key}) : super(key: key);

  @override
  State<HomeScreenSimple> createState() => _HomeScreenSimpleState();
}

class _HomeScreenSimpleState extends State<HomeScreenSimple> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    await issuesProvider.fetchAllIssues();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderComplete>(context);
    final issuesProvider = Provider.of<IssuesProvider>(context);

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

    final user = authProvider.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(
          child: Text(
            'Please log in to continue',
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.whiteColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.whiteColor.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      user.fullName ?? 'User',
                      style: AppTheme.headlineMedium.copyWith(
                        color: AppTheme.whiteColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Report issues and help improve your community',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.whiteColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: AppTheme.titleLarge.copyWith(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Column(
                children: [
                  _buildActionButton(
                    icon: Icons.report_problem,
                    title: 'Report Issue',
                    subtitle: 'Report a new problem',
                    color: AppTheme.primaryColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReportIssueScreenNew()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    icon: Icons.visibility,
                    title: 'My Reports',
                    subtitle: 'View your submitted reports',
                    color: AppTheme.secondaryColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReportsScreenFixed()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    icon: Icons.map,
                    title: 'Map View',
                    subtitle: 'See all issues on map',
                    color: AppTheme.infoColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapScreenEnhanced()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    icon: Icons.people,
                    title: 'Community',
                    subtitle: 'Join discussions',
                    color: AppTheme.accentColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CommunityScreenFixed()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Reports
              Text(
                'Recent Reports',
                style: AppTheme.titleLarge.copyWith(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (issuesProvider.issues.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: AppTheme.greyColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No reports yet',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.whiteColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Be the first to report an issue!',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.greyColor,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: issuesProvider.issues.take(3).length,
                  itemBuilder: (context, index) {
                    final issue = issuesProvider.issues[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue.title,
                            style: AppTheme.titleMedium.copyWith(
                              color: AppTheme.whiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(issue.status).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  issue.status.toUpperCase(),
                                  style: AppTheme.bodySmall.copyWith(
                                    color: _getStatusColor(issue.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatDate(issue.createdAt),
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.greyColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.darkSurface,
          foregroundColor: AppTheme.whiteColor,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.greyColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.greyColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warningColor;
      case 'in_progress':
        return AppTheme.infoColor;
      case 'completed':
        return AppTheme.successColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.greyColor;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
