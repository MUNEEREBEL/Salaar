// lib/screens/worker/worker_issue_management_modern.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider_complete.dart';
import '../../providers/issues_provider.dart';
import '../../theme/app_theme.dart';
import '../dinosaur_loading_screen.dart';
import 'dart:io';

class WorkerIssueManagementModern extends StatefulWidget {
  const WorkerIssueManagementModern({Key? key}) : super(key: key);

  @override
  State<WorkerIssueManagementModern> createState() => _WorkerIssueManagementModernState();
}

class _WorkerIssueManagementModernState extends State<WorkerIssueManagementModern> {
  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  bool _isLoading = false;

  final List<String> _statusOptions = ['all', 'pending', 'in_progress', 'completed'];
  final List<String> _priorityOptions = ['all', 'high', 'medium', 'low'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _initializeRealtimeUpdates();
    });
  }

  void _initializeRealtimeUpdates() {
    // Initialize real-time updates like admin screen
    Provider.of<IssuesProvider>(context, listen: false).initializeRealtimeUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Column(
        children: [
          // Modern Filter Section
          _buildFilterSection(),
          
          // Issues List
          Expanded(
            child: Consumer<IssuesProvider>(
              builder: (context, issuesProvider, child) {
                if (issuesProvider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  );
                }

                final assignedIssues = _getAssignedIssues(issuesProvider.issues);
                final filteredIssues = _getFilteredIssues(assignedIssues);

                if (filteredIssues.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredIssues.length,
                  itemBuilder: (context, index) {
                    final issue = filteredIssues[index];
                    return _buildModernIssueCard(issue);
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
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
          Icon(Icons.filter_list, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Filter:',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.whiteColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCompactFilterDropdown(
              _selectedStatus,
              _statusOptions,
              (value) => setState(() => _selectedStatus = value!),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCompactFilterDropdown(
              _selectedPriority,
              _priorityOptions,
              (value) => setState(() => _selectedPriority = value!),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              Provider.of<IssuesProvider>(context, listen: false).fetchAllIssues(forceRefresh: true);
            },
            icon: Icon(Icons.refresh, color: AppTheme.primaryColor, size: 20),
            tooltip: 'Refresh',
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFilterDropdown(
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.greyColor.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppTheme.darkCard,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.whiteColor),
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option.toUpperCase(),
                style: AppTheme.bodySmall.copyWith(fontSize: 11),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.greyColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.darkBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.greyColor.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppTheme.darkCard,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option.toUpperCase()),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernIssueCard(dynamic issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            color: _getStatusColor(issue.status).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: _getStatusColor(issue.status).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(issue.status).withOpacity(0.1),
                  _getStatusColor(issue.status).withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    issue.title,
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusChip(issue.status),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
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
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),

                // Details
                _buildDetailsRow(issue),
                const SizedBox(height: 20),

                // Action Buttons
                _buildActionButtons(issue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
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
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildDetailsRow(Issue issue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.greyColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildDetailItem(
                Icons.category,
                'Category',
                issue.category,
                AppTheme.primaryColor,
              ),
              const SizedBox(width: 16),
              _buildDetailItem(
                Icons.priority_high,
                'Priority',
                (issue.priority ?? 'medium').toUpperCase(),
                _getPriorityColor(issue.priority ?? 'medium'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDetailItem(
                Icons.access_time,
                'Created',
                _formatDate(issue.createdAt.toString()),
                AppTheme.infoColor,
              ),
              const SizedBox(width: 16),
              _buildDetailItem(
                Icons.location_on,
                'Location',
                issue.address ?? 'No address',
                AppTheme.successColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.greyColor,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: AppTheme.bodySmall.copyWith(
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
    );
  }

  Widget _buildActionButtons(dynamic issue) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.visibility,
            label: 'View Details',
            color: AppTheme.primaryColor,
            onPressed: () => _showIssueDetails(issue),
            isOutlined: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.check_circle,
            label: 'Mark Completed',
            color: issue.status == 'completed' ? AppTheme.greyColor : AppTheme.successColor,
            onPressed: issue.status != 'completed' ? () => _showCompletionDialog(issue) : () {},
            isOutlined: false,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required bool isOutlined,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppTheme.whiteColor,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.greyColor.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              color: AppTheme.greyColor,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              'No Tasks Found',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any tasks matching the current filters.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedStatus = 'all';
                  _selectedPriority = 'all';
                });
              },
              icon: Icon(Icons.refresh),
              label: Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.whiteColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _getAssignedIssues(List<dynamic> issues) {
    final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) return [];
    
    return issues.where((issue) => issue.assigneeId == currentUser.id).toList();
  }

  List<dynamic> _getFilteredIssues(List<dynamic> issues) {
    return issues.where((issue) {
      final statusMatch = _selectedStatus == 'all' || issue.status == _selectedStatus;
      final priorityMatch = _selectedPriority == 'all' || (issue.priority ?? 'medium') == _selectedPriority;
      return statusMatch && priorityMatch;
    }).toList();
  }

  void _showIssueDetails(dynamic issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Task Details',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Title', issue.title),
              _buildDetailRow('Description', issue.description),
              _buildDetailRow('Status', issue.status.toUpperCase()),
              _buildDetailRow('Priority', (issue.priority ?? 'medium').toUpperCase()),
              _buildDetailRow('Category', issue.category),
              _buildDetailRow('Address', issue.address ?? 'No address'),
              _buildDetailRow('Created', _formatDate(issue.createdAt.toString())),
              
              // Google Maps Navigation
              if (issue.latitude != null && issue.longitude != null) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _openInGoogleMaps(issue.latitude, issue.longitude),
                  icon: Icon(Icons.map, size: 16),
                  label: Text('Open in Google Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.infoColor,
                    foregroundColor: AppTheme.whiteColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                ),
              ],

              // Issue Images
              if (issue.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Issue Images:',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: issue.imageUrls.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showImageDialog(issue.imageUrls[index]),
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.greyColor.withOpacity(0.3)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              issue.imageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppTheme.darkCard,
                                  child: Icon(Icons.image, color: AppTheme.greyColor),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Completion Image
              if (issue.completionImageUrl != null && issue.completionImageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Completion Image:',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showImageDialog(issue.completionImageUrl!),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        issue.completionImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppTheme.darkCard,
                            child: Icon(Icons.image, color: AppTheme.greyColor),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  void _showCompletionDialog(dynamic issue) {
    File? completionImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.darkSurface,
            title: Text(
              'Mark Task as Completed',
              style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
            ),
            content: Container(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                          'Task: ${issue.title}',
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

                  // Photo requirement for completion
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.warningColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt, color: AppTheme.warningColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Photo required for completion',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.warningColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Image picker
                  GestureDetector(
                    onTap: () => _pickCompletionImage((image) {
                      setState(() {
                        completionImage = image;
                      });
                    }),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: completionImage != null 
                              ? AppTheme.successColor 
                              : AppTheme.greyColor.withOpacity(0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: completionImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                completionImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  color: AppTheme.greyColor,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to add completion photo',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.greyColor,
                                  ),
                                ),
                              ],
                            ),
                    ),
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
                onPressed: completionImage != null ? () async {
                  try {
                    // Upload completion image
                    String imageUrl = await _uploadCompletionImage(completionImage!, issue.id);

                    await Provider.of<IssuesProvider>(context, listen: false)
                        .updateIssueStatusForWorker(issue.id, 'completed', 'medium', imageUrl);

                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Task marked as completed! User will receive +20 XP'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                    
                    _loadData();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error completing task: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  }
                } : null,
                child: Text('Mark as Completed'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickCompletionImage(Function(File) onImagePicked) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        onImagePicked(File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<String> _uploadCompletionImage(File imageFile, String issueId) async {
    try {
      final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final fileName = 'completion_${issueId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${currentUser.id}/$fileName';

      // Upload to Supabase Storage
      await Supabase.instance.client.storage
          .from('issue-images')
          .upload(filePath, imageFile);

      // Get public URL
      final imageUrl = Supabase.instance.client.storage
          .from('issue-images')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload completion image: $e');
    }
  }

  Future<void> _openInGoogleMaps(double? latitude, double? longitude) async {
    if (latitude == null || longitude == null) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DinosaurLoadingScreen(
        message: 'Opening Maps...',
        showProgress: false,
      ),
    );
    
    // Try multiple map apps with better URL schemes
    final urls = [
      // Native Google Maps app
      'comgooglemaps://?q=$latitude,$longitude&center=$latitude,$longitude&zoom=15',
      // Apple Maps (for iOS)
      'maps://?q=$latitude,$longitude',
      // Generic maps app
      'geo:$latitude,$longitude?q=$latitude,$longitude',
      // Google Maps web (fallback)
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      // Alternative Google Maps web
      'https://maps.google.com/maps?q=$latitude,$longitude&z=15',
    ];
    
    bool launched = false;
    String? lastError;
    
    for (String url in urls) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
          break;
        }
      } catch (e) {
        lastError = e.toString();
        print('Failed to launch $url: $e');
        continue;
      }
    }
    
    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);
    }
    
    if (!launched && mounted) {
      // Show better error message with options
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.darkCard,
          title: Text(
            'Maps App Not Found',
            style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No maps app is installed on your device. You can:',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.download, color: AppTheme.primaryColor),
                title: Text(
                  'Install Google Maps',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
                ),
                subtitle: Text(
                  'Get directions and navigation',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.google.android.apps.maps');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  } catch (e) {
                    print('Failed to open Play Store: $e');
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.copy, color: AppTheme.infoColor),
                title: Text(
                  'Copy Coordinates',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
                ),
                subtitle: Text(
                  '$latitude, $longitude',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await Clipboard.setData(ClipboardData(text: '$latitude, $longitude'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Coordinates copied to clipboard'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.greyColor),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMapAppOption(String name, String playStoreUrl) {
    return ListTile(
      leading: Icon(Icons.map, color: AppTheme.primaryColor),
      title: Text(
        name,
        style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
      ),
      onTap: () async {
        try {
          final uri = Uri.parse(playStoreUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          print('Failed to open Play Store: $e');
        }
      },
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.darkCard,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, color: AppTheme.greyColor, size: 64),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load image',
                                style: AppTheme.bodyLarge.copyWith(color: AppTheme.greyColor),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: AppTheme.whiteColor, size: 32),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  shape: CircleBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadData() {
    Provider.of<IssuesProvider>(context, listen: false).fetchAllIssues(forceRefresh: true);
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
}
