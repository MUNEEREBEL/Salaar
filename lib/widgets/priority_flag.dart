// lib/widgets/priority_flag.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PriorityFlag extends StatelessWidget {
  final String priority;
  final bool isCompact;
  final bool showIcon;
  final double? size;
  final VoidCallback? onTap;

  const PriorityFlag({
    Key? key,
    required this.priority,
    this.isCompact = false,
    this.showIcon = true,
    this.size,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final priorityData = _getPriorityData(priority);
    final flagSize = size ?? (isCompact ? 16.0 : 20.0);
    
    Widget flag = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: priorityData['color'].withOpacity(0.2),
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        border: Border.all(
          color: priorityData['color'].withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: priorityData['color'].withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              priorityData['icon'],
              size: flagSize * 0.8,
              color: priorityData['color'],
            ),
            SizedBox(width: isCompact ? 4 : 6),
          ],
          Text(
            priorityData['text'],
            style: TextStyle(
              color: priorityData['color'],
              fontWeight: FontWeight.bold,
              fontSize: flagSize * 0.7,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: flag,
      );
    }

    return flag;
  }

  Map<String, dynamic> _getPriorityData(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
      case 'critical':
        return {
          'color': AppTheme.errorColor,
          'icon': Icons.priority_high,
          'text': 'URGENT',
        };
      case 'high':
        return {
          'color': AppTheme.warningColor,
          'icon': Icons.keyboard_arrow_up,
          'text': 'HIGH',
        };
      case 'medium':
        return {
          'color': AppTheme.infoColor,
          'icon': Icons.remove,
          'text': 'MEDIUM',
        };
      case 'low':
        return {
          'color': AppTheme.successColor,
          'icon': Icons.keyboard_arrow_down,
          'text': 'LOW',
        };
      default:
        return {
          'color': AppTheme.greyColor,
          'icon': Icons.help_outline,
          'text': priority.toUpperCase(),
        };
    }
  }
}

class PriorityFlagChip extends StatelessWidget {
  final String priority;
  final bool isSelected;
  final VoidCallback? onTap;
  final double? size;

  const PriorityFlagChip({
    Key? key,
    required this.priority,
    this.isSelected = false,
    this.onTap,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final priorityData = _getPriorityData(priority);
    final chipSize = size ?? 20.0;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: chipSize * 0.4,
          vertical: chipSize * 0.2,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? priorityData['color']
              : priorityData['color'].withOpacity(0.2),
          borderRadius: BorderRadius.circular(chipSize * 0.6),
          border: Border.all(
            color: priorityData['color'],
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: priorityData['color'].withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              priorityData['icon'],
              size: chipSize * 0.8,
              color: isSelected ? AppTheme.whiteColor : priorityData['color'],
            ),
            SizedBox(width: chipSize * 0.2),
            Text(
              priorityData['text'],
              style: TextStyle(
                color: isSelected ? AppTheme.whiteColor : priorityData['color'],
                fontWeight: FontWeight.bold,
                fontSize: chipSize * 0.6,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getPriorityData(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
      case 'critical':
        return {
          'color': AppTheme.errorColor,
          'icon': Icons.priority_high,
          'text': 'URGENT',
        };
      case 'high':
        return {
          'color': AppTheme.warningColor,
          'icon': Icons.keyboard_arrow_up,
          'text': 'HIGH',
        };
      case 'medium':
        return {
          'color': AppTheme.infoColor,
          'icon': Icons.remove,
          'text': 'MEDIUM',
        };
      case 'low':
        return {
          'color': AppTheme.successColor,
          'icon': Icons.keyboard_arrow_down,
          'text': 'LOW',
        };
      default:
        return {
          'color': AppTheme.greyColor,
          'icon': Icons.help_outline,
          'text': priority.toUpperCase(),
        };
    }
  }
}

class PriorityFlagSelector extends StatefulWidget {
  final String? selectedPriority;
  final ValueChanged<String>? onPriorityChanged;
  final List<String> availablePriorities;
  final bool isCompact;

  const PriorityFlagSelector({
    Key? key,
    this.selectedPriority,
    this.onPriorityChanged,
    this.availablePriorities = const ['low', 'medium', 'high', 'urgent'],
    this.isCompact = false,
  }) : super(key: key);

  @override
  State<PriorityFlagSelector> createState() => _PriorityFlagSelectorState();
}

class _PriorityFlagSelectorState extends State<PriorityFlagSelector> {
  String? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _selectedPriority = widget.selectedPriority;
  }

  @override
  void didUpdateWidget(PriorityFlagSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPriority != oldWidget.selectedPriority) {
      _selectedPriority = widget.selectedPriority;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.availablePriorities.map((priority) {
        return PriorityFlagChip(
          priority: priority,
          isSelected: _selectedPriority == priority,
          onTap: () {
            setState(() {
              _selectedPriority = priority;
            });
            widget.onPriorityChanged?.call(priority);
          },
          size: widget.isCompact ? 16 : 20,
        );
      }).toList(),
    );
  }
}

class PriorityFlagBadge extends StatelessWidget {
  final String priority;
  final Widget child;
  final Position position;
  final double? size;

  const PriorityFlagBadge({
    Key? key,
    required this.priority,
    required this.child,
    this.position = Position.topRight,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final priorityData = _getPriorityData(priority);
    final badgeSize = size ?? 12.0;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: position == Position.topRight || position == Position.topLeft ? -badgeSize / 2 : null,
          bottom: position == Position.bottomRight || position == Position.bottomLeft ? -badgeSize / 2 : null,
          right: position == Position.topRight || position == Position.bottomRight ? -badgeSize / 2 : null,
          left: position == Position.topLeft || position == Position.bottomLeft ? -badgeSize / 2 : null,
          child: Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              color: priorityData['color'],
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.darkBackground,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: priorityData['color'].withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              priorityData['icon'],
              size: badgeSize * 0.6,
              color: AppTheme.whiteColor,
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getPriorityData(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
      case 'critical':
        return {
          'color': AppTheme.errorColor,
          'icon': Icons.priority_high,
        };
      case 'high':
        return {
          'color': AppTheme.warningColor,
          'icon': Icons.keyboard_arrow_up,
        };
      case 'medium':
        return {
          'color': AppTheme.infoColor,
          'icon': Icons.remove,
        };
      case 'low':
        return {
          'color': AppTheme.successColor,
          'icon': Icons.keyboard_arrow_down,
        };
      default:
        return {
          'color': AppTheme.greyColor,
          'icon': Icons.help_outline,
        };
    }
  }
}

enum Position {
  topRight,
  topLeft,
  bottomRight,
  bottomLeft,
}

class PriorityFlagList extends StatelessWidget {
  final List<String> priorities;
  final String? selectedPriority;
  final ValueChanged<String>? onPriorityChanged;
  final bool isCompact;
  final Axis direction;

  const PriorityFlagList({
    Key? key,
    required this.priorities,
    this.selectedPriority,
    this.onPriorityChanged,
    this.isCompact = false,
    this.direction = Axis.horizontal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return direction == Axis.horizontal
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: priorities.map((priority) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PriorityFlag(
                  priority: priority,
                  isCompact: isCompact,
                  onTap: () => onPriorityChanged?.call(priority),
                ),
              );
            }).toList(),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: priorities.map((priority) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PriorityFlag(
                  priority: priority,
                  isCompact: isCompact,
                  onTap: () => onPriorityChanged?.call(priority),
                ),
              );
            }).toList(),
          );
  }
}
