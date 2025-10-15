// lib/screens/citizen/report_issue_screen_new.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/issues_provider.dart';
import '../../services/location_service.dart';
import '../../services/ai_service_complete.dart';
import '../../services/geoapify_service.dart';
import '../../services/comprehensive_permission_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/salaar_loading_widget.dart';
import '../../widgets/success_card.dart';
import 'report_success_screen_new.dart';

class ReportIssueScreenNew extends StatefulWidget {
  const ReportIssueScreenNew({Key? key}) : super(key: key);

  @override
  State<ReportIssueScreenNew> createState() => _ReportIssueScreenNewState();
}

class _ReportIssueScreenNewState extends State<ReportIssueScreenNew> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  String _selectedCategory = 'infrastructure';
  String _selectedPriority = 'medium';
  List<File> _selectedImages = [];
  double? _latitude;
  double? _longitude;
  String _address = 'Getting location...';
  bool _isLoadingLocation = true;
  bool _aiAnalyzing = false;
  Map<String, dynamic>? _aiAnalysis;
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _categories = [
    'infrastructure',
    'sanitation',
    'traffic',
    'safety',
    'environment',
    'utilities',
    'other'
  ];

  final List<String> _priorities = [
    'low',
    'medium',
    'high',
    'urgent'
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      final hasPermission = await ComprehensivePermissionService.hasLocationPermission();
      if (!hasPermission) {
        final granted = await ComprehensivePermissionService.requestLocationPermission();
        if (!granted) {
          setState(() {
            _isLoadingLocation = false;
            _address = 'Location permission denied';
          });
          return;
        }
      }

      // Use the same location service as worker/admin/developer
      final location = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _latitude = location?['latitude'];
          _longitude = location?['longitude'];
          _isLoadingLocation = false;
        });
      }

      await _getAddressFromCoordinates();
    } catch (e) {
      print('Location error: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _latitude = 18.062160; // Default to Vizianagaram coordinates
          _longitude = 83.404149;
          _address = 'Vizianagaram, Andhra Pradesh, India';
          _locationController.text = _address;
        });
      }
    }
  }

  Future<void> _getAddressFromCoordinates() async {
    if (_latitude == null || _longitude == null) return;

    try {
      final address = await LocationService.getAddressFromCoordinates(
        _latitude!,
        _longitude!,
      );
      setState(() {
        _address = address;
        _locationController.text = address;
      });
    } catch (e) {
      setState(() {
        _address = 'Location: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}';
        _locationController.text = _address;
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await GeoapifyService.searchPlaces(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching locations: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectLocation(Map<String, dynamic> place) {
    final lat = place['lat'] as double;
    final lon = place['lon'] as double;

    setState(() {
      _latitude = lat;
      _longitude = lon;
      _address = place['formatted'] ?? place['name'] ?? 'Selected Location';
      _locationController.text = _address;
      _searchResults = [];
      _searchController.clear();
    });
  }

  Future<void> _analyzeWithAI() async {
    if (_descriptionController.text.isEmpty) return;

    setState(() => _aiAnalyzing = true);

    try {
      final analysis = await AIServiceComplete.generateTitleAndDescription(
        issueType: _selectedCategory,
        description: _descriptionController.text,
        location: _address,
      );

      setState(() {
        _aiAnalysis = analysis;
        if (analysis['title'] != null) {
          _titleController.text = analysis['title'] as String;
        }
        if (analysis['description'] != null) {
          _descriptionController.text = analysis['description'] as String;
        }
      });

      // Show AI suggestions
      if (mounted) {
        _showAISuggestions(analysis);
      }
    } catch (e) {
      print('AI Analysis Error: $e');
    } finally {
      setState(() => _aiAnalyzing = false);
    }
  }

  void _showAISuggestions(Map<String, dynamic> analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'AI Analysis',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (analysis['error'] != null)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: AppTheme.errorColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        analysis['error'] as String,
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
            if (analysis['isDuplicate'] == 'true')
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppTheme.errorColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This might be a duplicate report',
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
            if (analysis['isInvalid'] == 'true')
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: AppTheme.errorColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This report might be invalid',
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
            if (analysis['error'] == null)
              Text(
                'AI has improved your title and description for better clarity.',
                style: TextStyle(color: AppTheme.whiteColor),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final hasPermission = source == ImageSource.camera
          ? await ComprehensivePermissionService.hasCameraPermission()
          : await ComprehensivePermissionService.hasStoragePermission();

      if (!hasPermission) {
        final granted = source == ImageSource.camera
            ? await ComprehensivePermissionService.requestCameraPermission()
            : await ComprehensivePermissionService.requestStoragePermission();

        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permission required to access ${source == ImageSource.camera ? 'camera' : 'gallery'}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          return;
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSizeInMB = await file.length() / (1024 * 1024);

        if (fileSizeInMB > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image size must be less than 5MB. Current size: ${fileSizeInMB.toStringAsFixed(1)}MB'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          return;
        }

        setState(() {
          _selectedImages.add(file);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait for location to be determined'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    // REQUIRE AT LEAST ONE PHOTO
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add at least one photo to submit the report'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
    
    try {
      final success = await issuesProvider.submitIssue(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        address: _address,
        images: _selectedImages,
        category: _selectedCategory,
        priority: _selectedPriority,
      );

      if (success && mounted) {
        // Show XP success card
        SuccessCardService.showXPSuccess(
          context: context,
          xpAmount: 10,
          reason: 'submitting report',
        );
        
        // Navigate to new success screen
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => ReportSuccessScreenNew(
                  reportTitle: _titleController.text,
                  xpGained: 10,
                ),
              ),
            );
          }
        });
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(issuesProvider.error ?? 'Failed to submit issue'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final issuesProvider = Provider.of<IssuesProvider>(context);

    if (issuesProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: SalaarLoadingWidget(message: 'Submitting your report...'),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Report Issue',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Section
              _buildLocationSection(),
              const SizedBox(height: 24),
              
              // Category and Priority
              _buildCategoryPrioritySection(),
              const SizedBox(height: 24),
              
              // Title and Description
              _buildTitleDescriptionSection(),
              const SizedBox(height: 24),
              
              // Images Section
              _buildImagesSection(),
              const SizedBox(height: 24),
              
              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      color: AppTheme.darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Location',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoadingLocation)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              readOnly: true,
              style: TextStyle(color: AppTheme.whiteColor),
              decoration: InputDecoration(
                hintText: 'Getting location...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: AppTheme.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: Icon(Icons.my_location, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _searchController,
              onChanged: _searchLocation,
              style: TextStyle(color: AppTheme.whiteColor),
              decoration: InputDecoration(
                hintText: 'Search for a specific location...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: AppTheme.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _searchResults.clear();
                        },
                        icon: Icon(Icons.clear, color: AppTheme.primaryColor),
                      )
                    : null,
              ),
            ),
            if (_searchResults.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final place = _searchResults[index];
                    return ListTile(
                      leading: Icon(Icons.location_on, color: AppTheme.primaryColor),
                      title: Text(
                        place['name'] ?? 'Unknown',
                        style: TextStyle(color: AppTheme.whiteColor),
                      ),
                      subtitle: Text(
                        place['formatted'] ?? '',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      onTap: () => _selectLocation(place),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Location is automatically detected. You can also search for a specific location.',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPrioritySection() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category & Priority',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Category Selection
            Text(
              'Select Category',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? _getCategoryColor(category).withOpacity(0.2)
                          : AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? _getCategoryColor(category)
                            : AppTheme.greyColor.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          color: isSelected 
                              ? _getCategoryColor(category)
                              : AppTheme.greyColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category.toUpperCase(),
                          style: AppTheme.bodyMedium.copyWith(
                            color: isSelected 
                                ? _getCategoryColor(category)
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
            
            // Priority Selection
            Text(
              'Select Priority',
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _priorities.map((priority) {
                final isSelected = _selectedPriority == priority;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPriority = priority;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? _getPriorityColor(priority).withOpacity(0.2)
                            : AppTheme.darkBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? _getPriorityColor(priority)
                              : AppTheme.greyColor.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getPriorityIcon(priority),
                            color: isSelected 
                                ? _getPriorityColor(priority)
                                : AppTheme.greyColor,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            priority.toUpperCase(),
                            style: AppTheme.bodySmall.copyWith(
                              color: isSelected 
                                  ? _getPriorityColor(priority)
                                  : AppTheme.greyColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleDescriptionSection() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Issue Details',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Title Field
            TextFormField(
              controller: _titleController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
              style: TextStyle(color: AppTheme.whiteColor),
              decoration: InputDecoration(
                labelText: 'Issue Title',
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintText: 'Enter a clear, descriptive title...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: AppTheme.darkBackground,
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
            const SizedBox(height: 20),
            
            // Description Field
            TextFormField(
              controller: _descriptionController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Description is required';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
              maxLines: 4,
              maxLength: 500,
              style: TextStyle(color: AppTheme.whiteColor),
              decoration: InputDecoration(
                labelText: 'Issue Description',
                labelStyle: TextStyle(color: Colors.grey[400]),
                hintText: 'Describe the issue in detail. Include specific details about location, severity, and any other relevant information...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                counterText: '${_descriptionController.text.length}/500 characters (min 10)',
                filled: true,
                fillColor: AppTheme.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {}); // Update character count
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Provide clear and detailed information to help us address your issue quickly.',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Card(
      color: AppTheme.darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Photos',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(Required)',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Add at least one photo to help us understand the issue better. Max 5MB per image.',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                    label: Text('Camera', style: TextStyle(color: AppTheme.primaryColor)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library, color: AppTheme.primaryColor),
                    label: Text('Gallery', style: TextStyle(color: AppTheme.primaryColor)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: AppTheme.whiteColor,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
        ),
        child: Text(
          'Submit Report',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.whiteColor,
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
        return AppTheme.primaryColor;
      case 'sanitation':
        return Colors.orange;
      case 'traffic':
        return Colors.red;
      case 'safety':
        return Colors.purple;
      case 'environment':
        return Colors.green;
      case 'utilities':
        return Colors.blue;
      case 'other':
        return AppTheme.greyColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
        return Icons.construction;
      case 'sanitation':
        return Icons.cleaning_services;
      case 'traffic':
        return Icons.traffic;
      case 'safety':
        return Icons.security;
      case 'environment':
        return Icons.eco;
      case 'utilities':
        return Icons.electrical_services;
      case 'other':
        return Icons.help_outline;
      default:
        return Icons.assignment;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Icons.keyboard_arrow_down;
      case 'medium':
        return Icons.remove;
      case 'high':
        return Icons.keyboard_arrow_up;
      case 'urgent':
        return Icons.priority_high;
      default:
        return Icons.remove;
    }
  }
}
