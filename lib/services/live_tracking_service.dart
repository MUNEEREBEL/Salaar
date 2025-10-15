// lib/services/live_tracking_service.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;

class LiveTrackingService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static Timer? _trackingTimer;
  static StreamController<Map<String, dynamic>> _locationStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get locationStream => _locationStreamController.stream;

  // Start live tracking for workers
  static void startLiveTracking(String workerId) {
    print('🛰️ Starting live tracking for worker: $workerId');
    
    ll.LatLng? lastPoint;
    _trackingTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      try {
        // Get current location
        final hasPermission = await _ensureLocationPermissions();
        if (!hasPermission) return;
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
        // enforce 15m threshold
        final currentPoint = ll.LatLng(pos.latitude, pos.longitude);
        if (lastPoint != null) {
          final distance = Geolocator.distanceBetween(
            lastPoint!.latitude, lastPoint!.longitude, pos.latitude, pos.longitude,
          );
          if (distance < 15) return; // skip
        }
        lastPoint = currentPoint;
        final location = {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'speed': pos.speed,
        };
        
        // Update worker location in database
        await _supabase
            .from('worker_locations')
            .upsert({
              'worker_id': workerId,
              'latitude': location['latitude'],
              'longitude': location['longitude'],
              'timestamp': DateTime.now().toIso8601String(),
              'battery_level': 85, // Simulated battery
              'accuracy': 10.0,
            });

        // Broadcast to stream
        _locationStreamController.add({
          'worker_id': workerId,
          'latitude': location['latitude'],
          'longitude': location['longitude'],
          'timestamp': DateTime.now(),
          'speed': location['speed'] ?? 0,
        });

        print('📍 Location updated: ${location['latitude']}, ${location['longitude']}');
      } catch (e) {
        print('❌ Tracking error: $e');
      }
    });
  }

  // Stop live tracking
  static void stopLiveTracking() {
    print('🛑 Stopping live tracking');
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }

  // Get worker's current location
  static Future<List<Map<String, dynamic>>> getWorkerLocations() async {
    try {
      final response = await _supabase
          .from('worker_locations')
          .select('*')
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching worker locations: $e');
      return [];
    }
  }

  // Simulate location updates
  static Future<bool> _ensureLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get route for worker to issue location
  static Future<List<Map<String, dynamic>>> getWorkerRoute(
    double startLat, 
    double startLng, 
    double endLat, 
    double endLng
  ) async {
    try {
      // Simulate route calculation
      return [
        {'lat': startLat, 'lng': startLng},
        {'lat': (startLat + endLat) / 2, 'lng': (startLng + endLng) / 2},
        {'lat': endLat, 'lng': endLng},
      ];
    } catch (e) {
      print('Route calculation error: $e');
      return [];
    }
  }

  static void dispose() {
    _trackingTimer?.cancel();
    _locationStreamController.close();
  }
}