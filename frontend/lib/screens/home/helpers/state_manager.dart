import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/geo_location.dart';
import '../../../core/services/maps_service.dart';
import 'location_helper.dart';
import 'navigation_helper.dart';
import 'map_ui_helper.dart';

class MapState {
  final LatLng currentLocation;
  final LatLng? destination;
  final String transportMode;
  final bool isNavigating;
  final bool isFollowing;
  final bool isLoading;
  final String? distance;
  final String? duration;
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final Set<Circle> transitStops;
  final Set<Circle> userLocationMarker;
  final List<dynamic> transitDetails;
  final int currentTransitStep;

  const MapState({
    required this.currentLocation,
    this.destination,
    required this.transportMode,
    required this.isNavigating,
    required this.isFollowing,
    required this.isLoading,
    this.distance,
    this.duration,
    required this.polylines,
    required this.markers,
    required this.transitStops,
    required this.userLocationMarker,
    required this.transitDetails,
    this.currentTransitStep = 0,
  });

  MapState copyWith({
    LatLng? currentLocation,
    LatLng? Function()? destination,
    String? transportMode,
    bool? isNavigating,
    bool? isFollowing,
    bool? isLoading,
    String? Function()? distance,
    String? Function()? duration,
    Set<Polyline>? polylines,
    Set<Marker>? markers,
    Set<Circle>? transitStops,
    Set<Circle>? userLocationMarker,
    List<dynamic>? transitDetails,
    int? currentTransitStep,
  }) {
    return MapState(
      currentLocation: currentLocation ?? this.currentLocation,
      destination: destination != null ? destination() : this.destination,
      transportMode: transportMode ?? this.transportMode,
      isNavigating: isNavigating ?? this.isNavigating,
      isFollowing: isFollowing ?? this.isFollowing,
      isLoading: isLoading ?? this.isLoading,
      distance: distance != null ? distance() : this.distance,
      duration: duration != null ? duration() : this.duration,
      polylines: polylines ?? this.polylines,
      markers: markers ?? this.markers,
      transitStops: transitStops ?? this.transitStops,
      userLocationMarker: userLocationMarker ?? this.userLocationMarker,
      transitDetails: transitDetails ?? this.transitDetails,
      currentTransitStep: currentTransitStep ?? this.currentTransitStep,
    );
  }
}

class StateManager {
  final Function(MapState) onStateUpdate;
  final MapsService mapsService;
  MapState _state;
  final BuildContext context;
  final GeoLocationService _locationService = GeoLocationService();
  Timer? _navigationTimer;
  Timer? _distanceTimer;
  Function(LatLng)? _followUserCallback;
  Function(LatLng, {double zoom})? _animateCameraToCallback;
  StreamSubscription<LatLng?>? _locationSubscription;

  final Map<String, Color> transportColors = {
    "driving": Colors.blue.shade700,
    "walking": Colors.green.shade700,
    "bicycling": Colors.orange.shade700,
    "transit": Colors.purple.shade700,
    "two_wheeler": Colors.red.shade700,
  };

  StateManager({
    required MapState initialState,
    required this.onStateUpdate,
    required this.mapsService,
    required this.context,
  }) : _state = initialState;

