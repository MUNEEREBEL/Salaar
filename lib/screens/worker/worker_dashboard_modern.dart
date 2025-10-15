// lib/screens/worker/worker_dashboard_modern.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_complete.dart';
import '../../providers/issues_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'worker_issue_management_modern.dart';
import 'worker_profile_screen.dart';

class WorkerDashboardModern extends StatefulWidget {
  const WorkerDashboardModern({Key? key}) : super(key: key);

  @override
  State<WorkerDashboardModern> createState() => _WorkerDashboardModernState();
}

class _WorkerDashboardModernState extends State<WorkerDashboardModern>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _assignedTasks = [];
  List<dynamic> _completedTasks = [];
  bool _isLoading = false;
  Map<String, dynamic> _workerStats = {};

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

  void _refreshData() {
    _loadData();
  }

  Future<void> _loadWorkerTasks() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser != null) {
        // Load assigned tasks
        final assignedResponse = await Supabase.instance.client
            .from('issues')
            .select('*')
            .eq('assignee_id', currentUser.id)
            .or('status.eq.pending,status.eq.in_progress');

        // Load completed tasks
        final completedResponse = await Supabase.instance.client
            .from('issues')
            .select('*')
            .eq('assignee_id', currentUser.id)
            .eq('status', 'completed');

        // Calculate stats
        final totalAssigned = (assignedResponse as List).length;
        final totalCompleted = (completedResponse as List).length;
        final completionRate = totalAssigned > 0 ? (totalCompleted / (totalAssigned + totalCompleted)) * 100 : 0.0;

        if (mounted) {
          setState(() {
            _assignedTasks = List<dynamic>.from(assignedResponse);
            _completedTasks = List<dynamic>.from(completedResponse);
            _workerStats = {
              'assigned': totalAssigned,
              'completed': totalCompleted,
              'completion_rate': completionRate,
              'total_tasks': totalAssigned + totalCompleted,
            };
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tasks: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Modern Header
            _buildModernHeader(),
            
            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.greyColor.withOpacity(0.2),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                labelColor: AppTheme.whiteColor,
                unselectedLabelColor: AppTheme.greyColor,
                labelStyle: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(text: 'Dashboard'),
                  Tab(text: 'My Tasks'),
                  Tab(text: 'Profile'),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboard(),
                  const WorkerIssueManagementModern(),
                  const WorkerProfileScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.successColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: AppTheme.titleLarge.copyWith(
                        color: AppTheme.greyColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Consumer<AuthProviderComplete>(
                      builder: (context, authProvider, child) {
                        final user = authProvider.currentUser;
                        return Text(
                          user?.fullName ?? 'Worker',
                          style: AppTheme.headlineMedium.copyWith(
                            color: AppTheme.whiteColor,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.work,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Quick Stats
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.greyColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactStatItem(
              'Assigned',
              '${_workerStats['assigned'] ?? 0}',
              Icons.assignment,
              AppTheme.warningColor,
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: AppTheme.greyColor.withOpacity(0.3),
          ),
          Expanded(
            child: _buildCompactStatItem(
              'Completed',
              '${_workerStats['completed'] ?? 0}',
              Icons.check_circle,
              AppTheme.successColor,
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: AppTheme.greyColor.withOpacity(0.3),
          ),
          Expanded(
            child: _buildCompactStatItem(
              'Rate',
              '${(_workerStats['completion_rate'] ?? 0).toStringAsFixed(0)}%',
              Icons.trending_up,
              AppTheme.infoColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.greyColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshData();
      },
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent Tasks Section
            Text(
              'Recent Tasks',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            else if (_assignedTasks.isEmpty)
              _buildEmptyState()
            else
              ..._assignedTasks.take(3).map((task) => _buildTaskCard(task)).toList(),
            
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
            
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.greyColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(task['status']).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.assignment,
              color: _getStatusColor(task['status']),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title'] ?? 'No Title',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  task['description'] ?? 'No Description',
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
              color: _getStatusColor(task['status']),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              task['status'].toUpperCase(),
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.greyColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            color: AppTheme.greyColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No Tasks Assigned',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any assigned tasks yet.',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.greyColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'View All Tasks',
            Icons.list_alt,
            AppTheme.primaryColor,
            () => _tabController.animateTo(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            'Update Profile',
            Icons.person,
            AppTheme.infoColor,
            () => _tabController.animateTo(2),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTheme.titleSmall.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
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
}
