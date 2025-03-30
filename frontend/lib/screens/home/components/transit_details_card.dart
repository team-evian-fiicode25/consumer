import 'package:flutter/material.dart';

class TransitDetailsCard extends StatelessWidget {
  final List<dynamic> transitDetails;
  
  final dynamic currentTransitStep;
  
  final String? duration;
  
  final Color transitColor;

  const TransitDetailsCard({
    Key? key,
    required this.transitDetails,
    required this.currentTransitStep,
    required this.duration,
    required this.transitColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (transitDetails.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          
          _buildTransitSegments(theme),
          
          _buildWalkingSegment(theme),
          
          _buildFooter(theme),
        ],
      ),
    );
  }
  
  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      child: Row(
        children: [
          Icon(
            Icons.directions_bus,
            color: transitColor,
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            "Public Transport",
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.eco,
            color: Colors.green.shade600,
            size: 10,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTransitSegments(ThemeData theme) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transitDetails.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.grey.shade200,
        indent: 25,
        endIndent: 10,
      ),
      itemBuilder: (context, index) {
        final detail = transitDetails[index];
        
        final bool isOnboard = _isCurrentlyOnBoard(detail);
        
        return _buildTransitSegmentItem(theme, detail, isOnboard);
      },
    );
  }
  
  bool _isCurrentlyOnBoard(dynamic detail) {
    if (currentTransitStep == null || detail == null) return false;
    if (!(detail is Map) || !(currentTransitStep is Map)) return false;
    
    final String? detailLine = detail['line']?.toString();
    final String? currentLine = currentTransitStep['line']?.toString();
    
    if (detailLine == null || currentLine == null) return false;
    
    return detailLine == currentLine && 
           currentTransitStep['isOnboard'] == true;
  }
  
  Widget _buildTransitSegmentItem(ThemeData theme, dynamic detail, bool isOnboard) {
    if (detail is! Map || !detail.containsKey('line')) {
      return const SizedBox.shrink();
    }
    
    final Color segmentColor = detail.containsKey('color') && detail['color'] is int 
        ? Color(detail['color'] as int) 
        : Colors.purple;
        
    final String line = detail['line']?.toString() ?? 'Unknown';
    
    final String type = detail['type']?.toString() ?? 'Bus';
    final String stops = detail['stops']?.toString() ?? '0';
    
    final String segmentDuration = detail['duration']?.toString() ?? '?';
    
    final bool isBus = type == 'Bus';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: isBus ? Colors.green.shade700 : segmentColor,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              line,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(width: 5),
          
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    if (isOnboard)
                      _buildOnBoardIndicator(theme),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        "ON BOARD",
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.green.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 7,
        ),
      ),
    );
  }
  
  Widget _buildWalkingSegment(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_walk,
            color: Colors.orange.shade700,
            size: 11,
          ),
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
  
  Widget _buildFooter(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            duration != null ? "Total: $duration" : "Calculating...",
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: transitColor,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
} 