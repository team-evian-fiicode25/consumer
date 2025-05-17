import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

typedef WaypointCallback = Function(int index);
typedef ReorderWaypointsCallback = Function(int oldIndex, int newIndex);
typedef AddWaypointCallback = Function();
typedef SearchDestinationCallback = Function();
typedef StartNavigationCallback = Function();

class TripPlanner extends StatelessWidget {
  final List<LatLng> waypoints;
  final List<String> waypointNames;
  final LatLng currentLocation;
  final WaypointCallback onWaypointRemoved;
  final ReorderWaypointsCallback onWaypointsReordered;
  final AddWaypointCallback onAddWaypoint;
  final SearchDestinationCallback onSearchDestination;
  final StartNavigationCallback onStartNavigation;
  final bool isLoading;

  const TripPlanner({
    Key? key,
    required this.waypoints,
    required this.waypointNames,
    required this.currentLocation,
    required this.onWaypointRemoved,
    required this.onWaypointsReordered,
    required this.onAddWaypoint,
    required this.onSearchDestination,
    required this.onStartNavigation,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Your Trip",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: waypoints.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildStartPoint(context);
              }
              
              final waypointIndex = index - 1;
              return _buildWaypointItem(context, waypointIndex);
            },
            onReorder: (oldIndex, newIndex) {
              if (oldIndex == 0 || newIndex == 0) {
                return;
              }
              
              final adjustedOldIndex = oldIndex - 1;
              final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex - 1;
              
              onWaypointsReordered(adjustedOldIndex, adjustedNewIndex);
            },
            footer: _buildAddButton(),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: ElevatedButton.icon(
            onPressed: waypoints.isNotEmpty ? onStartNavigation : null,
            icon: isLoading 
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(Icons.navigation),
            label: Text("Start Navigation"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStartPoint(BuildContext context) {
    return Container(
      key: ValueKey('start_point'),
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            alignment: Alignment.center,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.green.shade200),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.my_location, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Current Location",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWaypointItem(BuildContext context, int index) {
    final isLastWaypoint = index == waypoints.length - 1;
    final waypointName = index < waypointNames.length 
        ? waypointNames[index] 
        : "Waypoint ${index + 1}";
        
    return Container(
      key: ValueKey('waypoint_$index'),
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 12,
                child: Center(
                  child: Container(
                    width: 2,
                    height: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              Container(
                width: 24,
                alignment: Alignment.center,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLastWaypoint ? Colors.red : Colors.blue,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
              if (!isLastWaypoint)
                Container(
                  width: 24,
                  height: 12,
                  child: Center(
                    child: Container(
                      width: 2,
                      height: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isLastWaypoint ? Colors.red.shade200 : Colors.blue.shade200,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isLastWaypoint ? Icons.place : Icons.flag,
                          size: 18,
                          color: isLastWaypoint ? Colors.red : Colors.blue,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            waypointName,
                            style: TextStyle(
                              fontWeight: isLastWaypoint ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 16),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => onWaypointRemoved(index),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          ReorderableDragStartListener(
            index: index + 1,
            child: Icon(Icons.drag_indicator, color: Colors.grey, size: 16),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: onAddWaypoint,
      child: Container(
        margin: EdgeInsets.only(top: 4, left: 36, right: 24, bottom: 8),
        child: Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Colors.blue.shade200, 
              width: 1,
              style: BorderStyle.solid,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, size: 18, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  "Add destination",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 