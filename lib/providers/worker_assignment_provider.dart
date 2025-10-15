// lib/providers/worker_assignment_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/ai_service_complete.dart';

class WorkerAssignmentProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  String? _error;
  
  // Worker data
  List<Map<String, dynamic>> _availableWorkers = [];
  List<Map<String, dynamic>> _assignedTasks = [];
  List<Map<String, dynamic>> _pendingAssignments = [];
  List<Map<String, dynamic>> _completedTasks = [];
  Map<String, dynamic> _workerStats = {};
  
  // AI-powered insights
  List<Map<String, dynamic>> _aiRecommendations = [];
  Map<String, dynamic> _workloadAnalysis = {};
  List<Map<String, dynamic>> _routeOptimization = [];
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get availableWorkers => _availableWorkers;
  List<Map<String, dynamic>> get assignedTasks => _assignedTasks;
  List<Map<String, dynamic>> get pendingAssignments => _pendingAssignments;
  List<Map<String, dynamic>> get completedTasks => _completedTasks;
  Map<String, dynamic> get workerStats => _workerStats;
  List<Map<String, dynamic>> get aiRecommendations => _aiRecommendations;
  Map<String, dynamic> get workloadAnalysis => _workloadAnalysis;
  List<Map<String, dynamic>> get routeOptimization => _routeOptimization;
  
  // Load all worker assignment data
  Future<void> loadWorkerData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Load all data in parallel
      await Future.wait([
        _loadAvailableWorkers(),
        _loadAssignedTasks(),
        _loadPendingAssignments(),
        _loadCompletedTasks(),
        _loadWorkerStats(),
      ]);
      
      // Load AI insights
      await _loadAIInsights();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load worker data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load available workers
  Future<void> _loadAvailableWorkers() async {
    try {
      final workers = await _supabase
          .from('profiles')
          .select('*')
          .eq('role', 'worker')
          .order('created_at', ascending: false);
      
      _availableWorkers = List<Map<String, dynamic>>.from(workers);
    } catch (e) {
      print('Error loading available workers: $e');
      _availableWorkers = [];
    }
  }
  
  // Load assigned tasks
  Future<void> _loadAssignedTasks() async {
    try {
      final tasks = await _supabase
          .from('assignments')
          .select('''
            *,
            issues!inner(*),
            profiles!assignments_assignee_id_fkey(*)
          ''')
          .eq('status', 'assigned')
          .order('created_at', ascending: false);
      
      _assignedTasks = List<Map<String, dynamic>>.from(tasks);
    } catch (e) {
      print('Error loading assigned tasks: $e');
      _assignedTasks = [];
    }
  }
  
  // Load pending assignments
  Future<void> _loadPendingAssignments() async {
    try {
      final pending = await _supabase
          .from('issues')
          .select('*')
          .eq('status', 'pending')
          .isFilter('assignee_id', null)
          .order('created_at', ascending: false);
      
      _pendingAssignments = List<Map<String, dynamic>>.from(pending);
    } catch (e) {
      print('Error loading pending assignments: $e');
      _pendingAssignments = [];
    }
  }
  
  // Load completed tasks
  Future<void> _loadCompletedTasks() async {
    try {
      final completed = await _supabase
          .from('assignments')
          .select('''
            *,
            issues!inner(*),
            profiles!assignments_assignee_id_fkey(*)
          ''')
          .eq('status', 'completed')
          .order('updated_at', ascending: false)
          .limit(20);
      
      _completedTasks = List<Map<String, dynamic>>.from(completed);
    } catch (e) {
      print('Error loading completed tasks: $e');
      _completedTasks = [];
    }
  }
  
  // Load worker statistics
  Future<void> _loadWorkerStats() async {
    try {
      final stats = await _supabase
          .rpc('get_worker_stats');
      
      _workerStats = stats ?? {};
    } catch (e) {
      print('Error loading worker stats: $e');
      _workerStats = {
        'total_workers': _availableWorkers.length,
        'active_assignments': _assignedTasks.length,
        'pending_assignments': _pendingAssignments.length,
        'completed_today': 0,
        'average_completion_time': '2.5 hours',
      };
    }
  }
  
  // Load AI insights
  Future<void> _loadAIInsights() async {
    try {
      // Generate AI recommendations for task assignment
      final recommendations = await AIServiceComplete.generateWorkerRecommendations(
        availableWorkers: _availableWorkers,
        pendingTasks: _pendingAssignments,
        assignedTasks: _assignedTasks,
      );
      
      _aiRecommendations = recommendations['recommendations'] ?? [];
      _workloadAnalysis = recommendations['workload_analysis'] ?? {};
      _routeOptimization = recommendations['route_optimization'] ?? [];
    } catch (e) {
      print('Error loading AI insights: $e');
      _aiRecommendations = [];
      _workloadAnalysis = {};
      _routeOptimization = [];
    }
  }
  
  // Assign task to worker using AI
  Future<bool> assignTaskWithAI({
    required String taskId,
    required String workerId,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Get AI recommendation for this assignment
      final aiRecommendation = await AIServiceComplete.getAssignmentRecommendation(
        taskId: taskId,
        workerId: workerId,
        availableWorkers: _availableWorkers,
        assignedTasks: _assignedTasks,
      );
      
      // Create assignment
      final assignment = await _supabase
          .from('assignments')
          .insert({
            'issue_id': taskId,
            'assignee_id': workerId,
            'assigned_by': _supabase.auth.currentUser?.id,
            'status': 'assigned',
            'notes': notes ?? aiRecommendation['recommended_notes'],
            'ai_confidence': aiRecommendation['confidence'],
            'ai_recommendation': aiRecommendation['reason'],
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      // Update issue status
      await _supabase
          .from('issues')
          .update({
            'assignee_id': workerId,
            'status': 'in_progress',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', taskId);
      
      // Reload data
      await loadWorkerData();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to assign task: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Auto-assign tasks using AI
  Future<Map<String, dynamic>> autoAssignTasks() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Get AI recommendations for auto-assignment
      final autoAssignment = await AIServiceComplete.autoAssignTasks(
        availableWorkers: _availableWorkers,
        pendingTasks: _pendingAssignments,
        assignedTasks: _assignedTasks,
      );
      
      final assignments = autoAssignment['assignments'] ?? [];
      int successCount = 0;
      int failureCount = 0;
      
      // Execute assignments
      for (final assignment in assignments) {
        try {
          await _supabase
              .from('assignments')
              .insert({
                'issue_id': assignment['task_id'],
                'assignee_id': assignment['worker_id'],
                'assigned_by': _supabase.auth.currentUser?.id,
                'status': 'assigned',
                'notes': assignment['notes'],
                'ai_confidence': assignment['confidence'],
                'ai_recommendation': assignment['reason'],
                'created_at': DateTime.now().toIso8601String(),
              });
          
          await _supabase
              .from('issues')
              .update({
                'assignee_id': assignment['worker_id'],
                'status': 'in_progress',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', assignment['task_id']);
          
          successCount++;
        } catch (e) {
          print('Failed to assign task ${assignment['task_id']}: $e');
          failureCount++;
        }
      }
      
      // Reload data
      await loadWorkerData();
      
      _isLoading = false;
      notifyListeners();
      
      return {
        'success': true,
        'assigned_count': successCount,
        'failed_count': failureCount,
        'total_recommendations': assignments.length,
      };
    } catch (e) {
      _error = 'Failed to auto-assign tasks: $e';
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Update task status
  Future<bool> updateTaskStatus({
    required String assignmentId,
    required String status,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _supabase
          .from('assignments')
          .update({
            'status': status,
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', assignmentId);
      
      // Update issue status if completed
      if (status == 'completed') {
        final assignment = await _supabase
            .from('assignments')
            .select('issue_id')
            .eq('id', assignmentId)
            .single();
        
        await _supabase
            .from('issues')
            .update({
              'status': 'resolved',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', assignment['issue_id']);
      }
      
      // Reload data
      await loadWorkerData();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update task status: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Get worker performance analytics
  Future<Map<String, dynamic>> getWorkerAnalytics(String workerId) async {
    try {
      final analytics = await AIServiceComplete.analyzeWorkerPerformance(
        workerId: workerId,
        assignedTasks: _assignedTasks,
        completedTasks: _completedTasks,
      );
      
      return analytics;
    } catch (e) {
      return {
        'error': 'Failed to get worker analytics: $e',
        'performance_score': 0.0,
        'completion_rate': 0.0,
        'average_time': 'N/A',
        'strengths': [],
        'improvements': [],
      };
    }
  }
  
  // Refresh data
  Future<void> refreshData() async {
    await loadWorkerData();
  }
}
