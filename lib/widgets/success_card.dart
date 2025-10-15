// lib/widgets/success_card.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SuccessCard extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onDismiss;
  final Duration duration;

  const SuccessCard({
    Key? key,
    required this.title,
    required this.message,
    this.icon = Icons.check_circle,
    this.iconColor,
    this.onDismiss,
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<SuccessCard> createState() => _SuccessCardState();
}

class _SuccessCardState extends State<SuccessCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted && widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.successColor.withOpacity(0.1),
                    AppTheme.successColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.successColor.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.successColor.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.iconColor ?? AppTheme.successColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: AppTheme.whiteColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.whiteColor,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.message,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.greyColor,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _dismiss,
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.greyColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Success Card Service
class SuccessCardService {
  static void showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.check_circle,
    Color? iconColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessCard(
        title: title,
        message: message,
        icon: icon,
        iconColor: iconColor,
        duration: duration,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  static void showXPSuccess({
    required BuildContext context,
    required int xpAmount,
    required String reason,
  }) {
    showSuccess(
      context: context,
      title: 'XP Earned!',
      message: '+$xpAmount XP for $reason',
      icon: Icons.star,
      iconColor: AppTheme.primaryColor,
      duration: const Duration(seconds: 4),
    );
  }

  static void showReportSuccess({
    required BuildContext context,
    required String reportTitle,
  }) {
    showSuccess(
      context: context,
      title: 'Report Submitted!',
      message: 'Admin will verify "$reportTitle" and you\'ll get +10 XP!',
      icon: Icons.report_problem,
      iconColor: AppTheme.successColor,
      duration: const Duration(seconds: 4),
    );
  }

  static void showProfileUpdateSuccess({
    required BuildContext context,
    required String updateType,
  }) {
    showSuccess(
      context: context,
      title: 'Profile Updated!',
      message: 'Your $updateType has been updated successfully',
      icon: Icons.person,
      iconColor: AppTheme.infoColor,
    );
  }

  static void showDataRefreshSuccess({
    required BuildContext context,
  }) {
    showSuccess(
      context: context,
      title: 'Data Refreshed!',
      message: 'All data has been updated successfully',
      icon: Icons.refresh,
      iconColor: AppTheme.primaryColor,
      duration: const Duration(seconds: 2),
    );
  }
}
