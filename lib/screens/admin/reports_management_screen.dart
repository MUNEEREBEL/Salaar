import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/issues_provider.dart';
import '../../theme/app_theme.dart';

class ReportsManagementScreen extends StatefulWidget {
  const ReportsManagementScreen({Key? key}) : super(key: key);

  @override
  State<ReportsManagementScreen> createState() => _ReportsManagementScreenState();
}

class _ReportsManagementScreenState extends State<ReportsManagementScreen> {
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';
  final List<String> _filters = ['All', 'Pending', 'In Progress', 'Completed', 'Cancelled', 'Unassigned', 'Assigned'];
  final List<String> _sortOptions = ['Newest', 'Oldest', 'Priority', 'Category'];

  @override
  void initState() {
    super.initState();
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                    'Manage and track all user reports',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.greyColor,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  Provider.of<IssuesProvider>(context, listen: false).fetchAllIssues(forceRefresh: true);
                },
                icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
                tooltip: 'Refresh Reports',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters and Sort - More visible
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.greyColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter & Sort',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Filter by Status',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: AppTheme.darkBackground,
                        ),
                        items: _filters.map((String filter) {
                          return DropdownMenuItem<String>(
                            value: filter,
                            child: Text(filter, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedFilter = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSort,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Sort by',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: AppTheme.darkBackground,
                        ),
                        items: _sortOptions.map((String sort) {
                          return DropdownMenuItem<String>(
                            value: sort,
                            child: Text(sort, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedSort = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Reports List
          Expanded(
            child: Consumer<IssuesProvider>(
              builder: (context, issuesProvider, child) {
                if (issuesProvider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  );
                }

                if (issuesProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: AppTheme.errorColor, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading reports',
                          style: AppTheme.titleMedium.copyWith(color: AppTheme.whiteColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          issuesProvider.error!,
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final filteredIssues = _getFilteredIssues(issuesProvider.issues);

                if (filteredIssues.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment, color: AppTheme.greyColor, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'No reports found',
                          style: AppTheme.titleMedium.copyWith(color: AppTheme.whiteColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredIssues.length,
                  itemBuilder: (context, index) {
                    final issue = filteredIssues[index];
                    return _buildReportCard(issue);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Issue issue) {
    return Card(
      color: AppTheme.darkSurface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    issue.title,
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: _buildStatusChip(issue.status),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              issue.description,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.greyColor,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Details
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDetailChip(
                    _getCategoryIcon(issue.category),
                    issue.category,
                    _getCategoryColor(issue.category),
                  ),
                  const SizedBox(width: 8),
                  _buildDetailChip(
                    _getPriorityIcon(issue.priority ?? 'medium'),
                    (issue.priority ?? 'medium').toUpperCase(),
                    _getPriorityColor(issue.priority ?? 'medium'),
                  ),
                  const SizedBox(width: 8),
                  _buildDetailChip(
                    Icons.location_on,
                    issue.address ?? 'No address',
                    AppTheme.infoColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Images
            if (issue.imageUrls.isNotEmpty) ...[
              SizedBox(
                height: 60,
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
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
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
              const SizedBox(height: 12),
            ],

            // Actions - Better responsive layout
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReportDetails(issue),
                    icon: Icon(Icons.visibility, size: 16),
                    label: Text('View'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: issue.status == 'pending' && (issue.assigneeId == null || issue.assigneeId!.isEmpty)
                        ? () => _showAssignmentDialog(issue)
                        : null,
                    icon: Icon(Icons.person_add, size: 16),
                    label: Text(issue.assigneeId != null && issue.assigneeId!.isNotEmpty ? 'Assigned' : 'Assign'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: issue.status == 'pending' && (issue.assigneeId == null || issue.assigneeId!.isEmpty)
                          ? AppTheme.warningColor
                          : AppTheme.greyColor,
                      side: BorderSide(
                        color: issue.status == 'pending' && (issue.assigneeId == null || issue.assigneeId!.isEmpty)
                            ? AppTheme.warningColor
                            : AppTheme.greyColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showStatusUpdateDialog(issue),
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Update'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.whiteColor,
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

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = AppTheme.warningColor;
        break;
      case 'in_progress':
        color = AppTheme.infoColor;
        break;
      case 'completed':
        color = AppTheme.successColor;
        break;
      case 'cancelled':
        color = AppTheme.errorColor;
        break;
      default:
        color = AppTheme.greyColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTheme.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: AppTheme.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
        return Icons.construction;
      case 'sanitation':
        return Icons.delete;
      case 'traffic':
        return Icons.traffic;
      case 'safety':
        return Icons.security;
      case 'environment':
        return Icons.eco;
      case 'utilities':
        return Icons.lightbulb;
      default:
        return Icons.info;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
        return AppTheme.primaryColor;
      case 'sanitation':
        return AppTheme.errorColor;
      case 'traffic':
        return AppTheme.warningColor;
      case 'safety':
        return AppTheme.infoColor;
      case 'environment':
        return AppTheme.successColor;
      case 'utilities':
        return AppTheme.accentColor;
      default:
        return AppTheme.greyColor;
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

  void _showReportDetails(Issue issue) {
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(color: AppTheme.greyColor.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Report Details',
                        style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Report Info
                      _buildDetailCard('Report Information', [
                        _buildDetailRow('Title', issue.title),
                        _buildDetailRow('Description', issue.description),
                        _buildDetailRow('Status', issue.status),
                        _buildDetailRow('Priority', issue.priority ?? 'medium'),
                        _buildDetailRow('Category', issue.category),
                        _buildDetailRow('Address', issue.address ?? 'No address'),
                        _buildDetailRow('Created', _formatDate(issue.createdAt.toString())),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      // User Details
                      _buildDetailCard('Reporter Information', [
                        _buildDetailRow('Reporter', _getReporterName(issue.userId)),
                        _buildDetailRow('Email', _getReporterEmail(issue.userId)),
                        _buildDetailRow('Assignee', _getAssigneeName(issue.assigneeId)),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      // Images
                      if (issue.imageUrls.isNotEmpty) ...[
                        _buildDetailCard('Images', [
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
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTheme.greyColor.withOpacity(0.2)),
                  ),
                ),
                child: Row(
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
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.whiteColor,
                        ),
                      ),
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

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.greyColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.titleSmall.copyWith(
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _getReporterName(String userId) {
    // Try to get from current issues data first
    try {
      final issues = Provider.of<IssuesProvider>(context, listen: false).issues;
      final issue = issues.where((i) => i.userId == userId).firstOrNull;
      
      if (issue != null && issue.reporterName != null) {
        return issue.reporterName!;
      }
    } catch (e) {
      print('Error getting reporter name: $e');
    }
    
    return 'User ${userId.substring(0, 8)}...';
  }

  String _getReporterEmail(String userId) {
    // Try to get from current issues data first
    try {
      final issues = Provider.of<IssuesProvider>(context, listen: false).issues;
      final issue = issues.where((i) => i.userId == userId).firstOrNull;
      
      if (issue != null && issue.reporterEmail != null) {
        return issue.reporterEmail!;
      }
    } catch (e) {
      print('Error getting reporter email: $e');
    }
    
    return 'user@example.com';
  }

  String _getAssigneeName(String? assigneeId) {
    if (assigneeId == null || assigneeId.isEmpty) {
      return 'Not assigned';
    }
    // This would typically fetch from a workers cache or database
    // For now, return a placeholder
    return 'Worker ${assigneeId.substring(0, 8)}...';
  }

  Future<Map<String, int>> _getWorkerStatsForAssignment(String workerId) async {
    try {
      // Get all tasks assigned to this worker
      final allIssuesResponse = await Supabase.instance.client
          .from('issues')
          .select('id, status')
          .eq('assignee_id', workerId);
      
      final allIssues = allIssuesResponse as List;
      
      // Count by status
      final completed = allIssues.where((issue) => 
        issue['status'] == 'resolved' || issue['status'] == 'completed').length;
      
      final ongoing = allIssues.where((issue) => 
        issue['status'] == 'in_progress' || issue['status'] == 'pending').length;

      return {
        'completed': completed,
        'ongoing': ongoing,
        'total': allIssues.length,
      };
    } catch (e) {
      print('Error getting worker stats for assignment: $e');
      return {'completed': 0, 'ongoing': 0, 'total': 0};
    }
  }

  String? _getDepartmentIdByCategory(String category, List<dynamic> departments) {
    // Map categories to department names
    final categoryToDeptMap = {
      'pothole': 'Infrastructure',
      'road_damage': 'Infrastructure',
      'bridge_issue': 'Infrastructure',
      'street_light': 'Infrastructure',
      'waste_management': 'Sanitation',
      'garbage': 'Sanitation',
      'drainage': 'Sanitation',
      'cleaning': 'Sanitation',
      'traffic_signal': 'Traffic',
      'road_safety': 'Traffic',
      'parking': 'Traffic',
      'safety_hazard': 'Safety',
      'emergency': 'Emergency',
      'fire_hazard': 'Safety',
      'environmental': 'Environment',
      'tree_issue': 'Environment',
      'water_issue': 'Utilities',
      'electricity': 'Utilities',
      'maintenance': 'Maintenance',
    };

    // Get department name for the category
    final deptName = categoryToDeptMap[category.toLowerCase()] ?? 'Infrastructure';
    
    // Find department ID by name
    for (var dept in departments) {
      if (dept['name'] == deptName) {
        return dept['id'];
      }
    }
    
    // Return first department as fallback
    return departments.isNotEmpty ? departments.first['id'] : null;
  }

  void _showAssignmentDialog(Issue issue) {
    String? selectedWorkerId;
    String? selectedDepartmentId;
    List<Map<String, dynamic>> workers = [];
    List<Map<String, dynamic>> departments = [];
    bool isLoading = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          if (isLoading) {
            // Load data when dialog opens
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                // Load departments
                final deptResponse = await Supabase.instance.client
                    .from('departments')
                    .select('*')
                    .eq('is_active', true)
                    .order('name');

                // Load workers - all active workers
                final workerResponse = await Supabase.instance.client
                    .from('profiles')
                    .select('*')
                    .eq('role', 'worker')
                    .eq('is_active', true)
                    .order('full_name');

                // Auto-select department based on issue category
                String? autoSelectedDeptId = _getDepartmentIdByCategory(issue.category, deptResponse);

                setState(() {
                  departments = List<Map<String, dynamic>>.from(deptResponse);
                  workers = List<Map<String, dynamic>>.from(workerResponse);
                  selectedDepartmentId = autoSelectedDeptId;
                  isLoading = false;
                });
              } catch (e) {
                setState(() {
                  isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading data: $e'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            });
          }

          return AlertDialog(
            backgroundColor: AppTheme.darkSurface,
            title: Text(
              'Assign Issue to Worker',
              style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
            ),
            content: Container(
              width: 400,
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    )
                  : Column(
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

                        // Department Selection
                        DropdownButtonFormField<String>(
                          value: selectedDepartmentId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Filter by Department',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: AppTheme.darkBackground,
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Departments'),
                            ),
                            ...departments.map((dept) {
                              return DropdownMenuItem<String>(
                                value: dept['id'],
                                child: Text(dept['name']),
                              );
                            }).toList(),
                          ],
                          onChanged: (String? value) {
                            setState(() {
                              selectedDepartmentId = value;
                              selectedWorkerId = null; // Reset worker selection
                            });
                          },
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
                                items: workers
                                    .where((worker) => selectedDepartmentId == null || 
                                        worker['department_id'] == selectedDepartmentId)
                                    .map((worker) {
                                  return DropdownMenuItem<String>(
                                    value: worker['id'],
                                    child: FutureBuilder<Map<String, int>>(
                                      future: _getWorkerStatsForAssignment(worker['id']),
                                      builder: (context, snapshot) {
                                        final stats = snapshot.data ?? {'completed': 0, 'ongoing': 0, 'total': 0};
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: Text(worker['full_name'] ?? 'Unknown Worker'),
                                            ),
                                            Text(
                                              '(${stats['completed']}/${stats['total']})',
                                              style: TextStyle(
                                                color: AppTheme.greyColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: AppTheme.greyColor)),
              ),
              ElevatedButton(
                      onPressed: selectedWorkerId != null ? () async {
                        try {
                          // Assign worker to issue and update status
                          await Supabase.instance.client
                              .from('issues')
                              .update({
                                'assignee_id': selectedWorkerId,
                                'status': 'in_progress', // Update status when assigned
                                'updated_at': DateTime.now().toIso8601String(),
                              })
                              .eq('id', issue.id);

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Worker Assigned! Issue status updated to In Progress.'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                          
                          // Refresh the issues list
                          setState(() {
                            // Trigger rebuild to refresh data
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error assigning issue: $e'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      } : null,
                child: Text('Assign'),
              ),
            ],
          );
        },
      ),
    );
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

  void _showStatusUpdateDialog(Issue issue) {
    String newStatus = issue.status;
    String newPriority = issue.priority ?? 'medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: Text(
            'Update Status',
            style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: newStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: ['pending', 'in_progress', 'completed', 'cancelled'].map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status.toUpperCase()),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      newStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: newPriority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: ['low', 'medium', 'high'].map((String priority) {
                  return DropdownMenuItem<String>(
                    value: priority,
                    child: Text(priority.toUpperCase()),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      newPriority = value;
                    });
                  }
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
                _updateIssueStatus(issue, newStatus, newPriority);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: Text('Update', style: TextStyle(color: AppTheme.whiteColor)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateIssueStatus(Issue issue, String newStatus, String newPriority) async {
    try {
      await Supabase.instance.client.from('issues').update({
        'status': newStatus,
        'priority': newPriority,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', issue.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issue status updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // Refresh the issues list
        Provider.of<IssuesProvider>(context, listen: false).fetchAllIssues(forceRefresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating issue: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}