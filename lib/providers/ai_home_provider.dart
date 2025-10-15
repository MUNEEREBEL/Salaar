// lib/providers/ai_home_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_service_complete.dart';

class AIHomeProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  String? _error;
  
  // AI-powered insights
  List<Map<String, dynamic>> _trendingIssues = [];
  List<Map<String, dynamic>> _smartRecommendations = [];
  Map<String, dynamic> _aiInsights = {};
  List<Map<String, dynamic>> _nearbyIssues = [];
  Map<String, dynamic> _weatherInsights = {};
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get trendingIssues => _trendingIssues;
  List<Map<String, dynamic>> get smartRecommendations => _smartRecommendations;
  Map<String, dynamic> get aiInsights => _aiInsights;
  List<Map<String, dynamic>> get nearbyIssues => _nearbyIssues;
  Map<String, dynamic> get weatherInsights => _weatherInsights;
  
  // Load AI-powered home data
  Future<void> loadAIData({
    required double latitude,
    required double longitude,
    required String userId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Load all data in parallel
      await Future.wait([
        _loadTrendingIssues(latitude, longitude),
        _loadSmartRecommendations(userId),
        _loadAIInsights(latitude, longitude),
        _loadNearbyIssues(latitude, longitude),
        _loadWeatherInsights(latitude, longitude),
      ]);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load AI data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load trending issues in user's area
  Future<void> _loadTrendingIssues(double lat, double lng) async {
    try {
      // Get recent issues in user's area (simplified for now)
      final issues = await _supabase
          .from('issues')
          .select('*')
          .order('created_at', ascending: false)
          .limit(20);
      
      // Use AI to analyze and categorize trending issues
      final analysis = await AIServiceComplete.analyzeTrendingIssues(
        issues: issues,
        location: 'User Area',
      );
      
      _trendingIssues = analysis['trending_issues'] ?? [];
    } catch (e) {
      print('Error loading trending issues: $e');
      _trendingIssues = [];
    }
  }
  
  // Load smart recommendations for user
  Future<void> _loadSmartRecommendations(String userId) async {
    try {
      // Get user's report history and preferences
      final userReports = await _supabase
          .from('issues')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(10);
      
      // Use AI to generate personalized recommendations
      final recommendations = await AIServiceComplete.generateRecommendations(
        userReports: userReports,
        userId: userId,
      );
      
      _smartRecommendations = recommendations['recommendations'] ?? [];
    } catch (e) {
      print('Error loading smart recommendations: $e');
      _smartRecommendations = [];
    }
  }
  
  // Load AI insights about the area
  Future<void> _loadAIInsights(double lat, double lng) async {
    try {
      // Get comprehensive area data (simplified for now)
      final areaData = {
        'total_issues': 0,
        'resolved_issues': 0,
        'pending_issues': 0,
        'common_issue_types': [],
        'recent_activity': [],
      };
      
      // Use AI to generate insights
      final insights = await AIServiceComplete.generateAreaInsights(
        areaData: areaData,
        location: 'User Area',
      );
      
      _aiInsights = insights;
    } catch (e) {
      print('Error loading AI insights: $e');
      _aiInsights = {};
    }
  }
  
  // Load nearby issues with AI analysis
  Future<void> _loadNearbyIssues(double lat, double lng) async {
    try {
      // Get nearby issues (simplified for now)
      final issues = await _supabase
          .from('issues')
          .select('*')
          .order('created_at', ascending: false)
          .limit(10);
      
      // Use AI to prioritize and categorize nearby issues
      final analysis = await AIServiceComplete.analyzeNearbyIssues(
        issues: issues,
        userLocation: {'lat': lat, 'lng': lng},
      );
      
      _nearbyIssues = analysis['prioritized_issues'] ?? [];
    } catch (e) {
      print('Error loading nearby issues: $e');
      _nearbyIssues = [];
    }
  }
  
  // Load weather insights with AI analysis
  Future<void> _loadWeatherInsights(double lat, double lng) async {
    try {
      // Get weather data (you can integrate with a weather API)
      final weatherData = {
        'temperature': 25,
        'condition': 'Sunny',
        'humidity': 60,
        'location': 'Vizianagaram, India',
      };
      
      // Use AI to generate weather-based insights
      final insights = await AIServiceComplete.generateWeatherInsights(
        weatherData: weatherData,
        location: 'User Area',
      );
      
      _weatherInsights = insights;
    } catch (e) {
      print('Error loading weather insights: $e');
      _weatherInsights = {};
    }
  }
  
  // Refresh AI data
  Future<void> refreshAIData({
    required double latitude,
    required double longitude,
    required String userId,
  }) async {
    await loadAIData(
      latitude: latitude,
      longitude: longitude,
      userId: userId,
    );
  }
  
  // Get AI-powered issue prediction
  Future<Map<String, dynamic>> predictIssueSeverity({
    required String issueType,
    required String description,
    required String location,
  }) async {
    try {
      return await AIServiceComplete.predictIssueSeverity(
        issueType: issueType,
        description: description,
        location: location,
      );
    } catch (e) {
      return {
        'severity': 'medium',
        'confidence': 0.5,
        'estimated_resolution_time': '2-3 days',
        'priority': 'normal',
      };
    }
  }
  
  // Get AI-powered suggestions for user actions
  Future<List<String>> getActionSuggestions({
    required String userId,
    required double lat,
    required double lng,
  }) async {
    try {
      final suggestions = await AIServiceComplete.generateActionSuggestions(
        userId: userId,
        location: {'lat': lat, 'lng': lng},
      );
      
      return suggestions['suggestions'] ?? [];
    } catch (e) {
      return [
        'Report a new issue in your area',
        'Check nearby reports and updates',
        'Join community discussions',
      ];
    }
  }
}
