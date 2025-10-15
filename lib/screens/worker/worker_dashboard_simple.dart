// Temporary simple worker dashboard to fix build issues
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_complete.dart';
import '../../providers/worker_assignment_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/salaar_loading_widget.dart';
import '../dinosaur_loading_screen.dart';

class WorkerDashboardSimple extends StatefulWidget {
  const WorkerDashboardSimple({Key? key}) : super(key: key);

  @override
  State<WorkerDashboardSimple> createState() => _WorkerDashboardSimpleState();
}

class _WorkerDashboardSimpleState extends State<WorkerDashboardSimple> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final workerProvider = Provider.of<WorkerAssignmentProvider>(context, listen: false);
    await workerProvider.loadWorkerData();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderComplete>(context);
    final workerProvider = Provider.of<WorkerAssignmentProvider>(context);

    if (authProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: const Center(
          child: SalaarLoadingWidget(message: 'Loading...'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Worker Dashboard'),
        backgroundColor: AppTheme.darkBackground,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${authProvider.currentUser?.fullName ?? 'Worker'}!',
                  style: AppTheme.headlineMedium.copyWith(
                    color: AppTheme.whiteColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Worker Dashboard - Simplified Version',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.whiteColor,
                  ),
                ),
                const SizedBox(height: 20),
                if (workerProvider.isLoading)
                  const DinosaurLoadingScreen(message: 'Loading worker dashboard...', showProgress: true)
                else
                  Text(
                    'Data loaded successfully!',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.successColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
