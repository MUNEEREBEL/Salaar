import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/issues_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../services/basic_notification_service.dart';
import '../../services/prabhas_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsManagementModern extends StatefulWidget {
  const ReportsManagementModern({Key? key}) : super(key: key);

  @override
  State<ReportsManagementModern> createState() => _ReportsManagementModernState();
}

class _ReportsManagementModernState extends State<ReportsManagementModern> {
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';
  final List<String> _filters = ['All', 'Pending', 'In Progress', 'Completed', 'Cancelled', 'Unassigned', 'Assigned'];
  final List<String> _sortOptions = ['Newest', 'Oldest', 'Priority', 'Category'];

  @override
  void initState() {
    super.initState();
    // Load issues when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IssuesProvider>(context, listen: false).fetchAllIssues();
    });
  }

  List<Issue> _getFilteredIssues(List<Issue> issues) {
    List<Issue> filtered = issues;

    // Filter by status or assignment
    if (_selectedFilter != 'All') {
      switch (_selectedFilter) {
        case 'Pending':
          filtered = filtered.where((issue) => issue.status == 'pending').toList();
          break;
        case 'In Progress':
          filtered = filtered.where((issue) => issue.status == 'in_progress').toList();
          break;
        case 'Completed':
          filtered = filtered.where((issue) => issue.status == 'completed').toList();
          break;
        case 'Cancelled':
          filtered = filtered.where((issue) => issue.status == 'cancelled').toList();
          break;
        case 'Unassigned':
          filtered = filtered.where((issue) => issue.assigneeId == null || issue.assigneeId!.isEmpty).toList();
          break;
        case 'Assigned':
          filtered = filtered.where((issue) => issue.assigneeId != null && issue.assigneeId!.isNotEmpty).toList();
          break;
        default:
          break;
      }
    }

    // Sort
    switch (_selectedSort) {
      case 'Newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Priority':
        final priorityOrder = {'high': 3, 'medium': 2, 'low': 1};
        filtered.sort((a, b) => (priorityOrder[b.priority] ?? 0).compareTo(priorityOrder[a.priority] ?? 0));
        break;
      case 'Category':
        filtered.sort((a, b) => a.category.compareTo(b.category));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Column(
        children: [
          // Modern Header with Stats
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.darkSurface,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reports Management',
                          style: AppTheme.headlineMedium.copyWith(
                            color: AppTheme.whiteColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track and manage all user reports',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.greyColor,
                          ),
                        ),
                      ],
                    ),
                    // Responsive app bar actions
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 400) {
                          // Wide screen - show all buttons
                          return Row(
                            children: [
                              IconButton(
                                onPressed: () => _showSendNotificationDialog(context),
                                icon: Icon(Icons.notifications_active, color: AppTheme.primaryColor),
                                tooltip: 'Send Notification to All Users',
                              ),
                              IconButton(
                                onPressed: () async {
                                  // Test Prabhas notification
                                  await PrabhasNotificationService.sendTestNotification();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Prabhas test notification sent! Check your notification panel.'),
                                      backgroundColor: AppTheme.successColor,
                                    ),
                                  );
                                },
                                icon: Icon(Icons.bug_report, color: AppTheme.warningColor),
                                tooltip: 'Test Notification',
                              ),
                              IconButton(
                                onPressed: () {
                                  Provider.of<IssuesProvider>(context, listen: false).fetchAllIssues(forceRefresh: true);
                                },
                                icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
                                tooltip: 'Refresh Reports',
                              ),
                            ],
                          );
                        } else {
                          // Narrow screen - show only essential buttons
                          return Row(
                            children: [
                              IconButton(
                                onPressed: () => _showSendNotificationDialog(context),
                                icon: Icon(Icons.notifications_active, color: AppTheme.primaryColor),
                                tooltip: 'Send Notification',
                              ),
                              IconButton(
                                onPressed: () {
                                  Provider.of<IssuesProvider>(context, listen: false).fetchAllIssues(forceRefresh: true);
                                },
                                icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
                                tooltip: 'Refresh',
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Quick Stats Cards - Compact
                Consumer<IssuesProvider>(
                  builder: (context, issuesProvider, child) {
                    final issues = issuesProvider.issues;
                    final unassigned = issues.where((i) => i.assigneeId == null || i.assigneeId!.isEmpty).length;
                    final assigned = issues.where((i) => i.assigneeId != null && i.assigneeId!.isNotEmpty).length;
                    final pending = issues.where((i) => i.status == 'pending').length;
                    final inProgress = issues.where((i) => i.status == 'in_progress').length;
                    
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCompactStatCard('Total', '${issues.length}', Icons.assignment, AppTheme.infoColor),
                          const SizedBox(width: 8),
                          _buildCompactStatCard('Unassigned', '$unassigned', Icons.person_add_disabled, AppTheme.warningColor),
                          const SizedBox(width: 8),
                          _buildCompactStatCard('Assigned', '$assigned', Icons.person_add, AppTheme.successColor),
                          const SizedBox(width: 8),
                          _buildCompactStatCard('Pending', '$pending', Icons.hourglass_empty, AppTheme.primaryColor),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Modern Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              border: Border(
                bottom: BorderSide(color: AppTheme.greyColor.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                // Filter Chips
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                            checkmarkColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.primaryColor : AppTheme.whiteColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: AppTheme.darkCard,
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryColor : AppTheme.greyColor.withOpacity(0.3),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                // Sort Dropdown
                PopupMenuButton<String>(
                  icon: Icon(Icons.sort, color: AppTheme.primaryColor),
                  tooltip: 'Sort Options',
                  onSelected: (value) {
                    setState(() {
                      _selectedSort = value;
                    });
                  },
                  itemBuilder: (context) => _sortOptions.map((sort) {
                    return PopupMenuItem<String>(
                      value: sort,
                      child: Row(
                        children: [
                          Icon(
                            _selectedSort == sort ? Icons.check : Icons.radio_button_unchecked,
                            color: _selectedSort == sort ? AppTheme.primaryColor : AppTheme.greyColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(sort),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Reports List
          Expanded(
            child: Consumer<IssuesProvider>(
              builder: (context, issuesProvider, child) {
                if (issuesProvider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  );
                }

                if (issuesProvider.issues.isEmpty) {
                  return _buildEmptyState();
                }

                final filteredIssues = _getFilteredIssues(issuesProvider.issues);

                if (filteredIssues.isEmpty) {
                  return _buildNoFilterResults();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredIssues.length,
                  itemBuilder: (context, index) {
                    final issue = filteredIssues[index];
                    return _buildModernReportCard(issue);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
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

  Widget _buildCompactStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: AppTheme.greyColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No reports found',
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.whiteColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reports will appear here when users submit them',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilterResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list,
            size: 80,
            color: AppTheme.greyColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No reports match your filter',
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.whiteColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filter criteria',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernReportCard(Issue issue) {
    final isAssigned = issue.assigneeId != null && issue.assigneeId!.isNotEmpty;
    final canAssign = issue.status == 'pending' && !isAssigned;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkSurface,
            AppTheme.darkSurface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isAssigned 
                ? AppTheme.successColor.withOpacity(0.15)
                : AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: isAssigned 
              ? AppTheme.successColor.withOpacity(0.4)
              : AppTheme.greyColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Header with Status Indicators
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAssigned
                    ? [AppTheme.successColor.withOpacity(0.15), AppTheme.successColor.withOpacity(0.05)]
                    : [AppTheme.primaryColor.withOpacity(0.15), AppTheme.primaryColor.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Top row with title and status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        issue.title,
                        style: AppTheme.titleLarge.copyWith(
                          color: AppTheme.whiteColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildStatusChip(issue.status),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Status indicators row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildIndicatorChip(
                      icon: isAssigned ? Icons.person : Icons.person_add,
                      label: isAssigned ? 'ASSIGNED' : 'UNASSIGNED',
                      color: isAssigned ? AppTheme.successColor : AppTheme.warningColor,
                    ),
                    _buildIndicatorChip(
                      icon: _getPriorityIcon(issue.priority ?? 'medium'),
                      label: (issue.priority ?? 'medium').toUpperCase(),
                      color: _getPriorityColor(issue.priority ?? 'medium'),
                    ),
                    _buildIndicatorChip(
                      icon: Icons.category,
                      label: issue.category.toUpperCase(),
                      color: AppTheme.infoColor,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.greyColor.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    issue.description,
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.greyColor,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 20),

                // Details Grid
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.greyColor.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.access_time, size: 20, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Created',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.greyColor,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatDate(issue.createdAt.toString()),
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.whiteColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.infoColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.location_on, size: 20, color: AppTheme.infoColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.greyColor,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  issue.address ?? 'No address provided',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.whiteColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons - Modern Grid Layout
                Column(
                  children: [
                    // First row of actions
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.visibility,
                            label: 'View Details',
                            color: AppTheme.primaryColor,
                            onPressed: () => _showReportDetails(issue),
                            isOutlined: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.edit,
                            label: 'Update Status',
                            color: AppTheme.infoColor,
                            onPressed: () => _showStatusUpdateDialog(issue),
                            isOutlined: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Second row of actions
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: isAssigned ? Icons.person : Icons.person_add,
                            label: isAssigned ? 'Already Assigned' : 'Assign Worker',
                            color: canAssign ? AppTheme.warningColor : AppTheme.greyColor,
                            onPressed: canAssign ? () => _showAssignmentDialog(issue) : null,
                            isOutlined: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.chat,
                            label: 'Chat',
                            color: AppTheme.successColor,
                            onPressed: () => _showChatDialog(issue),
                            isOutlined: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(status).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.whiteColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildIndicatorChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    required bool isOutlined,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppTheme.whiteColor,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: color.withOpacity(0.3),
        ),
      );
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.remove;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warningColor;
      case 'in_progress':
        return AppTheme.primaryColor;
      case 'completed':
        return AppTheme.successColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.greyColor;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'low':
        return AppTheme.successColor;
      default:
        return AppTheme.greyColor;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showReportDetails(Issue issue) async {
    // Get reporter details
    String reporterName = 'Unknown User';
    String reporterEmail = 'No email';
    String assignedWorkerName = 'Not Assigned';
    String assignedWorkerDepartment = '';
    String assignedWorkerPhone = '';
    
    try {
      // Get reporter details
      final reporterResponse = await Supabase.instance.client
          .from('profiles')
          .select('full_name, email')
          .eq('id', issue.userId)
          .single();
      
      reporterName = reporterResponse['full_name'] ?? 'Unknown User';
      reporterEmail = reporterResponse['email'] ?? 'No email';
      
      // Get assigned worker details if assigned
      if (issue.assigneeId != null && issue.assigneeId!.isNotEmpty) {
        final workerResponse = await Supabase.instance.client
            .from('profiles')
            .select('full_name, department, phone_number')
            .eq('id', issue.assigneeId!)
            .single();
        
        assignedWorkerName = workerResponse['full_name'] ?? 'Unknown Worker';
        assignedWorkerDepartment = workerResponse['department'] ?? 'No Department';
        assignedWorkerPhone = workerResponse['phone_number'] ?? 'No Phone';
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.darkSurface,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(color: AppTheme.greyColor.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment, color: AppTheme.primaryColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Report Details',
                        style: AppTheme.titleLarge.copyWith(
                          color: AppTheme.whiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: AppTheme.greyColor),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Report Information
                      _buildDetailSection('Report Information', [
                        _buildDetailRow('Title', issue.title),
                        _buildDetailRow('Description', issue.description),
                        _buildDetailRow('Status', issue.status.toUpperCase()),
                        _buildDetailRow('Priority', (issue.priority ?? 'medium').toUpperCase()),
                        _buildDetailRow('Category', issue.category),
                        _buildDetailRow('Address', issue.address ?? 'No address provided'),
                        _buildDetailRow('Created', _formatDateTime(issue.createdAt.toString())),
                      ]),
                      
                      const SizedBox(height: 20),
                      
                      // Reporter Information
                      _buildDetailSection('Reporter Information', [
                        _buildDetailRow('Name', reporterName),
                        _buildDetailRow('Email', reporterEmail),
                      ]),
                      
                      const SizedBox(height: 20),
                      
                      // Assignment Information
                      _buildDetailSection('Assignment Information', [
                        _buildDetailRow('Assigned Worker', assignedWorkerName),
                        if (assignedWorkerDepartment.isNotEmpty)
                          _buildDetailRow('Worker Department', assignedWorkerDepartment),
                        if (assignedWorkerPhone.isNotEmpty)
                          _buildDetailRow('Worker Phone', assignedWorkerPhone),
                        _buildDetailRow('Assignment Status', issue.assigneeId != null && issue.assigneeId!.isNotEmpty ? 'ASSIGNED' : 'UNASSIGNED'),
                      ]),
                      
                      const SizedBox(height: 20),
                      
                      // Images
                      if (issue.imageUrls.isNotEmpty) ...[
                        _buildDetailSection('Images', [
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: issue.imageUrls.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      issue.imageUrls[index],
                                      width: 150,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 150,
                                          height: 200,
                                          color: AppTheme.darkCard,
                                          child: Icon(
                                            Icons.broken_image,
                                            color: AppTheme.greyColor,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTheme.greyColor.withOpacity(0.2)),
                  ),
                ),
                child: Column(
                  children: [
                    // First row of actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showChatDialog(issue);
                            },
                            icon: Icon(Icons.chat, size: 16),
                            label: Text('Chat'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: BorderSide(color: AppTheme.primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showStatusUpdateDialog(issue);
                            },
                            icon: Icon(Icons.edit, size: 16),
                            label: Text('Update Status'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.infoColor,
                              foregroundColor: AppTheme.whiteColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Second row of actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: issue.status == 'pending' && (issue.assigneeId == null || issue.assigneeId!.isEmpty)
                                ? () {
                                    Navigator.pop(context);
                                    _showAssignmentDialog(issue);
                                  }
                                : null,
                            icon: Icon(
                              issue.assigneeId != null && issue.assigneeId!.isNotEmpty ? Icons.person : Icons.person_add,
                              size: 16,
                            ),
                            label: Text(issue.assigneeId != null && issue.assigneeId!.isNotEmpty ? 'Already Assigned' : 'Assign Worker'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: issue.assigneeId != null && issue.assigneeId!.isNotEmpty 
                                  ? AppTheme.greyColor 
                                  : AppTheme.warningColor,
                              side: BorderSide(
                                color: issue.assigneeId != null && issue.assigneeId!.isNotEmpty 
                                    ? AppTheme.greyColor 
                                    : AppTheme.warningColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, size: 16),
                            label: Text('Close'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.greyColor,
                              side: BorderSide(color: AppTheme.greyColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.greyColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.greyColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.whiteColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  void _showChatDialog(Issue issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Chat with Reporter',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
        ),
        content: Container(
          width: 300,
          height: 200,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Chat feature coming soon!\n\nYou can communicate with the reporter about this issue here.',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.darkBackground,
                ),
                style: TextStyle(color: AppTheme.whiteColor),
              ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Message sent!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showAssignmentDialog(Issue issue) {
    String? selectedWorkerId;
    List<Map<String, dynamic>> workers = [];
    bool isLoading = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          if (isLoading) {
            // Load workers when dialog opens
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                final workerResponse = await Supabase.instance.client
                    .from('profiles')
                    .select('*')
                    .eq('role', 'worker')
                    .eq('is_active', true)
                    .order('full_name');

                setState(() {
                  workers = List<Map<String, dynamic>>.from(workerResponse);
                  isLoading = false;
                });
              } catch (e) {
                setState(() {
                  isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading workers: $e'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            });
          }

          return AlertDialog(
            backgroundColor: AppTheme.darkSurface,
            title: Text(
              'Assign Worker',
              style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
            ),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Issue Info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.darkCard,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Issue: ${issue.title}',
                                  style: AppTheme.titleSmall.copyWith(
                                    color: AppTheme.whiteColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Category: ${issue.category}',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.greyColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Worker Selection
                          DropdownButtonFormField<String>(
                            value: selectedWorkerId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Select Worker',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: AppTheme.darkBackground,
                            ),
                            items: workers.map((worker) {
                              return DropdownMenuItem<String>(
                                value: worker['id'],
                                child: Text(
                                  '${worker['full_name']} (${worker['department'] ?? 'No Department'})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              setState(() {
                                selectedWorkerId = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: AppTheme.greyColor)),
              ),
              ElevatedButton(
                onPressed: selectedWorkerId != null ? () async {
                  try {
                    // Assign worker to issue and update status to in_progress
                    await Supabase.instance.client
                        .from('issues')
                        .update({
                          'assignee_id': selectedWorkerId,
                          'status': 'in_progress', // Change status from pending to in_progress
                          'updated_at': DateTime.now().toIso8601String(),
                        })
                        .eq('id', issue.id);

                    // Send notification to user
                    await _sendAssignmentNotification(issue.userId, issue.title, selectedWorkerId!, issue.id, issue.priority ?? 'medium');

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Worker Assigned! Status updated to In Progress. Notification sent to user.'),
                        backgroundColor: AppTheme.successColor,
                        duration: Duration(seconds: 4),
                      ),
                    );
                    
                    // Refresh the issues list
                    Provider.of<IssuesProvider>(context, listen: false).fetchAllIssues(forceRefresh: true);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error assigning worker: $e'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                } : null,
                child: Text('Assign Worker'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendAssignmentNotification(String userId, String issueTitle, String workerId, String issueId, String priority) async {
    try {
      // Get worker details
      final workerResponse = await Supabase.instance.client
          .from('profiles')
          .select('full_name, department_id')
          .eq('id', workerId)
          .single();
      
      final workerName = workerResponse['full_name'] ?? 'Unknown Worker';
      final workerDepartment = workerResponse['department_id'] ?? 'No Department';

      // Send Prabhas style notification to user about worker assignment
      await PrabhasNotificationService.sendWorkerAssignmentToUser(
        workerName: workerName,
        issueTitle: issueTitle,
        issueId: issueId,
        userId: userId,
      );

      // Send Prabhas style notification to worker about task assignment
      await PrabhasNotificationService.sendWorkerAssignmentToWorker(
        issueTitle: issueTitle,
        issueId: issueId,
        workerId: workerId,
      );


      print('Assignment notifications sent to user $userId and worker $workerId');
    } catch (e) {
      print('Error sending assignment notifications: $e');
    }
  }

  void _showStatusUpdateDialog(Issue issue) {
    String selectedStatus = issue.status;
    final statusOptions = ['pending', 'in_progress', 'completed', 'cancelled'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.darkSurface,
            title: Text(
              'Update Issue Status',
              style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
            ),
            content: Container(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Issue Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Issue: ${issue.title}',
                          style: AppTheme.titleSmall.copyWith(
                            color: AppTheme.whiteColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current Status: ${issue.status.toUpperCase()}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Selection
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Select New Status',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: AppTheme.darkBackground,
                    ),
                    items: statusOptions.map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
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
                onPressed: selectedStatus != issue.status ? () async {
                  try {
                    // Update issue status
                    await Supabase.instance.client
                        .from('issues')
                        .update({
                          'status': selectedStatus,
                          'updated_at': DateTime.now().toIso8601String(),
                        })
                        .eq('id', issue.id);

                    // Send notification to user about status change
                    await _sendStatusUpdateNotification(issue.userId, issue.title, selectedStatus);

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Status updated to ${selectedStatus.toUpperCase()}! Notification sent to user.'),
                        backgroundColor: AppTheme.successColor,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    
                    // Refresh the issues list
                    Provider.of<IssuesProvider>(context, listen: false).fetchAllIssues(forceRefresh: true);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating status: $e'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                } : null,
                child: Text('Update Status'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendStatusUpdateNotification(String userId, String issueTitle, String newStatus) async {
    try {
      String statusMessage = '';
      String notificationTitle = '';
      
      switch (newStatus) {
        case 'pending':
          statusMessage = 'Your report has been set to Pending status.';
          notificationTitle = 'Report Status Updated';
          break;
        case 'in_progress':
          statusMessage = 'Your report is now In Progress. A worker is working on it.';
          notificationTitle = 'Report In Progress';
          break;
        case 'completed':
          statusMessage = 'Your report has been completed! Thank you for your contribution.';
          notificationTitle = 'Report Completed';
          break;
        case 'cancelled':
          statusMessage = 'Your report has been cancelled. Please contact support if you have questions.';
          notificationTitle = 'Report Cancelled';
          break;
      }

      // Create notification
      await Supabase.instance.client
          .from('notifications')
          .insert({
            'user_id': userId,
            'title': notificationTitle,
            'message': 'Report: "$issueTitle" - $statusMessage',
            'type': newStatus == 'completed' ? 'success' : 'info',
            'created_at': DateTime.now().toIso8601String(),
          });

      print('Status update notification sent to user $userId');
    } catch (e) {
      print('Error sending status update notification: $e');
    }
  }

  // Send notification to all users
  Future<void> _showSendNotificationDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = 'info';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: Text(
          'Send Notification to All Users',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              decoration: AppTheme.inputDecoration.copyWith(
                labelText: 'Notification Title',
                prefixIcon: Icon(Icons.title, color: AppTheme.greyColor),
              ),
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: messageController,
              decoration: AppTheme.inputDecoration.copyWith(
                labelText: 'Notification Message',
                prefixIcon: Icon(Icons.message, color: AppTheme.greyColor),
              ),
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: AppTheme.inputDecoration.copyWith(
                labelText: 'Notification Type',
                prefixIcon: Icon(Icons.category, color: AppTheme.greyColor),
              ),
              dropdownColor: AppTheme.darkSurface,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
              items: [
                DropdownMenuItem(value: 'info', child: Text('Info', style: TextStyle(color: AppTheme.whiteColor))),
                DropdownMenuItem(value: 'success', child: Text('Success', style: TextStyle(color: AppTheme.whiteColor))),
                DropdownMenuItem(value: 'warning', child: Text('Warning', style: TextStyle(color: AppTheme.whiteColor))),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent', style: TextStyle(color: AppTheme.whiteColor))),
              ],
              onChanged: (value) {
                selectedType = value ?? 'info';
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
            onPressed: () async {
              if (titleController.text.isNotEmpty && messageController.text.isNotEmpty) {
                Navigator.pop(context);
                await _sendNotificationToAllUsers(
                  titleController.text,
                  messageController.text,
                  selectedType,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: Text('Send', style: TextStyle(color: AppTheme.whiteColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendNotificationToAllUsers(String title, String message, String type) async {
    try {
      // Get all user IDs from profiles table
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id');

      if (response != null && response is List) {
        final userIds = response.map((user) => user['id'] as String).toList();
        
        // Send notification to each user
        for (String userId in userIds) {
          await Supabase.instance.client
              .from('notifications')
              .insert({
                'user_id': userId,
                'title': title,
                'message': message,
                'type': type,
                'created_at': DateTime.now().toIso8601String(),
              });

          // Send enhanced notification with custom sound based on type
          String soundFile = 'xp_sound'; // Default sound
          switch (type.toLowerCase()) {
            case 'info':
              soundFile = 'xp_sound';
              break;
            case 'alert':
              soundFile = 'task_sound';
              break;
            case 'review':
              soundFile = 'worker_assignment';
              break;
            case 'urgent':
              soundFile = 'task_sound';
              break;
            default:
              soundFile = 'xp_sound';
          }
          
          // Send Prabhas style admin notification
          await PrabhasNotificationService.sendAdminNotification(
            message: message,
            type: type,
            userId: userId,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notification sent to ${userIds.length} users'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      print('Error sending notification to all users: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
