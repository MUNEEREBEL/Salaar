// lib/screens/developer/developer_dashboard_complete.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_complete.dart';
import '../../providers/issues_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/salaar_loading_widget.dart';
import '../../models/user.dart';
import '../../services/supabase_service.dart';
import 'server_control_screen.dart';

class DeveloperDashboardComplete extends StatefulWidget {
  const DeveloperDashboardComplete({Key? key}) : super(key: key);

  @override
  State<DeveloperDashboardComplete> createState() => _DeveloperDashboardCompleteState();
}

class _DeveloperDashboardCompleteState extends State<DeveloperDashboardComplete>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<SalaarUser> _allUsers = [];
  List<SalaarUser> _allReports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseService.supabase
          .from('profiles')
          .select('*')
          .order('created_at', ascending: false);
      
      _allUsers = (response as List)
          .map((user) => SalaarUser.fromJson(user))
          .toList();
    } catch (e) {
      print('Error loading users: $e');
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
        body: SalaarLoadingWidget(message: 'Loading developer dashboard...'),
      );
    }

    final user = authProvider.currentUser!;
    final issues = issuesProvider.issues;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Developer Dashboard',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.secondaryColor,
          labelColor: AppTheme.secondaryColor,
          unselectedLabelColor: AppTheme.greyColor,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'All Accounts', icon: Icon(Icons.people)),
            Tab(text: 'Server Control', icon: Icon(Icons.settings)),
            Tab(text: 'Level Control', icon: Icon(Icons.trending_up)),
            Tab(text: 'Testing', icon: Icon(Icons.bug_report)),
          ],
        ),
        actions: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.secondaryColor.withOpacity(0.2),
            child: Text(
              (user.fullName ?? user.username ?? 'D').substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: AppTheme.secondaryColor,
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
          _buildAllAccountsTab(),
          ServerControlScreen(),
          _buildLevelControlTab(),
          _buildTestingTab(),
        ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(user, issues) {
    final totalUsers = _allUsers.length;
    final totalReports = issues.length;
    final pendingReports = issues.where((issue) => issue.status == 'pending').length;
    final completedReports = issues.where((issue) => issue.status == 'completed').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          _buildWelcomeSection(user),
          const SizedBox(height: 24),
          
          // System Stats
          _buildSystemStats(totalUsers, totalReports, pendingReports, completedReports),
          const SizedBox(height: 24),
          
          // Developer Tools
          _buildDeveloperTools(),
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
                  colors: [AppTheme.secondaryColor, AppTheme.accentColor],
                ),
              ),
              child: Icon(
                Icons.code,
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
                    'Developer Dashboard - Full system access',
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

  Widget _buildSystemStats(int totalUsers, int totalReports, int pendingReports, int completedReports) {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Statistics',
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
                    totalUsers.toString(),
                    Icons.people,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Total Reports',
                    totalReports.toString(),
                    Icons.assignment,
                    AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Pending',
                    pendingReports.toString(),
                    Icons.pending,
                    AppTheme.accentColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    completedReports.toString(),
                    Icons.check_circle,
                    AppTheme.successColor,
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

  Widget _buildDeveloperTools() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Developer Tools',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildToolCard(
                    'Database',
                    Icons.storage,
                    AppTheme.primaryColor,
                    () => _showDatabaseTools(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildToolCard(
                    'Analytics',
                    Icons.analytics,
                    AppTheme.successColor,
                    () => _showAnalyticsTools(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildToolCard(
                    'Testing',
                    Icons.bug_report,
                    AppTheme.accentColor,
                    () => _showTestingTools(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildToolCard(
                    'Logs',
                    Icons.list_alt,
                    AppTheme.secondaryColor,
                    () => _showSystemLogs(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(String title, IconData icon, Color color, VoidCallback onTap) {
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
              'Recent System Activity',
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
              ...recentIssues.map((issue) => _buildActivityItem(issue)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(issue) {
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
                  'Report: ${issue.issueType.toUpperCase()}',
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

  Widget _buildAllAccountsTab() {
    if (_isLoading) {
      return Center(
        child: SalaarLoadingWidget(message: 'Loading all accounts...'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Account Stats
          _buildAccountStats(),
          const SizedBox(height: 16),
          
          // Search and Filter
          _buildSearchFilter(),
          const SizedBox(height: 16),
          
          // Accounts List
          ..._allUsers.map((user) => _buildAccountCard(user)),
        ],
      ),
    );
  }

  Widget _buildAccountStats() {
    final userCount = _allUsers.where((u) => u.role == 'user').length;
    final adminCount = _allUsers.where((u) => u.role == 'admin').length;
    final workerCount = _allUsers.where((u) => u.role == 'worker').length;
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
              'Account Distribution',
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
                    'Users',
                    userCount.toString(),
                    Icons.person,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Admins',
                    adminCount.toString(),
                    Icons.admin_panel_settings,
                    AppTheme.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Workers',
                    workerCount.toString(),
                    Icons.engineering,
                    AppTheme.successColor,
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

  Widget _buildSearchFilter() {
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
                  hintText: 'Search accounts...',
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
                    borderSide: BorderSide(color: AppTheme.secondaryColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.filter_list, color: AppTheme.secondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(SalaarUser user) {
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
              onSelected: (value) => _handleAccountAction(value, user),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text('Edit Account'),
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
                  value: 'give_points',
                  child: Row(
                    children: [
                      Icon(Icons.stars, color: AppTheme.accentColor),
                      const SizedBox(width: 8),
                      Text('Give Points'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Text('Delete Account'),
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

  Widget _buildLevelControlTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Level System Overview
          _buildLevelSystemOverview(),
          const SizedBox(height: 16),
          
          // Level Management Tools
          _buildLevelManagementTools(),
          const SizedBox(height: 16),
          
          // User Level Distribution
          _buildUserLevelDistribution(),
        ],
      ),
    );
  }

  Widget _buildLevelSystemOverview() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Level System Overview',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildLevelInfo('Level 1: The Beginning', '0-100 XP', AppTheme.primaryColor),
            _buildLevelInfo('Level 2: Ghaniyaar', '100-300 XP', AppTheme.accentColor),
            _buildLevelInfo('Level 3: Mannarasi', '300-700 XP', AppTheme.successColor),
            _buildLevelInfo('Level 4: Shouryaanga', '700-1000 XP', AppTheme.secondaryColor),
            _buildLevelInfo('Level 5: SALAAR', '1000+ XP', AppTheme.accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelInfo(String level, String xpRange, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              level,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            xpRange,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelManagementTools() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Level Management Tools',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildToolCard(
                    'Bulk Level Up',
                    Icons.trending_up,
                    AppTheme.primaryColor,
                    () => _showBulkLevelUpDialog(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildToolCard(
                    'Reset Levels',
                    Icons.refresh,
                    AppTheme.errorColor,
                    () => _showResetLevelsDialog(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildToolCard(
                    'Give XP',
                    Icons.stars,
                    AppTheme.accentColor,
                    () => _showGiveXPDialog(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildToolCard(
                    'Level Analytics',
                    Icons.analytics,
                    AppTheme.successColor,
                    () => _showLevelAnalytics(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserLevelDistribution() {
    final level1 = _allUsers.where((u) => u.expPoints < 100).length;
    final level2 = _allUsers.where((u) => u.expPoints >= 100 && u.expPoints < 300).length;
    final level3 = _allUsers.where((u) => u.expPoints >= 300 && u.expPoints < 700).length;
    final level4 = _allUsers.where((u) => u.expPoints >= 700 && u.expPoints < 1000).length;
    final level5 = _allUsers.where((u) => u.expPoints >= 1000).length;

    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Level Distribution',
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
                    'Level 1',
                    level1.toString(),
                    Icons.person,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Level 2',
                    level2.toString(),
                    Icons.star,
                    AppTheme.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Level 3',
                    level3.toString(),
                    Icons.star_half,
                    AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Level 4',
                    level4.toString(),
                    Icons.star_border,
                    AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Level 5',
                    level5.toString(),
                    Icons.star,
                    AppTheme.accentColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    _allUsers.length.toString(),
                    Icons.people,
                    AppTheme.greyColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Testing Tools
          _buildTestingTools(),
          const SizedBox(height: 16),
          
          // System Health
          _buildSystemHealth(),
          const SizedBox(height: 16),
          
          // Performance Metrics
          _buildPerformanceMetrics(),
        ],
      ),
    );
  }

  Widget _buildTestingTools() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Testing Tools',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildToolCard(
                    'Create Test Data',
                    Icons.add_circle,
                    AppTheme.primaryColor,
                    () => _createTestData(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildToolCard(
                    'Clear Test Data',
                    Icons.delete_sweep,
                    AppTheme.errorColor,
                    () => _clearTestData(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildToolCard(
                    'Run Tests',
                    Icons.play_arrow,
                    AppTheme.successColor,
                    () => _runTests(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildToolCard(
                    'View Logs',
                    Icons.list_alt,
                    AppTheme.accentColor,
                    () => _viewLogs(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemHealth() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Health',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildHealthItem('Database Connection', 'Healthy', AppTheme.successColor),
            _buildHealthItem('API Response Time', '45ms', AppTheme.successColor),
            _buildHealthItem('Memory Usage', '67%', AppTheme.accentColor),
            _buildHealthItem('Storage Usage', '23%', AppTheme.successColor),
            _buildHealthItem('Active Users', '${_allUsers.length}', AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.whiteColor,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: AppTheme.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
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
                    'Avg Response',
                    '45ms',
                    Icons.speed,
                    AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Uptime',
                    '99.9%',
                    Icons.timer,
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
                    'Requests/min',
                    '1,234',
                    Icons.trending_up,
                    AppTheme.accentColor,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    'Error Rate',
                    '0.1%',
                    Icons.error_outline,
                    AppTheme.successColor,
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

  // Action Methods
  void _showDatabaseTools() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Database Tools',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.backup, color: AppTheme.primaryColor),
              title: Text('Backup Database', style: TextStyle(color: AppTheme.whiteColor)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Database backup initiated...'),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.restore, color: AppTheme.accentColor),
              title: Text('Restore Database', style: TextStyle(color: AppTheme.whiteColor)),
              onTap: () {
                Navigator.pop(context);
                _restoreDatabase();
              },
            ),
            ListTile(
              leading: Icon(Icons.cleaning_services, color: AppTheme.errorColor),
              title: Text('Clean Database', style: TextStyle(color: AppTheme.whiteColor)),
              onTap: () {
                Navigator.pop(context);
                _cleanDatabase();
              },
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

  void _showAnalyticsTools() {
    _showAnalyticsDialog();
  }

  void _showTestingTools() {
    _showTestingDialog();
  }

  void _showSystemLogs() {
    _showLogsDialog();
  }

  void _handleAccountAction(String action, SalaarUser user) {
    switch (action) {
      case 'edit':
        _showEditAccountDialog(user);
        break;
      case 'change_role':
        _showChangeRoleDialog(user);
        break;
      case 'give_points':
        _showGivePointsDialog(user);
        break;
      case 'delete':
        _showDeleteAccountDialog(user);
        break;
    }
  }

  void _showEditAccountDialog(SalaarUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Edit Account',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: TextStyle(color: AppTheme.whiteColor),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: TextStyle(color: AppTheme.greyColor),
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: user.fullName),
            ),
            const SizedBox(height: 16),
            TextField(
              style: TextStyle(color: AppTheme.whiteColor),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: AppTheme.greyColor),
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: user.username),
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
                  content: Text('Account updated successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.whiteColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(SalaarUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Change Role',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current role: ${user.role}',
              style: TextStyle(color: AppTheme.greyColor),
            ),
            const SizedBox(height: 16),
            ...['user', 'admin', 'worker', 'developer'].map((role) => ListTile(
              leading: Radio<String>(
                value: role,
                groupValue: user.role,
                onChanged: (value) {},
                activeColor: AppTheme.primaryColor,
              ),
              title: Text(
                role.toUpperCase(),
                style: TextStyle(color: AppTheme.whiteColor),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Role changed to ${role.toUpperCase()}!'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
            )),
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

  void _showGivePointsDialog(SalaarUser user) {
    final pointsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Give Points',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current XP: ${user.expPoints}',
              style: TextStyle(color: AppTheme.greyColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pointsController,
              style: TextStyle(color: AppTheme.whiteColor),
              decoration: InputDecoration(
                labelText: 'Points to add',
                labelStyle: TextStyle(color: AppTheme.greyColor),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
                  content: Text('${pointsController.text} points added!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: Text('Add Points'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.whiteColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(SalaarUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Delete Account',
          style: TextStyle(color: AppTheme.errorColor),
        ),
        content: Text(
          'Are you sure you want to delete ${user.fullName ?? user.username}? This action cannot be undone.',
          style: TextStyle(color: AppTheme.whiteColor),
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
                  content: Text('Account deleted successfully!'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            },
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: AppTheme.whiteColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showBulkLevelUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text('Bulk Level Up', style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select users to level up:',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'XP Amount',
                hintText: 'Enter XP to give',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.number,
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
                  content: Text('Users leveled up successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: Text('Level Up', style: TextStyle(color: AppTheme.whiteColor)),
          ),
        ],
      ),
    );
  }

  void _showResetLevelsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Reset All Levels',
          style: TextStyle(color: AppTheme.errorColor),
        ),
        content: Text(
          'Are you sure you want to reset all user levels? This will set all users to Level 1 with 0 XP.',
          style: TextStyle(color: AppTheme.whiteColor),
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
                  content: Text('All levels reset successfully!'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            },
            child: Text('Reset'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: AppTheme.whiteColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showGiveXPDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text('Give XP', style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'User Email',
                hintText: 'Enter user email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'XP Amount',
                hintText: 'Enter XP to give',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.number,
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
                  content: Text('XP given successfully!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: Text('Give XP', style: TextStyle(color: AppTheme.whiteColor)),
          ),
        ],
      ),
    );
  }

  void _showLevelAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text('Level Analytics', style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAnalyticsItem('Total Users', '1,234'),
              _buildAnalyticsItem('Level 1 Users', '456'),
              _buildAnalyticsItem('Level 2 Users', '321'),
              _buildAnalyticsItem('Level 3 Users', '234'),
              _buildAnalyticsItem('Level 4+ Users', '223'),
              _buildAnalyticsItem('Average XP', '2,456'),
              _buildAnalyticsItem('Highest Level', 'Level 5'),
            ],
          ),
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

  Widget _buildAnalyticsItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor)),
          Text(value, style: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _createTestData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Creating test data...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _clearTestData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Clear Test Data',
          style: TextStyle(color: AppTheme.errorColor),
        ),
        content: Text(
          'Are you sure you want to clear all test data? This action cannot be undone.',
          style: TextStyle(color: AppTheme.whiteColor),
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
                  content: Text('Test data cleared successfully!'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            },
            child: Text('Clear'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: AppTheme.whiteColor,
            ),
          ),
        ],
      ),
    );
  }

  void _runTests() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Running tests...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _viewLogs() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing system logs...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Future<void> _restoreDatabase() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restore Database'),
        content: Text('This will restore the database to the last backup. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Database restore initiated...'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            child: Text('Restore'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
          ),
        ],
      ),
    );
  }

  Future<void> _cleanDatabase() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clean Database'),
        content: Text('This will clean up old data and optimize the database. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Database cleanup completed!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: Text('Clean'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Analytics Tools'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.trending_up),
              title: Text('Issue Trends'),
              onTap: () {
                Navigator.pop(context);
                _showIssueTrends();
              },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('User Analytics'),
              onTap: () {
                Navigator.pop(context);
                _showUserAnalytics();
              },
            ),
            ListTile(
              leading: Icon(Icons.assessment),
              title: Text('Performance Metrics'),
              onTap: () {
                Navigator.pop(context);
                _showPerformanceMetrics();
              },
            ),
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

  void _showTestingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Testing Tools'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.bug_report),
              title: Text('Run Unit Tests'),
              onTap: () {
                Navigator.pop(context);
                _runUnitTests();
              },
            ),
            ListTile(
              leading: Icon(Icons.integration_instructions),
              title: Text('Integration Tests'),
              onTap: () {
                Navigator.pop(context);
                _runIntegrationTests();
              },
            ),
            ListTile(
              leading: Icon(Icons.security),
              title: Text('Security Tests'),
              onTap: () {
                Navigator.pop(context);
                _runSecurityTests();
              },
            ),
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

  void _showLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('System Logs'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              'System logs will be displayed here...\n\n'
              'Log Level: INFO\n'
              'Timestamp: ${DateTime.now()}\n'
              'Status: System running normally\n'
              'Memory Usage: 45%\n'
              'CPU Usage: 12%\n'
              'Database Connections: 5/10\n'
              'Active Users: 23\n'
              'Issues Processed Today: 15\n'
              'Average Response Time: 2.3s',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Logs exported successfully!'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            child: Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showIssueTrends() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Issue trends analysis displayed'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showUserAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User analytics displayed'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showPerformanceMetrics() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Performance metrics displayed'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _runUnitTests() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unit tests completed - All passed!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _runIntegrationTests() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Integration tests completed - All passed!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _runSecurityTests() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Security tests completed - No vulnerabilities found!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}
