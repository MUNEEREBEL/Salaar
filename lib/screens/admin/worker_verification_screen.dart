import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class WorkerVerificationScreen extends StatefulWidget {
  const WorkerVerificationScreen({Key? key}) : super(key: key);

  @override
  State<WorkerVerificationScreen> createState() => _WorkerVerificationScreenState();
}

class _WorkerVerificationScreenState extends State<WorkerVerificationScreen> {
  List<Map<String, dynamic>> _pendingVerifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingVerifications();
  }

  Future<void> _loadPendingVerifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load issues that are in progress and have assignee_id
      final response = await Supabase.instance.client
          .from('issues')
          .select('''
            *,
            profiles!assignee_id(
              id,
              full_name,
              email,
              department
            )
          ''')
          .eq('status', 'in_progress')
          .not('assignee_id', 'is', null);

      if (mounted) {
        setState(() {
          _pendingVerifications = List<Map<String, dynamic>>.from(response);
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
            content: Text('Error loading verifications: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _verifyWorkerUpdate(String issueId, String newStatus, String? notes) async {
    try {
      await Supabase.instance.client
          .from('issues')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
            'completed_at': newStatus == 'completed' ? DateTime.now().toIso8601String() : null,
            'admin_notes': notes,
          })
          .eq('id', issueId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Worker update verified successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // Refresh data
        _loadPendingVerifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying update: $e'),
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
                    'Worker Verification',
                    style: AppTheme.headlineMedium.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Verify worker status updates and image uploads',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.greyColor,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _loadPendingVerifications,
                icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
                tooltip: 'Refresh Verifications',
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          else if (_pendingVerifications.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user, color: AppTheme.greyColor, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No Pending Verifications',
                    style: AppTheme.titleMedium.copyWith(color: AppTheme.whiteColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All worker updates have been verified',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _pendingVerifications.length,
                itemBuilder: (context, index) {
                  final verification = _pendingVerifications[index];
                  return _buildVerificationCard(verification);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(Map<String, dynamic> verification) {
    final issue = verification;
    final worker = verification['profiles'];

    return Card(
      color: AppTheme.darkSurface,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    issue['title'] ?? 'Untitled Issue',
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.warningColor),
                  ),
                  child: Text(
                    'PENDING VERIFICATION',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Issue Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Issue Details',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    issue['description'] ?? 'No description',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.whiteColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildDetailChip(
                        _getCategoryIcon(issue['category']),
                        issue['category'] ?? 'Other',
                        _getCategoryColor(issue['category']),
                      ),
                      const SizedBox(width: 8),
                      _buildDetailChip(
                        _getPriorityIcon(issue['priority']),
                        (issue['priority'] ?? 'medium').toUpperCase(),
                        _getPriorityColor(issue['priority']),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Worker Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned Worker',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          (worker?['full_name'] ?? 'W').substring(0, 1).toUpperCase(),
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
                              worker?['full_name'] ?? 'Unknown Worker',
                              style: AppTheme.titleMedium.copyWith(
                                color: AppTheme.whiteColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${worker?['department'] ?? 'No Department'} • ${worker?['email'] ?? 'No Email'}',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.greyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Images (if any)
            if (issue['image_urls'] != null && (issue['image_urls'] as List).isNotEmpty) ...[
              Text(
                'Worker Uploaded Images',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (issue['image_urls'] as List).length,
                  itemBuilder: (context, index) {
                    final imageUrl = (issue['image_urls'] as List)[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
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
              const SizedBox(height: 16),
            ],

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(issue['id']),
                    icon: Icon(Icons.close, size: 16),
                    label: Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: BorderSide(color: AppTheme.errorColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApproveDialog(issue['id']),
                    icon: Icon(Icons.check, size: 16),
                    label: Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
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

  void _showApproveDialog(String issueId) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Approve Worker Update',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to approve this worker update?',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Admin Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              _verifyWorkerUpdate(issueId, 'completed', notesController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
            child: Text('Approve', style: TextStyle(color: AppTheme.whiteColor)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String issueId) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Reject Worker Update',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to reject this worker update?',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Reason for Rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              _verifyWorkerUpdate(issueId, 'pending', notesController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: Text('Reject', style: TextStyle(color: AppTheme.whiteColor)),
          ),
        ],
      ),
    );
  }
}
