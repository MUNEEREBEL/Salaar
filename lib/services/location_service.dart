// lib/services/location_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static const String _geoapifyKey = 'f243a38f871e4f3ebe678518a622ce26';
  static Map<String, double>? _cachedLocation;
  static DateTime? _lastLocationTime;

  // Get current location with caching and multiple fallbacks
  static Future<Map<String, double>?> getCurrentLocation() async {
    try {
      // Return cached location if less than 5 minutes old
      if (_cachedLocation != null && _lastLocationTime != null) {
        final age = DateTime.now().difference(_lastLocationTime!);
        if (age.inMinutes < 5) {
          print('📍 Using cached location: $_cachedLocation');
          return _cachedLocation;
        }
      }

      print('📍 Getting fresh location...');
      
      // Try GPS first (fastest if available)
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 3), // 3 second timeout
        );
        
        _cachedLocation = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
        _lastLocationTime = DateTime.now();
        
        print('📍 GPS location found: $_cachedLocation');
        return _cachedLocation;
      } catch (e) {
        print('📍 GPS failed, trying IP-API: $e');
      }

      // Fallback to IP-API with timeout
      final response = await http.get(
        Uri.parse('http://ip-api.com/json/'),
      ).timeout(Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success') {
          final lat = data['lat']?.toDouble();
          final lon = data['lon']?.toDouble();
          
          if (lat != null && lon != null) {
            _cachedLocation = {
              'latitude': lat,
              'longitude': lon,
            };
            _lastLocationTime = DateTime.now();
            
            print('📍 IP-API location found: $_cachedLocation');
            return _cachedLocation;
          }
        }
      }
      
      // Final fallback
      print('📍 Using fallback location (Bangalore)');
      _cachedLocation = {
        'latitude': 12.9716,
        'longitude': 77.5946,
      };
      _lastLocationTime = DateTime.now();
      return _cachedLocation;
      
    } catch (e) {
      print('📍 All location methods failed: $e, using fallback');
      _cachedLocation = {
        'latitude': 12.9716,
        'longitude': 77.5946,
      };
      _lastLocationTime = DateTime.now();
      return _cachedLocation;
    }
  }

  // Get address from coordinates using Geoapify
  static Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      print('🏠 Getting address for: $lat, $lng');
      final response = await http.get(
        Uri.parse('https://api.geoapify.com/v1/geocode/reverse?lat=$lat&lon=$lng&apiKey=$_geoapifyKey')
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🏠 Reverse geocode result: $result');
        
        if (result['features'] != null && result['features'].isNotEmpty) {
          final address = result['features'][0]['properties']['formatted'] ?? 'Unknown location';
          print('🏠 Address found: $address');
          return address;
        }
      }
      
      final fallbackAddress = 'Location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      print('🏠 Using fallback address: $fallbackAddress');
      return fallbackAddress;
    } catch (e) {
      print('🏠 Address error: $e');
      return 'Location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }

  // Search locations by query using Geoapify
  static Future<List<Map<String, dynamic>>> searchLocation(String query) async {
    try {
      print('🔍 Searching locations for: $query');
      final response = await http.get(
        Uri.parse('https://api.geoapify.com/v1/geocode/search?text=$query&apiKey=$_geoapifyKey&limit=10')
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('🔍 Search results: ${result['features']?.length} found');
        
        List<Map<String, dynamic>> locations = [];
        
        if (result['features'] != null) {
          for (var feature in result['features']) {
            final props = feature['properties'];
            locations.add({
              'address': props['formatted'],
              'lat': props['lat'],
              'lon': props['lon'],
              'city': props['city'],
              'country': props['country'],
            });
          }
        }
        
        print('🔍 Returning ${locations.length} locations');
        return locations;
      }
      
      print('🔍 No results found');
      return [];
    } catch (e) {
      print('🔍 Location search error: $e');
      return [];
    }
  }
}