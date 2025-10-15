// lib/screens/worker/worker_tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/issues_provider.dart';
import '../../services/image_upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../widgets/seed_loading_widget.dart';

class WorkerTasksScreen extends StatefulWidget {
  const WorkerTasksScreen({super.key});

  @override
  State<WorkerTasksScreen> createState() => _WorkerTasksScreenState();
}

class _WorkerTasksScreenState extends State<WorkerTasksScreen> {
  String _selectedFilter = 'assigned';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<IssuesProvider>(context, listen: false);
      provider.fetchAssignedIssuesForWorker();
    });
  }

  @override
  Widget build(BuildContext context) {
    final issuesProvider = Provider.of<IssuesProvider>(context);

    if (issuesProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: SeedLoadingWidget(message: 'Loading your tasks...'),
      );
    }

    // Filter issues for worker (assigned to them or available for assignment)
    final source = issuesProvider.assignedIssues.isNotEmpty
        ? issuesProvider.assignedIssues
        : issuesProvider.issues;
    final workerIssues = source.where((issue) {
      if (_selectedFilter == 'assigned') {
        return issue.status == 'assigned' || issue.status == 'working';
      } else if (_selectedFilter == 'available') {
        return issue.status == 'pending';
      } else if (_selectedFilter == 'completed') {
        return issue.status == 'resolved' || issue.status == 'done';
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Tasks',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: () => issuesProvider.fetchAllIssues(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterButton('Assigned', 'assigned'),
                ),
                Expanded(
                  child: _buildFilterButton('Available', 'available'),
                ),
                Expanded(
                  child: _buildFilterButton('Completed', 'completed'),
                ),
              ],
            ),
          ),

          // Stats
          _buildTaskStats(workerIssues),

          // Tasks List
          Expanded(
            child: workerIssues.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: workerIssues.length,
                    itemBuilder: (context, index) {
                      return _buildTaskItem(workerIssues[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTheme.bodyMedium.copyWith(
            color: isSelected ? Colors.black : AppTheme.greyColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskStats(List<Issue> tasks) {
    final assigned = tasks.where((t) => t.status == 'assigned').length;
    final inProgress = tasks.where((t) => t.status == 'working').length;
    final completed = tasks.where((t) => t.status == 'resolved').length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Assigned', assigned.toString(), AppTheme.warningColor),
          _buildStatItem('In Progress', inProgress.toString(), AppTheme.accentColor),
          _buildStatItem('Completed', completed.toString(), AppTheme.successColor),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
        ),
      ],
    );
  }

  Widget _buildTaskItem(Issue issue) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    List<Widget> actions = [];

    switch (issue.status) {
      case 'assigned':
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.assignment_turned_in;
        statusText = 'Assigned';
        actions.add(_buildActionButton('Start Work', Icons.play_arrow, () {
          _startWorking(issue);
        }));
        break;
      case 'working':
        statusColor = AppTheme.accentColor;
        statusIcon = Icons.build;
        statusText = 'In Progress';
        actions.add(_buildActionButton('Upload Photo', Icons.photo_camera, () {
          _requireCompletionPhoto(issue);
        }));
        break;
      case 'done':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        actions.add(_buildActionButton('View Details', Icons.visibility, () {
          _viewIssueDetails(issue);
        }));
        break;
      default:
        statusColor = AppTheme.greyColor;
        statusIcon = Icons.pending;
        statusText = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: AppTheme.bodySmall.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
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
          Text(
            issue.issueType,
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.whiteColor,
              fontWeight: FontWeight.bold,
            ),
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
              Icon(Icons.location_on, size: 14, color: AppTheme.greyColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  issue.address ?? 'Location not specified',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (actions.isNotEmpty)
            Row(
              children: actions,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: BorderSide(color: AppTheme.primaryColor),
        ),
        icon: Icon(icon, size: 16),
        label: Text(text),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 64, color: AppTheme.greyColor),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'assigned' 
                ? 'No tasks assigned'
                : _selectedFilter == 'available'
                    ? 'No available tasks'
                    : 'No completed tasks',
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.greyColor),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'available'
                ? 'Check back later for new tasks'
                : 'Your tasks will appear here',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
          ),
        ],
      ),
    );
  }

  void _updateIssueStatus(Issue issue, String newStatus) {
    // TODO: Implement status update in IssuesProvider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status updated to $newStatus'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  Future<void> _requireCompletionPhoto(Issue issue) async {
    final picker = ImagePicker();
    final XFile? shot = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    if (shot == null) return;
    final url = await ImageUploadService.uploadSingle(File(shot.path));
    if (url == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }
    final provider = Provider.of<IssuesProvider>(context, listen: false);
    await provider.updateIssueStatus(issueId: issue.id, newStatus: 'done', completionPhotoUrl: url);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task marked done'), backgroundColor: AppTheme.successColor),
    );
  }

  void _startWorking(Issue issue) {
    // Start background tracking and set working status
    _updateIssueStatus(issue, 'working');
    // Optionally, navigate to map with route
    // Navigator.push(context, MaterialPageRoute(builder: (_) => MapScreen(routeEnd: LatLng(issue.latitude, issue.longitude))));
  }

  void _viewIssueDetails(Issue issue) {
    // TODO: Navigate to issue details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for ${issue.issueType}'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}