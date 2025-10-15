// lib/screens/citizen/reports_screen_fixed.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/issues_provider.dart';
import '../../providers/auth_provider_complete.dart';
import '../../providers/navigation_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/salaar_loading_widget.dart';
import 'report_detail_screen.dart';

class ReportsScreenFixed extends StatefulWidget {
  const ReportsScreenFixed({super.key});

  @override
  State<ReportsScreenFixed> createState() => _ReportsScreenFixedState();
}

class _ReportsScreenFixedState extends State<ReportsScreenFixed> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  String _selectedSort = 'newest';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    await issuesProvider.forceRefreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final issuesProvider = Provider.of<IssuesProvider>(context);
    final authProvider = Provider.of<AuthProviderComplete>(context);

    if (issuesProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: SalaarLoadingWidget(message: 'Loading your reports...'),
      );
    }

    final filteredIssues = _filterAndSortIssues(issuesProvider.issues);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'My Reports',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
              await issuesProvider.forceRefreshAll();
            },
            icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
          ),
          IconButton(
            onPressed: () {
              Provider.of<NavigationProvider>(context, listen: false).setCurrentIndex(2);
            },
            icon: Icon(Icons.add, color: AppTheme.primaryColor),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  style: TextStyle(color: AppTheme.whiteColor),
                  decoration: InputDecoration(
                    hintText: 'Search reports...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
                    filled: true,
                    fillColor: AppTheme.darkSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Filter and Sort Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: InputDecoration(
                          labelText: 'Filter',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: AppTheme.darkSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        dropdownColor: AppTheme.darkSurface,
                        style: TextStyle(color: AppTheme.whiteColor),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('All Reports')),
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                          DropdownMenuItem(value: 'completed', child: Text('Completed')),
                          DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSort,
                        decoration: InputDecoration(
                          labelText: 'Sort',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: AppTheme.darkSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        dropdownColor: AppTheme.darkSurface,
                        style: TextStyle(color: AppTheme.whiteColor),
                        items: [
                          DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                          DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
                          DropdownMenuItem(value: 'status', child: Text('By Status')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSort = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Reports List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
                await issuesProvider.forceRefreshAll();
              },
              color: AppTheme.primaryColor,
              child: filteredIssues.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredIssues.length,
                      itemBuilder: (context, index) {
                        final issue = filteredIssues[index];
                        return _buildReportCard(issue);
                      },
                    ),
            ),
          ),
          ],
        ),
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
            color: AppTheme.greyColor,
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'No Reports Found',
            style: AppTheme.headlineMedium.copyWith(
              color: AppTheme.whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by reporting your first issue',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.greyColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Provider.of<NavigationProvider>(context, listen: false).setCurrentIndex(2);
            },
            icon: Icon(Icons.add, color: AppTheme.whiteColor),
            label: Text(
              'Report Issue',
              style: TextStyle(color: AppTheme.whiteColor),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(issue) {
    return Card(
      color: AppTheme.darkSurface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailScreen(issue: issue),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkSurface,
                AppTheme.darkSurface.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with category and priority
                Row(
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(issue.issueType).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getCategoryColor(issue.issueType).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(issue.issueType),
                            color: _getCategoryColor(issue.issueType),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            issue.issueType.toUpperCase(),
                            style: AppTheme.bodySmall.copyWith(
                              color: _getCategoryColor(issue.issueType),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Priority Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(issue.priority ?? 'medium').withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getPriorityColor(issue.priority ?? 'medium').withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getPriorityText(issue.priority ?? 'medium'),
                        style: AppTheme.bodySmall.copyWith(
                          color: _getPriorityColor(issue.priority ?? 'medium'),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Title/Description
                Text(
                  issue.title ?? issue.description,
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                if (issue.title != null && issue.description != issue.title) ...[
                  const SizedBox(height: 8),
                  Text(
                    issue.description,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.greyColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Images Section
                if (issue.imageUrls.isNotEmpty) ...[
                  SizedBox(
                    height: 80,
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
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
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
                
                // Status and ID Row
                Row(
                  children: [
                    // Status Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(issue.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(issue.status).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(issue.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusText(issue.status),
                            style: AppTheme.bodySmall.copyWith(
                              color: _getStatusColor(issue.status),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Report ID
                    if (issue.reportId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBackground.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ID: ${issue.reportId}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.greyColor,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Footer with date and location
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: AppTheme.greyColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(issue.createdAt),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.greyColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Icon(
                      Icons.location_on,
                      color: AppTheme.greyColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        issue.address ?? 'Location not available',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.greyColor,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<dynamic> _filterAndSortIssues(List<dynamic> issues) {
    final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    
    var filtered = issues.where((issue) {
      // CRITICAL: Only show reports created by the current user
      if (currentUserId != null && issue.userId != currentUserId) {
        return false;
      }
      
      // Filter by status
      if (_selectedFilter != 'all' && issue.status != _selectedFilter) {
        return false;
      }
      
      // Filter by search
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        return issue.issueType.toLowerCase().contains(searchTerm) ||
               issue.description.toLowerCase().contains(searchTerm);
      }
      
      return true;
    }).toList();

    // Sort issues
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'newest':
          return b.createdAt.compareTo(a.createdAt);
        case 'oldest':
          return a.createdAt.compareTo(b.createdAt);
        case 'status':
          return a.status.compareTo(b.status);
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return filtered;
  }

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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
        return AppTheme.primaryColor;
      case 'sanitation':
        return Colors.orange;
      case 'traffic':
        return Colors.red;
      case 'safety':
        return Colors.purple;
      case 'environment':
        return Colors.green;
      case 'utilities':
        return Colors.blue;
      case 'other':
        return AppTheme.greyColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
        return Icons.construction;
      case 'sanitation':
        return Icons.cleaning_services;
      case 'traffic':
        return Icons.traffic;
      case 'safety':
        return Icons.security;
      case 'environment':
        return Icons.eco;
      case 'utilities':
        return Icons.electrical_services;
      case 'other':
        return Icons.help_outline;
      default:
        return Icons.assignment;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return 'LOW';
      case 'medium':
        return 'MED';
      case 'high':
        return 'HIGH';
      case 'urgent':
        return 'URGENT';
      default:
        return 'MED';
    }
  }
}
