// lib/services/geoapify_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// Use your actual Geoapify Key
const String geoapifyApiKey = '1d118383a0834cef99027cdc30689e5e';
const String geoapifyBaseUrl = 'https://api.geoapify.com/v1';

class GeoapifyService {
  
  static Future<Map<String, dynamic>> fetchWeather(LatLng location) async {
    try {
      // Using OpenWeatherMap API (free tier)
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${location.latitude}&lon=${location.longitude}&appid=YOUR_OPENWEATHER_API_KEY&units=metric'
      );
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final main = json['main'] as Map<String, dynamic>;
        final weather = json['weather'][0] as Map<String, dynamic>;
        
        return {
          'temp': '${main['temp'].round()}°C',
          'status': weather['main'],
          'symbol': _getWeatherSymbol(weather['main']),
          'description': weather['description'],
        };
      }
    } catch (e) {
      print('Error fetching weather: $e');
    }
    
    // Fallback to mock data
    return {
      'temp': '25°C',
      'status': 'Sunny',
      'symbol': '☀️',
      'description': 'Clear sky',
    };
  }

  static String _getWeatherSymbol(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'snow':
        return '❄️';
      case 'thunderstorm':
        return '⛈️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
        '$geoapifyBaseUrl/routing?waypoints=${start.latitude},${start.longitude}|${end.latitude},${end.longitude}&mode=drive&apiKey=$geoapifyApiKey'
      );
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // Parse the route coordinates from response
        // This is a simplified implementation
        return [start, end];
      }
      return [start, end];
    } catch (e) {
      print('Error fetching route: $e');
      return [start, end];
    }
  }

  static Future<String> reverseGeocode(LatLng location) async {
    try {
      final url = Uri.parse(
        '$geoapifyBaseUrl/geocode/reverse?lat=${location.latitude}&lon=${location.longitude}&apiKey=$geoapifyApiKey'
      );
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final features = json['features'] as List;
        if (features.isNotEmpty) {
          return features[0]['properties']['formatted'] as String? ?? 'Unknown Area';
        }
      }
      return 'Unknown Area';
    } catch (e) {
      print('Error in reverse geocoding: $e');
      return 'Unknown Area';
    }
  }

  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    try {
      final url = Uri.parse(
        '$geoapifyBaseUrl/geocode/search?text=${Uri.encodeComponent(query)}&apiKey=$geoapifyApiKey&limit=5'
      );
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final features = json['features'] as List;
        
        return features.map<Map<String, dynamic>>((feature) {
          final properties = feature['properties'] as Map<String, dynamic>;
          final geometry = feature['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List;
          
          return {
            'name': properties['name'] ?? properties['formatted'],
            'formatted': properties['formatted'],
            'lat': coordinates[1] as double,
            'lon': coordinates[0] as double,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }
}