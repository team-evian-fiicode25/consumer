import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationHelper {
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
} 