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
      height: 36,
      margin: const EdgeInsets.fromLTRB(16, 1, 16, 5),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          _buildCompactShortcut(
              theme,
              "Home",
              Icons.home,
              const LatLng(44.31302218631675, 23.833631876187884)),
          const SizedBox(width: 8),
          _buildCompactShortcut(theme, "Work", Icons.work,
              const LatLng(44.314, 23.834)),
          const SizedBox(width: 8),
          _buildCompactShortcut(theme, "Gym", Icons.fitness_center,
              const LatLng(44.315, 23.835)),
          const SizedBox(width: 8),
          _buildCompactShortcut(theme, "Shopping", Icons.shopping_bag,
              const LatLng(44.316, 23.836)),
        ],
      ),
    );
  }

  Widget _buildCompactShortcut(
      ThemeData theme, String label, IconData icon, LatLng destination) {
    return InkWell(
      onTap: () => onShortcutSelected(destination),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 16,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 