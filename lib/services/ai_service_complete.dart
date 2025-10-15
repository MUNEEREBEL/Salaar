// lib/services/ai_service_complete.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AIServiceComplete {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // ANALYZE REPORT AND GENERATE TITLE/DESCRIPTION
  static Future<Map<String, dynamic>> analyzeReport({
    required String issueType,
    required String description,
    required String location,
  }) async {
    try {
      // Check if API key is configured
      if (!ApiConfig.isOpenAiConfigured) {
        print('⚠️ OpenAI API key not configured, using fallback analysis');
        return {
          'title': issueType,
          'description': description,
          'isDuplicate': false,
          'isInvalid': false,
          'confidence': 0.5,
          'suggestions': ['AI analysis temporarily unavailable'],
          'error': null,
        };
      }

      // Check for gibberish first
      if (_isGibberish(description)) {
        return {
          'title': issueType,
          'description': description,
          'isDuplicate': false,
          'isInvalid': true,
          'confidence': 0.1,
          'error': 'Please provide a proper description instead of random text',
          'suggestions': ['Write a clear description of the problem', 'Include specific details about the issue'],
        };
      }

      final prompt = '''
Analyze this civic issue report and provide:
1. A concise, professional title (max 50 characters)
2. An improved, clear description
3. Whether this might be a duplicate of existing reports
4. Whether this report is valid and meaningful
5. Confidence score (0.0 to 1.0)
6. Suggestions for improvement

Issue Type: $issueType
Description: $description
Location: $location

Respond in JSON format:
{
  "title": "string",
  "description": "string", 
  "isDuplicate": boolean,
  "isInvalid": boolean,
  "confidence": number,
  "suggestions": ["string1", "string2"]
}
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.getOpenAiKey()}',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        try {
          final analysis = jsonDecode(content);
          return {
            'title': analysis['title'] ?? issueType,
            'description': analysis['description'] ?? description,
            'isDuplicate': analysis['isDuplicate'] ?? false,
            'isInvalid': analysis['isInvalid'] ?? false,
            'confidence': (analysis['confidence'] ?? 0.8).toDouble(),
            'suggestions': List<String>.from(analysis['suggestions'] ?? []),
            'error': null,
          };
        } catch (e) {
          return {
            'title': issueType,
            'description': description,
            'isDuplicate': false,
            'isInvalid': false,
            'confidence': 0.5,
            'suggestions': ['Please provide more details about the issue'],
            'error': 'AI analysis completed but format was invalid',
          };
        }
      } else {
        print('OpenAI API Error: ${response.statusCode} - ${response.body}');
        return {
          'title': issueType,
          'description': description,
          'isDuplicate': false,
          'isInvalid': false,
          'confidence': 0.0,
          'suggestions': ['AI analysis temporarily unavailable'],
          'error': 'AI analysis failed. Please try again later.',
        };
      }
    } catch (e) {
      print('AI Service Error: $e');
      return {
        'title': issueType,
        'description': description,
        'isDuplicate': false,
        'isInvalid': false,
        'confidence': 0.0,
        'suggestions': ['AI analysis temporarily unavailable'],
        'error': 'An unexpected error occurred during AI analysis.',
      };
    }
  }

  // DETECT GIBBERISH TEXT
  static bool _isGibberish(String text) {
    if (text.length < 3) return false;
    
    // Check for repeated characters
    final repeatedChars = RegExp(r'(.)\1{2,}');
    if (repeatedChars.hasMatch(text)) return true;
    
    // Check for random character patterns
    final randomPattern = RegExp(r'^[a-z]{2,}[0-9]{2,}[a-z]{2,}$|^[0-9]{2,}[a-z]{2,}[0-9]{2,}$');
    if (randomPattern.hasMatch(text.toLowerCase())) return true;
    
    // Check for keyboard mashing patterns
    final keyboardMash = RegExp(r'^[qwertyuiopasdfghjklzxcvbnm]{5,}$|^[asdf]{3,}$|^[qwer]{3,}$');
    if (keyboardMash.hasMatch(text.toLowerCase())) return true;
    
    // Check for very short words with numbers
    final shortWordsWithNumbers = RegExp(r'^[a-z]{1,3}[0-9]{1,3}[a-z]{1,3}$');
    if (shortWordsWithNumbers.hasMatch(text.toLowerCase())) return true;
    
    // Check for excessive special characters
    final specialChars = text.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '');
    if (specialChars.length > text.length * 0.3) return true;
    
    // Check for meaningless character combinations
    final meaningless = RegExp(r'^[bcdfghjklmnpqrstvwxyz]{4,}$');
    if (meaningless.hasMatch(text.toLowerCase())) return true;
    
    return false;
  }

  // GENERATE SMART SUGGESTIONS
  static Future<List<String>> generateSuggestions({
    required String issueType,
    required String location,
  }) async {
    try {
      final prompt = '''
Generate 3 helpful suggestions for reporting a $issueType issue in $location.
Provide practical, actionable advice that would help citizens report this type of issue effectively.

Respond as a JSON array of strings:
["suggestion1", "suggestion2", "suggestion3"]
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.getOpenAiKey()}',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.8,
          'max_tokens': 200,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        try {
          final suggestions = jsonDecode(content);
          return List<String>.from(suggestions);
        } catch (e) {
          return _getDefaultSuggestions(issueType);
        }
      } else {
        return _getDefaultSuggestions(issueType);
      }
    } catch (e) {
      return _getDefaultSuggestions(issueType);
    }
  }

  // DEFAULT SUGGESTIONS
  static List<String> _getDefaultSuggestions(String issueType) {
    switch (issueType.toLowerCase()) {
      case 'road':
        return [
          'Take clear photos showing the road condition',
          'Include specific location details and landmarks',
          'Mention if it affects traffic or safety'
        ];
      case 'water':
        return [
          'Describe the water quality or supply issue',
          'Include photos if possible',
          'Mention how long the problem has existed'
        ];
      case 'electricity':
        return [
          'Report the exact location of the issue',
          'Include photos of damaged equipment',
          'Mention if it poses a safety risk'
        ];
      case 'waste':
        return [
          'Take photos of the waste accumulation',
          'Describe the type of waste',
          'Mention if it\'s causing health issues'
        ];
      default:
        return [
          'Provide a clear description of the problem',
          'Include photos if possible',
          'Mention the exact location and any safety concerns'
        ];
    }
  }

  // ANALYZE TRENDING ISSUES
  static Future<Map<String, dynamic>> analyzeTrendingIssues({
    required List<dynamic> issues,
    required String location,
  }) async {
    try {
      final prompt = '''
Analyze these civic issues and identify trending patterns:

Issues: ${issues.map((issue) => '${issue['issue_type']}: ${issue['description']}').join('\n')}
Location: $location

Provide analysis in JSON format:
{
  "trending_issues": [
    {
      "type": "string",
      "count": number,
      "trend": "increasing/decreasing/stable",
      "severity": "low/medium/high",
      "description": "string"
    }
  ],
  "insights": "string",
  "recommendations": ["string1", "string2"]
}
''';

      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      return {
        'trending_issues': [],
        'insights': 'Unable to analyze trending issues',
        'recommendations': ['Check local reports regularly', 'Report new issues promptly'],
      };
    }
  }

  // GENERATE SMART RECOMMENDATIONS
  static Future<Map<String, dynamic>> generateRecommendations({
    required List<dynamic> userReports,
    required String userId,
  }) async {
    try {
      final prompt = '''
Based on this user's report history, generate personalized recommendations:

User Reports: ${userReports.map((report) => '${report['issue_type']}: ${report['description']}').join('\n')}

Provide recommendations in JSON format:
{
  "recommendations": [
    {
      "type": "action/insight/tip",
      "title": "string",
      "description": "string",
      "priority": "high/medium/low",
      "action": "string"
    }
  ],
  "user_insights": "string"
}
''';

      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      return {
        'recommendations': [
          {
            'type': 'action',
            'title': 'Report New Issue',
            'description': 'Help improve your community by reporting issues',
            'priority': 'medium',
            'action': 'report_issue',
          }
        ],
        'user_insights': 'Active community member',
      };
    }
  }

  // GENERATE AREA INSIGHTS
  static Future<Map<String, dynamic>> generateAreaInsights({
    required Map<String, dynamic> areaData,
    required String location,
  }) async {
    try {
      final prompt = '''
Analyze this area data and provide insights:

Area Data: $areaData
Location: $location

Provide insights in JSON format:
{
  "overall_health": "excellent/good/fair/poor",
  "common_issues": ["string1", "string2"],
  "improvement_areas": ["string1", "string2"],
  "positive_aspects": ["string1", "string2"],
  "summary": "string"
}
''';

      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      return {
        'overall_health': 'good',
        'common_issues': ['Road maintenance', 'Public facilities'],
        'improvement_areas': ['Infrastructure', 'Public services'],
        'positive_aspects': ['Active community', 'Good reporting'],
        'summary': 'Your area is generally well-maintained with active community participation',
      };
    }
  }

  // ANALYZE NEARBY ISSUES
  static Future<Map<String, dynamic>> analyzeNearbyIssues({
    required List<dynamic> issues,
    required Map<String, double> userLocation,
  }) async {
    try {
      final prompt = '''
Analyze and prioritize these nearby issues based on proximity and severity:

Issues: ${issues.map((issue) => '${issue['issue_type']}: ${issue['description']} at ${issue['address']}').join('\n')}
User Location: ${userLocation['lat']}, ${userLocation['lng']}

Provide prioritized analysis in JSON format:
{
  "prioritized_issues": [
    {
      "id": "string",
      "title": "string",
      "distance": "string",
      "severity": "low/medium/high",
      "urgency": "low/medium/high",
      "description": "string"
    }
  ],
  "nearby_summary": "string"
}
''';

      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      return {
        'prioritized_issues': [],
        'nearby_summary': 'No nearby issues found',
      };
    }
  }

  // GENERATE WEATHER INSIGHTS
  static Future<Map<String, dynamic>> generateWeatherInsights({
    required Map<String, dynamic> weatherData,
    required String location,
  }) async {
    try {
      final prompt = '''
Analyze this weather data and provide civic insights:

Weather: $weatherData
Location: $location

Provide weather-based insights in JSON format:
{
  "weather_impact": "string",
  "recommendations": ["string1", "string2"],
  "safety_tips": ["string1", "string2"],
  "mood": "string"
}
''';

      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      return {
        'weather_impact': 'Good weather conditions for outdoor activities',
        'recommendations': ['Great day for community cleanup', 'Ideal for reporting outdoor issues'],
        'safety_tips': ['Stay hydrated', 'Use sunscreen'],
        'mood': 'pleasant',
      };
    }
  }

  // GENERATE ACTION SUGGESTIONS
  static Future<Map<String, dynamic>> generateActionSuggestions({
    required String userId,
    required Map<String, double> location,
  }) async {
    try {
      final prompt = '''
Generate personalized action suggestions for a civic engagement app user:

User ID: $userId
Location: ${location['lat']}, ${location['lng']}

Provide suggestions in JSON format:
{
  "suggestions": [
    "string1",
    "string2",
    "string3"
  ],
  "motivation": "string"
}
''';

      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      return {
        'suggestions': [
          'Report a new issue in your area',
          'Check nearby reports and updates',
          'Join community discussions',
        ],
        'motivation': 'Help make your community better!',
      };
    }
  }

  // PREDICT ISSUE SEVERITY
  static Future<Map<String, dynamic>> predictIssueSeverity({
    required String issueType,
    required String description,
    required String location,
  }) async {
    try {
      final prompt = '''
Predict the severity and priority of this civic issue:

Issue Type: $issueType
Description: $description
Location: $location

Provide prediction in JSON format:
{
  "severity": "low/medium/high",
  "confidence": number,
  "estimated_resolution_time": "string",
  "priority": "low/medium/high",
  "factors": ["string1", "string2"]
}
''';

      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      return {
        'severity': 'medium',
        'confidence': 0.5,
        'estimated_resolution_time': '2-3 days',
        'priority': 'normal',
        'factors': ['Standard issue type', 'Normal location'],
      };
    }
  }

  // GENERATE WORKER RECOMMENDATIONS
  static Future<Map<String, dynamic>> generateWorkerRecommendations({
    required List<dynamic> availableWorkers,
    required List<dynamic> pendingTasks,
    required List<dynamic> assignedTasks,
  }) async {
    try {
      final prompt = '''
Analyze worker assignment data and provide recommendations:

Available Workers: ${availableWorkers.map((w) => '${w['full_name']} (${w['id']})').join(', ')}
Pending Tasks: ${pendingTasks.map((t) => '${t['issue_type']}: ${t['description']}').join(', ')}
Assigned Tasks: ${assignedTasks.length} currently assigned

Provide recommendations in JSON format:
{
  "recommendations": [
    {
      "task_id": "string",
      "worker_id": "string",
      "reason": "string",
      "confidence": number,
      "estimated_time": "string",
      "priority": "high/medium/low"
    }
  ],
  "workload_analysis": {
    "overall_workload": "balanced/overloaded/underutilized",
    "worker_utilization": "string",
    "recommendations": ["string1", "string2"]
  },
  "route_optimization": [
    {
      "worker_id": "string",
      "optimized_route": ["task1", "task2"],
      "estimated_travel_time": "string",
      "efficiency_score": number
    }
  ]
}
''';

      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      return {
        'recommendations': [],
        'workload_analysis': {
          'overall_workload': 'balanced',
          'worker_utilization': 'Normal workload distribution',
          'recommendations': ['Monitor worker capacity', 'Balance task distribution'],
        },
        'route_optimization': [],
      };
    }
  }

  // GET ASSIGNMENT RECOMMENDATION
  static Future<Map<String, dynamic>> getAssignmentRecommendation({
    required String taskId,
    required String workerId,
    required List<dynamic> availableWorkers,
    required List<dynamic> assignedTasks,
  }) async {
    try {
      final prompt = '''
Analyze this specific task assignment:

Task ID: $taskId
Worker ID: $workerId
Available Workers: ${availableWorkers.length}
Current Assignments: ${assignedTasks.length}

Provide assignment recommendation in JSON format:
{
  "confidence": number,
  "reason": "string",
  "recommended_notes": "string",
  "estimated_completion_time": "string",
  "risk_factors": ["string1", "string2"],
  "success_probability": number
}
''';

      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      return {
        'confidence': 0.7,
        'reason': 'Standard assignment based on availability',
        'recommended_notes': 'Please complete this task as soon as possible',
        'estimated_completion_time': '2-3 hours',
        'risk_factors': ['Standard risk factors apply'],
        'success_probability': 0.8,
      };
    }
  }

  // AUTO ASSIGN TASKS
  static Future<Map<String, dynamic>> autoAssignTasks({
    required List<dynamic> availableWorkers,
    required List<dynamic> pendingTasks,
    required List<dynamic> assignedTasks,
  }) async {
    try {
      final prompt = '''
Automatically assign pending tasks to available workers:

Available Workers: ${availableWorkers.map((w) => '${w['full_name']} (${w['id']})').join(', ')}
Pending Tasks: ${pendingTasks.map((t) => '${t['id']}: ${t['issue_type']} - ${t['description']}').join(', ')}
Current Assignments: ${assignedTasks.length}

Provide auto-assignment in JSON format:
{
  "assignments": [
    {
      "task_id": "string",
      "worker_id": "string",
      "reason": "string",
      "confidence": number,
      "notes": "string",
      "priority": "high/medium/low"
    }
  ],
  "summary": "string",
  "total_assignments": number,
  "unassigned_tasks": ["string1", "string2"]
}
''';

      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      return {
        'assignments': [],
        'summary': 'Unable to generate auto-assignments',
        'total_assignments': 0,
        'unassigned_tasks': pendingTasks.map((t) => t['id'].toString()).toList(),
      };
    }
  }

  // ANALYZE WORKER PERFORMANCE
  static Future<Map<String, dynamic>> analyzeWorkerPerformance({
    required String workerId,
    required List<dynamic> assignedTasks,
    required List<dynamic> completedTasks,
  }) async {
    try {
      final prompt = '''
Analyze worker performance:

Worker ID: $workerId
Assigned Tasks: ${assignedTasks.where((t) => t['assignee_id'] == workerId).length}
Completed Tasks: ${completedTasks.where((t) => t['assignee_id'] == workerId).length}

Provide performance analysis in JSON format:
{
  "performance_score": number,
  "completion_rate": number,
  "average_completion_time": "string",
  "strengths": ["string1", "string2"],
  "improvements": ["string1", "string2"],
  "recommendations": ["string1", "string2"],
  "workload_capacity": "high/medium/low"
}
''';

      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      return {
        'performance_score': 0.75,
        'completion_rate': 0.8,
        'average_completion_time': '2.5 hours',
        'strengths': ['Reliable', 'Good communication'],
        'improvements': ['Time management', 'Technical skills'],
        'recommendations': ['Provide additional training', 'Monitor progress closely'],
        'workload_capacity': 'medium',
      };
    }
  }

  // Helper method to make HTTP requests
  static Future<Map<String, dynamic>> _makeRequest(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.getOpenAiKey()}',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.3,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'].trim();
        
        // Try to parse as JSON, fallback to simple response
        try {
          return jsonDecode(content);
        } catch (e) {
          return {'response': content};
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('AI request failed: $e');
      rethrow;
    }
  }

  // GENERATE TITLE AND DESCRIPTION
  static Future<Map<String, dynamic>> generateTitleAndDescription({
    required String issueType,
    required String description,
    required String location,
  }) async {
    try {
      final prompt = '''
Generate a title and improved description for this civic issue:

Issue Type: $issueType
Description: $description
Location: $location

Provide response in JSON format:
{
  "title": "string",
  "description": "string",
  "suggestions": ["string1", "string2"]
}
''';

      final response = await _makeRequest(prompt);
      return response;
    } catch (e) {
      return {
        'title': 'Civic Issue Report',
        'description': description,
        'suggestions': ['Add more details', 'Include specific location'],
      };
    }
  }

  // CATEGORIZE ISSUE
  static Future<String> categorizeIssue(String description) async {
    try {
      final prompt = '''
Categorize this civic issue description into one of these categories:
- Road
- Water
- Electricity
- Waste
- Public Safety
- Environment
- Other

Description: $description

Respond with just the category name.
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.getOpenAiKey()}',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.3,
          'max_tokens': 20,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final category = data['choices'][0]['message']['content'].trim();
        return category;
      } else {
        return 'Other';
      }
    } catch (e) {
      return 'Other';
    }
  }
}
