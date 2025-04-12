import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'dart:async';

class GeoLocationService {
  static Position? _lastKnownPosition;

  static Future<LatLng?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    _lastKnownPosition = position;
    return LatLng(position.latitude, position.longitude);
  }
  
  static Stream<LatLng?> getLocationStream({bool highAccuracy = true}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
        distanceFilter: highAccuracy ? 5 : 10,
      ),
    ).map((Position position) {
      _lastKnownPosition = position;
      return LatLng(position.latitude, position.longitude);
    });
  }
  
  static Future<bool> checkAndRequestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }
}
