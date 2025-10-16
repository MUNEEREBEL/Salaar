// lib/screens/citizen/community_screen_fixed.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/auth_provider_complete.dart';
import '../../providers/issues_provider.dart';
import '../../theme/app_theme.dart';
import 'discussions_screen.dart';
import '../../widgets/salaar_loading_widget.dart';

class CommunityScreenFixed extends StatefulWidget {
  const CommunityScreenFixed({Key? key}) : super(key: key);

  @override
  State<CommunityScreenFixed> createState() => _CommunityScreenFixedState();
}

class _CommunityScreenFixedState extends State<CommunityScreenFixed>
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

    _animationController.forward();
    // Load data after the frame is built to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    
    // Load data asynchronously without blocking UI - prioritize leaderboard first
    try {
      // Load leaderboard first (most important)
      await communityProvider.fetchLeaderboard();
      
      // Load other data in background
      Future.wait([
        communityProvider.fetchDiscussions(),
        issuesProvider.fetchAllIssues(),
      ]).catchError((error) {
        print('Error loading secondary community data: $error');
      });
    } catch (error) {
      print('Error loading community data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final communityProvider = Provider.of<CommunityProvider>(context);
    final authProvider = Provider.of<AuthProviderComplete>(context);
    final issuesProvider = Provider.of<IssuesProvider>(context);

    // Show loading only if no data is available yet
    if (communityProvider.isLoading && communityProvider.leaderboard.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: SalaarLoadingWidget(message: 'Loading community...'),
      );
    }

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
                                  'Community',
                                  style: AppTheme.headlineMedium.copyWith(
                                    color: AppTheme.whiteColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Connect with your neighbors',
                                  style: AppTheme.bodyLarge.copyWith(
                                    color: AppTheme.greyColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const DiscussionsScreen()),
                              );
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.chat,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              _showCreateDiscussionDialog();
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.add,
                                color: AppTheme.accentColor,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Community Stats
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildCommunityStats(communityProvider, issuesProvider),
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

            // Leaderboard
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildLeaderboard(communityProvider),
                  ),
                ),
              ),
            ),

            // Recent Discussions
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildRecentDiscussions(communityProvider),
                  ),
                ),
              ),
            ),

            // Community Insights
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildCommunityInsights(issuesProvider),
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

  Widget _buildCommunityStats(CommunityProvider provider, IssuesProvider issuesProvider) {
    final totalIssues = issuesProvider.issues.length;
    final activeUsers = provider.leaderboard.length;
    final discussions = provider.discussions.length;
    
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Overview',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Issues',
                    totalIssues.toString(),
                    Icons.assignment,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Active Users',
                    activeUsers.toString(),
                    Icons.people,
                    AppTheme.secondaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Discussions',
                    discussions.toString(),
                    Icons.chat,
                    AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
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
        // Responsive grid for action cards
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              // Wide screen - 3 columns
              return Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.chat,
                      title: 'Start Discussion',
                      subtitle: 'Share ideas',
                      color: AppTheme.primaryColor,
                      onTap: () => _showCreateDiscussionDialog(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.people,
                      title: 'View Members',
                      subtitle: 'See who\'s active',
                      color: AppTheme.secondaryColor,
                      onTap: () => _showMembersDialog(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.insights,
                      title: 'Community Stats',
                      subtitle: 'View analytics',
                      color: AppTheme.accentColor,
                      onTap: () => _showStatsDialog(),
                    ),
                  ),
                ],
              );
            } else {
              // Narrow screen - 2 columns with scroll
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: (constraints.maxWidth - 24) / 2,
                      child: _buildActionCard(
                        icon: Icons.chat,
                        title: 'Start Discussion',
                        subtitle: 'Share ideas',
                        color: AppTheme.primaryColor,
                        onTap: () => _showCreateDiscussionDialog(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: (constraints.maxWidth - 24) / 2,
                      child: _buildActionCard(
                        icon: Icons.people,
                        title: 'View Members',
                        subtitle: 'See who\'s active',
                        color: AppTheme.secondaryColor,
                        onTap: () => _showMembersDialog(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: (constraints.maxWidth - 24) / 2,
                      child: _buildActionCard(
                        icon: Icons.insights,
                        title: 'Community Stats',
                        subtitle: 'View analytics',
                        color: AppTheme.accentColor,
                        onTap: () => _showStatsDialog(),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.greyColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboard(CommunityProvider provider) {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: AppTheme.accentColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Top Contributors',
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.leaderboard.isEmpty)
              _buildEmptyLeaderboard()
            else
              ...provider.leaderboard.take(5).map((user) => _buildLeaderboardItem(user)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLeaderboard() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            color: AppTheme.greyColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No Contributors Yet',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to contribute to the community!',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.greyColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(CommunityUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.greyColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
            child: Text(
              (user.fullName ?? 'U').substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName ?? 'Unknown User',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${user.issuesReported} reports',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.greyColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${user.expPoints} XP',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDiscussions(CommunityProvider provider) {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.chat, color: AppTheme.primaryColor, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recent Discussions',
                          style: AppTheme.titleLarge.copyWith(
                            color: AppTheme.whiteColor,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DiscussionsScreen()),
                    );
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.discussions.isEmpty)
              _buildEmptyDiscussions()
            else
              ...provider.discussions.take(3).map((discussion) => _buildDiscussionItem(discussion)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDiscussions() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: AppTheme.greyColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No Discussions Yet',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the first discussion in your community!',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.greyColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionItem(discussion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.greyColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            discussion['title'] ?? 'Untitled Discussion',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.whiteColor,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            discussion['content'] ?? '',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.greyColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                child: Text(
                  (discussion['author'] ?? 'U').substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                discussion['author'] ?? 'Unknown',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.greyColor,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(discussion['created_at'] ?? DateTime.now()),
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.greyColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityInsights(IssuesProvider issuesProvider) {
    final allIssues = issuesProvider.issues;
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
            Row(
              children: [
                Icon(Icons.insights, color: AppTheme.accentColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Community Insights',
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Most reported categories
            Text(
              'Most Reported Issues',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            ...(categoryCount.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
                .take(3)
                .map((entry) => _buildCategoryInsight(entry.key, entry.value, allIssues.length))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryInsight(String category, int count, int total) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.greyColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getCategoryIcon(category),
            color: _getCategoryColor(category),
            size: 20,
          ),
          const SizedBox(width: 12),
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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
        return AppTheme.primaryColor;
      case 'sanitation':
        return Colors.orange;
      case 'traffic':
        return Colors.red;
      case 'safety':
        return Colors.purple;
      case 'environment':
        return Colors.green;
      case 'utilities':
        return Colors.blue;
      case 'other':
        return AppTheme.greyColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
        return Icons.construction;
      case 'sanitation':
        return Icons.cleaning_services;
      case 'traffic':
        return Icons.traffic;
      case 'safety':
        return Icons.security;
      case 'environment':
        return Icons.eco;
      case 'utilities':
        return Icons.electrical_services;
      case 'other':
        return Icons.help_outline;
      default:
        return Icons.assignment;
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

  void _showCreateDiscussionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Create Discussion',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        content: Text(
          'Discussion creation feature will be available soon!',
          style: TextStyle(color: AppTheme.greyColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showMembersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Community Members',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        content: Text(
          'Member list feature will be available soon!',
          style: TextStyle(color: AppTheme.greyColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Community Statistics',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        content: Text(
          'Detailed statistics feature will be available soon!',
          style: TextStyle(color: AppTheme.greyColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }
}