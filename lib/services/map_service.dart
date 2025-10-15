// lib/services/map_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapService {
  static const String _apiKey = '1d118383a0834cef99027cdc30689e5e';
  static const String _geocodingKey = 'f243a38f871e4f3ebe678518a622ce26';
  static const String _routingKey = '5c656b9e81dd4727a7f3c5578ef0b780';
  static const String _placesKey = '1a2509abcac84de6ad96a31f34b906b6';

  // Get map tile URL for flutter_map
  static String getMapTileUrl(int x, int y, int z) {
    return 'https://maps.geoapify.com/v1/tile/carto/$z/$x/$y.png?&apiKey=$_apiKey';
  }

  // Geocoding - convert address to coordinates
  static Future<Map<String, dynamic>> geocodeAddress(String address) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.geoapify.com/v1/geocode/search?text=${Uri.encodeComponent(address)}&apiKey=$_geocodingKey')
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to geocode address: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Geocoding error: $e');
    }
  }

  // Reverse geocoding - coordinates to address
  static Future<Map<String, dynamic>> reverseGeocode(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.geoapify.com/v1/geocode/reverse?lat=$lat&lon=$lon&apiKey=$_geocodingKey')
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to reverse geocode: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Reverse geocoding error: $e');
    }
  }

  // Get route between points
  static Future<Map<String, dynamic>> getRoute(List<LatLng> waypoints, {String mode = 'drive'}) async {
    try {
      final waypointsStr = waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|');
      final response = await http.get(
        Uri.parse('https://api.geoapify.com/v1/routing?waypoints=$waypointsStr&mode=$mode&apiKey=$_routingKey')
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Routing error: $e');
    }
  }

  // Get nearby places
  static Future<Map<String, dynamic>> getNearbyPlaces(String categories, double lat, double lon, double radius, {int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.geoapify.com/v2/places?categories=$categories&filter=circle:$lon,$lat,$radius&limit=$limit&apiKey=$_placesKey')
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get nearby places: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Places error: $e');
    }
  }

  // Get address from coordinates
  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      final result = await reverseGeocode(lat, lng);
      if (result['features'] != null && result['features'].isNotEmpty) {
        return result['features'][0]['properties']['formatted'] ?? 'Unknown location';
      }
      return 'Unknown location';
    } catch (e) {
      return 'Location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }
}