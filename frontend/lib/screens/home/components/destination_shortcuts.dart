import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DestinationShortcuts extends StatelessWidget {
  final Function(LatLng) onShortcutSelected;

  const DestinationShortcuts({
    Key? key,
    required this.onShortcutSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Quick destinations',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildShortcut(
                  theme,
                  'University',
                  Icons.school,
                  Colors.blue.shade700,
                  const LatLng(44.317863, 23.803995),
                ),
                _buildShortcut(
                  theme,
                  'Park',
                  Icons.park,
                  Colors.green.shade600,
                  const LatLng(44.323022, 23.832363),
                ),
                _buildShortcut(
                  theme,
                  'Mall',
                  Icons.shopping_bag,
                  Colors.purple.shade600,
                  const LatLng(44.316494, 23.795797),
                ),
                _buildShortcut(
                  theme,
                  'Hospital',
                  Icons.local_hospital,
                  Colors.red.shade600,
                  const LatLng(44.313901, 23.816483),
                ),
                _buildShortcut(
                  theme,
                  'Market',
                  Icons.shopping_cart,
                  Colors.amber.shade700,
                  const LatLng(44.311523, 23.803779),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcut(
    ThemeData theme,
    String label,
    IconData icon,
    Color color,
    LatLng location,
  ) {
    return GestureDetector(
      onTap: () => onShortcutSelected(location),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 