import 'package:flutter/material.dart';

class TransportModeOptions extends StatelessWidget {
  final String currentMode;
  final Map<String, Color> transportColors;
  final double distanceInMeters;
  final Function(String) onModeSelected;

  const TransportModeOptions({
    super.key,
    required this.currentMode,
    required this.transportColors,
    required this.distanceInMeters,
    required this.onModeSelected,
  });

  bool _isTransitAppropriate() => distanceInMeters > 2000;
  
  bool _isWalkingRecommended() => distanceInMeters < 800;
  
  bool _isEcoFriendly(String mode) {
    return mode == "walking" || mode == "bicycling" || mode == "transit";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTransportModeButton(
              context,
              "driving",
              Icons.directions_car,
              "Drive",
            ),
            _buildTransportModeButton(
              context,
              "bicycling",
              Icons.directions_bike,
              "Bicycle",
              isEco: true,
            ),
            _buildTransportModeButton(
              context,
              "two_wheeler",
              Icons.motorcycle,
              "Bike",
            ),
            _buildTransportModeButton(
              context,
              "walking",
              Icons.directions_walk,
              "Walk",
              recommended: _isWalkingRecommended(),
              isEco: true,
            ),
            _buildTransportModeButton(
              context,
              "transit",
              Icons.directions_transit,
              "Transit",
              isEco: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportModeButton(
    BuildContext context,
    String mode,
    IconData icon,
    String label, {
    bool disabled = false,
    bool recommended = false,
    bool isEco = false,
  }) {
    final isSelected = currentMode == mode;
    final color = transportColors[mode] ?? Colors.grey;
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = (screenWidth - 40) / 5;
    
    final tooltipMessage = disabled 
        ? 'Not recommended for short distances'
        : recommended 
            ? 'Recommended for this distance'
            : isEco
                ? 'Eco-friendly option'
                : 'Tap to select';
    
    return Tooltip(
      message: tooltipMessage,
      child: Container(
        width: buttonWidth,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: OutlinedButton(
          onPressed: disabled ? null : () => onModeSelected(mode),
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected 
                ? color.withOpacity(0.1) 
                : null,
            side: BorderSide(
              color: isSelected 
                  ? color 
                  : isEco && !isSelected 
                      ? Colors.green.withOpacity(0.5)
                      : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: disabled 
                    ? Colors.grey 
                    : isSelected 
                        ? color 
                        : Colors.black87,
                size: 22,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: disabled 
                            ? Colors.grey 
                            : isSelected 
                                ? color 
                                : Colors.black87,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (isEco)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 3,
                  width: 16,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? color 
                        : Colors.green.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 