// lib/screens/worker/worker_dashboard_ai_enhanced.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_complete.dart';
import '../../providers/worker_assignment_provider.dart';
import '../../providers/issues_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/salaar_loading_widget.dart';
import '../../models/user.dart';

class WorkerDashboardAIEnhanced extends StatefulWidget {
  const WorkerDashboardAIEnhanced({Key? key}) : super(key: key);

  @override
  State<WorkerDashboardAIEnhanced> createState() => _WorkerDashboardAIEnhancedState();
}

class _WorkerDashboardAIEnhancedState extends State<WorkerDashboardAIEnhanced>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    final workerProvider = Provider.of<WorkerAssignmentProvider>(context, listen: false);
    
    await issuesProvider.fetchAllIssues();
    await workerProvider.loadWorkerData();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderComplete>(context);
    // final workerProvider = Provider.of<WorkerAssignmentProvider>(context);

    if (authProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: const Center(
          child: SalaarLoadingWidget(message: 'Loading...'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        title: Text(
          'AI Enhanced Dashboard',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.whiteColor),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentColor,
          labelColor: AppTheme.whiteColor,
          unselectedLabelColor: AppTheme.greyColor,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.assignment), text: 'My Tasks'),
            Tab(icon: Icon(Icons.work), text: 'Available'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildMyTasksTab(),
            _buildAvailableTasksTab(),
            _buildAnalyticsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 20),
          _buildAIInsightsSection(),
          const SizedBox(height: 20),
          _buildQuickActionsSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final authProvider = Provider.of<AuthProviderComplete>(context);
    final user = authProvider.currentUser;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentColor, AppTheme.accentColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${user?.fullName ?? 'Worker'}!',
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.whiteColor,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI is analyzing your workload and optimizing your tasks',
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.whiteColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.psychology, color: AppTheme.accentColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'AI Insights',
              style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              _buildInsightCard(
                'Workload Analysis',
                'Your current efficiency is 85%',
                Icons.trending_up,
                AppTheme.successColor,
              ),
              const SizedBox(height: 12),
              _buildInsightCard(
                'Route Optimization',
                'AI suggests grouping nearby tasks',
                Icons.route,
                AppTheme.warningColor,
              ),
              const SizedBox(height: 12),
              _buildInsightCard(
                'Weather Alert',
                'Rain expected in 2 hours',
                Icons.cloud,
                AppTheme.errorColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, String description, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on, color: AppTheme.accentColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'Quick Actions',
              style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Auto Assign',
                Icons.auto_awesome,
                () => _showAutoAssignDialog(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Refresh Data',
                Icons.refresh,
                _loadData,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.accentColor, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.whiteColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTasksTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 64, color: AppTheme.greyColor),
          SizedBox(height: 16),
          Text(
            'No assigned tasks',
            style: TextStyle(color: AppTheme.greyColor, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Tasks will appear here when assigned',
            style: TextStyle(color: AppTheme.greyColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTasksTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work, size: 64, color: AppTheme.greyColor),
          SizedBox(height: 16),
          Text(
            'No available tasks',
            style: TextStyle(color: AppTheme.greyColor, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Available tasks will appear here',
            style: TextStyle(color: AppTheme.greyColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTasksTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: AppTheme.greyColor),
          SizedBox(height: 16),
          Text(
            'No completed tasks',
            style: TextStyle(color: AppTheme.greyColor, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Completed tasks will appear here',
            style: TextStyle(color: AppTheme.greyColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Analytics',
            style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics, size: 64, color: AppTheme.greyColor),
                  SizedBox(height: 16),
                  Text(
                    'Analytics coming soon',
                    style: TextStyle(color: AppTheme.greyColor, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Performance metrics will be displayed here',
                    style: TextStyle(color: AppTheme.greyColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAutoAssignDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Auto Assign Tasks',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
        ),
        content: Text(
          'AI will automatically assign the best available tasks to you based on your location, skills, and current workload.',
          style: AppTheme.bodyLarge.copyWith(color: AppTheme.greyColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.greyColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Auto-assignment feature coming soon!'),
                  backgroundColor: AppTheme.warningColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
            child: const Text('Auto Assign', style: TextStyle(color: AppTheme.whiteColor)),
          ),
        ],
      ),
    );
  }
}