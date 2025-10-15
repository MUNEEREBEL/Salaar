// lib/services/comprehensive_permission_service.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';

class ComprehensivePermissionService {
  static final ComprehensivePermissionService _instance = ComprehensivePermissionService._internal();
  factory ComprehensivePermissionService() => _instance;
  ComprehensivePermissionService._internal();

  // Permission status tracking
  Map<Permission, PermissionStatus> _permissionStatuses = {};

  /// Request all necessary permissions for the app
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final service = ComprehensivePermissionService();
    
    // Core permissions - only request location when in use
    final permissions = [
      Permission.locationWhenInUse, // Only request location while using app
      Permission.camera,
      Permission.photos,
      Permission.storage,
      Permission.notification,
    ];

    Map<Permission, PermissionStatus> results = {};
    
    for (Permission permission in permissions) {
      try {
        final status = await permission.request();
        results[permission] = status;
        service._permissionStatuses[permission] = status;
        
        print('Permission ${permission.toString()}: $status');
      } catch (e) {
        print('Error requesting ${permission.toString()}: $e');
        results[permission] = PermissionStatus.denied;
        service._permissionStatuses[permission] = PermissionStatus.denied;
      }
    }

    return results;
  }

  /// Check if location permissions are granted
  static Future<bool> hasLocationPermission() async {
    final service = ComprehensivePermissionService();
    
    final locationStatus = await Permission.location.status;
    final locationWhenInUseStatus = await Permission.locationWhenInUse.status;
    
    service._permissionStatuses[Permission.location] = locationStatus;
    service._permissionStatuses[Permission.locationWhenInUse] = locationWhenInUseStatus;
    
    return locationStatus.isGranted || locationWhenInUseStatus.isGranted;
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    final service = ComprehensivePermissionService();
    
    final cameraStatus = await Permission.camera.status;
    service._permissionStatuses[Permission.camera] = cameraStatus;
    
    return cameraStatus.isGranted;
  }

  /// Check if storage permission is granted
  static Future<bool> hasStoragePermission() async {
    final service = ComprehensivePermissionService();
    
    final storageStatus = await Permission.storage.status;
    final photosStatus = await Permission.photos.status;
    
    service._permissionStatuses[Permission.storage] = storageStatus;
    service._permissionStatuses[Permission.photos] = photosStatus;
    
    return storageStatus.isGranted || photosStatus.isGranted;
  }

  /// Check if notification permission is granted
  static Future<bool> hasNotificationPermission() async {
    final service = ComprehensivePermissionService();
    
    final notificationStatus = await Permission.notification.status;
    service._permissionStatuses[Permission.notification] = notificationStatus;
    
    return notificationStatus.isGranted;
  }

  /// Request location permission specifically
  static Future<bool> requestLocationPermission() async {
    final service = ComprehensivePermissionService();
    
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled');
      return false;
    }

    // Request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return false;
    }

    return true;
  }

  /// Request camera permission specifically
  static Future<bool> requestCameraPermission() async {
    final service = ComprehensivePermissionService();
    
    final status = await Permission.camera.request();
    service._permissionStatuses[Permission.camera] = status;
    
    return status.isGranted;
  }

  /// Request storage permission specifically
  static Future<bool> requestStoragePermission() async {
    final service = ComprehensivePermissionService();
    
    final storageStatus = await Permission.storage.request();
    final photosStatus = await Permission.photos.request();
    
    service._permissionStatuses[Permission.storage] = storageStatus;
    service._permissionStatuses[Permission.photos] = photosStatus;
    
    return storageStatus.isGranted || photosStatus.isGranted;
  }

  /// Request notification permission specifically
  static Future<bool> requestNotificationPermission() async {
    final service = ComprehensivePermissionService();
    
    final status = await Permission.notification.request();
    service._permissionStatuses[Permission.notification] = status;
    
    return status.isGranted;
  }

  /// Show permission dialog with explanation
  static Future<void> showPermissionDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onGranted,
    VoidCallback? onDenied,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Row(
            children: [
              const Icon(Icons.security, color: Color(0xFFD4AF37)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDenied?.call();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onGranted();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              child: const Text('Grant Permission'),
            ),
          ],
        );
      },
    );
  }

  /// Check if all essential permissions are granted
  static Future<bool> hasAllEssentialPermissions() async {
    final hasLocation = await hasLocationPermission();
    final hasCamera = await hasCameraPermission();
    final hasStorage = await hasStoragePermission();
    final hasNotification = await hasNotificationPermission();
    
    return hasLocation && hasCamera && hasStorage && hasNotification;
  }

  /// Get permission status for a specific permission
  static PermissionStatus? getPermissionStatus(Permission permission) {
    final service = ComprehensivePermissionService();
    return service._permissionStatuses[permission];
  }

  /// Open app settings for permission management
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Check if we can proceed with location-based features
  static Future<bool> canUseLocationFeatures() async {
    return await hasLocationPermission() && await Geolocator.isLocationServiceEnabled();
  }

  /// Check if we can proceed with camera features
  static Future<bool> canUseCameraFeatures() async {
    return await hasCameraPermission();
  }

  /// Check if we can proceed with storage features
  static Future<bool> canUseStorageFeatures() async {
    return await hasStoragePermission();
  }

  /// Get user-friendly permission status message
  static String getPermissionStatusMessage(Permission permission) {
    final service = ComprehensivePermissionService();
    final status = service._permissionStatuses[permission];
    
    switch (status) {
      case PermissionStatus.granted:
        return 'Permission granted';
      case PermissionStatus.denied:
        return 'Permission denied';
      case PermissionStatus.permanentlyDenied:
        return 'Permission permanently denied. Please enable in settings.';
      case PermissionStatus.restricted:
        return 'Permission restricted';
      case PermissionStatus.limited:
        return 'Permission limited';
      case PermissionStatus.provisional:
        return 'Permission provisional';
      default:
        return 'Permission status unknown';
    }
  }
}
