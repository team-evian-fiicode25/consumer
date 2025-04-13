import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/back_button.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/settings/settings_bloc.dart';

class SettingsOptionsPage extends StatefulWidget {
  const SettingsOptionsPage({super.key});

  @override
  State<SettingsOptionsPage> createState() => _SettingsOptionsPageState();
}

class _SettingsOptionsPageState extends State<SettingsOptionsPage> {
  // TODO (mihaescuvlad): Extract into something
  // Maybe a constant class which extrands this class to keep it clean
  // Or a separate global constants file
  // Or Reader Monad pattern
  final List<String> _distanceUnits = ['Kilometers', 'Miles'];
  final List<String> _transportMethods = ['Car', 'Public Transit', 'Bicycle', 'Walking'];
  final List<String> _themeModes = ['Light', 'Dark', 'System'];

  String _getThemeModeString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  ThemeMode _getThemeModeFromString(String themeModeString) {
    switch (themeModeString) {
      case 'Light':
        return ThemeMode.light;
      case 'Dark':
        return ThemeMode.dark;
      case 'System':
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: CustomBackButton(path: "settings"),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          if (settingsState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              final currentThemeMode = _getThemeModeString(themeState.themeMode);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'General Settings'),
                    const SizedBox(height: 16),
                    
                    // TODO (mihaescuvlad): Discuss saved locations functionality
                    _buildNavigationCard(
                      context,
                      icon: Icons.location_on,
                      title: 'Saved Locations',
                      description: 'Manage your favorite and saved places',
                      onTap: () {
                        debugPrint('Navigate to saved locations');
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader(context, 'Map & Navigation'),
                    const SizedBox(height: 16),
                    
                    _buildSwitchTile(
                      context,
                      icon: Icons.traffic,
                      title: 'Traffic Updates',
                      subtitle: 'Show real-time traffic information on the map',
                      value: settingsState.showTrafficUpdates,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(TrafficUpdatesChanged(value));
                        _showSettingSavedSnackbar('Traffic updates');
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildDropdownTile(
                      context,
                      icon: Icons.straighten,
                      title: 'Distance Units',
                      value: settingsState.distanceUnit,
                      items: _distanceUnits,
                      onChanged: (value) {
                        if (value != null) {
                          context.read<SettingsBloc>().add(DistanceUnitChanged(value));
                          _showSettingSavedSnackbar('Distance unit');
                        }
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildDropdownTile(
                      context,
                      icon: Icons.directions_car,
                      title: 'Preferred Transport',
                      value: settingsState.preferredTransport,
                      items: _transportMethods,
                      onChanged: (value) {
                        if (value != null) {
                          context.read<SettingsBloc>().add(PreferredTransportChanged(value));
                          _showSettingSavedSnackbar('Preferred transport');
                        }
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader(context, 'Appearance'),
                    const SizedBox(height: 16),
                    
                    _buildDropdownTile(
                      context,
                      icon: Icons.palette,
                      title: 'Theme',
                      value: currentThemeMode,
                      items: _themeModes,
                      onChanged: (value) {
                        if (value != null) {
                          context.read<ThemeBloc>().add(
                            ThemeChanged(_getThemeModeFromString(value))
                          );
                          
                          _showSettingSavedSnackbar('Theme');
                        }
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader(context, 'Notifications'),
                    const SizedBox(height: 16),
                    
                    _buildSwitchTile(
                      context,
                      icon: Icons.notifications,
                      title: 'Enable Notifications',
                      subtitle: 'Receive updates and alerts about your rides',
                      value: settingsState.enableNotifications,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(NotificationsChanged(value));
                        _showSettingSavedSnackbar('Notifications');
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader(context, 'Privacy'),
                    const SizedBox(height: 16),
                    
                    _buildSwitchTile(
                      context,
                      icon: Icons.history,
                      title: 'Location History',
                      subtitle: 'Save your ride history for easier access',
                      value: settingsState.enableLocationHistory,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(LocationHistoryChanged(value));
                        _showSettingSavedSnackbar('Location history');
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSwitchTile(
                      context,
                      icon: Icons.volume_up,
                      title: 'Sound Effects',
                      subtitle: 'Play sounds for notifications and app events',
                      value: settingsState.enableSoundEffects,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(SoundEffectsChanged(value));
                        _showSettingSavedSnackbar('Sound effects');
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildSectionHeader(context, 'About'),
                    const SizedBox(height: 16),
                    
                    // TODO (mihaescuvlad): Find a way to fetch the app version dynamically
                    _buildNavigationCard(
                      context,
                      icon: Icons.info,
                      title: 'App Information',
                      description: 'Version 0.1.1 (Build 2025.03.22)',
                      onTap: () {
                        _showAppInfoDialog(context);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showSettingSavedSnackbar(String settingName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$settingName updated'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
  
  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 40.0),
          child: Text(subtitle),
        ),
        activeColor: theme.colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  Widget _buildDropdownTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                style: theme.textTheme.bodyMedium,
                dropdownColor: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                items: items.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavigationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showAppInfoDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'App Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Version', '1.0.0'),
            _buildInfoRow('Build Date', 'March 22, 2025'),
            _buildInfoRow('Developer', 'FIICODE Team'),
            _buildInfoRow('Contact', 'support@fiicode.com'),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}