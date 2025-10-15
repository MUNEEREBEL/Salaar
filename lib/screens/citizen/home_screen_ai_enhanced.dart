// lib/screens/citizen/home_screen_ai_enhanced.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider_complete.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/issues_provider.dart';
import '../../providers/announcements_provider.dart';
// import '../../providers/ai_home_provider.dart'; // File doesn't exist
import '../../services/geoapify_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
// import 'report_issue_screen_new.dart'; // File doesn't exist
import 'reports_screen_fixed.dart';
import 'community_screen_fixed.dart';
import 'profile_screen_simple.dart';

class HomeScreenAIEnhanced extends StatefulWidget {
  const HomeScreenAIEnhanced({Key? key}) : super(key: key);

  @override
  State<HomeScreenAIEnhanced> createState() => _HomeScreenAIEnhancedState();
}

class _HomeScreenAIEnhancedState extends State<HomeScreenAIEnhanced>
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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    final announcementsProvider = Provider.of<AnnouncementsProvider>(context, listen: false);
    final aiHomeProvider = Provider.of<AIHomeProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
    
    await issuesProvider.fetchAllIssues();
    
    // Load AI data if user is authenticated
    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      try {
        // Use default location if location service fails
        double lat = 18.1124; // Vizianagaram coordinates
        double lng = 83.4150;
        
        try {
          final location = await LocationService.getCurrentLocation();
          if (location != null) {
            lat = location['latitude'] ?? 18.1124;
            lng = location['longitude'] ?? 83.4150;
          }
        } catch (e) {
          print('Location service failed, using default location: $e');
        }
        
        await aiHomeProvider.loadAIData(
          latitude: lat,
          longitude: lng,
          userId: authProvider.currentUser!.id,
        );
      } catch (e) {
        print('Error loading AI data: $e');
        // Continue without AI data - the screen will still work
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderComplete>(context);
    final issuesProvider = Provider.of<IssuesProvider>(context);
    final announcementsProvider = Provider.of<AnnouncementsProvider>(context);
    final aiHomeProvider = Provider.of<AIHomeProvider>(context);

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
                'Loading AI Insights...',
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
        child: CustomScrollView(
        slivers: [
          // Enhanced App Bar with AI Status
          SliverAppBar(
            expandedHeight: 140,
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
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.psychology,
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
                        'SALAAR AI',
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
              // AI Status Indicator
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: aiHomeProvider.isLoading 
                      ? Colors.orange.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: aiHomeProvider.isLoading 
                        ? Colors.orange
                        : Colors.green,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      aiHomeProvider.isLoading ? Icons.sync : Icons.psychology,
                      color: aiHomeProvider.isLoading ? Colors.orange : Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      aiHomeProvider.isLoading ? 'AI Loading' : 'AI Active',
                      style: TextStyle(
                        color: aiHomeProvider.isLoading ? Colors.orange : Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

          // AI-Powered Weather Card
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildAIWeatherCard(aiHomeProvider),
                ),
              ),
            ),
          ),

          // AI Insights Section
          if (aiHomeProvider.aiInsights.isNotEmpty)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildAIInsightsSection(aiHomeProvider),
                  ),
                ),
              ),
            ),

          // Smart Recommendations
          if (aiHomeProvider.smartRecommendations.isNotEmpty)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSmartRecommendationsSection(aiHomeProvider),
                  ),
                ),
              ),
            ),

          // Enhanced Quick Actions
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildEnhancedQuickActions(),
                ),
              ),
            ),
          ),

          // Trending Issues (AI-Powered)
          if (aiHomeProvider.trendingIssues.isNotEmpty)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildTrendingIssuesSection(aiHomeProvider),
                  ),
                ),
              ),
            ),

          // Nearby Issues (AI-Prioritized)
          if (aiHomeProvider.nearbyIssues.isNotEmpty)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildNearbyIssuesSection(aiHomeProvider),
                  ),
                ),
              ),
            ),

          // Announcements
          if (announcementsProvider.announcements.isNotEmpty)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildAnnouncementsSection(announcementsProvider),
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

          // Enhanced Stats Cards
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildEnhancedStatsSection(issuesProvider, aiHomeProvider),
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

  Widget _buildAIWeatherCard(AIHomeProvider aiProvider) {
    final weatherInsights = aiProvider.weatherInsights;
    
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkSurface,
              AppTheme.darkSurface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.wb_sunny,
                      color: AppTheme.accentColor,
                      size: 32,
                    ),
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
                      weatherInsights['mood'] ?? 'Good Day',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (weatherInsights['weather_impact'] != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          weatherInsights['weather_impact'] ?? '',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.whiteColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIInsightsSection(AIHomeProvider aiProvider) {
    final insights = aiProvider.aiInsights;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.insights,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'AI Area Insights',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          color: AppTheme.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getHealthColor(insights['overall_health']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getHealthColor(insights['overall_health']).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${insights['overall_health'] ?? 'Good'}'.toUpperCase(),
                        style: AppTheme.bodySmall.copyWith(
                          color: _getHealthColor(insights['overall_health']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.psychology,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  insights['summary'] ?? 'Your area is generally well-maintained',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.whiteColor,
                  ),
                ),
                if (insights['positive_aspects'] != null && (insights['positive_aspects'] as List).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (insights['positive_aspects'] as List).map<Widget>((aspect) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          aspect,
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartRecommendationsSection(AIHomeProvider aiProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb,
              color: AppTheme.accentColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Smart Recommendations',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...aiProvider.smartRecommendations.take(3).map((recommendation) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: AppTheme.darkSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(recommendation['priority']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getRecommendationIcon(recommendation['type']),
                        color: _getPriorityColor(recommendation['priority']),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendation['title'] ?? 'Recommendation',
                            style: AppTheme.titleMedium.copyWith(
                              color: AppTheme.whiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recommendation['description'] ?? '',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.greyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (recommendation['action'] != null)
                      IconButton(
                        onPressed: () => _handleRecommendationAction(recommendation['action']),
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEnhancedQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.flash_on,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Quick Actions',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              icon: Icons.report_problem,
              title: 'Report Issue',
              subtitle: 'AI-Powered',
              color: AppTheme.primaryColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportIssueScreenNew()),
              ),
            ),
            _buildActionCard(
              icon: Icons.visibility,
              title: 'View Reports',
              subtitle: 'Smart Filter',
              color: AppTheme.secondaryColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsScreenFixed()),
              ),
            ),
            _buildActionCard(
              icon: Icons.people,
              title: 'Community',
              subtitle: 'AI Insights',
              color: AppTheme.accentColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CommunityScreenFixed()),
              ),
            ),
            _buildActionCard(
              icon: Icons.person,
              title: 'Profile',
              subtitle: 'Personalized',
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreenFixed()),
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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
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
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingIssuesSection(AIHomeProvider aiProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              color: AppTheme.accentColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Trending Issues',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                'AI Powered',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...aiProvider.trendingIssues.take(3).map((issue) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: AppTheme.darkSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(issue['severity']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTrendIcon(issue['trend']),
                        color: _getSeverityColor(issue['severity']),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue['type'] ?? 'Issue',
                            style: AppTheme.titleMedium.copyWith(
                              color: AppTheme.whiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${issue['count'] ?? 0} reports • ${issue['trend'] ?? 'stable'}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.greyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(issue['severity']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getSeverityColor(issue['severity']).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        issue['severity'] ?? 'medium',
                        style: AppTheme.bodySmall.copyWith(
                          color: _getSeverityColor(issue['severity']),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNearbyIssuesSection(AIHomeProvider aiProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Nearby Issues',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                'AI Prioritized',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...aiProvider.nearbyIssues.take(3).map((issue) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: AppTheme.darkSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getUrgencyColor(issue['urgency']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.warning,
                        color: _getUrgencyColor(issue['urgency']),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue['title'] ?? 'Nearby Issue',
                            style: AppTheme.titleMedium.copyWith(
                              color: AppTheme.whiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${issue['distance'] ?? 'Unknown'} • ${issue['severity'] ?? 'medium'}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.greyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getUrgencyColor(issue['urgency']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getUrgencyColor(issue['urgency']).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        issue['urgency'] ?? 'medium',
                        style: AppTheme.bodySmall.copyWith(
                          color: _getUrgencyColor(issue['urgency']),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAnnouncementsSection(AnnouncementsProvider announcementsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.campaign,
              color: AppTheme.accentColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Announcements',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...announcementsProvider.announcements.take(2).map((announcement) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: AppTheme.darkSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title ?? 'Announcement',
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.whiteColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      announcement.content ?? '',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.greyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRecentReportsSection(IssuesProvider issuesProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.assignment,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Recent Reports',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsScreenFixed()),
              ),
              child: Text(
                'View All',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...issuesProvider.issues.take(3).map((issue) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: AppTheme.darkSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(issue.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIssueIcon(issue.issueType),
                        color: _getStatusColor(issue.status),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue.issueType,
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(issue.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(issue.status).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        issue.status,
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
        }).toList(),
      ],
    );
  }

  Widget _buildEnhancedStatsSection(IssuesProvider issuesProvider, AIHomeProvider aiProvider) {
    final totalIssues = issuesProvider.issues.length;
    final resolvedIssues = issuesProvider.issues.where((issue) => issue.status == 'resolved').length;
    final pendingIssues = issuesProvider.issues.where((issue) => issue.status == 'pending').length;
    final inProgressIssues = issuesProvider.issues.where((issue) => issue.status == 'in_progress').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.analytics,
              color: AppTheme.accentColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'AI-Enhanced Statistics',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Live Data',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              title: 'Total Issues',
              value: totalIssues.toString(),
              icon: Icons.assignment,
              color: AppTheme.primaryColor,
              trend: '+12%',
            ),
            _buildStatCard(
              title: 'Resolved',
              value: resolvedIssues.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
              trend: '+8%',
            ),
            _buildStatCard(
              title: 'In Progress',
              value: inProgressIssues.toString(),
              icon: Icons.hourglass_empty,
              color: Colors.orange,
              trend: '+5%',
            ),
            _buildStatCard(
              title: 'Pending',
              value: pendingIssues.toString(),
              icon: Icons.pending,
              color: Colors.red,
              trend: '-3%',
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
    required String trend,
  }) {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: trend.startsWith('+') ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend,
                    style: AppTheme.bodySmall.copyWith(
                      color: trend.startsWith('+') ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.headlineMedium.copyWith(
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for colors and icons
  Color _getHealthColor(String? health) {
    switch (health?.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getUrgencyColor(String? urgency) {
    switch (urgency?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'pending':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRecommendationIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'action':
        return Icons.flash_on;
      case 'insight':
        return Icons.lightbulb;
      case 'tip':
        return Icons.tips_and_updates;
      default:
        return Icons.info;
    }
  }

  IconData _getTrendIcon(String? trend) {
    switch (trend?.toLowerCase()) {
      case 'increasing':
        return Icons.trending_up;
      case 'decreasing':
        return Icons.trending_down;
      case 'stable':
        return Icons.trending_flat;
      default:
        return Icons.trending_flat;
    }
  }

  IconData _getIssueIcon(String? issueType) {
    switch (issueType?.toLowerCase()) {
      case 'road':
        return Icons.route;
      case 'water':
        return Icons.water_drop;
      case 'electricity':
        return Icons.electrical_services;
      case 'waste':
        return Icons.delete;
      case 'public safety':
        return Icons.security;
      case 'environment':
        return Icons.eco;
      default:
        return Icons.report_problem;
    }
  }

  void _handleRecommendationAction(String? action) {
    switch (action) {
      case 'report_issue':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReportIssueScreenNew()),
        );
        break;
      case 'view_reports':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReportsScreenFixed()),
        );
        break;
      case 'join_community':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CommunityScreenFixed()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action: $action'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
    }
  }
}
