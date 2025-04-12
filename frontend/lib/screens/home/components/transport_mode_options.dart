import 'package:flutter/material.dart';

class TransportModeOptions extends StatefulWidget {
  final String currentMode;
  final Map<String, Color> transportColors;
  final Function(String) onModeSelected;
  final double distanceInMeters;
  final Map<String, bool>? availableModes;
  final Map<String, Map<String, String>>? modeEstimates;

  const TransportModeOptions({
    Key? key,
    required this.currentMode,
    required this.transportColors,
    required this.onModeSelected,
    this.distanceInMeters = 0,
    this.availableModes,
    this.modeEstimates,
  }) : super(key: key);

  @override
  State<TransportModeOptions> createState() => _TransportModeOptionsState();
}

class _TransportModeOptionsState extends State<TransportModeOptions> {
  late Map<String, bool> _availableModes;

  @override
  void initState() {
    super.initState();
    _updateAvailableModes();
  }

  @override
  void didUpdateWidget(covariant TransportModeOptions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.distanceInMeters != widget.distanceInMeters ||
        oldWidget.availableModes != widget.availableModes) {
      _updateAvailableModes();
    }
  }

  void _updateAvailableModes() {
    _availableModes = {
      'driving': true,
      'walking': true,
      'bicycling': true,
      'transit': true,
      'two_wheeler': true,
      'ridesharing': true,
    };

    if (widget.availableModes != null) {
      _availableModes.addAll(widget.availableModes!);
    }
  }

  String? _formatDuration(Map<String, String>? estimate) {
    if (estimate == null || estimate['duration'] == null || estimate['duration']!.isEmpty) {
      return null;
    }
    final durationText = estimate['duration']!;
    if (durationText == "Not available") return null;

    final parts = durationText.split(' ');
    if (parts.length >= 2) {
      if (parts[1].contains('min')) {
        return '${parts[0]} min';
      }
      return durationText.length > 8 ? durationText.substring(0, 8) : durationText;
    }
    return durationText;
  }

  String _unavailableMessage(String mode, String label, Map<String, String>? estimate) {
    if (mode == 'bicycling' &&
        estimate != null &&
        estimate['duration'] == 'Not available' &&
        estimate['status'] == 'ZERO_RESULTS') {
      return 'Route not available for bicycling';
    }
    return 'No routes available for $label mode';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildModeOption(theme, 'walking', 'Walk', Icons.directions_walk,
              widget.transportColors['walking'] ?? Colors.green.shade700,
              estimate: widget.modeEstimates?['walking']),
          _buildModeOption(theme, 'transit', 'Transit', Icons.directions_transit,
              widget.transportColors['transit'] ?? Colors.purple.shade700,
              estimate: widget.modeEstimates?['transit']),
          _buildModeOption(theme, 'bicycling', 'Bike', Icons.directions_bike,
              widget.transportColors['bicycling'] ?? Colors.orange.shade700,
              estimate: widget.modeEstimates?['bicycling']),
          _buildModeOption(theme, 'ridesharing', 'Ride', Icons.local_taxi,
              widget.transportColors['ridesharing'] ?? Colors.green.shade700),
          _buildModeOption(theme, 'two_wheeler', 'Motorcycle', Icons.two_wheeler,
              widget.transportColors['two_wheeler'] ?? Colors.red.shade700,
              estimate: widget.modeEstimates?['two_wheeler']),
          _buildModeOption(theme, 'driving', 'Car', Icons.directions_car,
              widget.transportColors['driving'] ?? Colors.blue.shade700,
              estimate: widget.modeEstimates?['driving']),
        ],
      ),
    );
  }

  Widget _buildModeOption(
      ThemeData theme,
      String mode,
      String label,
      IconData icon,
      Color color, {
        Map<String, String>? estimate,
      }) {
    final bool isSelected = widget.currentMode == mode;
    final bool isAvailable = _availableModes[mode] ?? true;
    final Color displayColor = isAvailable
        ? (isSelected ? color : Colors.grey.shade700)
        : Colors.grey.shade400;
    final String? duration = _formatDuration(estimate);
    final String unavailableMsg = _unavailableMessage(mode, label, estimate);

    return GestureDetector(
      onTap: isAvailable
          ? () => widget.onModeSelected(mode)
          : () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(unavailableMsg),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        height: 90,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected && isAvailable ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected && isAvailable ? color : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? displayColor.withOpacity(isSelected ? 0.15 : 0.1)
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: displayColor, size: 24),
                ),
                if (!isAvailable)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    child: const Center(
                      child: Icon(Icons.not_interested, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected && isAvailable ? FontWeight.bold : FontWeight.normal,
                  color: isAvailable ? displayColor : Colors.grey.shade400,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (duration != null && isAvailable)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  duration,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: isSelected ? displayColor : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
