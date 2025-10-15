// lib/widgets/double_tap_interaction.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class DoubleTapInteraction extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onTap;
  final Duration debounceTime;
  final bool enableHapticFeedback;
  final String? tooltip;

  const DoubleTapInteraction({
    Key? key,
    required this.child,
    this.onDoubleTap,
    this.onTap,
    this.debounceTime = const Duration(milliseconds: 300),
    this.enableHapticFeedback = true,
    this.tooltip,
  }) : super(key: key);

  @override
  State<DoubleTapInteraction> createState() => _DoubleTapInteractionState();
}

class _DoubleTapInteractionState extends State<DoubleTapInteraction>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Timer? _debounceTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    if (_isProcessing) return;

    _isProcessing = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceTime, () {
      _isProcessing = false;
    });

    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    widget.onTap?.call();
  }

  void _handleDoubleTap() {
    if (_isProcessing) return;

    _isProcessing = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceTime, () {
      _isProcessing = false;
    });

    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    widget.onDoubleTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip ?? '',
      child: GestureDetector(
        onTap: _handleTap,
        onDoubleTap: _handleDoubleTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}

// Double-tap interaction for report cards
class DoubleTapReportCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onUpvote;
  final VoidCallback? onClaim;
  final bool isWorker;
  final String? tooltip;

  const DoubleTapReportCard({
    Key? key,
    required this.child,
    this.onUpvote,
    this.onClaim,
    this.isWorker = false,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DoubleTapInteraction(
      onDoubleTap: isWorker ? onClaim : onUpvote,
      tooltip: tooltip ?? (isWorker ? 'Double-tap to claim' : 'Double-tap to upvote'),
      child: child,
    );
  }
}

// Double-tap interaction for refresh
class DoubleTapRefresh extends StatelessWidget {
  final Widget child;
  final VoidCallback onRefresh;
  final String? tooltip;

  const DoubleTapRefresh({
    Key? key,
    required this.child,
    required this.onRefresh,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DoubleTapInteraction(
      onDoubleTap: onRefresh,
      tooltip: tooltip ?? 'Double-tap to refresh',
      child: child,
    );
  }
}

// Double-tap interaction for photo upload
class DoubleTapPhotoUpload extends StatelessWidget {
  final Widget child;
  final VoidCallback onAddPhoto;
  final VoidCallback? onRemovePhoto;
  final bool hasPhoto;
  final String? tooltip;

  const DoubleTapPhotoUpload({
    Key? key,
    required this.child,
    required this.onAddPhoto,
    this.onRemovePhoto,
    this.hasPhoto = false,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DoubleTapInteraction(
      onDoubleTap: hasPhoto ? onRemovePhoto : onAddPhoto,
      tooltip: tooltip ?? (hasPhoto ? 'Double-tap to remove' : 'Double-tap to add photo'),
      child: child,
    );
  }
}

// Success animation for double-tap actions
class DoubleTapSuccessAnimation extends StatefulWidget {
  final Widget child;
  final bool showAnimation;
  final Duration animationDuration;

  const DoubleTapSuccessAnimation({
    Key? key,
    required this.child,
    this.showAnimation = false,
    this.animationDuration = const Duration(milliseconds: 1000),
  }) : super(key: key);

  @override
  State<DoubleTapSuccessAnimation> createState() => _DoubleTapSuccessAnimationState();
}

class _DoubleTapSuccessAnimationState extends State<DoubleTapSuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void didUpdateWidget(DoubleTapSuccessAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showAnimation && !oldWidget.showAnimation) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: _scaleAnimation.value,
              child: widget.child,
            ),
            if (widget.showAnimation)
              Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: AppTheme.whiteColor,
                    size: 24,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
