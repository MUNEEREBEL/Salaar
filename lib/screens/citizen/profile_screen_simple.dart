// Temporary simple profile screen to fix build issues
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_complete.dart';
import '../../theme/app_theme.dart';
import '../../widgets/salaar_loading_widget.dart';

class ProfileScreenSimple extends StatefulWidget {
  const ProfileScreenSimple({Key? key}) : super(key: key);

  @override
  State<ProfileScreenSimple> createState() => _ProfileScreenSimpleState();
}

class _ProfileScreenSimpleState extends State<ProfileScreenSimple> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Simple data loading
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderComplete>(context);

    if (authProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: const Center(
          child: SalaarLoadingWidget(message: 'Loading...'),
        ),
      );
    }

    final user = authProvider.currentUser!;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Profile'),
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
                  'Profile - Simplified Version',
                  style: AppTheme.headlineMedium.copyWith(
                    color: AppTheme.whiteColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome, ${user.fullName}!',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.whiteColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Email: ${user.email}',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.whiteColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Role: ${user.role}',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryColor,
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
