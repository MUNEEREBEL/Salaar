// lib/widgets/task_completion_checklist.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChecklistItem {
  final String id;
  final String title;
  final String? description;
  final bool isRequired;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completedBy;

  ChecklistItem({
    required this.id,
    required this.title,
    this.description,
    this.isRequired = false,
    this.isCompleted = false,
    this.completedAt,
    this.completedBy,
  });

  ChecklistItem copyWith({
    String? id,
    String? title,
    String? description,
    bool? isRequired,
    bool? isCompleted,
    DateTime? completedAt,
    String? completedBy,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_required': isRequired,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'completed_by': completedBy,
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isRequired: json['is_required'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      completedBy: json['completed_by'] as String?,
    );
  }
}

class TaskCompletionChecklist extends StatefulWidget {
  final String taskId;
  final List<ChecklistItem> initialItems;
  final ValueChanged<List<ChecklistItem>>? onChecklistChanged;
  final bool isReadOnly;
  final String? currentUserId;

  const TaskCompletionChecklist({
    Key? key,
    required this.taskId,
    this.initialItems = const [],
    this.onChecklistChanged,
    this.isReadOnly = false,
    this.currentUserId,
  }) : super(key: key);

  @override
  State<TaskCompletionChecklist> createState() => _TaskCompletionChecklistState();
}

class _TaskCompletionChecklistState extends State<TaskCompletionChecklist> {
  late List<ChecklistItem> _items;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  @override
  void didUpdateWidget(TaskCompletionChecklist oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialItems != oldWidget.initialItems) {
      _items = List.from(widget.initialItems);
    }
  }

  void _toggleItem(int index) {
    if (widget.isReadOnly) return;

    setState(() {
      _items[index] = _items[index].copyWith(
        isCompleted: !_items[index].isCompleted,
        completedAt: !_items[index].isCompleted ? DateTime.now() : null,
        completedBy: !_items[index].isCompleted ? widget.currentUserId : null,
      );
    });

    widget.onChecklistChanged?.call(_items);
  }

  void _addItem() {
    if (widget.isReadOnly) return;

    showDialog(
      context: context,
      builder: (context) => _AddChecklistItemDialog(
        onAdd: (title, description, isRequired) {
          final newItem = ChecklistItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            description: description,
            isRequired: isRequired,
          );
          
          setState(() {
            _items.add(newItem);
          });
          
          widget.onChecklistChanged?.call(_items);
        },
      ),
    );
  }

  void _editItem(int index) {
    if (widget.isReadOnly) return;

    showDialog(
      context: context,
      builder: (context) => _EditChecklistItemDialog(
        item: _items[index],
        onUpdate: (title, description, isRequired) {
          setState(() {
            _items[index] = _items[index].copyWith(
              title: title,
              description: description,
              isRequired: isRequired,
            );
          });
          
          widget.onChecklistChanged?.call(_items);
        },
      ),
    );
  }

  void _deleteItem(int index) {
    if (widget.isReadOnly) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Delete Item',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
        ),
        content: Text(
          'Are you sure you want to delete this checklist item?',
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
              setState(() {
                _items.removeAt(index);
              });
              widget.onChecklistChanged?.call(_items);
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

  @override
  Widget build(BuildContext context) {
    final completedCount = _items.where((item) => item.isCompleted).length;
    final requiredCount = _items.where((item) => item.isRequired).length;
    final completedRequiredCount = _items.where((item) => item.isRequired && item.isCompleted).length;
    final progress = _items.isEmpty ? 0.0 : completedCount / _items.length;

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
                  Icons.checklist,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Completion Checklist',
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.whiteColor,
                  ),
                ),
                const Spacer(),
                if (!widget.isReadOnly)
                  IconButton(
                    onPressed: _addItem,
                    icon: Icon(
                      Icons.add,
                      color: AppTheme.primaryColor,
                    ),
                    tooltip: 'Add Item',
                  ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
            
            // Progress Bar
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.darkCard,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? AppTheme.successColor : AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${completedCount}/${_items.length}',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            // Status Summary
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (requiredCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: completedRequiredCount == requiredCount 
                            ? AppTheme.successColor.withOpacity(0.2)
                            : AppTheme.warningColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: completedRequiredCount == requiredCount 
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Required: $completedRequiredCount/$requiredCount',
                        style: AppTheme.bodySmall.copyWith(
                          color: completedRequiredCount == requiredCount 
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (progress == 1.0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.successColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.successColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Complete',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            
            // Checklist Items
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              if (_items.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.checklist_rtl,
                        size: 48,
                        color: AppTheme.greyColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No checklist items',
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
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return _buildChecklistItem(item, index);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(ChecklistItem item, int index) {
    return Card(
      color: AppTheme.darkCard,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: widget.isReadOnly ? null : (value) => _toggleItem(index),
          activeColor: AppTheme.primaryColor,
        ),
        title: Text(
          item.title,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.whiteColor,
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            decorationColor: AppTheme.greyColor,
          ),
        ),
        subtitle: item.description != null
            ? Text(
                item.description!,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.greyColor,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.isRequired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.errorColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  'REQUIRED',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            if (!widget.isReadOnly) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editItem(index);
                      break;
                    case 'delete':
                      _deleteItem(index);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: AppTheme.primaryColor, size: 16),
                        const SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppTheme.errorColor, size: 16),
                        const SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
                child: Icon(
                  Icons.more_vert,
                  color: AppTheme.greyColor,
                ),
              ),
            ],
          ],
        ),
        onTap: widget.isReadOnly ? null : () => _toggleItem(index),
      ),
    );
  }
}

