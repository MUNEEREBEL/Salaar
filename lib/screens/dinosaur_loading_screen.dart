// lib/screens/dinosaur_loading_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';

class DinosaurLoadingScreen extends StatefulWidget {
  final String? message;
  final bool showProgress;
  
  const DinosaurLoadingScreen({
    Key? key,
    this.message,
    this.showProgress = true,
  }) : super(key: key);

  @override
  State<DinosaurLoadingScreen> createState() => _DinosaurLoadingScreenState();
}

class _DinosaurLoadingScreenState extends State<DinosaurLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _dinosaurController;
  late AnimationController _fireController;
  late AnimationController _textController;
  
  late Animation<double> _dinosaurAnimation;
  late Animation<double> _fireAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();
    
    // Dinosaur animation (bouncing)
    _dinosaurController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _dinosaurAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dinosaurController,
      curve: Curves.elasticOut,
    ));
    
    // Fire animation (flickering)
    _fireController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fireAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _fireController,
      curve: Curves.easeInOut,
    ));
    
    // Text animation (fade in)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));
    
    // Start animations
    _dinosaurController.repeat(reverse: true);
    _fireController.repeat(reverse: true);
    _textController.forward();
  }

  @override
  void dispose() {
    _dinosaurController.dispose();
    _fireController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.darkBackground,
              AppTheme.darkBackground.withOpacity(0.8),
              AppTheme.primaryColor.withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dinosaur with Fire
              AnimatedBuilder(
                animation: _dinosaurAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (_dinosaurAnimation.value * 0.2),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Fire effect
                        AnimatedBuilder(
                          animation: _fireAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _fireAnimation.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.orange.withOpacity(0.3),
                                      Colors.red.withOpacity(0.2),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Dinosaur Emoji
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '🦖', // T-Rex emoji
                              style: TextStyle(
                                fontSize: 50,
                                height: 1.0, // Adjust line height for better centering
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        // Fire particles
                        ...List.generate(8, (index) {
                          return AnimatedBuilder(
                            animation: _fireAnimation,
                            builder: (context, child) {
                              final angle = (index * 45.0) * (3.14159 / 180);
                              final radius = 60 + (_fireAnimation.value * 10);
                              final x = radius * cos(angle);
                              final y = radius * sin(angle);
                              
                              return Positioned(
                                left: 50 + x - 5,
                                top: 50 + y - 5,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // App Title
              FadeTransition(
                opacity: _textAnimation,
                child: Text(
                  'SALAAR',
                  style: AppTheme.headlineLarge.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    letterSpacing: 2,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Subtitle
              FadeTransition(
                opacity: _textAnimation,
                child: Text(
                  'Community Reporter',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.greyColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Loading message
              if (widget.message != null)
                FadeTransition(
                  opacity: _textAnimation,
                  child: Text(
                    widget.message!,
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.whiteColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 30),
              
              // Progress indicator
              if (widget.showProgress)
                FadeTransition(
                  opacity: _textAnimation,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          backgroundColor: AppTheme.greyColor.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading...',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.greyColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

