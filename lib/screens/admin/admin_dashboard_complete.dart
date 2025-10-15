// lib/screens/admin/admin_dashboard_complete.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider_complete.dart';
import '../../providers/issues_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/salaar_loading_widget.dart';
import '../../models/user.dart';
import '../../services/supabase_service.dart';
import 'user_management_screen.dart';
import 'notification_management_screen.dart';

class AdminDashboardComplete extends StatefulWidget {
  const AdminDashboardComplete({Key? key}) : super(key: key);

  @override
  State<AdminDashboardComplete> createState() => _AdminDashboardCompleteState();
}

class _AdminDashboardCompleteState extends State<AdminDashboardComplete>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<SalaarUser> _allUsers = [];
  List<SalaarUser> _workers = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    await issuesProvider.fetchAllIssues();
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final response = await SupabaseService.supabase
          .from('profiles')
          .select('*')
          .order('created_at', ascending: false);
      
      _allUsers = (response as List)
          .map((user) => SalaarUser.fromJson(user))
          .toList();
      
      _workers = _allUsers.where((user) => user.role == 'worker').toList();
    } catch (e) {
      print('Error loading users: $e');
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderComplete>(context);
    final issuesProvider = Provider.of<IssuesProvider>(context);

    if (authProvider.isLoading || issuesProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: SalaarLoadingWidget(message: 'Loading admin dashboard...'),
      );
    }

    final user = authProvider.currentUser!;
    final issues = issuesProvider.issues;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
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
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Workers', icon: Icon(Icons.work)),
            Tab(text: 'Manage', icon: Icon(Icons.admin_panel_settings)),
          ],
        ),
        actions: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
            child: Text(
              (user.fullName ?? user.username ?? 'A').substring(0, 1).toUpperCase(),
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: TabBarView(
          controller: _tabController,
          children: [
          _buildOverviewTab(user, issues),
          _buildUsersTab(),
          _buildWorkersTab(),
          const UserManagementScreen(),
        ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(user, issues) {
    final pendingCount = issues.where((issue) => issue.status == 'pending').length;
    final inProgressCount = issues.where((issue) => issue.status == 'in_progress').length;
    final completedCount = issues.where((issue) => issue.status == 'completed').length;
    final rejectedCount = issues.where((issue) => issue.status == 'rejected').length;
    final totalUsers = _allUsers.length;
    final activeWorkers = _workers.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          _buildWelcomeSection(user),
          const SizedBox(height: 24),
          
          // Stats Overview
          _buildStatsOverview(pendingCount, inProgressCount, completedCount, rejectedCount, totalUsers, activeWorkers),
          const SizedBox(height: 24),
          
          // Quick Actions
          _buildQuickActions(),
          const SizedBox(height: 24),
          
          // Recent Activity
          _buildRecentActivity(issues),
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
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
              ),
              child: Icon(
                Icons.admin_panel_settings,
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
                    'Admin Dashboard - Manage all reports and users',
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

  Widget _buildStatsOverview(int pending, int inProgress, int completed, int rejected, int totalUsers, int activeWorkers) {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview',
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
                    'Pending Reports',
                    pending.toString(),
                    Icons.pending,
                    AppTheme.accentColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'In Progress',
                    inProgress.toString(),
                    Icons.work,
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
                    'Completed',
                    completed.toString(),
                    Icons.check_circle,
                    AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Rejected',
                    rejected.toString(),
                    Icons.cancel,
                    AppTheme.errorColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Users',
                    totalUsers.toString(),
                    Icons.people,
                    AppTheme.secondaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Active Workers',
                    activeWorkers.toString(),
                    Icons.engineering,
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
                    'Create Worker',
                    Icons.person_add,
                    AppTheme.primaryColor,
                    () => _showCreateWorkerDialog(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    'System Analytics',
                    Icons.analytics,
                    AppTheme.successColor,
                    () => _showAnalyticsDialog(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    'Bulk Actions',
                    Icons.settings,
                    AppTheme.accentColor,
                    () => _showBulkActionsDialog(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    'Export Data',
                    Icons.download,
                    AppTheme.secondaryColor,
                    () => _exportData(),
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

  Widget _buildRecentActivity(issues) {
    final recentIssues = issues.take(5).toList();

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
            if (recentIssues.isEmpty)
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
              ...recentIssues.map((issue) => _buildIssueItem(issue)),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueItem(issue) {
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
    );
  }

  Widget _buildReportsTab(issues) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Filter and Search
          _buildReportsFilter(),
          const SizedBox(height: 16),
          
          // Reports List
          ...issues.map((issue) => _buildDetailedIssueCard(issue)),
        ],
      ),
    );
  }

  Widget _buildReportsFilter() {
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
                  hintText: 'Search reports...',
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
              onPressed: () {},
              icon: Icon(Icons.filter_list, color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedIssueCard(issue) {
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
                  issue.issueType.toUpperCase(),
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(issue.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
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
            const SizedBox(height: 8),
            Text(
              issue.description,
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
                    issue.location ?? 'Location not specified',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.greyColor,
                    ),
                  ),
                ),
                Icon(Icons.access_time, color: AppTheme.greyColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  _formatDate(issue.createdAt),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _assignWorker(issue),
                    icon: Icon(Icons.person_add, size: 16),
                    label: Text('Assign Worker'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.whiteColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewDetails(issue),
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
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_isLoadingUsers) {
      return Center(
        child: SalaarLoadingWidget(message: 'Loading users...'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // User Stats
          _buildUserStats(),
          const SizedBox(height: 16),
          
          // Users List
          ..._allUsers.map((user) => _buildUserCard(user)),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    final userCount = _allUsers.length;
    final activeUsers = _allUsers.where((u) => u.role == 'user').length;
    final adminCount = _allUsers.where((u) => u.role == 'admin').length;
    final developerCount = _allUsers.where((u) => u.role == 'developer').length;

    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Statistics',
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
                    'Total Users',
                    userCount.toString(),
                    Icons.people,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Citizens',
                    activeUsers.toString(),
                    Icons.person,
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
                    'Admins',
                    adminCount.toString(),
                    Icons.admin_panel_settings,
                    AppTheme.accentColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Developers',
                    developerCount.toString(),
                    Icons.code,
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

  Widget _buildUserCard(SalaarUser user) {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
              child: Text(
                (user.fullName ?? user.username).substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: _getRoleColor(user.role),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName ?? user.username,
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.greyColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.role).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: AppTheme.bodySmall.copyWith(
                        color: _getRoleColor(user.role),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '${user.expPoints} XP',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.issuesReported} reports',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppTheme.greyColor),
              onSelected: (value) => _handleUserAction(value, user),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text('Edit User'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'change_role',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, color: AppTheme.accentColor),
                      const SizedBox(width: 8),
                      Text('Change Role'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Text('Delete User'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkersTab() {
    if (_isLoadingUsers) {
      return Center(
        child: SalaarLoadingWidget(message: 'Loading workers...'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Worker Stats
          _buildWorkerStats(),
          const SizedBox(height: 16),
          
          // Create Worker Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateWorkerDialog(),
              icon: Icon(Icons.person_add),
              label: Text('Create New Worker'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.whiteColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Notification Management Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationManagementScreen(),
                  ),
                );
              },
              icon: Icon(Icons.notifications),
              label: Text('Manage Notifications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: AppTheme.whiteColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Workers List
          ..._workers.map((worker) => _buildWorkerCard(worker)),
        ],
      ),
    );
  }

  Widget _buildWorkerStats() {
    final totalWorkers = _workers.length;
    final activeWorkers = _workers.where((w) => w.issuesVerified > 0).length;
    final avgReports = _workers.isNotEmpty 
        ? (_workers.map((w) => w.issuesVerified).reduce((a, b) => a + b) / _workers.length).round()
        : 0;

    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Worker Performance',
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
                    'Total Workers',
                    totalWorkers.toString(),
                    Icons.engineering,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Active Workers',
                    activeWorkers.toString(),
                    Icons.work,
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
                    'Avg Reports/Worker',
                    avgReports.toString(),
                    Icons.analytics,
                    AppTheme.accentColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Success Rate',
                    '85%',
                    Icons.trending_up,
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

  Widget _buildWorkerCard(SalaarUser worker) {
    final successRate = worker.issuesVerified > 0 
        ? ((worker.issuesVerified / (worker.issuesVerified + worker.issuesReported)) * 100).round()
        : 0;

    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  child: Icon(
                    Icons.engineering,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.fullName ?? worker.username,
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.whiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${worker.username}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.greyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$successRate% Success',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${worker.issuesVerified} completed',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.greyColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewWorkerDetails(worker),
                    icon: Icon(Icons.visibility, size: 16),
                    label: Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.whiteColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _assignTaskToWorker(worker),
                    icon: Icon(Icons.assignment, size: 16),
                    label: Text('Assign Task'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentColor,
                      side: BorderSide(color: AppTheme.accentColor),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
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

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppTheme.accentColor;
      case 'developer':
        return AppTheme.secondaryColor;
      case 'worker':
        return AppTheme.primaryColor;
      case 'user':
        return AppTheme.successColor;
      default:
        return AppTheme.greyColor;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Action Methods
  void _showCreateWorkerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Create Worker Account',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              style: TextStyle(color: AppTheme.whiteColor),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: TextStyle(color: AppTheme.greyColor),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              style: TextStyle(color: AppTheme.whiteColor),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: AppTheme.greyColor),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              style: TextStyle(color: AppTheme.whiteColor),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: AppTheme.greyColor),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              style: TextStyle(color: AppTheme.whiteColor),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: AppTheme.greyColor),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.greyColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createWorker();
            },
            child: Text('Create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.whiteColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'System Analytics',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAnalyticsItem('Total Reports', '1,234'),
            _buildAnalyticsItem('Resolved Reports', '987'),
            _buildAnalyticsItem('Average Resolution Time', '2.3 days'),
            _buildAnalyticsItem('User Satisfaction', '4.2/5'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.whiteColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.greyColor)),
          Text(value, style: TextStyle(color: AppTheme.whiteColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showBulkActionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Bulk Actions',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete_sweep, color: AppTheme.errorColor),
              title: Text('Delete Selected Reports', style: TextStyle(color: AppTheme.whiteColor)),
              onTap: () {
                Navigator.pop(context);
                _showBulkDeleteDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.assignment, color: AppTheme.primaryColor),
              title: Text('Assign to Workers', style: TextStyle(color: AppTheme.whiteColor)),
              onTap: () {
                Navigator.pop(context);
                _showBulkAssignmentDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.download, color: AppTheme.successColor),
              title: Text('Export Reports', style: TextStyle(color: AppTheme.whiteColor)),
              onTap: () {
                Navigator.pop(context);
                _exportData();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.greyColor)),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting data...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _assignWorker(issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Assign Worker',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _workers.map((worker) => ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              child: Text(
                (worker.fullName ?? worker.username).substring(0, 1).toUpperCase(),
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
            title: Text(
              worker.fullName ?? worker.username,
              style: TextStyle(color: AppTheme.whiteColor),
            ),
            subtitle: Text(
              '${worker.issuesVerified} completed',
              style: TextStyle(color: AppTheme.greyColor),
            ),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Worker assigned successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.greyColor)),
          ),
        ],
      ),
    );
  }

  void _viewDetails(issue) {
    _showIssueDetails(issue);
  }

  void _handleUserAction(String action, SalaarUser user) {
    switch (action) {
      case 'edit':
        _editUser(user);
        break;
      case 'change_role':
        _changeUserRole(user);
        break;
      case 'delete':
        _deleteUser(user);
        break;
    }
  }

  void _createWorker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Worker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Worker Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Worker created successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: Text('Create'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  void _editUser(SalaarUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: user.fullName),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: user.email),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User updated successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: Text('Save'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  void _changeUserRole(SalaarUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Role: ${user.role}'),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'New Role',
                border: OutlineInputBorder(),
              ),
              items: ['user', 'worker', 'admin', 'developer'].map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                // Handle role change
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User role updated successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: Text('Update'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  void _deleteUser(SalaarUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User deleted successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
          ),
        ],
      ),
    );
  }

  void _viewWorkerDetails(SalaarUser worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Worker Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${worker.fullName}'),
            Text('Email: ${worker.email}'),
            Text('Role: ${worker.role}'),
            Text('Department: ${worker.department ?? 'Not assigned'}'),
            Text('Status: ${worker.isActive ? 'Active' : 'Inactive'}'),
            Text('Joined: ${worker.createdAt?.toString().split(' ')[0] ?? 'Unknown'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _assignTaskToWorker(SalaarUser worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Task to ${worker.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Task Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: ['low', 'medium', 'high', 'urgent'].map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                // Handle priority selection
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Task assigned successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: Text('Assign'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text('Bulk Delete Reports', style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor)),
        content: Text(
          'Are you sure you want to delete all selected reports? This action cannot be undone.',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
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
                  content: Text('Reports deleted successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: Text('Delete', style: TextStyle(color: AppTheme.whiteColor)),
          ),
        ],
      ),
    );
  }

  void _showBulkAssignmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text('Bulk Assign Reports', style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select a worker to assign all selected reports to:',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Worker',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _workers.map((worker) {
                return DropdownMenuItem(
                  value: worker.id,
                  child: Text(worker.fullName ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (value) {
                // Handle assignment
              },
            ),
          ],
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
                  content: Text('Reports assigned successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: Text('Assign', style: TextStyle(color: AppTheme.whiteColor)),
          ),
        ],
      ),
    );
  }

  void _showIssueDetails(issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text('Issue Details', style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Title', issue['title'] ?? 'N/A'),
              _buildDetailRow('Description', issue['description'] ?? 'N/A'),
              _buildDetailRow('Status', issue['status'] ?? 'N/A'),
              _buildDetailRow('Priority', issue['priority'] ?? 'N/A'),
              _buildDetailRow('Category', issue['category'] ?? 'N/A'),
              _buildDetailRow('Address', issue['address'] ?? 'N/A'),
              _buildDetailRow('Created', issue['created_at'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppTheme.greyColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle edit issue
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: Text('Edit', style: TextStyle(color: AppTheme.whiteColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
            ),
          ),
        ],
      ),
    );
  }
}
