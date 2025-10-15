// lib/screens/report_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // Add this for Clipboard
import '../../providers/issues_provider.dart';
import '../../theme/app_theme.dart';
import '../dinosaur_loading_screen.dart';

class ReportDetailScreen extends StatelessWidget {
  final Issue issue;

  const ReportDetailScreen({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Report Details',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.chat, color: AppTheme.whiteColor),
            onPressed: () => _showChatDialog(context),
            tooltip: 'Chat about this report',
          ),
          IconButton(
            icon: Icon(Icons.download, color: AppTheme.whiteColor),
            onPressed: () => _downloadReport(context),
            tooltip: 'Download report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Header
            _buildReportHeader(),
            const SizedBox(height: 24),

            // Issue Details
            _buildIssueDetails(),
            const SizedBox(height: 24),

            // Location Information
            _buildLocationInfo(context),
            const SizedBox(height: 24),

            // Images Section
            if (issue.imageUrls.isNotEmpty) ...[
              _buildImagesSection(context),
              const SizedBox(height: 24),
            ],

            // Completion Image Section (from worker)
            if (issue.completionImageUrl != null && issue.completionImageUrl!.isNotEmpty) ...[
              _buildCompletionImageSection(context),
              const SizedBox(height: 24),
            ],

            // Status Timeline
            _buildStatusTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHeader() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (issue.status) {
      case 'resolved':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        statusText = 'Resolved';
        break;
      case 'in_progress':
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.build;
        statusText = 'In Progress';
        break;
      default:
        statusColor = AppTheme.greyColor;
        statusIcon = Icons.pending;
        statusText = 'Pending';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.2), statusColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.issueType,
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (issue.reportId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Report ID: ${issue.reportId}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.whiteColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Report #${issue.id.substring(0, 8).toUpperCase()}',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText.toUpperCase(),
                    style: AppTheme.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Issue Details',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Issue Type', issue.issueType),
          const SizedBox(height: 12),
          _buildDetailRow('Priority', issue.priority?.toUpperCase() ?? 'MEDIUM'),
          const SizedBox(height: 12),
          _buildDetailRow('Description', ''),
          const SizedBox(height: 8),
          Text(
            issue.description,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Reported On', _formatDate(issue.createdAt)),
          const SizedBox(height: 12),
          _buildDetailRow('Last Updated', _formatDate(issue.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location Information',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Address', issue.address ?? 'Not specified'),
          const SizedBox(height: 12),
          _buildDetailRow('Coordinates', '${issue.latitude.toStringAsFixed(6)}, ${issue.longitude.toStringAsFixed(6)}'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openInMaps(issue.latitude, issue.longitude, context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(Icons.map, size: 20),
                  label: Text('Open in Maps'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyCoordinates(issue.latitude, issue.longitude, context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(Icons.copy, size: 20, color: AppTheme.primaryColor),
                  label: Text(
                    'Copy Coordinates',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Evidence Photos',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.download, color: AppTheme.primaryColor),
                onPressed: () => _downloadAllImages(context),
                tooltip: 'Download All Images',
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: issue.imageUrls.length,
            itemBuilder: (context, index) {
              return _buildImageItem(issue.imageUrls[index], index, context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionImageSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.successColor.withOpacity(0.1), AppTheme.successColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Completion Photo',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.download, color: AppTheme.successColor),
                onPressed: () => _downloadSingleImage(issue.completionImageUrl!, context),
                tooltip: 'Download Completion Photo',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Worker has uploaded a completion photo showing the resolved issue.',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.greyColor,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _viewImageFullScreen(issue.completionImageUrl!, 0, context),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.successColor.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.successColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  issue.completionImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.darkCard,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, color: AppTheme.greyColor, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load completion image',
                            style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to retry',
                            style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.successColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This photo was uploaded by the assigned worker to confirm the issue has been resolved.',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(String imageUrl, int index, BuildContext context) {
    return GestureDetector(
      onTap: () => _viewImageFullScreen(imageUrl, index, context),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: GestureDetector(
                onTap: () => _downloadSingleImage(imageUrl, context),
                child: Icon(Icons.download, size: 12, color: AppTheme.whiteColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Status Timeline',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTimelineItem(
            'Report Submitted', 
            issue.createdAt, 
            Icons.report_problem, 
            AppTheme.primaryColor,
            'Issue reported and submitted for review'
          ),
          if (issue.status == 'in_progress' || issue.status == 'completed')
            _buildTimelineItem(
              'Work Started', 
              issue.updatedAt, 
              Icons.build, 
              AppTheme.warningColor,
              'Issue assigned to worker and work in progress'
            ),
          if (issue.status == 'completed')
            _buildTimelineItem(
              'Issue Resolved', 
              issue.updatedAt, 
              Icons.check_circle, 
              AppTheme.successColor,
              'Issue has been successfully resolved'
            ),
          if (issue.status == 'pending')
            _buildTimelineItem(
              'Under Review', 
              issue.updatedAt, 
              Icons.visibility, 
              AppTheme.infoColor,
              'Issue is being reviewed by admin'
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, DateTime date, IconData icon, Color color, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.greyColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    _formatDateTime(date),
                    style: AppTheme.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.whiteColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
          ),
        ),
      ],
    );
  }

  // Helper Methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    // Format: "2 hours ago (12:30 PM, Oct 12)"
    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      timeAgo = 'Just now';
    }
    
    // Format time and date
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${monthNames[date.month - 1]} ${date.day}';
    
    return '$timeAgo ($timeStr, $dateStr)';
  }

  // Action Methods
  void _viewImageFullScreen(String imageUrl, int index, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.close, color: AppTheme.whiteColor, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.download, color: AppTheme.whiteColor, size: 30),
                onPressed: () => _downloadSingleImage(imageUrl, context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadSingleImage(String imageUrl, BuildContext context) async {
    try {
      if (await canLaunchUrl(Uri.parse(imageUrl))) {
        await launchUrl(Uri.parse(imageUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image download started'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _downloadAllImages(BuildContext context) async {
    try {
      for (final imageUrl in issue.imageUrls) {
        if (await canLaunchUrl(Uri.parse(imageUrl))) {
          await launchUrl(Uri.parse(imageUrl));
          await Future.delayed(Duration(milliseconds: 500)); // Small delay between downloads
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All images download started'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _openInMaps(double lat, double lng, BuildContext context) async {
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
      'comgooglemaps://?q=$lat,$lng&center=$lat,$lng&zoom=15',
      // Apple Maps (for iOS)
      'maps://?q=$lat,$lng',
      // Generic maps app
      'geo:$lat,$lng?q=$lat,$lng',
      // Google Maps web (fallback)
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      // Alternative Google Maps web
      'https://maps.google.com/maps?q=$lat,$lng&z=15',
    ];
    
    bool launched = false;
    String? lastError;
    
    for (String url in urls) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
          print('✅ Successfully launched: $url');
          break;
        } else {
          print('❌ Cannot launch: $url');
        }
      } catch (e) {
        lastError = e.toString();
        print('❌ Failed to launch $url: $e');
        continue;
      }
    }
    
    // Close loading dialog
    Navigator.pop(context);
    
    if (!launched) {
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
                  '$lat, $lng',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await Clipboard.setData(ClipboardData(text: '$lat, $lng'));
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

  Future<void> _copyCoordinates(double lat, double lng, BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: '$lat, $lng'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coordinates copied to clipboard'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  Future<void> _downloadReport(BuildContext context) async {
    try {
      final reportText = '''
SALAAR REPORTER - ISSUE REPORT
==============================

Report ID: ${issue.id.substring(0, 8).toUpperCase()}
Issue Type: ${issue.issueType}
Status: ${issue.status.toUpperCase()}
Priority: ${issue.priority?.toUpperCase() ?? 'MEDIUM'}

DESCRIPTION:
${issue.description}

LOCATION:
${issue.address ?? 'Not specified'}
Coordinates: ${issue.latitude}, ${issue.longitude}

TIMELINE:
Reported: ${_formatDateTime(issue.createdAt)}
Last Updated: ${_formatDateTime(issue.updatedAt)}

IMAGES:
${issue.imageUrls.map((url) => '• $url').join('\n')}
      ''';

      // For web, show the text in a dialog that can be copied
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: Text(
            'Report Details',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.whiteColor),
          ),
          content: SingleChildScrollView(
            child: SelectableText(
              reportText,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: AppTheme.primaryColor)),
            ),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: reportText));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Report copied to clipboard'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
              ),
              child: Text('Copy to Clipboard'),
            ),
          ],
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Row(
          children: [
            Icon(Icons.chat, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Report Discussion',
              style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              // Chat messages area
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.greyColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      // Placeholder for chat messages
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: AppTheme.greyColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: AppTheme.bodyLarge.copyWith(
                                  color: AppTheme.greyColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start a discussion about this report',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.greyColor.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Message input
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.greyColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                style: TextStyle(color: AppTheme.whiteColor),
                                decoration: InputDecoration(
                                  hintText: 'Type your message...',
                                  hintStyle: TextStyle(color: AppTheme.greyColor),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // TODO: Implement send message functionality
                                _showChatDialog(context);
                              },
                              icon: Icon(
                                Icons.send,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
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
            child: Text(
              'Close',
              style: TextStyle(color: AppTheme.greyColor),
            ),
          ),
        ],
      ),
    );
  }
}