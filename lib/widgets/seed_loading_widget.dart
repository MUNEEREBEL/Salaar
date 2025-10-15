// lib/widgets/seed_loading_widget.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SeedLoadingWidget extends StatefulWidget {
  final String? message;

  const SeedLoadingWidget({super.key, this.message});

  @override
  State<SeedLoadingWidget> createState() => _SeedLoadingWidgetState();
}

class _SeedLoadingWidgetState extends State<SeedLoadingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _growthAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _growthAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Soil
                  Container(
                    width: 120,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFF8B4513),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  
                  // Growing Plant
                  Transform.translate(
                    offset: Offset(0, -20 * _growthAnimation.value),
                    child: Column(
                      children: [
                        // Stem
                        Container(
                          width: 6,
                          height: 30 * _growthAnimation.value,
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        
                        // Leaves
                        if (_growthAnimation.value > 0.5)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.rotate(
                                angle: -0.3,
                                child: Container(
                                  width: 15,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Transform.rotate(
                                angle: 0.3,
                                child: Container(
                                  width: 15,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(10),
                                      bottomLeft: Radius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  
                  // Seed
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            widget.message ?? 'Growing your data...',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.greyColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
  }
}