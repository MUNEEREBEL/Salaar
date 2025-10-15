// lib/screens/worker/worker_issue_management.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/issues_provider.dart';
import '../../theme/app_theme.dart';
import 'dart:io';

class WorkerIssueManagement extends StatefulWidget {
  const WorkerIssueManagement({Key? key}) : super(key: key);

  @override
  State<WorkerIssueManagement> createState() => _WorkerIssueManagementState();
}

class _WorkerIssueManagementState extends State<WorkerIssueManagement> {
  String _selectedStatus = 'pending';
  String _selectedPriority = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IssuesProvider>(context, listen: false).fetchAllIssues();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Issue Management',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Provider.of<IssuesProvider>(context, listen: false).fetchAllIssues(forceRefresh: true);
            },
            icon: Icon(Icons.refresh, color: AppTheme.whiteColor),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          _buildFilterSection(),
          
          // Issues list
          Expanded(
            child: Consumer<IssuesProvider>(
              builder: (context, issuesProvider, child) {
                if (issuesProvider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  );
                }

                final filteredIssues = _filterIssues(issuesProvider.issues);
                
                if (filteredIssues.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: AppTheme.greyColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No issues found',
                          style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No issues match your current filters',
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredIssues.length,
                  itemBuilder: (context, index) {
                    final issue = filteredIssues[index];
                    return _buildIssueCard(issue);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.darkSurface,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: AppTheme.whiteColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: AppTheme.darkBackground,
                  ),
                  dropdownColor: AppTheme.darkSurface,
                  style: TextStyle(color: AppTheme.whiteColor),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'verified', child: Text('Verified')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value ?? 'all';
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    labelStyle: TextStyle(color: AppTheme.whiteColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: AppTheme.darkBackground,
                  ),
                  dropdownColor: AppTheme.darkSurface,
                  style: TextStyle(color: AppTheme.whiteColor),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('All Priority')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value ?? 'all';
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(issue) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(issue.issueType),
                  color: _getCategoryColor(issue.issueType),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    issue.title,
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(issue.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    issue.status.toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.whiteColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              issue.description,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(issue.issueType),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    issue.issueType.toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.whiteColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(issue.priority),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (issue.priority ?? 'MEDIUM').toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.whiteColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(issue.createdAt),
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showUpdateDialog(issue),
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Update Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.whiteColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showIssueDetails(issue),
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

  void _showUpdateDialog(issue) {
    String newStatus = issue.status;
    String newPriority = issue.priority ?? 'medium';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: Text(
            'Update Issue',
            style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: newStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  labelStyle: TextStyle(color: AppTheme.whiteColor),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.darkBackground,
                ),
                dropdownColor: AppTheme.darkSurface,
                style: TextStyle(color: AppTheme.whiteColor),
                items: [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'verified', child: Text('Verified')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) {
                  setState(() {
                    newStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: newPriority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  labelStyle: TextStyle(color: AppTheme.whiteColor),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.darkBackground,
                ),
                dropdownColor: AppTheme.darkSurface,
                style: TextStyle(color: AppTheme.whiteColor),
                items: [
                  DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                ],
                onChanged: (value) {
                  setState(() {
                    newPriority = value!;
                  });
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
                await _updateIssueStatus(issue.id, newStatus, newPriority);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.whiteColor,
              ),
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateIssueStatus(String issueId, String newStatus, String newPriority) async {
    try {
      final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
      await issuesProvider.updateIssueStatusForWorker(issueId, newStatus, newPriority);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issue status updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update issue: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showIssueDetails(issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Issue Details',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Title: ${issue.title}',
                style: AppTheme.bodyLarge.copyWith(color: AppTheme.whiteColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Description: ${issue.description}',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Type: ${issue.issueType}',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
              ),
              Text(
                'Status: ${issue.status}',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
              ),
              Text(
                'Priority: ${issue.priority ?? 'Medium'}',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
              ),
              Text(
                'Location: ${issue.address ?? 'Not specified'}',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
              ),
              Text(
                'Created: ${_formatDate(issue.createdAt)}',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
              ),
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

  List<dynamic> _filterIssues(List<dynamic> issues) {
    return issues.where((issue) {
      bool statusMatch = _selectedStatus == 'all' || issue.status == _selectedStatus;
      bool priorityMatch = _selectedPriority == 'all' || (issue.priority ?? 'medium') == _selectedPriority;
      return statusMatch && priorityMatch;
    }).toList();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
        return Colors.blue;
      case 'sanitation':
        return Colors.brown;
      case 'traffic':
        return Colors.orange;
      case 'safety':
        return Colors.red;
      case 'environment':
        return Colors.green;
      case 'utilities':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
        return Icons.build;
      case 'sanitation':
        return Icons.water_drop;
      case 'traffic':
        return Icons.traffic;
      case 'safety':
        return Icons.security;
      case 'environment':
        return Icons.eco;
      case 'utilities':
        return Icons.electrical_services;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'verified':
        return Colors.green;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
