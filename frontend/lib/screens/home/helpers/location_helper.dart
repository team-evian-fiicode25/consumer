import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationHelper {
  static double calculateDistanceInMeters(LatLng origin, LatLng destination) {
    const double earthRadius = 6371000;
    final double lat1 = (origin.latitude * pi) / 180;
    final double lng1 = (origin.longitude * pi) / 180;
    final double lat2 = (destination.latitude * pi) / 180;
    final double lng2 = (destination.longitude * pi) / 180;

    final double dLat = lat2 - lat1;
    final double dLng = lng2 - lng1;

    final double a = pow(sin(dLat / 2), 2) +
        cos(lat1) * cos(lat2) * pow(sin(dLng / 2), 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double calculateBearing(LatLng start, LatLng end) {
    final double lat1 = start.latitude * (pi / 180);
    final double lon1 = start.longitude * (pi / 180);
    final double lat2 = end.latitude * (pi / 180);
    final double lon2 = end.longitude * (pi / 180);
    
    final double dLon = lon2 - lon1;
    
    final double y = sin(dLon) * cos(lat2);
    final double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    
    double bearing = atan2(y, x) * (180 / pi);
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

  static Polyline createDirectionIndicator(LatLng location, double heading) {
    final double headingRadians = heading * (pi / 180);
    
    final double distance = 0.00005;
    final double lat = location.latitude + (distance * cos(headingRadians));
    final double lng = location.longitude + (distance * sin(headingRadians));
    
    return Polyline(
      polylineId: const PolylineId('direction_indicator'),
      points: [location, LatLng(lat, lng)],
      color: Colors.blue.shade900,
      width: 4,
      endCap: Cap.roundCap,
    );
  }

  static bool isTransitAppropriate(LatLng? origin, LatLng? destination) {
    if (origin == null || destination == null) {
      return true;
    }

    double distanceInMeters = calculateDistanceInMeters(origin, destination);
    return distanceInMeters > 800;
  }
  
  static bool isWalkingDistance(LatLng? origin, LatLng? destination) {
    if (origin == null || destination == null) return false;
    
    final distanceInMeters = calculateDistanceInMeters(origin, destination);
    return distanceInMeters < 800;
  }

  static double parseDistanceStringToMeters(String? distanceText) {
    if (distanceText == null) return 0;
    
    final RegExp regExp = RegExp(r'([\d.]+)\s*(km|m)');
    final match = regExp.firstMatch(distanceText);
    
    if (match != null) {
      final value = double.tryParse(match.group(1) ?? '0') ?? 0;
      final unit = match.group(2);
      
      if (unit == 'km') {
        return value * 1000;
      } else {
        return value;
      }
    }
    
    return 0;
  }
} 