import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

typedef WaypointCallback = Function(int index);
typedef ReorderWaypointsCallback = Function(int oldIndex, int newIndex);
typedef AddWaypointCallback = Function();

class WaypointsEditor extends StatelessWidget {
  final List<LatLng> waypoints;
  final List<String> waypointNames;
  final WaypointCallback onWaypointRemoved;
  final ReorderWaypointsCallback onWaypointsReordered;
  final AddWaypointCallback onAddWaypoint;

  const WaypointsEditor({
    super.key,
    required this.waypoints,
    required this.waypointNames,
    required this.onWaypointRemoved,
    required this.onWaypointsReordered,
    required this.onAddWaypoint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Trip Waypoints",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: onAddWaypoint,
                icon: Icon(Icons.add_location, size: 18),
                label: Text("Add Waypoint"),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        if (waypoints.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "No waypoints in your trip yet. Add waypoints to create a multi-stop journey.",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ] else ...[
          Container(
            height: 150,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              onReorder: onWaypointsReordered,
              itemCount: waypoints.length,
              itemBuilder: (context, index) {
                return _buildWaypointCard(context, index);
              },
              proxyDecorator: (child, index, animation) {
                return Material(
                  elevation: 4,
                  child: child,
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWaypointCard(BuildContext context, int index) {
    final isLastWaypoint = index == waypoints.length - 1;
    final waypointName = index < waypointNames.length 
        ? waypointNames[index] 
        : "Waypoint ${index + 1}";
    
    return Container(
      key: ValueKey('waypoint_$index'),
      width: 160,
      margin: EdgeInsets.only(left: 12, right: index == waypoints.length - 1 ? 12 : 0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isLastWaypoint ? Colors.red.shade300 : Colors.blue.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: isLastWaypoint ? Colors.red.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      isLastWaypoint ? "Final Stop" : "Waypoint ${index + 1}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isLastWaypoint ? Colors.red.shade700 : Colors.blue.shade700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: isLastWaypoint ? Colors.red.shade700 : Colors.blue.shade700,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    onPressed: () => onWaypointRemoved(index),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLastWaypoint ? Icons.place : Icons.adjust,
                      color: isLastWaypoint ? Colors.red : Colors.blue,
                    ),
                    SizedBox(height: 4),
                    Text(
                      waypointName,
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.drag_indicator,
                    size: 16,
                    color: Colors.grey,
                  ),
                  isLastWaypoint
                      ? Icon(Icons.flag, size: 16, color: Colors.red)
                      : Text(
                          "Stop ${index + 1}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 