import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

class MapUIHelper {
  static Set<Circle> createUserLocationMarkers(LatLng location) {
    return {
      Circle(
        circleId: const CircleId('user_location'),
        center: location,
        radius: 8,
        fillColor: Colors.blue.shade700,
        strokeWidth: 2,
        strokeColor: Colors.white,
      ),
      Circle(
        circleId: const CircleId('user_location_accuracy'),
        center: location,
        radius: 30,
        fillColor: Colors.blue.withOpacity(0.1),
        strokeWidth: 1,
        strokeColor: Colors.blue.withOpacity(0.3),
      ),
    };
  }
  
  static Marker createDestinationMarker(LatLng location) {
    return Marker(
      markerId: const MarkerId('destination'),
      position: location,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
  }
  
  static Set<Marker> getFilteredMarkers(Set<Marker> markers) {
    return markers.where((marker) => marker.markerId.value != 'user_direction').toSet();
  }
  
  static Widget buildLoadingIndicator(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: CircularProgressIndicator(
        color: theme.colorScheme.primary,
      ),
    );
  }

  static Widget buildMyLocationButton(
      BuildContext context, {
        required bool isFollowing,
        required double bottomOffset,
        required VoidCallback onPressed,
      }) {
    if (!isFollowing) {
      return Positioned(
        right: 16,
        bottom: bottomOffset,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.gps_fixed,
              color: Colors.blue,
            ),
            onPressed: onPressed,
            tooltip: 'My Location',
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
} 