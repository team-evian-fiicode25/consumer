import 'package:flutter/material.dart';

class NavigationControls extends StatelessWidget {
  final bool isNavigating;
  final String? distance;
  final String? duration;
  final String transportMode;
  final Map<String, Color> transportColors;
  final VoidCallback onNavigationToggle;
  final VoidCallback? onNavigationStop;
  final VoidCallback onUpdateDistanceAndTime;

  const NavigationControls({
    super.key,
    required this.isNavigating,
    required this.distance,
    required this.duration,
    required this.transportMode,
    required this.transportColors,
    required this.onNavigationToggle,
    this.onNavigationStop,
    required this.onUpdateDistanceAndTime,
  });

  bool get _isCalculating => distance == null || distance!.isEmpty || duration == null || duration!.isEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final IconData transportIcon = _getTransportIcon();
    final Color transportColor = transportColors[transportMode] ?? theme.colorScheme.primary;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 3, 16, 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if (isNavigating) {
                if (onNavigationStop != null) {
                  onNavigationStop!();
                } else {
                  debugPrint('Warning: onNavigationStop callback is null');
                }
              } else {
                onNavigationToggle();
                if (_isCalculating) {
                  onUpdateDistanceAndTime();
                }
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isNavigating 
                    ? theme.colorScheme.error
                    : Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isNavigating 
                        ? theme.colorScheme.error.withOpacity(0.3)
                        : Colors.green.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isNavigating ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 10),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      transportIcon,
                      color: transportColor,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    _isCalculating && !isNavigating
                        ? _buildCalculatingIndicator(context)
                        : Text(
                            distance ?? "Calculating...",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              fontSize: 13,
                            ),
                          ),
                  ],
                ),
                
                const SizedBox(height: 3),
                
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: transportColor,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    _isCalculating && !isNavigating
                        ? _buildCalculatingIndicator(context)
                        : Text(
                            duration ?? "Calculating...",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              fontSize: 13,
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getTransportIcon() {
    switch (transportMode) {
      case "bicycling":
        return Icons.directions_bike;
      case "two_wheeler":
        return Icons.motorcycle;
      case "walking":
        return Icons.directions_walk;
      case "transit":
        return Icons.directions_transit;
      case "driving":
      default:
        return Icons.directions_car;
    }
  }
  
  Widget _buildCalculatingIndicator(BuildContext context) {
    return Row(
      children: [
        Text(
          "Calculating",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
          ),
        ),
        const SizedBox(
          width: 30,
          child: _DotLoadingIndicator(),
        ),
      ],
    );
  }
}

class _DotLoadingIndicator extends StatefulWidget {
  const _DotLoadingIndicator();
  
  @override
  _DotLoadingIndicatorState createState() => _DotLoadingIndicatorState();
}

class _DotLoadingIndicatorState extends State<_DotLoadingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _dotCount = 0;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat();
    
    _controller.addListener(() {
      if (_controller.value < 0.33) {
        if (_dotCount != 1) setState(() => _dotCount = 1);
      } else if (_controller.value < 0.66) {
        if (_dotCount != 2) setState(() => _dotCount = 2);
      } else {
        if (_dotCount != 3) setState(() => _dotCount = 3);
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    String dots = '';
    for (int i = 0; i < _dotCount; i++) {
      dots += '.';
    }
    
    return Text(
      dots,
      style: const TextStyle(
        fontWeight: FontWeight.bold, 
        fontSize: 13,
      ),
    );
  }
} 