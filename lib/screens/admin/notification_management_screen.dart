// lib/screens/admin/notification_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider_complete.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_notification_service.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({Key? key}) : super(key: key);

  @override
  State<NotificationManagementScreen> createState() => _NotificationManagementScreenState();
}

class _NotificationManagementScreenState extends State<NotificationManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AdminNotificationService _notificationService = AdminNotificationService();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _selectedRole = 'user';
  String _selectedUser = '';
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _notifications = [];
  Map<String, int> _stats = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _loadUsers();
      await _loadNotifications();
      await _loadStats();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, email, role')
          .order('full_name');
      
      setState(() {
        _users = (response as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await Supabase.instance.client
          .from('notifications')
          .select('*')
          .order('created_at', ascending: false)
          .limit(100);
      
      setState(() {
        _notifications = (response as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _notificationService.getNotificationStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Notification Management',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.greyColor,
          tabs: const [
            Tab(text: 'Send'),
            Tab(text: 'History'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendTab(),
          _buildHistoryTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildSendTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Broadcast to all users
          Card(
            color: AppTheme.darkSurface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Broadcast to All Users',
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: AppTheme.whiteColor),
                    decoration: InputDecoration(
                      labelText: 'Notification Title',
                      labelStyle: TextStyle(color: AppTheme.greyColor),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    style: TextStyle(color: AppTheme.whiteColor),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      labelStyle: TextStyle(color: AppTheme.greyColor),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendBroadcast,
                      icon: Icon(Icons.broadcast_on_home),
                      label: Text('Send to All Users'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.whiteColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Send to specific role
          Card(
            color: AppTheme.darkSurface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send to Role',
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Select Role',
                      border: OutlineInputBorder(),
                    ),
                    items: ['user', 'worker', 'admin', 'developer'].map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendToRole,
                      icon: Icon(Icons.group),
                      label: Text('Send to ${_selectedRole.toUpperCase()}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: AppTheme.whiteColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Send to specific user
          Card(
            color: AppTheme.darkSurface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send to Specific User',
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedUser.isEmpty ? null : _selectedUser,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Select User',
                      border: OutlineInputBorder(),
                    ),
                    items: _users.map<DropdownMenuItem<String>>((user) {
                      return DropdownMenuItem<String>(
                        value: user['id'],
                        child: Text('${user['full_name']} (${user['email']})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUser = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _selectedUser.isNotEmpty ? _sendToUser : null,
                      icon: Icon(Icons.person),
                      label: Text('Send to User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: AppTheme.whiteColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return Card(
          color: AppTheme.darkSurface,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: notification['is_broadcast'] == true 
                  ? AppTheme.primaryColor 
                  : AppTheme.secondaryColor,
              child: Icon(
                notification['is_broadcast'] == true 
                    ? Icons.broadcast_on_home 
                    : Icons.person,
                color: AppTheme.whiteColor,
              ),
            ),
            title: Text(
              notification['title'] ?? 'No Title',
              style: TextStyle(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['message'] ?? 'No Message',
                  style: TextStyle(color: AppTheme.greyColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Type: ${notification['type'] ?? 'Unknown'}',
                  style: TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Sent: ${_formatDate(notification['created_at'])}',
                  style: TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: notification['is_read'] == true
                ? Icon(Icons.check_circle, color: AppTheme.successColor)
                : Icon(Icons.radio_button_unchecked, color: AppTheme.greyColor),
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: AppTheme.darkSurface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Notification Statistics',
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Total', _stats['total'] ?? 0, AppTheme.primaryColor),
                      _buildStatCard('Unread', _stats['unread'] ?? 0, AppTheme.accentColor),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Broadcasts', _stats['broadcasts'] ?? 0, AppTheme.secondaryColor),
                      _buildStatCard('Direct', _stats['direct'] ?? 0, AppTheme.successColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.greyColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Future<void> _sendBroadcast() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
    final success = await _notificationService.sendNotificationToAllUsers(
      title: _titleController.text,
      message: _messageController.text,
      adminId: authProvider.currentUser?.id,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification sent successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      _titleController.clear();
      _messageController.clear();
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send notification'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _sendToRole() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
    final success = await _notificationService.sendNotificationToRole(
      role: _selectedRole,
      title: _titleController.text,
      message: _messageController.text,
      adminId: authProvider.currentUser?.id,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification sent to ${_selectedRole} role!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send notification'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _sendToUser() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
    final success = await _notificationService.sendNotificationToUser(
      userId: _selectedUser,
      title: _titleController.text,
      message: _messageController.text,
      adminId: authProvider.currentUser?.id,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification sent to user!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send notification'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }
}
