// lib/screens/admin/announcements_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/announcements_provider.dart';
import '../../theme/app_colors.dart';

class AnnouncementsManagementScreen extends StatefulWidget {
  const AnnouncementsManagementScreen({super.key});

  @override
  State<AnnouncementsManagementScreen> createState() => _AnnouncementsManagementScreenState();
}

class _AnnouncementsManagementScreenState extends State<AnnouncementsManagementScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedType = 'info';

  @override
  Widget build(BuildContext context) {
    final announcementsProvider = Provider.of<AnnouncementsProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.deepDarkBackground,
      appBar: AppBar(
        title: const Text('Manage Announcements'),
        backgroundColor: AppColors.darkSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Create Announcement Form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Create New Announcement',
                    style: TextStyle(
                      color: AppColors.softWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: TextStyle(color: AppColors.softWhite.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(color: AppColors.softWhite),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      labelStyle: TextStyle(color: AppColors.softWhite.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(color: AppColors.softWhite),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    items: const [
                      DropdownMenuItem(value: 'info', child: Text('Info')),
                      DropdownMenuItem(value: 'warning', child: Text('Warning')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                      DropdownMenuItem(value: 'success', child: Text('Success')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Type',
                      labelStyle: TextStyle(color: AppColors.softWhite.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final success = await announcementsProvider.createAnnouncement(
                        title: _titleController.text,
                        content: _contentController.text,
                        type: _selectedType,
                      );

                      if (success) {
                        _titleController.clear();
                        _contentController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Announcement created successfully'),
                            backgroundColor: AppColors.vividGreen,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to create announcement'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vividGreen,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Create Announcement'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
