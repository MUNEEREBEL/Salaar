// lib/screens/citizen/map_screen_enhanced.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../../providers/issues_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/location_service.dart';

class MapScreenEnhanced extends StatefulWidget {
  const MapScreenEnhanced({Key? key}) : super(key: key);

  @override
  State<MapScreenEnhanced> createState() => _MapScreenEnhancedState();
}

class _MapScreenEnhancedState extends State<MapScreenEnhanced> {
  late MapController _mapController;
  Timer? _refreshTimer;
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  List<Map<String, dynamic>> _nearbyIssues = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRealTimeUpdates() {
    // Refresh nearby issues every 15 seconds for better real-time experience
    _refreshTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (_currentLocation != null) {
        _loadNearbyIssues();
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      print('📍 User map: Getting current location...');
      final location = await LocationService.getCurrentLocation();
      if (location != null) {
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(
              location['latitude'] as double, 
              location['longitude'] as double
            );
            _isLoadingLocation = false;
          });
          print('📍 User map: Location found - ${location['latitude']}, ${location['longitude']}');
          _loadNearbyIssues();
        }
      } else {
        print('📍 User map: No location found, using default');
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _currentLocation = LatLng(18.062160, 83.404149); // Default to Vizianagaram
          });
          _loadNearbyIssues();
        }
      }
    } catch (e) {
      print('📍 User map: Location error: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _currentLocation = LatLng(18.062160, 83.404149); // Default to Vizianagaram
        });
        _loadNearbyIssues();
      }
    }
  }

  Future<void> _loadNearbyIssues() async {
    try {
      final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
      await issuesProvider.fetchAllIssues(forceRefresh: true);
      
      if (mounted) {
        setState(() {
          // Filter out completed issues and only show active ones
          _nearbyIssues = issuesProvider.issues
              .where((issue) => issue.status != 'completed') // Remove completed reports
              .map((issue) => {
                'id': issue.id,
                'title': issue.title ?? issue.description,
                'description': issue.description,
                'latitude': issue.latitude,
                'longitude': issue.longitude,
                'status': issue.status,
                'category': issue.issueType,
                'priority': issue.priority,
                'address': issue.address,
                'created_at': issue.createdAt,
                'image_urls': issue.imageUrls,
              }).toList();
        });
        print('✅ Loaded ${_nearbyIssues.length} active issues on map (completed issues filtered out)');
      }
    } catch (e) {
      print('Error loading issues: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Issues', style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor)),
        backgroundColor: AppTheme.darkBackground,
        actions: [
          IconButton(
            onPressed: () {
              _loadNearbyIssues();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Map refreshed with latest issues!'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            icon: Icon(Icons.refresh, color: AppTheme.whiteColor),
            tooltip: 'Refresh Issues',
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _loadNearbyIssues();
              await Future.delayed(Duration(milliseconds: 500));
            },
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation ?? LatLng(18.062160, 83.404149),
                initialZoom: 15.0,
                onTap: (tapPosition, point) {
                  // Handle map tap
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                  userAgentPackageName: 'com.salaar.reporter',
                ),
                MarkerLayer(
                  markers: _buildMarkers(),
                ),
              ],
            ),
          ),
          
          // Zoom controls
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                // Zoom in button
                FloatingActionButton.small(
                  onPressed: () {
                    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                  },
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.add, color: AppTheme.whiteColor),
                ),
                const SizedBox(height: 8),
                // Zoom out button
                FloatingActionButton.small(
                  onPressed: () {
                    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                  },
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.remove, color: AppTheme.whiteColor),
                ),
                const SizedBox(height: 8),
                // Current location button
                FloatingActionButton(
                  onPressed: _getCurrentLocation,
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.my_location, color: AppTheme.whiteColor),
                ),
              ],
            ),
          ),
          
          // Real-time indicator
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: AppTheme.whiteColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Loading indicator
          if (_isLoadingLocation)
            Center(
              child: Card(
                color: AppTheme.darkSurface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryColor),
                      const SizedBox(height: 8),
                      Text(
                        'Loading your location...',
                        style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];
    
    // Add current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.whiteColor, width: 3),
            ),
            child: Icon(
              Icons.person,
              color: AppTheme.whiteColor,
              size: 16,
            ),
          ),
        ),
      );
    }
    
    // Group issues by location to handle clustering
    Map<String, List<Map<String, dynamic>>> locationGroups = {};
    for (var issue in _nearbyIssues) {
      final lat = issue['latitude'] as double?;
      final lng = issue['longitude'] as double?;
      if (lat != null && lng != null) {
        // Round coordinates to group nearby issues (within ~10 meters)
        final roundedLat = (lat * 1000).round() / 1000;
        final roundedLng = (lng * 1000).round() / 1000;
        final key = '${roundedLat}_${roundedLng}';
        
        if (!locationGroups.containsKey(key)) {
          locationGroups[key] = [];
        }
        locationGroups[key]!.add(issue);
      }
    }
    
    // Add clustered markers
    for (var entry in locationGroups.entries) {
      final issues = entry.value;
      final firstIssue = issues.first;
      final lat = firstIssue['latitude'] as double;
      final lng = firstIssue['longitude'] as double;
      
      // Add small random offset for multiple issues at same location
      final offsetLat = lat + (issues.length > 1 ? (issues.indexOf(firstIssue) * 0.0001) : 0);
      final offsetLng = lng + (issues.length > 1 ? (issues.indexOf(firstIssue) * 0.0001) : 0);
      
      markers.add(
        Marker(
          point: LatLng(offsetLat, offsetLng),
          width: issues.length > 1 ? 50 : 40,
          height: issues.length > 1 ? 50 : 40,
          child: GestureDetector(
            onTap: () => _showIssueDetails(context, firstIssue, issues),
            child: Container(
              decoration: BoxDecoration(
                color: _getCategoryColor(firstIssue['category'] ?? firstIssue['issue_type']),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.whiteColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _getCategoryIcon(firstIssue['category'] ?? firstIssue['issue_type']),
                      color: AppTheme.whiteColor,
                      size: issues.length > 1 ? 24 : 20,
                    ),
                  ),
                  if (issues.length > 1)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.whiteColor, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            '${issues.length}',
                            style: TextStyle(
                              color: AppTheme.whiteColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return markers;
  }

  void _showIssueDetails(BuildContext context, Map<String, dynamic> issue, [List<Map<String, dynamic>>? allIssues]) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        final issues = allIssues ?? [issue];
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.location_on, color: AppTheme.primaryColor, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issues.length > 1 ? '${issues.length} Issues at this location' : 'Issue Details',
                      style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppTheme.greyColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Issues list
              Expanded(
                child: ListView.builder(
                  itemCount: issues.length,
                  itemBuilder: (context, index) {
                    final currentIssue = issues[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.greyColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(currentIssue['category'] ?? currentIssue['issue_type']).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  currentIssue['category'] ?? 'N/A',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: _getCategoryColor(currentIssue['category'] ?? currentIssue['issue_type']),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(currentIssue['status']).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  currentIssue['status']?.toUpperCase() ?? 'PENDING',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: _getStatusColor(currentIssue['status']),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentIssue['title'] ?? 'No Title',
                            style: AppTheme.bodyLarge.copyWith(
                              color: AppTheme.whiteColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentIssue['description'] ?? 'No description provided.',
                            style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.priority_high, color: AppTheme.warningColor, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Priority: ${currentIssue['priority'] ?? 'MEDIUM'}',
                                style: AppTheme.bodySmall.copyWith(color: AppTheme.whiteColor),
                              ),
                              const Spacer(),
                              Icon(Icons.access_time, color: AppTheme.infoColor, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(currentIssue['created_at']),
                                style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
                              ),
                            ],
                          ),
                          if (currentIssue['image_urls'] != null && (currentIssue['image_urls'] as List).isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: (currentIssue['image_urls'] as List).length,
                                itemBuilder: (context, imgIndex) {
                                  final imageUrl = (currentIssue['image_urls'] as List)[imgIndex];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        imageUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 60,
                                          height: 60,
                                          color: AppTheme.greyColor.withOpacity(0.3),
                                          child: Icon(Icons.broken_image, color: AppTheme.whiteColor, size: 20),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Address info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Address: ${issue['address'] ?? 'N/A'}',
                        style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return AppTheme.successColor;
      case 'in_progress':
        return AppTheme.warningColor;
      case 'pending':
        return AppTheme.infoColor;
      default:
        return AppTheme.greyColor;
    }
  }

  String _formatDate(dynamic date) {
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (date is String) {
      try {
        final parsedDate = DateTime.parse(date);
        return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
      } catch (e) {
        return 'N/A';
      }
    }
    return 'N/A';
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
        return Colors.blue;
      case 'sanitation':
        return Colors.brown;
      case 'traffic':
        return Colors.orange;
      case 'safety':
        return Colors.red;
      case 'environment':
        return Colors.green;
      case 'utilities':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'infrastructure':
        return Icons.build;
      case 'sanitation':
        return Icons.water_drop;
      case 'traffic':
        return Icons.traffic;
      case 'safety':
        return Icons.security;
      case 'environment':
        return Icons.eco;
      case 'utilities':
        return Icons.electrical_services;
      default:
        return Icons.help;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}