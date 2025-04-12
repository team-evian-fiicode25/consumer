import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/maps_service.dart';
import '../maps_search_delegate.dart';
import 'location_helper.dart';

class RouteHelper {
  static Future<void> animateCameraTo(
    Completer<GoogleMapController> mapController,
    LatLng location, {
    double zoom = 16,
  }) async {
    final GoogleMapController controller = await mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: zoom),
      ),
    );
  }

  static Future<void> followUser(
    Completer<GoogleMapController> mapController,
    LatLng location,
  ) async {
    try {
      final GoogleMapController controller = await mapController.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: await controller.getZoomLevel(),
        ),
      ));
    } catch (e) {
      debugPrint('Error following user: $e');
    }
  }

  static Future<LatLng?> searchAndSelectDestination(
    BuildContext context,
    MapsService mapsService,
    LatLng currentLocation,
  ) async {
    final String? selectedQuery = await showSearch<String?>(
      context: context,
      delegate: MapsSearchDelegate(
        mapsService: mapsService,
        currentLocation: currentLocation,
      ),
    );
    
    if (selectedQuery != null && selectedQuery.isNotEmpty) {
      return await mapsService.searchPlace(selectedQuery);
    }
    
    return null;
  }
}

class SearchPageDelegate extends SearchDelegate<String?> {
  final MapsService mapsService;
  final LatLng currentLocation;

  SearchPageDelegate({
    required this.mapsService,
    required this.currentLocation,
  });

  @override
  List<Widget> buildActions(BuildContext context) => [];

  @override
  Widget buildLeading(BuildContext context) => Container();

  @override
  Widget buildResults(BuildContext context) => Container();

  @override
  Widget buildSuggestions(BuildContext context) => Container();
} 