  Future<void> initialize() async {
    try {
      updateState((state) => state.copyWith(
        isLoading: true, 
      ));
      
      final initialLocation = await fetchInitialLocation();
      
      final userMarkers = MapUIHelper.createUserLocationMarkers(initialLocation);
      
      updateState((state) => state.copyWith(
        currentLocation: initialLocation,
        isLoading: false,
        userLocationMarker: userMarkers,
      ));
      
      _locationSubscription?.cancel();
      
      _locationSubscription = GeoLocationService.getLocationStream().listen(_onLocationUpdate);
      
      if (_animateCameraToCallback != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _animateCameraToCallback!(initialLocation, zoom: 16);
        });
      }
    } catch (e) {
      debugPrint('Error initializing state: $e');
      updateState((state) => state.copyWith(
        isLoading: false,
      ));
    }
  }

  Future<LatLng> fetchInitialLocation() async {
    try {
      final location = await GeoLocationService.getCurrentLocation();
      if (location != null) {
        return location;
      }
      return _state.currentLocation;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return _state.currentLocation;
    }
  }

  void registerCameraCallbacks({
    required Function(LatLng location, {double zoom}) animateCameraTo,
    required Function(LatLng location) followUser,
  }) {
    _animateCameraToCallback = animateCameraTo;
    _followUserCallback = followUser;
  }
  
  void _onLocationUpdate(LatLng? location) {
    if (location == null) return;
    
    final currentLocation = location;
    final userMarkers = MapUIHelper.createUserLocationMarkers(currentLocation);
    
    updateState((state) => state.copyWith(
      currentLocation: currentLocation,
      userLocationMarker: userMarkers,
    ));
    
    if (_state.isFollowing && _followUserCallback != null) {
      _followUserCallback!(currentLocation);
    }
  }

  void updateState(MapState Function(MapState currentState) updateFunction) {
    final prevIsNavigating = _state.isNavigating;
    
    _state = updateFunction(_state);
    
    onStateUpdate(_state);
  }

  Future<void> setDestination(LatLng destinationLocation) async {
    final bool isSignificantChange = _state.destination == null || 
        LocationHelper.calculateDistanceInMeters(_state.destination!, destinationLocation) > 100;
    
    updateState((state) => state.copyWith(
      isLoading: isSignificantChange,
      polylines: {},
      transitDetails: <dynamic>[],
      transitStops: <Circle>{},
      isNavigating: false,
    ));
    
    try {
      final destinationMarker = MapUIHelper.createDestinationMarker(destinationLocation);
      
      updateState((state) => state.copyWith(
        destination: () => destinationLocation,
        markers: {destinationMarker},
        isLoading: false,
      ));
      
      await updateDistanceAndTime();
    } catch (e) {
      debugPrint('Error setting destination: $e');
      updateState((state) => state.copyWith(
        isLoading: false,
      ));
    }
  }

  Future<void> _calculateRoute() async {
    if (_state.destination == null) return;
    
    final loadingTimer = Timer(const Duration(milliseconds: 700), () {
      updateState((state) => state.copyWith(
        isLoading: true,
      ));
    });
    
    bool loadingSet = false;
    
    try {
      final origin = _state.currentLocation;
      final destination = _state.destination!;
      final mode = _convertTransportModeForAPI(_state.transportMode);
      
      if (_state.transportMode == "transit") {
        final alternativeRoutes = await mapsService.getTransitAlternatives(origin, destination);
        
        loadingTimer.cancel();
        
        if (alternativeRoutes != null && alternativeRoutes.isNotEmpty) {
          List<dynamic> bestRoute = _selectBestTransitRoute(alternativeRoutes);
          
          final List<LatLng> polylinePoints = bestRoute[0];
          final List<LatLng> stopsLocations = bestRoute[1];
          List<dynamic> transitDetails = bestRoute[2];
          Map<String, dynamic> routeInfo = bestRoute[3];
          
          final Set<Circle> transitStops = {};
          for (int i = 0; i < stopsLocations.length; i++) {
            final stopLocation = stopsLocations[i];
            transitStops.add(
              Circle(
                circleId: CircleId('transit_stop_$i'),
                center: stopLocation,
                radius: 10,
                fillColor: transportColors["transit"]!.withOpacity(0.7),
                strokeWidth: 2,
                strokeColor: transportColors["transit"]!,
              ),
            );
          }
          
          transitDetails = transitDetails.map((detail) {
            if (detail is Map) {
              return {
                'line': detail['line'] ?? 'Unknown',
                'color': detail['color'] ?? 0xFF9C27B0, 
                'type': detail['type'] ?? 'Transit',
                'stops': detail['stops'] ?? '0',
                'duration': detail['duration'] ?? '? min',
                'isOnboard': detail['isOnboard'] ?? false,
              };
            } else {
              return {
                'line': 'Unknown',
                'color': 0xFF9C27B0,
                'type': 'Transit',
                'stops': '0',
                'duration': '? min',
                'isOnboard': false,
              };
            }
          }).toList();
          
          final polyline = Polyline(
            polylineId: const PolylineId('route'),
            points: polylinePoints,
            color: transportColors[_state.transportMode]!,
            width: 5,
          );
          
          updateState((state) => state.copyWith(
            polylines: {polyline},
            transitDetails: transitDetails,
            transitStops: transitStops,
            isLoading: false,
            isNavigating: true,
          ));
          loadingSet = true;
        } else {
          final response = await mapsService.getRoutePolylines(
            origin: origin,
            destination: destination,
            mode: mode,
            includeTransitDetails: true,
          );
          
          _processRegularRouteResponse(response);
        }
      } else {
        final response = await mapsService.getRoutePolylines(
          origin: origin,
          destination: destination,
          mode: mode,
          includeTransitDetails: false,
        );
        
        loadingTimer.cancel();
        
        if (response != null && 
            response.isNotEmpty && 
            response.length > 3 && 
            response[3] is Map && 
            response[3]['status'] == 'ZERO_RESULTS' && 
            _state.transportMode == 'bicycling') {
          _fallbackToTwoWheeler();
          return;
        }
        
        _processRegularRouteResponse(response);
      }
      
      await updateDistanceAndTime();
    } catch (e) {
      loadingTimer.cancel();
      
      debugPrint('Error calculating route: $e');
      updateState((state) => state.copyWith(
        isLoading: false,
      ));
      loadingSet = true;
    } finally {
      if (!loadingSet) {
        updateState((state) => state.copyWith(
          isLoading: false,
        ));
      }
    }
  }
  
  List<dynamic> _selectBestTransitRoute(List<List<dynamic>> alternatives) {
    final busRoutes = alternatives.where((route) {
      final transitDetails = route[2] as List;
      return transitDetails.any((detail) => detail is Map && detail['type'] == 'Bus');
    }).toList();
    
    final tramOrSubwayRoutes = alternatives.where((route) {
      final transitDetails = route[2] as List;
      return transitDetails.any((detail) => detail is Map && 
             (detail['type'] == 'Tram' || detail['type'] == 'Subway')) &&
             !transitDetails.any((detail) => detail is Map && detail['type'] == 'Train');
    }).toList();
    
    final trainRoutes = alternatives.where((route) {
      final transitDetails = route[2] as List;
      return transitDetails.any((detail) => detail is Map && detail['type'] == 'Train');
    }).toList();
    
    if (busRoutes.isNotEmpty) {
      busRoutes.sort((a, b) {
        final aDuration = (a[3] as Map<String, dynamic>)['totalDuration'];
        final bDuration = (b[3] as Map<String, dynamic>)['totalDuration'];
        
        if (aDuration.contains('min') && bDuration.contains('min')) {
          final aMinutes = int.tryParse(aDuration.split(' ')[0]) ?? 0;
          final bMinutes = int.tryParse(bDuration.split(' ')[0]) ?? 0;
          return aMinutes.compareTo(bMinutes);
        }
        return 0;
      });
      
      return busRoutes.first;
    }
    
    if (tramOrSubwayRoutes.isNotEmpty) {
      tramOrSubwayRoutes.sort((a, b) {
        final aDuration = (a[3] as Map<String, dynamic>)['totalDuration'];
        final bDuration = (b[3] as Map<String, dynamic>)['totalDuration'];
        
        if (aDuration.contains('min') && bDuration.contains('min')) {
          final aMinutes = int.tryParse(aDuration.split(' ')[0]) ?? 0;
          final bMinutes = int.tryParse(bDuration.split(' ')[0]) ?? 0;
          return aMinutes.compareTo(bMinutes);
        }
        return 0;
      });
      
      return tramOrSubwayRoutes.first;
    }
    
    if (trainRoutes.isNotEmpty) {
      trainRoutes.sort((a, b) {
        final aDuration = (a[3] as Map<String, dynamic>)['totalDuration'];
        final bDuration = (b[3] as Map<String, dynamic>)['totalDuration'];
        
        if (aDuration.contains('min') && bDuration.contains('min')) {
          final aMinutes = int.tryParse(aDuration.split(' ')[0]) ?? 0;
          final bMinutes = int.tryParse(bDuration.split(' ')[0]) ?? 0;
          return aMinutes.compareTo(bMinutes);
        }
        return 0;
      });
      
      return trainRoutes.first;
    }
    
    alternatives.sort((a, b) {
      final aTransfers = (a[2] as List).length;
      final bTransfers = (b[2] as List).length;
      return aTransfers.compareTo(bTransfers);
    });
    
    return alternatives.first;
  }
  
  void _processRegularRouteResponse(List<dynamic>? response) {
    if (response != null && response.isNotEmpty) {
      if (response.length > 3 && response[3] is Map && response[3]['status'] == 'ZERO_RESULTS' && _state.transportMode == 'bicycling') {
        _fallbackToTwoWheeler();
        return;
      }
      
      final List<LatLng> polylinePoints = response[0] is List<LatLng> 
          ? response[0] 
          : response[0] is List 
              ? (response[0] as List).map((point) {
                  if (point is LatLng) return point;
                  return const LatLng(0, 0);
                }).toList() 
              : <LatLng>[];
              
      if (polylinePoints.isEmpty && _state.transportMode == 'bicycling') {
        debugPrint('Empty polyline for bicycling, falling back to two_wheeler mode');
        _fallbackToTwoWheeler();
        return;
      }
      
      final Set<Circle> transitStops = {};
      List<dynamic> transitDetails = [];
      
      if (_state.transportMode == "transit" && response.length > 1) {
        if (response.length > 1 && response[1] is List) {
          for (int i = 0; i < (response[1] as List).length; i++) {
            final stopLocation = response[1][i];
            if (stopLocation is LatLng) {
              transitStops.add(
                Circle(
                  circleId: CircleId('transit_stop_$i'),
                  center: stopLocation,
                  radius: 10,
                  fillColor: transportColors["transit"]!.withOpacity(0.7),
                  strokeWidth: 2,
                  strokeColor: transportColors["transit"]!,
                ),
              );
            }
          }
        }
        
        if (response.length > 2 && response[2] is List) {
          transitDetails = response[2];
          
          transitDetails = transitDetails.map((detail) {
            if (detail is Map) {
              return {
                'line': detail['line'] ?? 'Unknown',
                'color': detail['color'] ?? 0xFF9C27B0,
                'type': detail['type'] ?? 'Transit',
                'stops': detail['stops'] ?? '0',
                'duration': detail['duration'] ?? '? min',
                'isOnboard': detail['isOnboard'] ?? false,
              };
            } else {
              return {
                'line': 'Unknown',
                'color': 0xFF9C27B0,
                'type': 'Transit',
                'stops': '0',
                'duration': '? min',
                'isOnboard': false,
              };
            }
          }).toList();
        }
      }
      
      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        points: polylinePoints,
        color: transportColors[_state.transportMode]!,
        width: 5,
      );
      
      updateState((state) => state.copyWith(
        polylines: {polyline},
        transitDetails: transitDetails,
        transitStops: transitStops,
        isLoading: false,
        isNavigating: true,
      ));
    } else {
      updateState((state) => state.copyWith(
        isLoading: false,
        isNavigating: true,
      ));
    }
  }

  Future<void> toggleNavigation() async {
    if (_state.isNavigating) {
      stopNavigation();
      return;
    }
    
    if (_state.destination == null) {
      return;
    }
    
    updateState((state) => state.copyWith(
      isFollowing: true,
      isNavigating: true,
    ));
    
    try {
      final routeResult = _calculateRoute();
      
      final loadingTimer = Timer(const Duration(milliseconds: 500), () {
        if (!_state.isLoading) {
          updateState((state) => state.copyWith(
            isLoading: true,
          ));
        }
      });
      
      await routeResult;
      
      loadingTimer.cancel();
      
      _navigationTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) async {
          if (_state.destination != null) {
            await _calculateRoute();
          }
        },
      );
      
      _distanceTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) async {
          await updateDistanceAndTime();
        },
      );
      
      if (_animateCameraToCallback != null) {
        _animateCameraToCallback!(_state.currentLocation, zoom: 18);
      }
      
      updateState((state) => state.copyWith(
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('Error starting navigation: $e');
      updateState((state) => state.copyWith(
        isLoading: false,
        isNavigating: false,
      ));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not calculate route: $e')),
      );
    }
  }

  Future<void> updateTransportMode(String mode) async {
    if (mode == _state.transportMode) return;
    
    List<dynamic> initialTransitDetails = [];
    if (mode == "transit") {
      initialTransitDetails = [
        {
          'line': 'Route',
          'color': 0xFF9C27B0,
          'type': 'Transit',
          'stops': '0',
          'duration': 'Calculating...',
          'isOnboard': false,
          'extra': ''
        }
      ];
    }
    
    updateState((state) => state.copyWith(
      transportMode: mode,
      transitDetails: initialTransitDetails,
      currentTransitStep: 0,
      polylines: {},
    ));
    
    if (_state.destination != null) {
      await updateDistanceAndTime();
    }
  }
  
  Future<bool> isTransitAvailable() async {
    if (_state.destination == null) return false;
    
    try {
      final transitResponse = await mapsService.getRoutePolylines(
        origin: _state.currentLocation,
        destination: _state.destination!,
        mode: 'transit',
        includeTransitDetails: true,
      );
      
      return transitResponse != null && 
             transitResponse.isNotEmpty && 
             transitResponse.length > 2 && 
             transitResponse[2] is List && 
             (transitResponse[2] as List).isNotEmpty;
    } catch (e) {
      debugPrint('Error checking transit availability: $e');
      return false;
    }
  }

  Future<void> updateDistanceAndTime() async {
    if (_state.destination == null) return;
    
    try {
      final result = await mapsService.getLocationTimeAndDistance(
        _state.currentLocation,
        _state.destination!,
        mode: _convertTransportModeForAPI(_state.transportMode),
      );
      
      if (result != null) {
        if (result['status'] == 'ZERO_RESULTS' && _state.transportMode == 'bicycling') {
          _fallbackToTwoWheeler();
          return;
        }
        
        updateState((state) => state.copyWith(
          distance: () => result['distance'],
          duration: () => result['duration'],
          polylines: !_state.isNavigating ? <Polyline>{} : null,
        ));
      }
    } catch (e) {
      debugPrint('Error updating distance and time: $e');
    }
  }

  String _convertTransportModeForAPI(String mode) {
    switch (mode) {
      case 'driving':
        return 'driving';
      case 'walking':
        return 'walking';
      case 'bicycling':
        return 'bicycling';
      case 'transit':
        return 'transit';
      case 'two_wheeler':
        return 'two_wheeler';
      default:
        return 'driving';
    }
  }

  void dispose() {
    _navigationTimer?.cancel();
    _navigationTimer = null;
    
    _distanceTimer?.cancel();
    _distanceTimer = null;
    
    _locationSubscription?.cancel();
    _locationSubscription = null;
    
    _followUserCallback = null;
    _animateCameraToCallback = null;
  }

  void stopNavigation() {
    _navigationTimer?.cancel();
    _navigationTimer = null;
    
    _distanceTimer?.cancel();
    _distanceTimer = null;
    
    updateState((state) => state.copyWith(
      transitDetails: <dynamic>[],
      transitStops: <Circle>{},
      polylines: <Polyline>{},
      isNavigating: false,
      currentTransitStep: 0,
    ));
    
    updateDistanceAndTime();
  }
  
  void clearDestination() {
    _navigationTimer?.cancel();
    _navigationTimer = null;
    
    _distanceTimer?.cancel();
    _distanceTimer = null;
    
    updateState((state) => state.copyWith(
      destination: () => null,
      isNavigating: false,
      isLoading: false,
      polylines: <Polyline>{},
      transitDetails: <dynamic>[],
      transitStops: <Circle>{},
      markers: <Marker>{},
      distance: () => null,
      duration: () => null,
      currentTransitStep: 0,
    ));
  }

  void _fallbackToTwoWheeler() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No bicycle routes found',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Switching to motorcycle option',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 3),
      ),
    );
    
    updateState((state) => state.copyWith(
      transportMode: 'two_wheeler',
      isLoading: false,
    ));
    
    updateDistanceAndTime();
  }
}