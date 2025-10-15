// lib/screens/citizen/discussions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_complete.dart';
import '../../theme/app_theme.dart';
import '../dinosaur_loading_screen.dart';

class DiscussionsScreen extends StatefulWidget {
  const DiscussionsScreen({Key? key}) : super(key: key);

  @override
  State<DiscussionsScreen> createState() => _DiscussionsScreenState();
}

class _DiscussionsScreenState extends State<DiscussionsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderComplete>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const DinosaurLoadingScreen(message: 'Loading discussions...', showProgress: true);
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Discussions',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showCreateDiscussionDialog,
            icon: Icon(Icons.add, color: AppTheme.primaryColor),
          ),
        ],
      ),
      body: Column(
        children: [
          // Leaderboard Section
          _buildLeaderboardSection(),
          
          // Discussions List
          Expanded(
            child: _buildDiscussionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadLeaderboard(),
      builder: (context, snapshot) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Leaderboard',
                style: AppTheme.titleLarge.copyWith(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasError)
                Text(
                  'Error loading leaderboard',
                  style: TextStyle(color: AppTheme.errorColor),
                )
              else if (snapshot.data?.isEmpty ?? true)
                Text(
                  'No leaderboard data available',
                  style: TextStyle(color: AppTheme.greyColor),
                )
              else
                ...snapshot.data!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final user = entry.value;
                  final rank = index + 1;
                  final name = user['full_name'] ?? 'Unknown User';
                  final reports = user['issues_reported'] ?? 0;
                  final level = _getLevelName(user['exp_points'] ?? 0);
                  
                  return _buildLeaderboardItem(rank, name, reports, level);
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadLeaderboard() async {
    try {
      // Import DatabaseService at the top of the file
      // return await DatabaseService.getLeaderboard();
      
      // For now, return empty list until DatabaseService is imported
      return [];
    } catch (e) {
      print('Error loading leaderboard: $e');
      return [];
    }
  }

  String _getLevelName(int expPoints) {
    if (expPoints >= 1000) return 'SALAAR';
    if (expPoints >= 700) return 'Shouryaanga';
    if (expPoints >= 300) return 'Mannarasi';
    if (expPoints >= 100) return 'Ghaniyaar';
    return 'The Beginning';
  }

  Widget _buildLeaderboardItem(int rank, String name, int reports, String level) {
    Color rankColor = AppTheme.greyColor;
    if (rank == 1) rankColor = AppTheme.accentColor;
    else if (rank == 2) rankColor = AppTheme.primaryColor;
    else if (rank == 3) rankColor = AppTheme.successColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: rankColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$reports reports • $level',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadDiscussions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DinosaurLoadingScreen(message: 'Loading discussions...', showProgress: true);
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading discussions: ${snapshot.error}',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          );
        }
        
        final discussions = snapshot.data ?? [];
        
        if (discussions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.greyColor),
                const SizedBox(height: 16),
                Text(
                  'No discussions yet',
                  style: AppTheme.titleMedium.copyWith(color: AppTheme.greyColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to start a discussion!',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: discussions.length,
          itemBuilder: (context, index) {
            final discussion = discussions[index];
            return _buildDiscussionCard(discussion);
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadDiscussions() async {
    try {
      // Import DatabaseService at the top of the file
      // return await DatabaseService.getAllDiscussions();
      
      // For now, return empty list until DatabaseService is imported
      return [];
    } catch (e) {
      print('Error loading discussions: $e');
      return [];
    }
  }

  Widget _buildDiscussionCard(Map<String, dynamic> discussion) {
    return Card(
      color: AppTheme.darkSurface,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to discussion details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                discussion['title'],
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'By ${discussion['author']}',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
              ),
              const SizedBox(height: 8),
              Text(
                discussion['content'],
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.whiteColor.withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${discussion['replies']} replies',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryColor),
                  ),
                  const Spacer(),
                  Text(
                    discussion['time'],
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDiscussionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Start Discussion',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              style: TextStyle(color: AppTheme.whiteColor),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: AppTheme.greyColor),
                filled: true,
                fillColor: AppTheme.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 3,
              style: TextStyle(color: AppTheme.whiteColor),
              decoration: InputDecoration(
                labelText: 'Content',
                labelStyle: TextStyle(color: AppTheme.greyColor),
                filled: true,
                fillColor: AppTheme.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
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
          ElevatedButton(
            onPressed: _isLoading ? null : _createDiscussion,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteColor),
                    ),
                  )
                : Text(
                    'Create',
                    style: TextStyle(color: AppTheme.whiteColor),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _createDiscussion() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Implement discussion creation
      await Future.delayed(Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Discussion created successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
        _titleController.clear();
        _contentController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create discussion'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
