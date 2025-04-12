import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationHelper {
  static double calculateDistanceInMeters(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters
    
    final double lat1Rad = point1.latitude * (math.pi / 180);
    final double lat2Rad = point2.latitude * (math.pi / 180);
    final double lon1Rad = point1.longitude * (math.pi / 180);
    final double lon2Rad = point2.longitude * (math.pi / 180);
    
    final double dLat = lat2Rad - lat1Rad;
    final double dLon = lon2Rad - lon1Rad;
    
    final double a = math.sin(dLat/2) * math.sin(dLat/2) +
                     math.cos(lat1Rad) * math.cos(lat2Rad) * 
                     math.sin(dLon/2) * math.sin(dLon/2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
    
    return earthRadius * c;
  }
  
  /// Returns a bearing from one point to another (0-360 degrees)
  static double calculateBearing(LatLng startPoint, LatLng endPoint) {
    final double startLat = startPoint.latitude * (math.pi / 180);
    final double startLong = startPoint.longitude * (math.pi / 180);
    final double destLat = endPoint.latitude * (math.pi / 180);
    final double destLong = endPoint.longitude * (math.pi / 180);
    
    final double y = math.sin(destLong - startLong) * math.cos(destLat);
    final double x = math.cos(startLat) * math.sin(destLat) -
                     math.sin(startLat) * math.cos(destLat) * math.cos(destLong - startLong);
    
    double bearing = math.atan2(y, x) * (180 / math.pi);
    if (bearing < 0) {
      bearing += 360;
    }
    
    return bearing;
  }

  static Set<Circle> createUserLocationMarker(LatLng location) {
    return {
      Circle(
        circleId: const CircleId('user_location_background'),
        center: location,
        radius: 8,
        fillColor: Colors.white,
        strokeColor: Colors.blue.shade700,
        strokeWidth: 3,
      ),
      Circle(
        circleId: const CircleId('user_location_foreground'),
        center: location,
        radius: 4, 
        fillColor: Colors.blue.shade700,
        strokeColor: Colors.blue.shade900,
        strokeWidth: 1,
      ),
    };
  }
}