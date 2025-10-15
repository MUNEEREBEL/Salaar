// lib/screens/maintenance_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/maintenance_service.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({Key? key}) : super(key: key);

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  String _message = 'Server is under maintenance. Please try again later.';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaintenanceMessage();
  }

  Future<void> _loadMaintenanceMessage() async {
    try {
      final message = await MaintenanceService.getMaintenanceMessage();
      setState(() {
        _message = message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    try {
      final isMaintenance = await MaintenanceService.isMaintenanceMode();
      if (!isMaintenance) {
        // Maintenance mode is off, restart app or navigate to main screen
        Navigator.pushReplacementNamed(context, '/');
      } else {
        // Still in maintenance, refresh message
        await _loadMaintenanceMessage();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Maintenance Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.warningColor, AppTheme.primaryColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.warningColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.build,
                  size: 60,
                  color: AppTheme.whiteColor,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Under Maintenance',
                style: AppTheme.headlineLarge.copyWith(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Message
              if (_isLoading)
                CircularProgressIndicator(color: AppTheme.primaryColor)
              else
                Text(
                  _message,
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.greyColor,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              
              const SizedBox(height: 48),
              
              // Check Status Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _checkStatus,
                  icon: _isLoading 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppTheme.whiteColor,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.refresh, color: AppTheme.whiteColor),
                  label: Text(
                    _isLoading ? 'Checking...' : 'Check Status',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // App Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SALAAR Reporter',
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.whiteColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'We are working hard to improve your experience',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.greyColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
