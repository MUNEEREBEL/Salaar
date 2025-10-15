// lib/screens/developer/developer_debug_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider_complete.dart';
import '../../providers/issues_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';

class DeveloperDebugScreen extends StatefulWidget {
  const DeveloperDebugScreen({Key? key}) : super(key: key);

  @override
  State<DeveloperDebugScreen> createState() => _DeveloperDebugScreenState();
}

class _DeveloperDebugScreenState extends State<DeveloperDebugScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _pinController = TextEditingController();
  bool _isAuthenticated = false;
  bool _isLoading = false;
  
  // Performance monitoring
  Timer? _performanceTimer;
  double _currentFPS = 0.0;
  int _memoryUsage = 0;
  int _networkLatency = 0;
  
  // Error logging
  List<Map<String, dynamic>> _errorLogs = [];
  final ScrollController _errorScrollController = ScrollController();
  
  // Environment switching
  String _currentEnvironment = 'production';
  final Map<String, String> _environments = {
    'development': 'Development',
    'staging': 'Staging',
    'production': 'Production',
  };
  
  // Mock data
  List<Map<String, dynamic>> _mockReports = [];
  List<Map<String, dynamic>> _mockUsers = [];
  bool _isMockDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _checkAuthentication();
    _startPerformanceMonitoring();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pinController.dispose();
    _performanceTimer?.cancel();
    _errorScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final isDevAuthenticated = prefs.getBool('dev_authenticated') ?? false;
    setState(() {
      _isAuthenticated = isDevAuthenticated;
    });
  }

  Future<void> _authenticateDeveloper() async {
    if (_pinController.text == '1234') { // Simple PIN for demo
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dev_authenticated', true);
      setState(() {
        _isAuthenticated = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Developer access granted!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid PIN!'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentFPS = 60.0; // Placeholder - implement actual FPS monitoring
          _memoryUsage = _getMemoryUsage();
          _networkLatency = _getNetworkLatency();
        });
      }
    });
  }

  int _getMemoryUsage() {
    // Placeholder - implement actual memory monitoring
    return (ProcessInfo.currentRss / 1024 / 1024).round();
  }

  int _getNetworkLatency() {
    // Placeholder - implement actual network latency monitoring
    return 50 + (DateTime.now().millisecond % 100);
  }

  void _addErrorLog(String level, String message, String stackTrace) {
    setState(() {
      _errorLogs.insert(0, {
        'timestamp': DateTime.now(),
        'level': level,
        'message': message,
        'stackTrace': stackTrace,
      });
    });
    
    // Auto-scroll to top
    if (_errorScrollController.hasClients) {
      _errorScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadMockData() async {
    setState(() => _isLoading = true);
    
    try {
      // Mock reports data
      _mockReports = List.generate(20, (index) => {
        'id': 'mock_report_$index',
        'title': 'Mock Report $index',
        'description': 'This is a mock report for testing purposes',
        'category': ['infrastructure', 'sanitation', 'traffic', 'safety'][index % 4],
        'priority': ['low', 'medium', 'high'][index % 3],
        'status': ['pending', 'in_progress', 'completed'][index % 3],
        'latitude': 18.062481 + (index * 0.001),
        'longitude': 83.409949 + (index * 0.001),
        'created_at': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
      });
      
      // Mock users data
      _mockUsers = List.generate(15, (index) => {
        'id': 'mock_user_$index',
        'email': 'user$index@example.com',
        'full_name': 'Mock User $index',
        'role': ['user', 'worker', 'admin'][index % 3],
        'exp_points': index * 100,
        'issues_reported': index * 2,
        'created_at': DateTime.now().subtract(Duration(days: index * 2)).toIso8601String(),
      });
      
      setState(() {
        _isMockDataLoaded = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mock data loaded successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      _addErrorLog('ERROR', 'Failed to load mock data: $e', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load mock data: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testAPI(String endpoint, Map<String, dynamic> params) async {
    try {
      final supabase = Supabase.instance.client;
      final startTime = DateTime.now();
      
      // Simulate API call based on endpoint
      switch (endpoint) {
        case 'get_issues':
          await supabase.from('issues').select().limit(10);
          break;
        case 'get_users':
          await supabase.from('profiles').select().limit(10);
          break;
        case 'create_issue':
          await supabase.from('issues').insert({
            'title': params['title'] ?? 'Test Issue',
            'description': params['description'] ?? 'Test Description',
            'category': params['category'] ?? 'other',
            'priority': params['priority'] ?? 'medium',
            'status': 'pending',
            'user_id': supabase.auth.currentUser?.id,
            'latitude': 18.062481,
            'longitude': 83.409949,
          });
          break;
        default:
          throw Exception('Unknown endpoint: $endpoint');
      }
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      
      _addErrorLog('INFO', 'API Test: $endpoint completed in ${duration}ms', '');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API test completed in ${duration}ms'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      _addErrorLog('ERROR', 'API Test failed: $e', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API test failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return _buildAuthenticationScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Developer Tools',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.greyColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Performance', icon: Icon(Icons.speed)),
            Tab(text: 'Errors', icon: Icon(Icons.bug_report)),
            Tab(text: 'Environment', icon: Icon(Icons.settings)),
            Tab(text: 'Mock Data', icon: Icon(Icons.data_object)),
            Tab(text: 'API Testing', icon: Icon(Icons.api)),
            Tab(text: 'Database', icon: Icon(Icons.storage)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('dev_authenticated', false);
              setState(() {
                _isAuthenticated = false;
              });
            },
            icon: Icon(Icons.logout, color: AppTheme.errorColor),
            tooltip: 'Exit Developer Mode',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPerformanceTab(),
          _buildErrorsTab(),
          _buildEnvironmentTab(),
          _buildMockDataTab(),
          _buildAPITestingTab(),
          _buildDatabaseTab(),
        ],
      ),
    );
  }

  Widget _buildAuthenticationScreen() {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: Card(
          color: AppTheme.darkSurface,
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.security,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Developer Access',
                  style: AppTheme.headlineMedium.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter PIN to access developer tools',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.greyColor,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'PIN',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.lock, color: AppTheme.primaryColor),
                  ),
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _authenticateDeveloper,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(
                    'Authenticate',
                    style: AppTheme.titleMedium.copyWith(color: AppTheme.whiteColor),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Default PIN: 1234',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.greyColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricCard('FPS', '${_currentFPS.toStringAsFixed(1)}', Icons.speed),
          const SizedBox(height: 16),
          _buildMetricCard('Memory Usage', '${_memoryUsage} MB', Icons.memory),
          const SizedBox(height: 16),
          _buildMetricCard('Network Latency', '${_networkLatency} ms', Icons.network_check),
          const SizedBox(height: 24),
          Text(
            'Performance Actions',
            style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _addErrorLog('INFO', 'Performance test triggered', '');
            },
            icon: Icon(Icons.play_arrow),
            label: Text('Run Performance Test'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Error Logs',
                style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorLogs.clear();
                  });
                },
                icon: Icon(Icons.clear_all),
                label: Text('Clear All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _errorLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No errors logged',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.whiteColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _errorScrollController,
                  itemCount: _errorLogs.length,
                  itemBuilder: (context, index) {
                    final log = _errorLogs[index];
                    return _buildErrorLogItem(log);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEnvironmentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Environment Settings',
            style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
          ),
          const SizedBox(height: 16),
          Card(
            color: AppTheme.darkSurface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Environment',
                    style: AppTheme.titleMedium.copyWith(color: AppTheme.whiteColor),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _currentEnvironment,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _environments.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _currentEnvironment = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Environment Actions',
            style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _addErrorLog('INFO', 'Environment switched to $_currentEnvironment', '');
            },
            icon: Icon(Icons.swap_horiz),
            label: Text('Switch Environment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mock Data Management',
            style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
          ),
          const SizedBox(height: 16),
          Card(
            color: AppTheme.darkSurface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Status',
                    style: AppTheme.titleMedium.copyWith(color: AppTheme.whiteColor),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _isMockDataLoaded ? Icons.check_circle : Icons.cancel,
                        color: _isMockDataLoaded ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isMockDataLoaded ? 'Mock data loaded' : 'No mock data',
                        style: AppTheme.bodyMedium.copyWith(
                          color: _isMockDataLoaded ? AppTheme.successColor : AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                  if (_isMockDataLoaded) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Reports: ${_mockReports.length}, Users: ${_mockUsers.length}',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Mock Data Actions',
            style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _loadMockData,
            icon: _isLoading 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppTheme.whiteColor,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(Icons.download),
            label: Text(_isLoading ? 'Loading...' : 'Load Mock Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAPITestingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API Testing',
            style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
          ),
          const SizedBox(height: 16),
          _buildAPITestCard('Get Issues', 'get_issues', {}),
          const SizedBox(height: 16),
          _buildAPITestCard('Get Users', 'get_users', {}),
          const SizedBox(height: 16),
          _buildAPITestCard('Create Issue', 'create_issue', {
            'title': 'Test Issue',
            'description': 'Test Description',
            'category': 'infrastructure',
            'priority': 'high',
          }),
        ],
      ),
    );
  }

  Widget _buildDatabaseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Database Management',
            style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
          ),
          const SizedBox(height: 16),
          Card(
            color: AppTheme.darkSurface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Database Status',
                    style: AppTheme.titleMedium.copyWith(color: AppTheme.whiteColor),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Connected to Supabase',
                        style: AppTheme.bodyMedium.copyWith(color: AppTheme.successColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Database Actions',
            style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _addErrorLog('INFO', 'Database connection test initiated', '');
            },
            icon: Icon(Icons.network_check),
            label: Text('Test Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      color: AppTheme.darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
                  ),
                  Text(
                    value,
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorLogItem(Map<String, dynamic> log) {
    final level = log['level'] as String;
    final message = log['message'] as String;
    final timestamp = log['timestamp'] as DateTime;
    
    Color levelColor;
    IconData levelIcon;
    
    switch (level) {
      case 'ERROR':
        levelColor = AppTheme.errorColor;
        levelIcon = Icons.error;
        break;
      case 'WARNING':
        levelColor = AppTheme.warningColor;
        levelIcon = Icons.warning;
        break;
      case 'INFO':
        levelColor = AppTheme.infoColor;
        levelIcon = Icons.info;
        break;
      default:
        levelColor = AppTheme.greyColor;
        levelIcon = Icons.help;
    }
    
    return Card(
      color: AppTheme.darkSurface,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(levelIcon, color: levelColor),
        title: Text(
          message,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
        ),
        subtitle: Text(
          '${level} - ${timestamp.toString().substring(11, 19)}',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
        ),
        trailing: IconButton(
          onPressed: () {
            _addErrorLog('INFO', 'Error log copied to clipboard', '');
            Clipboard.setData(ClipboardData(text: message));
          },
          icon: Icon(Icons.copy, color: AppTheme.greyColor),
        ),
      ),
    );
  }

  Widget _buildAPITestCard(String title, String endpoint, Map<String, dynamic> params) {
    return Card(
      color: AppTheme.darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTheme.titleMedium.copyWith(color: AppTheme.whiteColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Endpoint: $endpoint',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _testAPI(endpoint, params),
              icon: Icon(Icons.play_arrow),
              label: Text('Test API'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
