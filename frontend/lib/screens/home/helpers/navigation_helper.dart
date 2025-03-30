import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationHelper {
  static void showArrivalDialog(
    BuildContext context, {
    required Function() onClearNavigation,
    required Function() onResumeLocationUpdates,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('You have arrived'),
        content: const Text('You have reached your destination.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onClearNavigation();
              onResumeLocationUpdates();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static IconData getTransportIcon(String transportMode) {
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

  static Polyline createRoutePolyline(
    List<LatLng> points,
    String transportMode,
    Color routeColor,
  ) {
    return Polyline(
      polylineId: const PolylineId("route"),
      points: points,
      color: routeColor,
      width: transportMode == "transit" ? 6 : 5,
      patterns: transportMode == "transit" ? 
        [PatternItem.dash(30), PatternItem.gap(15)] : 
        [],
    );
  }

  static Set<Circle> createTransitStops(
    List<dynamic> stopLocations,
    Color routeColor,
  ) {
    Set<Circle> stops = {};
    
    if (stopLocations.isNotEmpty) {
      for (int i = 1; i < stopLocations.length - 1; i++) {
        final stopLocation = stopLocations[i] as LatLng;
        
        stops.add(
          Circle(
            circleId: CircleId("transit_stop_$i"),
            center: stopLocation,
            radius: 8,
            fillColor: Colors.white,
            strokeColor: routeColor,
            strokeWidth: 2,
          )
        );
      }
    }
    
    return stops;
  }

  static List<Map<String, dynamic>> parseTransitDetails(List<dynamic> transitDetails) {
    List<Map<String, dynamic>> transitInfo = [];
    
    for (var detail in transitDetails) {
      if (detail is Map<String, dynamic>) {
        transitInfo.add({
          'type': detail['type'] ?? 'Bus',
          'line': detail['line'] ?? '',
          'color': detail['color'] ?? Colors.blue.value,
          'from': detail['from'] ?? '',
          'to': detail['to'] ?? '',
          'duration': detail['duration'] ?? '',
          'stops': detail['stops'] ?? 0,
          'extra': detail['extra'] ?? '',
        });
      }
    }
    
    return transitInfo;
  }
} 