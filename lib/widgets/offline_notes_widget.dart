// lib/widgets/offline_notes_widget.dart
import 'package:flutter/material.dart';
import '../services/offline_notes_service.dart';
import '../theme/app_theme.dart';

class OfflineNotesWidget extends StatefulWidget {
  final String taskId;
  final bool isCompact;
  final VoidCallback? onNotesChanged;

  const OfflineNotesWidget({
    Key? key,
    required this.taskId,
    this.isCompact = false,
    this.onNotesChanged,
  }) : super(key: key);

  @override
  State<OfflineNotesWidget> createState() => _OfflineNotesWidgetState();
}

class _OfflineNotesWidgetState extends State<OfflineNotesWidget> {
  final OfflineNotesService _notesService = OfflineNotesService();
  final TextEditingController _noteController = TextEditingController();
  List<OfflineNote> _notes = [];
  bool _isLoading = false;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    await _notesService.initialize();
    await _loadNotes();
    _checkOnlineStatus();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    
    try {
      final notes = _notesService.getNotesForTask(widget.taskId);
      setState(() {
        _notes = notes;
      });
    } catch (e) {
      print('Error loading notes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkOnlineStatus() async {
    final isOnline = await _notesService.isOnline;
    setState(() {
      _isOnline = isOnline;
    });
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;

    try {
      await _notesService.addNote(widget.taskId, _noteController.text.trim());
      _noteController.clear();
      await _loadNotes();
      widget.onNotesChanged?.call();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isOnline ? 'Note added successfully!' : 'Note saved offline'),
          backgroundColor: _isOnline ? AppTheme.successColor : AppTheme.warningColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add note: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _updateNote(String noteId, String newContent) async {
    try {
      await _notesService.updateNote(noteId, newContent);
      await _loadNotes();
      widget.onNotesChanged?.call();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isOnline ? 'Note updated successfully!' : 'Note updated offline'),
          backgroundColor: _isOnline ? AppTheme.successColor : AppTheme.warningColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update note: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await _notesService.deleteNote(noteId);
      await _loadNotes();
      widget.onNotesChanged?.call();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note deleted successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete note: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _syncNotes() async {
    try {
      await _notesService.syncAllNotes();
      await _loadNotes();
      await _checkOnlineStatus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notes synced successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sync notes: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactView();
    }
    
    return _buildFullView();
  }

  Widget _buildCompactView() {
    return Card(
      color: AppTheme.darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note_alt,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notes (${_notes.length})',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.whiteColor,
                  ),
                ),
                const Spacer(),
                if (!_isOnline)
                  Icon(
                    Icons.cloud_off,
                    color: AppTheme.warningColor,
                    size: 16,
                  ),
              ],
            ),
            if (_notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _notes.last.content,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.greyColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullView() {
    return Card(
      color: AppTheme.darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.note_alt,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Task Notes',
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.whiteColor,
                  ),
                ),
                const Spacer(),
                if (!_isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.warningColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off,
                          color: AppTheme.warningColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Offline',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.warningColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _syncNotes,
                  icon: Icon(
                    Icons.sync,
                    color: AppTheme.primaryColor,
                  ),
                  tooltip: 'Sync Notes',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Add Note Section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Add a note...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addNote,
                  icon: Icon(Icons.add, size: 16),
                  label: Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Notes List
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            else if (_notes.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.note_add,
                      size: 48,
                      color: AppTheme.greyColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No notes yet',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.greyColor,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  return _buildNoteItem(note);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem(OfflineNote note) {
    return Card(
      color: AppTheme.darkCard,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.content,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.whiteColor,
                    ),
                  ),
                ),
                if (!note.isSynced)
                  Icon(
                    Icons.cloud_upload,
                    color: AppTheme.warningColor,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _formatDateTime(note.updatedAt),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.greyColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showEditNoteDialog(note),
                  icon: Icon(
                    Icons.edit,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                  tooltip: 'Edit Note',
                ),
                IconButton(
                  onPressed: () => _showDeleteNoteDialog(note),
                  icon: Icon(
                    Icons.delete,
                    color: AppTheme.errorColor,
                    size: 16,
                  ),
                  tooltip: 'Delete Note',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNoteDialog(OfflineNote note) {
    final controller = TextEditingController(text: note.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Edit Note',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter note content...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.greyColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateNote(note.id, controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(
              'Update',
              style: TextStyle(color: AppTheme.whiteColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteNoteDialog(OfflineNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Delete Note',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
        ),
        content: Text(
          'Are you sure you want to delete this note?',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.greyColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteNote(note.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: Text(
              'Delete',
              style: TextStyle(color: AppTheme.whiteColor),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
