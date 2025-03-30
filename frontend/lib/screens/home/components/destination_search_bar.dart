import 'package:flutter/material.dart';

class DestinationSearchBar extends StatelessWidget {
  final bool isNavigating;
  final VoidCallback onSearchPressed;
  final VoidCallback? onNavigationStop;

  const DestinationSearchBar({
    Key? key,
    required this.isNavigating,
    required this.onSearchPressed,
    this.onNavigationStop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 3),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, 1)
          )
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isNavigating ? null : onSearchPressed,
        borderRadius: BorderRadius.circular(20),
        child: Opacity(
          opacity: isNavigating ? 0.8 : 1.0,
          child: Row(
            children: [
              Icon(
                Icons.search, 
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isNavigating ? "Navigation active" : "Where to?",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 