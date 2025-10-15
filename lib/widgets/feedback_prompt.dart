// lib/widgets/feedback_prompt.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class FeedbackPrompt extends StatefulWidget {
  final String taskId;
  final String taskTitle;
  final VoidCallback? onFeedbackSubmitted;
  final bool showImmediately;

  const FeedbackPrompt({
    Key? key,
    required this.taskId,
    required this.taskTitle,
    this.onFeedbackSubmitted,
    this.showImmediately = false,
  }) : super(key: key);

  @override
  State<FeedbackPrompt> createState() => _FeedbackPromptState();
}

class _FeedbackPromptState extends State<FeedbackPrompt>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  bool _isVisible = false;
  bool _isSubmitted = false;
  String? _selectedRating;
  String? _selectedDifficulty;
  String? _selectedSatisfaction;

  final List<Map<String, dynamic>> _difficultyOptions = [
    {'value': 'very_easy', 'label': 'Very Easy', 'icon': Icons.sentiment_very_satisfied, 'color': AppTheme.successColor},
    {'value': 'easy', 'label': 'Easy', 'icon': Icons.sentiment_satisfied, 'color': AppTheme.successColor},
    {'value': 'moderate', 'label': 'Moderate', 'icon': Icons.sentiment_neutral, 'color': AppTheme.warningColor},
    {'value': 'difficult', 'label': 'Difficult', 'icon': Icons.sentiment_dissatisfied, 'color': AppTheme.errorColor},
    {'value': 'very_difficult', 'label': 'Very Difficult', 'icon': Icons.sentiment_very_dissatisfied, 'color': AppTheme.errorColor},
  ];

  final List<Map<String, dynamic>> _satisfactionOptions = [
    {'value': 'excellent', 'label': 'Excellent', 'icon': Icons.star, 'color': AppTheme.primaryColor},
    {'value': 'good', 'label': 'Good', 'icon': Icons.star_half, 'color': AppTheme.infoColor},
    {'value': 'average', 'label': 'Average', 'icon': Icons.star_border, 'color': AppTheme.warningColor},
    {'value': 'poor', 'label': 'Poor', 'icon': Icons.star_outline, 'color': AppTheme.errorColor},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
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

    if (widget.showImmediately) {
      _showPrompt();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showPrompt() {
    setState(() {
      _isVisible = true;
    });
    _animationController.forward();
  }

  void _hidePrompt() {
    _animationController.reverse().then((_) {
      setState(() {
        _isVisible = false;
      });
    });
  }

  void _submitFeedback() {
    if (_selectedRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitted = true;
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Simulate feedback submission
    Future.delayed(const Duration(milliseconds: 500), () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      
      widget.onFeedbackSubmitted?.call();
      _hidePrompt();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  color: AppTheme.darkSurface,
                  margin: const EdgeInsets.all(24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _isSubmitted
                        ? _buildSuccessView()
                        : _buildFeedbackForm(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle,
          size: 64,
          color: AppTheme.successColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Feedback Submitted!',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Thank you for helping us improve our service.',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.greyColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeedbackForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.feedback,
              color: AppTheme.primaryColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Completed!',
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.taskTitle,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.greyColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _hidePrompt,
              icon: Icon(
                Icons.close,
                color: AppTheme.greyColor,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Rating Section
        Text(
          'How was this task?',
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.whiteColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            final rating = (index + 1).toString();
            final isSelected = _selectedRating == rating;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRating = rating;
                });
                HapticFeedback.lightImpact();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.primaryColor
                        : AppTheme.greyColor.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  Icons.star,
                  color: isSelected 
                      ? AppTheme.primaryColor
                      : AppTheme.greyColor,
                  size: 24,
                ),
              ),
            );
          }),
        ),
        
        const SizedBox(height: 24),
        
        // Difficulty Section
        Text(
          'How difficult was it?',
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.whiteColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _difficultyOptions.map((option) {
            final isSelected = _selectedDifficulty == option['value'];
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDifficulty = option['value'] as String;
                });
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (option['color'] as Color).withOpacity(0.2)
                      : AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? option['color'] as Color
                        : AppTheme.greyColor.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      color: isSelected 
                          ? option['color'] as Color
                          : AppTheme.greyColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      option['label'] as String,
                      style: AppTheme.bodySmall.copyWith(
                        color: isSelected 
                            ? option['color'] as Color
                            : AppTheme.greyColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 24),
        
        // Satisfaction Section
        Text(
          'Overall satisfaction?',
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.whiteColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _satisfactionOptions.map((option) {
            final isSelected = _selectedSatisfaction == option['value'];
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSatisfaction = option['value'] as String;
                });
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (option['color'] as Color).withOpacity(0.2)
                      : AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? option['color'] as Color
                        : AppTheme.greyColor.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      color: isSelected 
                          ? option['color'] as Color
                          : AppTheme.greyColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      option['label'] as String,
                      style: AppTheme.bodySmall.copyWith(
                        color: isSelected 
                            ? option['color'] as Color
                            : AppTheme.greyColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 24),
        
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _hidePrompt,
                child: Text(
                  'Skip',
                  style: TextStyle(color: AppTheme.greyColor),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Submit Feedback',
                  style: TextStyle(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class QuickFeedbackButton extends StatelessWidget {
  final String taskId;
  final String taskTitle;
  final VoidCallback? onFeedbackSubmitted;

  const QuickFeedbackButton({
    Key? key,
    required this.taskId,
    required this.taskTitle,
    this.onFeedbackSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => FeedbackPrompt(
            taskId: taskId,
            taskTitle: taskTitle,
            onFeedbackSubmitted: onFeedbackSubmitted,
            showImmediately: true,
          ),
        );
      },
      icon: Icon(Icons.feedback, size: 16),
      label: Text('Was this easy?'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

class FeedbackSummary extends StatelessWidget {
  final Map<String, dynamic> feedbackData;

  const FeedbackSummary({
    Key? key,
    required this.feedbackData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback Summary',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeedbackItem(
              'Rating',
              '${feedbackData['rating'] ?? 'N/A'}/5',
              Icons.star,
              AppTheme.primaryColor,
            ),
            _buildFeedbackItem(
              'Difficulty',
              _formatDifficulty(feedbackData['difficulty']),
              _getDifficultyIcon(feedbackData['difficulty']),
              _getDifficultyColor(feedbackData['difficulty']),
            ),
            _buildFeedbackItem(
              'Satisfaction',
              _formatSatisfaction(feedbackData['satisfaction']),
              _getSatisfactionIcon(feedbackData['satisfaction']),
              _getSatisfactionColor(feedbackData['satisfaction']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.greyColor,
            ),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDifficulty(String? difficulty) {
    switch (difficulty) {
      case 'very_easy': return 'Very Easy';
      case 'easy': return 'Easy';
      case 'moderate': return 'Moderate';
      case 'difficult': return 'Difficult';
      case 'very_difficult': return 'Very Difficult';
      default: return 'N/A';
    }
  }

  String _formatSatisfaction(String? satisfaction) {
    switch (satisfaction) {
      case 'excellent': return 'Excellent';
      case 'good': return 'Good';
      case 'average': return 'Average';
      case 'poor': return 'Poor';
      default: return 'N/A';
    }
  }

  IconData _getDifficultyIcon(String? difficulty) {
    switch (difficulty) {
      case 'very_easy': return Icons.sentiment_very_satisfied;
      case 'easy': return Icons.sentiment_satisfied;
      case 'moderate': return Icons.sentiment_neutral;
      case 'difficult': return Icons.sentiment_dissatisfied;
      case 'very_difficult': return Icons.sentiment_very_dissatisfied;
      default: return Icons.help_outline;
    }
  }

  IconData _getSatisfactionIcon(String? satisfaction) {
    switch (satisfaction) {
      case 'excellent': return Icons.star;
      case 'good': return Icons.star_half;
      case 'average': return Icons.star_border;
      case 'poor': return Icons.star_outline;
      default: return Icons.help_outline;
    }
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty) {
      case 'very_easy':
      case 'easy':
        return AppTheme.successColor;
      case 'moderate':
        return AppTheme.warningColor;
      case 'difficult':
      case 'very_difficult':
        return AppTheme.errorColor;
      default:
        return AppTheme.greyColor;
    }
  }

  Color _getSatisfactionColor(String? satisfaction) {
    switch (satisfaction) {
      case 'excellent': return AppTheme.primaryColor;
      case 'good': return AppTheme.infoColor;
      case 'average': return AppTheme.warningColor;
      case 'poor': return AppTheme.errorColor;
      default: return AppTheme.greyColor;
    }
  }
}
