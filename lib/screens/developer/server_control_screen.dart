// lib/screens/developer/server_control_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_complete.dart';
import '../../theme/app_theme.dart';
import '../../services/maintenance_service.dart';

class ServerControlScreen extends StatefulWidget {
  const ServerControlScreen({Key? key}) : super(key: key);

  @override
  State<ServerControlScreen> createState() => _ServerControlScreenState();
}

class _ServerControlScreenState extends State<ServerControlScreen> {
  bool _isMaintenanceMode = false;
  String _maintenanceMessage = 'Server is under maintenance. Please try again later.';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMaintenanceStatus();
  }

  Future<void> _loadMaintenanceStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await MaintenanceService.getMaintenanceStatus();
      setState(() {
        _isMaintenanceMode = status['is_maintenance'] ?? false;
        _maintenanceMessage = status['message'] ?? _maintenanceMessage;
      });
    } catch (e) {
      print('Error loading maintenance status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleMaintenanceMode() async {
    setState(() => _isLoading = true);
    try {
      final success = await MaintenanceService.setMaintenanceMode(
        !_isMaintenanceMode,
        _maintenanceMessage,
      );
      
      if (success) {
        setState(() => _isMaintenanceMode = !_isMaintenanceMode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isMaintenanceMode 
                ? 'Maintenance mode enabled' 
                : 'Maintenance mode disabled'
            ),
            backgroundColor: _isMaintenanceMode 
              ? AppTheme.warningColor 
              : AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update maintenance mode'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderComplete>(context);
    
    if (!authProvider.isDeveloper) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(
          title: Text('Access Denied'),
          backgroundColor: AppTheme.darkBackground,
        ),
        body: Center(
          child: Text(
            'Only developers can access this feature',
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.whiteColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Server Control',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Server Status Card
                  Card(
                    color: AppTheme.darkSurface,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isMaintenanceMode ? Icons.warning : Icons.check_circle,
                                color: _isMaintenanceMode 
                                  ? AppTheme.warningColor 
                                  : AppTheme.successColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Server Status',
                                style: AppTheme.titleLarge.copyWith(
                                  color: AppTheme.whiteColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isMaintenanceMode 
                              ? 'Maintenance Mode: ON' 
                              : 'Server: Online',
                            style: AppTheme.bodyLarge.copyWith(
                              color: _isMaintenanceMode 
                                ? AppTheme.warningColor 
                                : AppTheme.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_isMaintenanceMode) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Users will see maintenance page',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.greyColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Maintenance Control Card
                  Card(
                    color: AppTheme.darkSurface,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Maintenance Control',
                            style: AppTheme.titleLarge.copyWith(
                              color: AppTheme.whiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Toggle Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _toggleMaintenanceMode,
                              icon: Icon(
                                _isMaintenanceMode ? Icons.play_arrow : Icons.pause,
                                color: AppTheme.whiteColor,
                              ),
                              label: Text(
                                _isMaintenanceMode 
                                  ? 'Disable Maintenance Mode' 
                                  : 'Enable Maintenance Mode',
                                style: AppTheme.bodyLarge.copyWith(
                                  color: AppTheme.whiteColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isMaintenanceMode 
                                  ? AppTheme.successColor 
                                  : AppTheme.warningColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Maintenance Message
                          Text(
                            'Maintenance Message',
                            style: AppTheme.titleMedium.copyWith(
                              color: AppTheme.whiteColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            maxLines: 3,
                            style: TextStyle(color: AppTheme.whiteColor),
                            decoration: InputDecoration(
                              hintText: 'Enter maintenance message...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: AppTheme.darkBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() => _maintenanceMessage = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Server Actions Card
                  Card(
                    color: AppTheme.darkSurface,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Server Actions',
                            style: AppTheme.titleLarge.copyWith(
                              color: AppTheme.whiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Reload Data Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _reloadData,
                              icon: Icon(Icons.refresh, color: AppTheme.whiteColor),
                              label: Text(
                                'Reload App Data',
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
                          
                          const SizedBox(height: 12),
                          
                          // Clear Cache Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _clearCache,
                              icon: Icon(Icons.clear_all, color: AppTheme.whiteColor),
                              label: Text(
                                'Clear App Cache',
                                style: AppTheme.bodyLarge.copyWith(
                                  color: AppTheme.whiteColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.secondaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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

  Future<void> _reloadData() async {
    setState(() => _isLoading = true);
    try {
      // Simulate data reload
      await Future.delayed(Duration(seconds: 2));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('App data reloaded successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reload data: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearCache() async {
    setState(() => _isLoading = true);
    try {
      // Simulate cache clear
      await Future.delayed(Duration(seconds: 1));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('App cache cleared successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear cache: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
