// lib/screens/admin/batch_worker_assignment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_complete.dart';
import '../../providers/issues_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';

class BatchWorkerAssignmentScreen extends StatefulWidget {
  const BatchWorkerAssignmentScreen({Key? key}) : super(key: key);

  @override
  State<BatchWorkerAssignmentScreen> createState() => _BatchWorkerAssignmentScreenState();
}

class _BatchWorkerAssignmentScreenState extends State<BatchWorkerAssignmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SalaarUser> _allWorkers = [];
  List<SalaarUser> _selectedWorkers = [];
  List<Map<String, dynamic>> _allReports = [];
  List<Map<String, dynamic>> _filteredReports = [];
  bool _isLoading = false;
  String _selectedArea = '';
  String _selectedCategory = '';
  String _selectedPriority = '';
  
  final List<String> _areas = [
    'Downtown',
    'Residential Area A',
    'Residential Area B',
    'Industrial Zone',
    'Commercial District',
    'Suburbs',
  ];
  
  final List<String> _categories = [
    'infrastructure',
    'sanitation',
    'traffic',
    'safety',
    'environment',
    'utilities',
  ];
  
  final List<String> _priorities = [
    'low',
    'medium',
    'high',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load workers
      final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
      // This is a placeholder - implement based on your user loading logic
      _allWorkers = [];
      
      // Load reports
      final issuesProvider = Provider.of<IssuesProvider>(context, listen: false);
      await issuesProvider.fetchAllIssues();
      _allReports = issuesProvider.issues.map((issue) => {
        'id': issue.id,
        'title': issue.title,
        'description': issue.description,
        'category': issue.category,
        'priority': issue.priority,
        'status': issue.status,
        'latitude': issue.latitude,
        'longitude': issue.longitude,
        'address': issue.address,
        'created_at': issue.createdAt,
      }).toList();
      
      _filteredReports = _allReports;
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterReports() {
    setState(() {
      _filteredReports = _allReports.where((report) {
        final matchesArea = _selectedArea.isEmpty || 
            (report['address'] as String?)?.toLowerCase().contains(_selectedArea.toLowerCase()) ?? false;
        final matchesCategory = _selectedCategory.isEmpty || 
            report['category'] == _selectedCategory;
        final matchesPriority = _selectedPriority.isEmpty || 
            report['priority'] == _selectedPriority;
        final matchesSearch = _searchController.text.isEmpty ||
            (report['title'] as String?)?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false;
        
        return matchesArea && matchesCategory && matchesPriority && matchesSearch;
      }).toList();
    });
  }

  void _toggleWorkerSelection(SalaarUser worker) {
    setState(() {
      if (_selectedWorkers.contains(worker)) {
        _selectedWorkers.remove(worker);
      } else {
        _selectedWorkers.add(worker);
      }
    });
  }

  Future<void> _assignSelectedReports() async {
    if (_selectedWorkers.isEmpty || _filteredReports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select workers and reports to assign'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      // This is a placeholder - implement actual assignment logic
      await Future.delayed(const Duration(seconds: 2));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully assigned ${_filteredReports.length} reports to ${_selectedWorkers.length} workers'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      
      // Clear selections
      setState(() {
        _selectedWorkers.clear();
        _filteredReports.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign reports: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Batch Worker Assignment',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : Column(
              children: [
                // Filters Section
                _buildFiltersSection(),
                
                // Summary Section
                _buildSummarySection(),
                
                // Content Section
                Expanded(
                  child: Row(
                    children: [
                      // Workers Section
                      Expanded(
                        flex: 1,
                        child: _buildWorkersSection(),
                      ),
                      
                      // Reports Section
                      Expanded(
                        flex: 2,
                        child: _buildReportsSection(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.darkSurface,
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (value) => _filterReports(),
            decoration: InputDecoration(
              hintText: 'Search reports...',
              prefixIcon: Icon(Icons.search, color: AppTheme.greyColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.greyColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.greyColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
          ),
          
          const SizedBox(height: 16),
          
          // Filter Dropdowns
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedArea.isEmpty ? null : _selectedArea,
                  decoration: InputDecoration(
                    labelText: 'Area',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _areas.map((area) {
                    return DropdownMenuItem(
                      value: area,
                      child: Text(area),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedArea = value ?? '';
                    });
                    _filterReports();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory.isEmpty ? null : _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value ?? '';
                    });
                    _filterReports();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPriority.isEmpty ? null : _selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _priorities.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(priority.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value ?? '';
                    });
                    _filterReports();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.darkCard,
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Selected Workers',
              '${_selectedWorkers.length}',
              Icons.people,
              AppTheme.primaryColor,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Filtered Reports',
              '${_filteredReports.length}',
              Icons.assignment,
              AppTheme.infoColor,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Total Reports',
              '${_allReports.length}',
              Icons.list,
              AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          children: [
            Text(
              value,
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Workers',
            style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _allWorkers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppTheme.greyColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No workers available',
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.whiteColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _allWorkers.length,
                    itemBuilder: (context, index) {
                      final worker = _allWorkers[index];
                      final isSelected = _selectedWorkers.contains(worker);
                      
                      return Card(
                        color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.darkSurface,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: CheckboxListTile(
                          title: Text(
                            worker.fullName ?? 'Unknown Worker',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.whiteColor,
                            ),
                          ),
                          subtitle: Text(
                            worker.email,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.greyColor,
                            ),
                          ),
                          value: isSelected,
                          onChanged: (value) => _toggleWorkerSelection(worker),
                          activeColor: AppTheme.primaryColor,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Reports to Assign',
                style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _assignSelectedReports,
                icon: Icon(Icons.assignment_turned_in),
                label: Text('Assign Selected'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredReports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: AppTheme.greyColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No reports match the filters',
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.whiteColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredReports.length,
                    itemBuilder: (context, index) {
                      final report = _filteredReports[index];
                      return _buildReportCard(report);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Card(
      color: AppTheme.darkSurface,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    report['title'] ?? 'Untitled Report',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.whiteColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(report['priority']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getPriorityColor(report['priority']).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    (report['priority'] ?? 'medium').toUpperCase(),
                    style: AppTheme.bodySmall.copyWith(
                      color: _getPriorityColor(report['priority']),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report['description'] ?? 'No description',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.greyColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getCategoryIcon(report['category']),
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  (report['category'] ?? 'other').toUpperCase(),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(report['created_at']),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'low':
        return AppTheme.successColor;
      default:
        return AppTheme.greyColor;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'infrastructure':
        return Icons.construction;
      case 'sanitation':
        return Icons.delete;
      case 'traffic':
        return Icons.traffic;
      case 'safety':
        return Icons.security;
      case 'environment':
        return Icons.eco;
      case 'utilities':
        return Icons.lightbulb;
      default:
        return Icons.info;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
