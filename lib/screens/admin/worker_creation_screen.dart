import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class WorkerCreationScreen extends StatefulWidget {
  const WorkerCreationScreen({Key? key}) : super(key: key);

  @override
  State<WorkerCreationScreen> createState() => _WorkerCreationScreenState();
}

class _WorkerCreationScreenState extends State<WorkerCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedDepartment = 'Infrastructure';
  bool _isCreating = false;

  List<Map<String, dynamic>> _departments = [];
  String? _selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    try {
      final response = await Supabase.instance.client
          .from('departments')
          .select('*')
          .eq('is_active', true)
          .order('name');

      if (mounted) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(response);
          if (_departments.isNotEmpty) {
            _selectedDepartmentId = _departments.first['id'];
          }
        });
      }
    } catch (e) {
      print('Error loading departments: $e');
    }
  }

  String _generateWorkerEmail(String name, String department) {
    final cleanName = name.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .substring(0, name.length > 10 ? 10 : name.length);
    final cleanDept = department.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return '${cleanName}_${cleanDept}@salaar.com';
  }

  Future<void> _createWorker() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final email = _generateWorkerEmail(_nameController.text, _selectedDepartment);
      final password = 'SalaarWorker@2024'; // Default password

      // Create auth user with normal signup
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': 'worker', // Set role in auth metadata
        },
      );

      if (authResponse.user != null) {
        // Get department name for display
        final selectedDept = _departments.firstWhere(
          (dept) => dept['id'] == _selectedDepartmentId,
          orElse: () => _departments.first,
        );
        
        // Create profile with worker role
        await Supabase.instance.client.from('profiles').insert({
          'id': authResponse.user!.id,
          'full_name': _nameController.text,
          'email': email,
          'phone_number': _phoneController.text,
          'role': 'worker',
          'department': selectedDept['name'],
          'department_id': _selectedDepartmentId,
          'is_active': true,
          'is_verified': true, // Set workers as verified by default
          'created_at': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Worker created successfully!'),
              backgroundColor: AppTheme.successColor,
              duration: Duration(seconds: 3),
            ),
          );

          // Reset form
          _nameController.clear();
          _phoneController.clear();
          if (_departments.isNotEmpty) {
            _selectedDepartmentId = _departments.first['id'];
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating worker: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Worker Account',
              style: AppTheme.headlineMedium.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new worker account with department assignment',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.greyColor,
              ),
            ),
            const SizedBox(height: 32),

            Card(
              color: AppTheme.darkSurface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      style: TextStyle(color: AppTheme.whiteColor),
                      onChanged: (value) {
                        // Validation will be done in _createWorker
                      },
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      style: TextStyle(color: AppTheme.whiteColor),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        // Validation will be done in _createWorker
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedDepartmentId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                      items: _departments.map((department) {
                        return DropdownMenuItem<String>(
                          value: department['id'],
                          child: Text(department['name']),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedDepartmentId = newValue;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a department';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Generated Email Preview
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generated Credentials:',
                            style: AppTheme.titleSmall.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Email: ${_generateWorkerEmail(_nameController.text, _selectedDepartment)}',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.whiteColor,
                            ),
                          ),
                          Text(
                            'Password: SalaarWorker@2024',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.greyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isCreating ? null : _createWorker,
                        icon: _isCreating 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteColor),
                              ),
                            )
                          : Icon(Icons.person_add),
                        label: Text(_isCreating ? 'Creating Worker...' : 'Create Worker'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.whiteColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
