import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapUIHelper {
  static Widget buildMyLocationButton(
    BuildContext context, {
    required bool isFollowing,
    required double bottomOffset,
    required Function() onPressed,
  }) {
    final theme = Theme.of(context);
    
    return Positioned(
      right: 16,
      bottom: bottomOffset,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Icon(
              Icons.my_location,
              color: theme.colorScheme.onPrimary,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
  
  static Widget buildLoadingIndicator(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: CircularProgressIndicator(
        color: theme.colorScheme.primary,
      ),
    );
  }
  
  static Marker createDestinationMarker(LatLng position, {String? title}) {
    return Marker(
      markerId: const MarkerId('destination'),
      position: position,
      infoWindow: InfoWindow(
        title: title ?? 'Destination',
        snippet: "Tap to start navigation",
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
  }
  
  static Circle createUserLocationMarker(LatLng position) {
    return Circle(
      circleId: const CircleId('user_location'),
      center: position,
      radius: 8,
      fillColor: Colors.blue.shade600.withOpacity(0.7),
      strokeWidth: 3,
      strokeColor: Colors.white,
    );
  }
  
  static Set<Circle> createUserLocationMarkers(LatLng location) {
    return {
      Circle(
        circleId: const CircleId('user_location_outer'),
        center: location,
        radius: 30,
        fillColor: Colors.blue.withOpacity(0.15),
        strokeWidth: 0,
        consumeTapEvents: false,
        visible: true,
        zIndex: 1,
      ),
      Circle(
        circleId: const CircleId('user_location_middle'),
        center: location,
        radius: 18,
        fillColor: Colors.blue.withOpacity(0.3),
        strokeWidth: 0,
        consumeTapEvents: false,
        visible: true,
        zIndex: 2,
      ),
      Circle(
        circleId: const CircleId('user_location_inner'),
        center: location,
        radius: 8,
        fillColor: Colors.blue,
        strokeWidth: 3,
        strokeColor: Colors.white,
        consumeTapEvents: false,
        visible: true,
        zIndex: 3,
      ),
    };
  }
  
  static Set<Marker> getFilteredMarkers(Set<Marker> markers) {
    return markers.where((marker) => marker.markerId.value != 'user_direction').toSet();
  }
} 