// lib/screens/worker/worker_dashboard_complete.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider_complete.dart';
import '../../providers/issues_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/salaar_loading_widget.dart';
import '../../models/user.dart';
import '../../services/supabase_service.dart';

class WorkerDashboardComplete extends StatefulWidget {
  const WorkerDashboardComplete({Key? key}) : super(key: key);

  @override
  State<WorkerDashboardComplete> createState() => _WorkerDashboardCompleteState();
}

class _WorkerDashboardCompleteState extends State<WorkerDashboardComplete>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _assignedTasks = [];
  List<dynamic> _completedTasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
      issuesProvider.fetchAllIssues();
      _loadWorkerTasks();
    });
  }

  Future<void> _loadWorkerTasks() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser != null) {
        // Load assigned tasks
        final assignedResponse = await SupabaseService.supabase
            .from('issues')
            .select('*')
            .eq('assigned_to', currentUser.id)
            .inFilter('status', ['assigned', 'in_progress'])
            .order('created_at', ascending: false);
        
        _assignedTasks = assignedResponse as List;
        
        // Load completed tasks
        final completedResponse = await SupabaseService.supabase
            .from('issues')
            .select('*')
            .eq('assigned_to', currentUser.id)
            .eq('status', 'completed')
            .order('created_at', ascending: false)
            .limit(10);
        
        _completedTasks = completedResponse as List;
      }
    } catch (e) {
      print('Error loading worker tasks: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderComplete>(context);
    final issuesProvider = Provider.of<IssuesProvider>(context);

    if (authProvider.isLoading || issuesProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: SalaarLoadingWidget(message: 'Loading worker dashboard...'),
      );
    }

    final user = authProvider.currentUser!;
    final issues = issuesProvider.issues;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Worker Dashboard',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.greyColor,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'My Tasks', icon: Icon(Icons.assignment)),
            Tab(text: 'Performance', icon: Icon(Icons.trending_up)),
          ],
        ),
        actions: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
            child: Text(
              (user.fullName ?? user.username ?? 'W').substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(user),
          _buildMyTasksTab(),
          _buildPerformanceTab(user),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(user) {
    final assignedCount = _assignedTasks.length;
    final completedCount = _completedTasks.length;
    final successRate = completedCount > 0 
        ? ((completedCount / (assignedCount + completedCount)) * 100).round()
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          _buildWelcomeSection(user),
          const SizedBox(height: 24),
          
          // Task Stats
          _buildTaskStats(assignedCount, completedCount, successRate),
          const SizedBox(height: 24),
          
          // Quick Actions
          _buildQuickActions(),
          const SizedBox(height: 24),
          
          // Recent Activity
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(user) {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.successColor],
                ),
              ),
              child: Icon(
                Icons.engineering,
                color: AppTheme.whiteColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user.fullName ?? user.username}',
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Worker Dashboard - Manage your tasks efficiently',
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

  Widget _buildTaskStats(int assigned, int completed, int successRate) {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Statistics',
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
                    'Assigned Tasks',
                    assigned.toString(),
                    Icons.assignment,
                    AppTheme.accentColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    completed.toString(),
                    Icons.check_circle,
                    AppTheme.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Success Rate',
                    '$successRate%',
                    Icons.trending_up,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Total XP',
                    '${_completedTasks.length * 20}',
                    Icons.stars,
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
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
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.greyColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
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
                    'Start GPS',
                    Icons.gps_fixed,
                    AppTheme.primaryColor,
                    () => _startGPSTracking(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    'View Map',
                    Icons.map,
                    AppTheme.successColor,
                    () => _openMapView(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    'Call Admin',
                    Icons.phone,
                    AppTheme.accentColor,
                    () => _callAdmin(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_completedTasks.isEmpty)
              Center(
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
                        'No recent activity',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.whiteColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._completedTasks.take(3).map((task) => _buildActivityItem(task)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.successColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Completed: ${task['issue_type']?.toString().toUpperCase() ?? 'UNKNOWN'}',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task['description'] ?? 'No description',
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
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Completed',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTasksTab() {
    if (_isLoading) {
      return Center(
        child: SalaarLoadingWidget(message: 'Loading tasks...'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Task Filter
          _buildTaskFilter(),
          const SizedBox(height: 16),
          
          // Assigned Tasks
          if (_assignedTasks.isNotEmpty) ...[
            Text(
              'Assigned Tasks',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._assignedTasks.map((task) => _buildTaskCard(task, true)),
          ],
          
          // Completed Tasks
          if (_completedTasks.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Recently Completed',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._completedTasks.take(5).map((task) => _buildTaskCard(task, false)),
          ],
          
          if (_assignedTasks.isEmpty && _completedTasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      color: AppTheme.greyColor,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tasks assigned yet',
                      style: AppTheme.titleLarge.copyWith(
                        color: AppTheme.whiteColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for new assignments',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.greyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskFilter() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                style: TextStyle(color: AppTheme.whiteColor),
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  hintStyle: TextStyle(color: AppTheme.greyColor),
                  prefixIcon: Icon(Icons.search, color: AppTheme.greyColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.greyColor.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.greyColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => _loadWorkerTasks(),
              icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(task, bool isAssigned) {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  task['issue_type']?.toString().toUpperCase() ?? 'UNKNOWN',
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAssigned 
                        ? AppTheme.accentColor.withOpacity(0.1)
                        : AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isAssigned ? 'Assigned' : 'Completed',
                    style: AppTheme.bodySmall.copyWith(
                      color: isAssigned ? AppTheme.accentColor : AppTheme.successColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task['description'] ?? 'No description available',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.greyColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryColor, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task['location'] ?? 'Location not specified',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.greyColor,
                    ),
                  ),
                ),
                Icon(Icons.access_time, color: AppTheme.greyColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  _formatDate(DateTime.parse(task['created_at'] ?? DateTime.now().toIso8601String())),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
            if (isAssigned) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startTask(task),
                      icon: Icon(Icons.play_arrow, size: 16),
                      label: Text('Start Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.whiteColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewTaskDetails(task),
                      icon: Icon(Icons.visibility, size: 16),
                      label: Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTab(user) {
    final completedCount = _completedTasks.length;
    final assignedCount = _assignedTasks.length;
    final successRate = (assignedCount + completedCount) > 0 
        ? ((completedCount / (assignedCount + completedCount)) * 100).round()
        : 0;
    final totalXP = completedCount * 20; // 20 XP per completed task

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Performance Overview
          _buildPerformanceOverview(completedCount, assignedCount, successRate, totalXP),
          const SizedBox(height: 16),
          
          // Performance Chart (placeholder)
          _buildPerformanceChart(),
          const SizedBox(height: 16),
          
          // Achievements
          _buildAchievements(),
          const SizedBox(height: 16),
          
          // Task History
          _buildTaskHistory(),
        ],
      ),
    );
  }

  Widget _buildPerformanceOverview(int completed, int assigned, int successRate, int totalXP) {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Overview',
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
                    'Tasks Completed',
                    completed.toString(),
                    Icons.check_circle,
                    AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Success Rate',
                    '$successRate%',
                    Icons.trending_up,
                    AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total XP Earned',
                    totalXP.toString(),
                    Icons.stars,
                    AppTheme.accentColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Current Level',
                    _getLevelFromXP(totalXP),
                    Icons.emoji_events,
                    AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trend',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.darkBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      color: AppTheme.greyColor,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Performance Chart',
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.whiteColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildAchievementItem(
              'First Task',
              'Complete your first task',
              Icons.emoji_events,
              _completedTasks.isNotEmpty,
            ),
            _buildAchievementItem(
              'Task Master',
              'Complete 10 tasks',
              Icons.star,
              _completedTasks.length >= 10,
            ),
            _buildAchievementItem(
              'Efficiency Expert',
              'Maintain 90% success rate',
              Icons.trending_up,
              _getSuccessRate() >= 90,
            ),
            _buildAchievementItem(
              'XP Collector',
              'Earn 500 XP',
              Icons.stars,
              (_completedTasks.length * 20) >= 500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(String title, String description, IconData icon, bool unlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: unlocked ? AppTheme.accentColor : AppTheme.greyColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: unlocked ? AppTheme.accentColor : AppTheme.greyColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.titleMedium.copyWith(
                    color: unlocked ? AppTheme.whiteColor : AppTheme.greyColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            Icon(
              Icons.check_circle,
              color: AppTheme.successColor,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildTaskHistory() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task History',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_completedTasks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        color: AppTheme.greyColor,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No task history yet',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.whiteColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._completedTasks.take(10).map((task) => _buildHistoryItem(task)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppTheme.successColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['issue_type']?.toString().toUpperCase() ?? 'UNKNOWN',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(DateTime.parse(task['created_at'] ?? DateTime.now().toIso8601String())),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+20 XP',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getLevelFromXP(int xp) {
    if (xp < 100) return 'Level 1';
    if (xp < 300) return 'Level 2';
    if (xp < 700) return 'Level 3';
    if (xp < 1000) return 'Level 4';
    return 'Level 5';
  }

  int _getSuccessRate() {
    final total = _assignedTasks.length + _completedTasks.length;
    if (total == 0) return 0;
    return ((_completedTasks.length / total) * 100).round();
  }

  // Action Methods
  void _startGPSTracking() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('GPS tracking started!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _openMapView() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening map view...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _callAdmin() async {
    const phoneNumber = 'tel:+1234567890'; // Replace with actual admin number
    if (await canLaunch(phoneNumber)) {
      await launch(phoneNumber);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not make phone call'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }


  void _startTask(task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Start Task',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        content: Text(
          'Are you ready to start working on this task?',
          style: TextStyle(color: AppTheme.greyColor),
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
                SnackBar(
                  content: Text('Task started successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: Text('Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.whiteColor,
            ),
          ),
        ],
      ),
    );
  }

  void _viewTaskDetails(task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Task Details',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type: ${task['issue_type']?.toString().toUpperCase() ?? 'UNKNOWN'}',
              style: TextStyle(color: AppTheme.whiteColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Description: ${task['description'] ?? 'No description'}',
              style: TextStyle(color: AppTheme.greyColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Location: ${task['location'] ?? 'Not specified'}',
              style: TextStyle(color: AppTheme.greyColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${_formatDate(DateTime.parse(task['created_at'] ?? DateTime.now().toIso8601String()))}',
              style: TextStyle(color: AppTheme.greyColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppTheme.greyColor)),
          ),
        ],
      ),
    );
  }
}
