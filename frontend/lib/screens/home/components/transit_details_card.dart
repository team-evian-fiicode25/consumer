import 'package:flutter/material.dart';
import 'transit_details_modal.dart';

class TransitDetailsCard extends StatelessWidget {
  final List<dynamic> transitDetails;
  final dynamic currentTransitStep;
  final String? duration;
  final Color transitColor;
  final int currentTransitSegmentIndex;

  const TransitDetailsCard({
    Key? key,
    required this.transitDetails,
    required this.currentTransitStep,
    required this.duration,
    required this.transitColor,
    this.currentTransitSegmentIndex = -1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (transitDetails.isEmpty) return const SizedBox.shrink();

    final bool isUserOnTransit = _isCurrentlyOnAnyTransit();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUserOnTransit ? Colors.green.shade200 : Colors.grey.shade200,
          width: isUserOnTransit ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, context, isUserOnTransit),
          if (isUserOnTransit) _buildTransitProgressIndicator(theme),
          _buildTransitSegments(theme),
          _buildWalkingSegment(theme),
          _buildFooter(theme, context),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, BuildContext context, bool isOnTransit) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
      child: Row(
        children: [
          Icon(
            isOnTransit ? Icons.directions_transit : Icons.directions_bus,
            color: isOnTransit ? Colors.green.shade700 : transitColor,
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            isOnTransit ? "On Public Transport" : "Public Transport",
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isOnTransit ? Colors.green.shade700 : theme.colorScheme.onSurface,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Icon(Icons.eco, color: Colors.green.shade600, size: 10),
        ],
      ),
    );
  }

  bool _isCurrentlyOnAnyTransit() {
    if (currentTransitStep is! Map) return false;
    if (currentTransitStep['isOnboard'] == true) return true;
    for (final detail in transitDetails) {
      if (detail is Map && detail['isOnboard'] == true) return true;
    }
    return false;
  }

  Widget _buildTransitSegments(ThemeData theme) {
    List<Widget> segments = [];

    for (int i = 0; i < transitDetails.length; i++) {
      final detail = transitDetails[i];
      if (detail is! Map) continue;
      final bool isCurrentSegment = _isCurrentlyOnBoard(detail);
      segments.add(_buildTransitSegmentItem(theme, detail, isCurrentSegment));
      if (i < transitDetails.length - 1) segments.add(const SizedBox(height: 3));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: segments,
    );
  }

  bool _isCurrentlyOnBoard(dynamic detail) {
    if (currentTransitStep is! Map || detail is! Map) return false;
    if (detail['isOnboard'] == true) return true;
    if (currentTransitStep['isOnboard'] == true) {
      return (detail['line']?.toString() == currentTransitStep['line']?.toString()) &&
          (detail['type']?.toString() == currentTransitStep['type']?.toString());
    }
    return false;
  }

  Widget _buildTransitSegmentItem(ThemeData theme, dynamic detail, bool isCurrentSegment) {
    if (!detail.containsKey('line')) return const SizedBox.shrink();

    final Color segmentColor = (detail.containsKey('color') && detail['color'] is int)
        ? Color(detail['color'] as int)
        : Colors.purple;

    final String line = detail['line']?.toString() ?? 'Unknown';
    final String type = detail['type']?.toString() ?? 'Bus';
    final String stops = detail['stops']?.toString() ?? '0';
    final String segmentDuration = detail['duration']?.toString() ?? '?';

    final bool isBus = type.toLowerCase() == 'bus';
    final bool isOnboard = isCurrentSegment || _isCurrentlyOnBoard(detail);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildLineBadge(line, isBus ? Colors.green.shade700 : segmentColor, theme),
          const SizedBox(width: 5),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getTransitTypeIcon(type),
                          size: 10,
                          color: isBus ? Colors.green.shade700 : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          "$type · $stops stops",
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                            color: isBus ? Colors.green.shade700 : null,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                    if (detail['from'] != null && detail['to'] != null)
                      Text(
                        "${detail['from']} → ${detail['to']}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 8,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (isOnboard) _buildOnBoardIndicator(theme),
                  ],
                ),
                const Spacer(),
                Text(
                  segmentDuration,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineBadge(String line, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        line,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  IconData _getTransitTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bus':
        return Icons.directions_bus;
      case 'tram':
        return Icons.tram;
      case 'subway':
        return Icons.subway;
      case 'train':
        return Icons.train;
      default:
        return Icons.directions_transit;
    }
  }

  Widget _buildOnBoardIndicator(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_transit, size: 8, color: Colors.green.shade700),
          const SizedBox(width: 2),
          Text(
            'ON BOARD',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkingSegment(ThemeData theme) {
    if (_isCurrentlyOnAnyTransit()) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.directions_walk, color: Colors.orange.shade700, size: 11),
          const SizedBox(width: 5),
          Text(
            "Walk to destination",
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 9,
            ),
            maxLines: 1,
          ),
          const Spacer(),
          Text(
            "4 mins",
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              TransitDetailsModal.show(
                context,
                transitDetails: transitDetails,
                currentTransitStep: currentTransitStep,
                totalTime: duration,
              );
            },
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Details",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: transitColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 10, color: transitColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitProgressIndicator(ThemeData theme) {
    if (!_isCurrentlyOnAnyTransit()) return const SizedBox.shrink();

    double progressPercentage = 0.0;
    if (transitDetails.isNotEmpty && currentTransitSegmentIndex >= 0) {
      progressPercentage = (currentTransitSegmentIndex + 1) / transitDetails.length;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      height: 3,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(1.5),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progressPercentage,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.green.shade500],
            ),
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ),
    );
  }
}
