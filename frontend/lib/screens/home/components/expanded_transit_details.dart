import 'package:flutter/material.dart';

class ExpandedTransitDetails extends StatelessWidget {
  final List<dynamic> transitDetails;
  final dynamic currentTransitStep;
  final String? totalTime;
  final VoidCallback onClose;

  const ExpandedTransitDetails({
    Key? key,
    required this.transitDetails,
    required this.currentTransitStep,
    required this.totalTime,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (transitDetails.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme),
          
          const Divider(height: 1),
          
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    _buildJourneyTimeline(theme),
                    
                    const SizedBox(height: 20),
                    
                    _buildTransitInfo(theme),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          const Icon(
            Icons.directions_transit,
            color: Colors.deepPurple,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transit Journey',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (totalTime != null)
                  Text(
                    'Total time: $totalTime',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyTimeline(ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transitDetails.length,
      itemBuilder: (context, index) {
        final detail = transitDetails[index];
        final bool isOnboard = _isCurrentlyOnBoard(detail);
        
        return _buildTimelineItem(theme, detail, isOnboard, index);
      },
    );
  }

  Widget _buildTimelineItem(ThemeData theme, dynamic detail, bool isOnboard, int index) {
    if (detail is! Map) return const SizedBox.shrink();
    
    final String type = detail['type']?.toString() ?? 'Transit';
    final String line = detail['line']?.toString() ?? 'Unknown';
    final String duration = detail['duration']?.toString() ?? '?';
    final String from = detail['from']?.toString() ?? 'Stop';
    final String to = detail['to']?.toString() ?? 'Destination';
    
    final Color lineColor = detail.containsKey('color') && detail['color'] is int
        ? Color(detail['color'] as int)
        : Colors.purple;
        
    final bool isFirstItem = index == 0;
    final bool isLastItem = index == transitDetails.length - 1;
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  duration,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isOnboard ? Colors.green.shade600 : lineColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getTransitTypeIcon(type),
                  color: Colors.white,
                  size: 10,
                ),
              ),
              if (!isLastItem)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFirstItem)
                  Text(
                    'From: $from',
                    style: theme.textTheme.bodyMedium,
                  ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOnboard ? Colors.green.shade600 : lineColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        line,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isOnboard)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.directions_transit,
                              size: 10,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ON BOARD',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'To: $to',
                  style: theme.textTheme.bodyMedium,
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitInfo(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transit Information',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.eco,
                color: Colors.green.shade600,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Eco-friendly option',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Public transport reduces carbon emissions compared to driving.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This route has ${transitDetails.length} transit segments.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  bool _isCurrentlyOnBoard(dynamic detail) {
    if (currentTransitStep == null || detail == null) return false;
    if (!(detail is Map) || !(currentTransitStep is Map)) return false;
    
    if (currentTransitStep['isOnboard'] == true) {
      final String? detailLine = detail['line']?.toString();
      final String? currentLine = currentTransitStep['line']?.toString();
      
      if (detailLine == null || currentLine == null) return false;
      
      return detailLine == currentLine && 
             detail['type']?.toString() == currentTransitStep['type']?.toString();
    }
    
    return false;
  }

  IconData _getTransitTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bus':
        return Icons.directions_bus;
      case 'subway':
        return Icons.subway;
      case 'train':
        return Icons.train;
      case 'tram':
        return Icons.tram;
      default:
        return Icons.directions_transit;
    }
  }
} 