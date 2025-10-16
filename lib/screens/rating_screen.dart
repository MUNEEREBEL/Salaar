// lib/screens/rating_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({Key? key}) : super(key: key);

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _selectedRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Open app store for rating
      final Uri playStoreUrl = Uri.parse('https://play.google.com/store/apps/details?id=com.example.salaar_reporter');
      
      if (await canLaunchUrl(playStoreUrl)) {
        await launchUrl(playStoreUrl, mode: LaunchMode.externalApplication);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening Play Store for rating...'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Could not launch Play Store');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open Play Store. Please rate us manually.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Rate Our App',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // App Icon and Title
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_user,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'How would you rate SALAAR?',
              style: AppTheme.headlineMedium.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your feedback helps us improve the app',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Star Rating
            LayoutBuilder(
              builder: (context, constraints) {
                final starSize = constraints.maxWidth > 400 ? 50.0 : 40.0;
                final starSpacing = constraints.maxWidth > 400 ? 8.0 : 4.0;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRating = index + 1;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: starSpacing),
                        child: Icon(
                          index < _selectedRating ? Icons.star : Icons.star_border,
                          size: starSize,
                          color: index < _selectedRating 
                              ? AppTheme.accentColor 
                              : AppTheme.greyColor,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Rating Text
            if (_selectedRating > 0)
              Text(
                _getRatingText(_selectedRating),
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 32),
            
            // Feedback Section
            Text(
              'Tell us more (Optional)',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              style: TextStyle(color: AppTheme.whiteColor),
              decoration: InputDecoration(
                hintText: 'What do you like about the app? What can we improve?',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: AppTheme.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
                child: _isSubmitting
                    ? CircularProgressIndicator(color: AppTheme.whiteColor)
                    : Text(
                        'Submit Rating',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.whiteColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Skip Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe Later',
                style: TextStyle(
                  color: AppTheme.greyColor,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}