class _AddChecklistItemDialog extends StatefulWidget {
  final Function(String title, String? description, bool isRequired) onAdd;

  const _AddChecklistItemDialog({
    Key? key,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<_AddChecklistItemDialog> createState() => _AddChecklistItemDialogState();
}

class _AddChecklistItemDialogState extends State<_AddChecklistItemDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isRequired = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.darkSurface,
      title: Text(
        'Add Checklist Item',
        style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: Text(
              'Required Item',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
            ),
            subtitle: Text(
              'This item must be completed to finish the task',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
            ),
            value: _isRequired,
            onChanged: (value) {
              setState(() {
                _isRequired = value ?? false;
              });
            },
            activeColor: AppTheme.primaryColor,
          ),
        ],
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
            if (_titleController.text.trim().isNotEmpty) {
              widget.onAdd(
                _titleController.text.trim(),
                _descriptionController.text.trim().isNotEmpty 
                    ? _descriptionController.text.trim() 
                    : null,
                _isRequired,
              );
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: Text(
            'Add Item',
            style: TextStyle(color: AppTheme.whiteColor),
          ),
        ),
      ],
    );
  }
}

class _EditChecklistItemDialog extends StatefulWidget {
  final ChecklistItem item;
  final Function(String title, String? description, bool isRequired) onUpdate;

  const _EditChecklistItemDialog({
    Key? key,
    required this.item,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<_EditChecklistItemDialog> createState() => _EditChecklistItemDialogState();
}

class _EditChecklistItemDialogState extends State<_EditChecklistItemDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool _isRequired;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController = TextEditingController(text: widget.item.description ?? '');
    _isRequired = widget.item.isRequired;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.darkSurface,
      title: Text(
        'Edit Checklist Item',
        style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: Text(
              'Required Item',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
            ),
            subtitle: Text(
              'This item must be completed to finish the task',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
            ),
            value: _isRequired,
            onChanged: (value) {
              setState(() {
                _isRequired = value ?? false;
              });
            },
            activeColor: AppTheme.primaryColor,
          ),
        ],
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
            if (_titleController.text.trim().isNotEmpty) {
              widget.onUpdate(
                _titleController.text.trim(),
                _descriptionController.text.trim().isNotEmpty 
                    ? _descriptionController.text.trim() 
                    : null,
                _isRequired,
              );
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: Text(
            'Update Item',
            style: TextStyle(color: AppTheme.whiteColor),
          ),
        ),
      ],
    );
  }
}
