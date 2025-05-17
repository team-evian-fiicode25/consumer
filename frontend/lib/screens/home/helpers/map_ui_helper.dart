import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    final filteredMarkers = markers.where((marker) => marker.markerId.value != 'user_direction').toSet();

    return enhanceMarkerInfoWindows(filteredMarkers);
  }

  static Set<Marker> enhanceMarkerInfoWindows(Set<Marker> markers) {
    return markers.map((marker) {
      if (marker.markerId.value == 'destination' ||
          marker.markerId.value == 'user_location') {
        return marker;
      }

      return marker.copyWith(
        consumeTapEventsParam: false,
        visibleParam: true,
        zIndexParam: 2,
        flatParam: false,
        draggableParam: false,
      );
    }).toSet();
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
        required double bottomOffset,
        required VoidCallback onPressed,
      }) {
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

  static Widget buildReportIncidentButton(
      BuildContext context, {
        required double bottomOffset,
        required VoidCallback onPressed,
      }) {
    return Positioned(
      right: 16,
      bottom: bottomOffset,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.report,
            color: Colors.white,
          ),
          onPressed: onPressed,
          tooltip: 'Report Incident',
        ),
      ),
    );
  }

  static Widget buildAirQualityButton(
      BuildContext context, {
        required double bottomOffset,
        required VoidCallback onPressed,
        required bool isActive,
        VoidCallback? onLongPress,
      }) {
    return Positioned(
      right: 16,
      bottom: bottomOffset,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.green.shade500 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_outlined,
                    color: isActive ? Colors.white : Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Air',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.green.shade700,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}