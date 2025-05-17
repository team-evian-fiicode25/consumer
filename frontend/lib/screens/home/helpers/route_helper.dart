import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/maps_service.dart';
import '../components/suggestion_item.dart';

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
    LatLng currentLocation, {
    String title = 'Search Destination',
  }) async {
    final TextEditingController controller = TextEditingController();
    String query = '';
    List<PlaceSuggestion> suggestions = [];
    bool isLoading = false;
    bool firstSearch = true;

    return await showModalBottomSheet<LatLng?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final contentHeight = MediaQuery.of(context).size.height * 0.85;
            
            void onSearchChanged(String text) {
              query = text;
              if (text.isEmpty) {
                setState(() {
                  suggestions = [];
                  isLoading = false;
                  firstSearch = true;
                });
                return;
              }
              
              setState(() {
                isLoading = true;
                firstSearch = false;
              });
              
              mapsService.getAutocompleteSuggestions(
                text, 
                currentLocation: currentLocation
              ).then((results) {
                if (query == text) {
                  setState(() {
                    suggestions = results;
                    isLoading = false;
                  });
                }
              }).catchError((_) {
                if (query == text) {
                  setState(() {
                    isLoading = false;
                  });
                }
              });
            }

            return Container(
              height: contentHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search location',
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: query.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    controller.clear();
                                    onSearchChanged('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: onSearchChanged,
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: !firstSearch
                          ? isLoading
                              ? Center(child: CircularProgressIndicator())
                              : suggestions.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No locations found',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: suggestions.length,
                                      itemBuilder: (context, index) {
                                        final suggestion = suggestions[index];
                                        return SuggestionItem(
                                          suggestion: suggestion,
                                          onTap: () async {
                                            final location = await mapsService.getPlaceDetails(suggestion.placeId);
                                            Navigator.of(context).pop(location);
                                          },
                                        );
                                      },
                                    )
                          : Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Start typing to search for a location',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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