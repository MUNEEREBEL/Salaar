import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class WorkerDetailsScreen extends StatefulWidget {
  const WorkerDetailsScreen({Key? key}) : super(key: key);

  @override
  State<WorkerDetailsScreen> createState() => _WorkerDetailsScreenState();
}

class _WorkerDetailsScreenState extends State<WorkerDetailsScreen> {
  List<Map<String, dynamic>> _workers = [];
  List<Map<String, dynamic>> _departments = [];
  String _selectedDepartment = 'All';
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Load departments
      final deptResponse = await Supabase.instance.client
          .from('departments')
          .select('*')
          .eq('is_active', true)
          .order('name');

      // Load workers with department info
      final workerResponse = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('role', 'worker')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(deptResponse);
          _workers = List<Map<String, dynamic>>.from(workerResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredWorkers() {
    if (_selectedDepartment == 'All') {
      return _workers;
    }
    return _workers.where((worker) => 
      worker['department_id'] == _selectedDepartment
    ).toList();
  }

  String _getDepartmentName(String? departmentId) {
    if (departmentId == null) return 'No Department';
    final department = _departments.firstWhere(
      (dept) => dept['id'] == departmentId,
      orElse: () => {'name': 'Unknown Department'},
    );
    return department['name'] ?? 'No Department';
  }

  Future<Map<String, dynamic>> _getWorkerStats(String workerId) async {
    try {
      // Get all tasks assigned to this worker
      final allIssuesResponse = await Supabase.instance.client
          .from('issues')
          .select('id, status')
          .eq('assignee_id', workerId);
      
      final allIssues = allIssuesResponse as List;
      
      // Count by status
      final completed = allIssues.where((issue) => 
        issue['status'] == 'resolved' || issue['status'] == 'completed').length;
      
      final ongoing = allIssues.where((issue) => 
        issue['status'] == 'in_progress' || issue['status'] == 'pending').length;

      return {
        'completed': completed,
        'ongoing': ongoing,
        'total': allIssues.length,
      };
    } catch (e) {
      print('Error getting worker stats: $e');
      return {'completed': 0, 'ongoing': 0, 'total': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: AppTheme.errorColor, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        style: AppTheme.bodyLarge.copyWith(color: AppTheme.whiteColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _workers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.work_off, color: AppTheme.greyColor, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'No workers found',
                            style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create workers to see their details here',
                            style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Department Filter
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.filter_list, color: AppTheme.primaryColor),
                              const SizedBox(width: 12),
                              Text(
                                'Filter by Department:',
                                style: AppTheme.titleMedium.copyWith(
                                  color: AppTheme.whiteColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedDepartment,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: AppTheme.darkCard,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: 'All',
                                      child: Text('All Departments'),
                                    ),
                                    ..._departments.map((dept) {
                                      return DropdownMenuItem<String>(
                                        value: dept['id'],
                                        child: Text(dept['name']),
                                      );
                                    }).toList(),
                                  ],
                                  onChanged: (String? value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedDepartment = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Workers List
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadData,
                            color: AppTheme.primaryColor,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _getFilteredWorkers().length,
                              itemBuilder: (context, index) {
                                final worker = _getFilteredWorkers()[index];
                                return _buildWorkerCard(worker);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Worker Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    worker['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'W',
                    style: TextStyle(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker['full_name'] ?? 'Unknown Worker',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.whiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getDepartmentName(worker['department_id']),
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (worker['is_active'] == true) 
                        ? AppTheme.successColor.withOpacity(0.2)
                        : AppTheme.errorColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (worker['is_active'] == true) 
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    ),
                  ),
                  child: Text(
                    (worker['is_active'] == true) ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: (worker['is_active'] == true) 
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Worker Stats
            FutureBuilder<Map<String, dynamic>>(
              future: _getWorkerStats(worker['id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }

                final stats = snapshot.data ?? {'completed': 0, 'ongoing': 0, 'total': 0};
                
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Completed',
                        stats['completed'].toString(),
                        AppTheme.successColor,
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Ongoing',
                        stats['ongoing'].toString(),
                        AppTheme.warningColor,
                        Icons.work,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Total',
                        stats['total'].toString(),
                        AppTheme.primaryColor,
                        Icons.assignment,
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Worker Details
            Row(
              children: [
                Icon(Icons.email, color: AppTheme.greyColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    worker['email'] ?? 'No email',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, color: AppTheme.greyColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    worker['phone_number'] ?? 'No phone',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppTheme.greyColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Joined: ${_formatDate(worker['created_at'])}',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
