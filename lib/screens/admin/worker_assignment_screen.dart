import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class WorkerAssignmentScreen extends StatefulWidget {
  const WorkerAssignmentScreen({Key? key}) : super(key: key);

  @override
  State<WorkerAssignmentScreen> createState() => _WorkerAssignmentScreenState();
}

class _WorkerAssignmentScreenState extends State<WorkerAssignmentScreen> {
  List<Map<String, dynamic>> _workers = [];
  List<Map<String, dynamic>> _unassignedIssues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load workers
      final workersResponse = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('role', 'worker')
          .eq('is_active', true);

      // Load all pending issues
      final issuesResponse = await Supabase.instance.client
          .from('issues')
          .select('*')
          .eq('status', 'pending');

      // Filter unassigned issues
      final unassignedIssues = (issuesResponse as List).where((issue) => 
        issue['assignee_id'] == null || issue['assignee_id'] == '').toList();

      if (mounted) {
        setState(() {
          _workers = List<Map<String, dynamic>>.from(workersResponse);
          _unassignedIssues = List<Map<String, dynamic>>.from(unassignedIssues);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _assignIssueToWorker(String issueId, String workerId) async {
    try {
      await Supabase.instance.client
          .from('issues')
          .update({
            'assignee_id': workerId,
            'status': 'in_progress',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', issueId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issue assigned successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // Refresh data
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning issue: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
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
                    'Worker Assignment',
                    style: AppTheme.headlineMedium.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Assign pending issues to workers',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.greyColor,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _loadData,
                icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
                tooltip: 'Refresh Data',
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          else
            Expanded(
              child: Row(
                children: [
                  // Workers List
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Workers (${_workers.length})',
                          style: AppTheme.titleLarge.copyWith(
                            color: AppTheme.whiteColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _workers.length,
                            itemBuilder: (context, index) {
                              final worker = _workers[index];
                              return _buildWorkerCard(worker);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  
                  // Unassigned Issues
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unassigned Issues (${_unassignedIssues.length})',
                          style: AppTheme.titleLarge.copyWith(
                            color: AppTheme.whiteColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _unassignedIssues.length,
                            itemBuilder: (context, index) {
                              final issue = _unassignedIssues[index];
                              return _buildIssueCard(issue);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    return Card(
      color: AppTheme.darkSurface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    (worker['full_name'] ?? 'W').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.whiteColor,
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
                        worker['full_name'] ?? 'Unknown Worker',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.whiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        worker['department'] ?? 'No Department',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.greyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: AppTheme.greyColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    worker['email'] ?? 'No Email',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.greyColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (worker['phone_number'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: AppTheme.greyColor),
                  const SizedBox(width: 8),
                  Text(
                    worker['phone_number'],
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.greyColor,
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

  Widget _buildIssueCard(Map<String, dynamic> issue) {
    return Card(
      color: AppTheme.darkSurface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              issue['title'] ?? 'Untitled Issue',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              issue['description'] ?? 'No description',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.greyColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildChip(
                  _getCategoryIcon(issue['category']),
                  issue['category'] ?? 'Other',
                  _getCategoryColor(issue['category']),
                ),
                const SizedBox(width: 8),
                _buildChip(
                  _getPriorityIcon(issue['priority']),
                  (issue['priority'] ?? 'medium').toUpperCase(),
                  _getPriorityColor(issue['priority']),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Assign to:',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.greyColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: 'Select Worker',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _workers.map((worker) {
                return DropdownMenuItem<String>(
                  value: worker['id'],
                  child: Text(worker['full_name'] ?? 'Unknown'),
                );
              }).toList(),
              onChanged: (String? workerId) {
                if (workerId != null) {
                  _assignIssueToWorker(issue['id'], workerId);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String text, Color color) {
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
          Text(
            text,
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
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

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
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

  IconData _getPriorityIcon(String? priority) {
    switch (priority?.toLowerCase()) {
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

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
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
}
