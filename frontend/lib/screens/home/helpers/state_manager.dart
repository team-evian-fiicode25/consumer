import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/services/air_quality_service.dart';
import '../../../core/services/geo_location.dart';
import '../../../core/services/incidents_service.dart';
import '../../../core/services/maps_service.dart';
import '../../../core/services/external_apps_service.dart';
import 'location_helper.dart';
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
  final dynamic currentTransitStep;
  final Set<TileOverlay> tileOverlays;
  final bool showAirQuality;

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
    this.currentTransitStep,
    this.tileOverlays = const {},
    this.showAirQuality = false,
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
    dynamic currentTransitStep,
    Set<TileOverlay>? tileOverlays,
    bool? showAirQuality,
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
      tileOverlays: tileOverlays ?? this.tileOverlays,
      showAirQuality: showAirQuality ?? this.showAirQuality,
    );
  }
}

class StateManager {
  final Function(MapState) onStateUpdate;
  final MapsService mapsService;
  final AirQualityService airQualityService;
  MapState _state;
  final BuildContext context;

  Timer? _navigationTimer;
  Timer? _distanceTimer;
  StreamSubscription<LatLng?>? _locationSubscription;

  Function(LatLng, {double zoom})? _animateCameraToCallback;
  Function(LatLng)? _followUserCallback;

  DateTime? _navigationStartTime;
  bool _isOnTransit = false;
  String _previousTransportMode = "walking";

  final Map<String, Map<String, String>> _modeEstimates = {
    "driving": {"distance": "", "duration": ""},
    "walking": {"distance": "", "duration": ""},
    "bicycling": {"distance": "", "duration": ""},
    "transit": {"distance": "", "duration": ""},
    "two_wheeler": {"distance": "", "duration": ""},
  };

  final Map<String, Color> transportColors = {
    "driving": Colors.blue.shade700,
    "walking": Colors.green.shade700,
    "bicycling": Colors.orange.shade700,
    "transit": Colors.purple.shade700,
    "two_wheeler": Colors.red.shade700,
    "ridesharing": Colors.green.shade700,
  };

  Map<String, bool> _availableModes = {
    'driving': true,
    'walking': true,
    'bicycling': true,
    'transit': true,
    'two_wheeler': true,
    'ridesharing': true,
  };

  final Map<String, IconData> _incidentIcons = {
    "Accident": Icons.warning,
    "Roadblock": Icons.block,
    "BadWeather": Icons.cloud,
    "Hazard": Icons.report,
    "Traffic": Icons.traffic,
    "Noise": Icons.surround_sound,
    "Other": Icons.help_outline,
  };

  final Set<TileOverlay> _tileOverlays = {};
  String _currentAirQualityMapType = AirQualityService.defaultMapType;
  List<String> _availableMapTypes = AirQualityService.mapTypes.keys.toList();
  
  String _currentAirQualityCategory = "";
  int? _currentAirQualityIndex = null;

  Map<String, bool> get availableModes => _availableModes;
  Map<String, Map<String, String>> get modeEstimates => _modeEstimates;
  String get currentAirQualityMapType => _currentAirQualityMapType;
  String get currentAirQualityCategory => _currentAirQualityCategory;
  int? get currentAirQualityIndex => _currentAirQualityIndex;

  final List<LatLng> _previousLocations = [];
  final List<DateTime> _previousLocationTimes = [];
  final int _maxLocationHistorySize = 5;

  StateManager({
    required MapState initialState,
    required this.onStateUpdate,
    required this.mapsService,
    required this.airQualityService,
    required this.context,
  }) : _state = initialState;

  Future<void> initialize() async {
    try {
      updateState((state) => state.copyWith(isLoading: true));

      final initialLocation = await fetchInitialLocation();
      final userMarkers = MapUIHelper.createUserLocationMarkers(initialLocation);

      _tileOverlays.clear();
      
      updateState((state) => state.copyWith(
        currentLocation: initialLocation,
        isLoading: false,
        userLocationMarker: userMarkers,
        tileOverlays: _tileOverlays,
        showAirQuality: false,
      ));

      await _locationSubscription?.cancel();
      _locationSubscription = GeoLocationService.getLocationStream()
          .listen(_onLocationUpdate);

      if (_animateCameraToCallback != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _animateCameraToCallback!(initialLocation, zoom: 16);
        });
      }

      await _setupLocationTracking();
      _updateLocationHistory(_state.currentLocation);
    } catch (e) {
      debugPrint('Error initializing state: $e');
      updateState((state) => state.copyWith(isLoading: false));
    }
  }

  Future<LatLng> fetchInitialLocation() async {
    try {
      final loc = await GeoLocationService.getCurrentLocation();
      return loc ?? _state.currentLocation;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return _state.currentLocation;
    }
  }

  void registerCameraCallbacks({
    required Function(LatLng, {double zoom}) animateCameraTo,
    required Function(LatLng) followUser,
  }) {
    _animateCameraToCallback = animateCameraTo;
    _followUserCallback = followUser;
  }

  void _onLocationUpdate(LatLng? location) {
    if (location == null) return;
    final currentLocation = location;
    final userMarkers = MapUIHelper.createUserLocationMarkers(currentLocation);
    bool isSignificantMove = _previousLocations.isNotEmpty &&
        LocationHelper.calculateDistanceInMeters(_previousLocations.last, currentLocation) > 20;
    _updateLocationHistory(currentLocation);
    updateState((state) => state.copyWith(
      currentLocation: currentLocation,
      userLocationMarker: userMarkers,
    ));
    if (_state.isNavigating && _state.destination != null && isSignificantMove) {
      _calculateRoute();
      updateDistanceAndTime();
    }

    if (_state.isNavigating && _state.transportMode == "transit") {
      _checkTransitStopProximity();
    }

    if (_state.isNavigating) {
      _fetchIncidents();
    }

    if (_state.isFollowing && _followUserCallback != null) {
      _followUserCallback!(currentLocation);
    }
  }

  Future<void> _fetchIncidents() async {
    if (!_state.isNavigating || _state.polylines.isEmpty) return;

    final polyline = _state.polylines.first;
    final List<Map<String, double>> route = polyline.points
        .map((p) => {"latitude": p.latitude, "longitude": p.longitude})
        .toList();

    try {
      IncidentsService service = IncidentsService();
      final data = await service.getIncidentsByRoute(route, 50.0);
      final incidents = data["incidents"] as List;

      Set<Marker> incidentMarkers = {};

      for (var inc in incidents) {
        final locRaw = inc["Location"] as String;
        final incidentType = inc["IncidentType"]?.toString() ?? "Other";
        final description = inc["description"]?.toString() ?? "";
        final incidentID = inc["incidentID"]?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
        final parsedLoc = parsePointWKT(locRaw);

        String title = incidentType;
        String snippet = description;
        BitmapDescriptor? icon;
        
        if (incidentType == "Noise") {
          icon = await getNoiseIncidentIcon(96);
          
          if (description.contains("Measured noise:")) {
            final parts = description.split("\n");
            if (parts.length >= 3) {
              final interpretationLine = parts.firstWhere(
                (line) => line.startsWith("Interpretation:"), 
                orElse: () => ""
              );
              
              final noiseLine = parts.firstWhere(
                (line) => line.startsWith("Measured noise:"), 
                orElse: () => ""
              );
              
              if (interpretationLine.isNotEmpty && noiseLine.isNotEmpty) {
                final interpretation = interpretationLine.replaceFirst("Interpretation:", "").trim();
                final noiseValue = noiseLine.replaceFirst("Measured noise:", "").trim();
                
                title = "🔊 Noise Incident: ${noiseValue.split(' ')[0]} dB";
                
                snippet = interpretation;
              }
            }
          }
        } else {
          final iconData = _incidentIcons[incidentType] ?? Icons.help_outline;
          final iconColor = Colors.red.shade800;
          icon = await getMarkerIconFromIconData(iconData, iconColor, size: 96);
        }

        if (snippet.length > 80) {
          snippet = snippet.substring(0, 77) + "...";
        }

        incidentMarkers.add(
          Marker(
            markerId: MarkerId(incidentID),
            position: parsedLoc,
            icon: icon,
            infoWindow: InfoWindow(
              title: title,
              snippet: snippet,
            ),
            visible: true,
            zIndex: 2,
            consumeTapEvents: false,
            draggable: false,
            flat: false,
          ),
        );
      }

      final destinationMarker = _state.markers.where((m) => m.markerId.value == 'destination').toSet();
      
      updateState((state) => state.copyWith(
        markers: destinationMarker.union(incidentMarkers),
      ));
    } catch (e) {
      print("❌ Error fetching incidents: $e");
    }
  }

  Future<BitmapDescriptor> getMarkerIconFromIconData(
      IconData iconData,
      Color color, {
        double size = 96,
      }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final textSpan = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.6,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: color,
      ),
    );

    textPainter.text = textSpan;
    textPainter.layout();

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2.2,
      paint,
    );
    
    final borderPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size / 12;
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2.2,
      borderPaint,
    );

    final offset = Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);

    final image = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
  }
  
  Future<BitmapDescriptor> getNoiseIncidentIcon(double size) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final soundWavesPaint = Paint()
      ..color = Colors.purple.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = size / 20
      ..strokeCap = StrokeCap.round;
    
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2.2,
      bgPaint,
    );
    
    final borderPaint = Paint()
      ..color = Colors.purple.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = size / 12;
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2.2,
      borderPaint,
    );
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    final textSpan = TextSpan(
      text: String.fromCharCode(Icons.mic.codePoint),
      style: TextStyle(
        fontSize: size * 0.5,
        fontFamily: Icons.mic.fontFamily,
        color: Colors.purple.shade700,
      ),
    );
    
    textPainter.text = textSpan;
    textPainter.layout();
    
    final offset = Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    );
    
    textPainter.paint(canvas, offset);
    
    final center = Offset(size / 2, size / 2);
    
    canvas.drawArc(
      Rect.fromCenter(center: center, width: size * 0.6, height: size * 0.6),
      -0.5,
      1.0,
      false,
      soundWavesPaint,
    );
    
    canvas.drawArc(
      Rect.fromCenter(center: center, width: size * 0.8, height: size * 0.8),
      -0.5,
      1.0,
      false,
      soundWavesPaint,
    );
    
    final image = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    
    return BitmapDescriptor.fromBytes(bytes);
  }

  LatLng parsePointWKT(String wkt) {
    const prefix = "POINT(";
    const suffix = ")";
    if (wkt.startsWith(prefix) && wkt.endsWith(suffix)) {
      final content = wkt.substring(prefix.length, wkt.length - suffix.length).trim();
      final parts = content.split(RegExp(r'\s+'));
      if (parts.length == 2) {
        final lon = double.tryParse(parts[0]);
        final lat = double.tryParse(parts[1]);
        if (lon != null && lat != null) {
          return LatLng(lat, lon);
        }
      }
    }
    throw FormatException("Invalid WKT format: $wkt");
  }

  void updateState(MapState Function(MapState) updateFunction) {
    _state = updateFunction(_state);
    onStateUpdate(_state);
  }

  Future<void> toggleNavigation() async {
    if (_state.destination == null || _state.isNavigating) {
      stopNavigation();
      return;
    }
    _navigationStartTime = DateTime.now();
    updateState((state) => state.copyWith(
      isNavigating: true,
      isFollowing: true,
    ));

    _animateCameraToCallback?.call(_state.currentLocation, zoom: 16);
    await _calculateRoute();

    _onLocationUpdate(_state.currentLocation);

    _distanceTimer?.cancel();
    _distanceTimer = Timer.periodic(const Duration(seconds: 3), (_) => updateDistanceAndTime());

    _navigationTimer?.cancel();
    _navigationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_state.isNavigating) {
        _navigationTimer?.cancel();
        return;
      }
      if (_state.isFollowing && _followUserCallback != null) {
        _followUserCallback!(_state.currentLocation);
      }
    });
  }

  Future<void> setDestination(LatLng destinationLocation) async {
    final bool isSignificantChange =
        _state.destination == null ||
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

      if (isSignificantChange) {
        await _updateAllModeEstimates();
      }
    } catch (e) {
      debugPrint('Error setting destination: $e');
      updateState((state) => state.copyWith(isLoading: false));
    }
  }

  Future<bool> _calculateRoute() async {
    if (_state.destination == null) return false;
    final origin = _state.currentLocation;
    final destination = _state.destination!;
    final mode = _state.transportMode;

    updateState((state) => state.copyWith(isLoading: true));

    try {
      final result = await mapsService.getRoutePolylines(
        origin: origin,
        destination: destination,
        mode: mode,
      );

      if (result != null && result.isNotEmpty) {
        bool hasValidRoute = true;
        if (result.length >= 4 && result[3] is Map<String, dynamic>) {
          final status = (result[3] as Map<String, dynamic>)['status'];
          if (status == 'ZERO_RESULTS') hasValidRoute = false;
        }

        if (hasValidRoute && _state.isNavigating) {
          final Set<Polyline> polylines = result[0] is Set<Polyline>
              ? result[0] as Set<Polyline>
              : <Polyline>{};

          Set<Circle> transitStops = {};
          List<dynamic> transitDetails = [];

          if (mode == "transit" && result.length >= 3) {
            final stops = result[1] as List<LatLng>;
            transitDetails = result[2] as List<dynamic>;
            for (int i = 0; i < stops.length; i++) {
              transitStops.add(Circle(
                circleId: CircleId('transit_stop_$i'),
                center: stops[i],
                radius: 8,
                fillColor: Colors.blue.shade100,
                strokeColor: Colors.blue.shade700,
                strokeWidth: 2,
              ));
            }
          }

          updateState((state) => state.copyWith(
            polylines: polylines,
            transitStops: transitStops,
            transitDetails: transitDetails,
            isLoading: false,
          ));
        } else if (hasValidRoute) {
          updateState((state) => state.copyWith(
            polylines: {},
            transitStops: {},
            transitDetails: [],
            isLoading: false,
          ));
        } else {
          await _updateAvailableModes();
          updateState((state) => state.copyWith(isLoading: false));
          return false;
        }
        return true;
      } else {
        await _updateAvailableModes();
        updateState((state) => state.copyWith(isLoading: false));
        return false;
      }
    } catch (e) {
      debugPrint('Error calculating route: $e');
      updateState((state) => state.copyWith(isLoading: false));
      return false;
    }
  }

  Future<void> updateTransportMode(String mode) async {
    if (mode == _state.transportMode) return;

    if (mode != 'ridesharing') {
      _previousTransportMode = _state.transportMode;
    }

    updateState((state) => state.copyWith(
      transportMode: mode,
      isLoading: true,
    ));

    if (mode == 'ridesharing') {
      if (_state.destination != null) {
        final didLaunch = await ExternalAppsService.openRideOptionsWithFeedback(
          context,
          _state.destination!,
          origin: _state.currentLocation,
        );
        updateState((state) => state.copyWith(
          transportMode: _previousTransportMode,
          isLoading: false,
        ));
        if (didLaunch == true) clearDestination();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please set a destination first"),
          duration: Duration(seconds: 2),
        ));
        updateState((state) => state.copyWith(
          transportMode: _previousTransportMode,
          isLoading: false,
        ));
      }
    } else {
      if (_state.destination != null) {
        if (_modeEstimates.containsKey(mode) &&
            _modeEstimates[mode]!['distance']?.isNotEmpty == true) {
          updateState((state) => state.copyWith(
            distance: () => _modeEstimates[mode]!['distance'],
            duration: () => _modeEstimates[mode]!['duration'],
            isLoading: false,
          ));
        }
        bool routeFound = await _calculateRoute();
        if (mode == 'bicycling' && !routeFound) {
          _showNoRoutesFoundMessage('bicycling');
          await _updateAvailableModes();
          updateState((state) => state.copyWith(
            transportMode: 'two_wheeler',
            isLoading: true,
          ));
          if (_modeEstimates.containsKey('two_wheeler') &&
              _modeEstimates['two_wheeler']!['distance']?.isNotEmpty == true) {
            updateState((state) => state.copyWith(
              distance: () => _modeEstimates['two_wheeler']!['distance'],
              duration: () => _modeEstimates['two_wheeler']!['duration'],
              isLoading: false,
            ));
          }
          await _calculateRoute();
        }
      } else {
        updateState((state) => state.copyWith(isLoading: false));
      }
    }
  }

  Future<void> updateDistanceAndTime() async {
    if (_state.destination == null) return;

    try {
      final response = await mapsService.getLocationTimeAndDistance(
        _state.currentLocation,
        _state.destination!,
        mode: _state.transportMode,
      );

      if (response != null) {
        final distance = response['distance'];
        final duration = response['duration'];
        if (distance != null && duration != null) {
          _modeEstimates[_state.transportMode] = {
            "distance": distance,
            "duration": duration,
          };
        }

        updateState((state) => state.copyWith(
          distance: () => distance,
          duration: () => duration,
        ));

        final double straightLineDistance = LocationHelper.calculateDistanceInMeters(
          _state.currentLocation,
          _state.destination!,
        );

        if (_state.isNavigating &&
            _navigationStartTime != null &&
            DateTime.now().difference(_navigationStartTime!).inSeconds >= 5) {
          final parsedDistance = int.tryParse(distance?.split(' ')[0] ?? '');
          if ((distance != null && distance.contains('m') && parsedDistance != null && parsedDistance < 70) ||
              straightLineDistance < 70) {
            _distanceTimer?.cancel();
            _showDestinationReachedNotification();
            clearDestination();
            return;
          }
        }

        if (_state.transportMode == "transit" && _state.isNavigating) {
          _checkTransitStopProximity();
        }
      }
    } catch (e) {
      debugPrint('Error updating distance and time: $e');
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _distanceTimer?.cancel();
    _locationSubscription?.cancel();
    _followUserCallback = null;
    _animateCameraToCallback = null;
    
    AirQualityService.clearAllCaches();
  }

  void stopNavigation() {
    _navigationTimer?.cancel();
    _distanceTimer?.cancel();
    _navigationStartTime = null;
    _isOnTransit = false;
    updateState((state) => state.copyWith(
      transitDetails: [],
      transitStops: {},
      polylines: {},
      isNavigating: false,
      currentTransitStep: null,
    ));
    updateDistanceAndTime();
  }

  void clearDestination() {
    _navigationTimer?.cancel();
    _distanceTimer?.cancel();
    _navigationStartTime = null;
    _isOnTransit = false;
    updateState((state) => state.copyWith(
      destination: () => null,
      isNavigating: false,
      isLoading: false,
      polylines: {},
      transitDetails: [],
      transitStops: {},
      markers: {},
      distance: () => null,
      duration: () => null,
      currentTransitStep: null,
    ));
    _animateCameraToCallback?.call(_state.currentLocation, zoom: 16);
  }

  void _showDestinationReachedNotification() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.location_on, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You have arrived!', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Your destination has been reached', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 5),
      ),
    );
    clearDestination();
  }

  void _checkTransitStopProximity() {
    if (!_state.isNavigating || _state.transportMode != 'transit' || _state.transitDetails.isEmpty) return;

    if (_isOnTransit) {
      _checkNextTransitStop();
      return;
    }

    try {
      for (int i = 0; i < _state.transitDetails.length; i++) {
        final transitDetail = _state.transitDetails[i];
        if (transitDetail is! Map || !transitDetail.containsKey('startLocation')) continue;

        final startLocation = transitDetail['startLocation'];
        if (startLocation is! Map || !startLocation.containsKey('lat') || !startLocation.containsKey('lng')) continue;

        final stopLocation = LatLng(startLocation['lat'] as double, startLocation['lng'] as double);
        final double distanceToStop = _calculateDistance(
          _state.currentLocation.latitude,
          _state.currentLocation.longitude,
          stopLocation.latitude,
          stopLocation.longitude,
        );

        const double BOARDING_THRESHOLD = 10.0;
        if (distanceToStop <= BOARDING_THRESHOLD) {
          _boardPublicTransport(i);
          return;
        } else {
          debugPrint('⚠️ User is not close enough to transit stop ${transitDetail['from']} (${distanceToStop.toStringAsFixed(2)}m > $BOARDING_THRESHOLD m)');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking transit stop proximity: $e');
    }
  }

  void _boardPublicTransport(int index) {
    try {
      if (index < 0 || index >= _state.transitDetails.length) return;
      final updatedDetails = List.from(_state.transitDetails);
      final detail = updatedDetails[index];
      if (detail is Map) {
        detail['isOnboard'] = true;
        updatedDetails[index] = detail;
        updateState((state) => state.copyWith(
          transitDetails: updatedDetails,
          currentTransitStep: detail,
        ));
        _isOnTransit = true;
        _focusOnFinalTransitDestination();
      } else {
        debugPrint('❌ Cannot board: Transit detail at index $index is not a Map');
      }
    } catch (e) {
      debugPrint('❌ Error boarding public transport: $e');
    }
  }

  void _exitPublicTransport() {
    _isOnTransit = false;
    final updatedDetails = _state.transitDetails.map((detail) {
      if (detail is Map) {
        final d = Map<String, dynamic>.from(detail);
        d['isOnboard'] = false;
        return d;
      }
      return detail;
    }).toList();

    updateState((state) => state.copyWith(
      transitDetails: updatedDetails,
      currentTransitStep: null,
    ));

    _updateRoute(preserveTransitDetails: true);
  }

  void _showNoRoutesFoundMessage(String mode) {
    if (!context.mounted) return;
    String message;
    switch (mode) {
      case 'bicycling':
        message = 'No bike routes available for this destination. Try motorcycle instead.';
        break;
      case 'transit':
        message = 'No public transit routes available for this destination.';
        break;
      case 'walking':
        message = 'This destination is too far for walking. Try another transport mode.';
        break;
      default:
        message = 'No routes available for this transport mode.';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _updateAvailableModes() async {
    if (_state.destination == null) return;
    final origin = _state.currentLocation;
    final destination = _state.destination!;
    final previous = Map.from(_availableModes);

    final List<Future<void>> checks = [];
    if (previous['bicycling'] == true || !previous.containsKey('bicycling')) {
      checks.add(_checkModeAvailability('bicycling', origin, destination));
    }
    if (previous['transit'] == true || !previous.containsKey('transit')) {
      checks.add(_checkModeAvailability('transit', origin, destination));
    }
    await Future.wait(checks);
  }

  Future<void> _checkModeAvailability(String mode, LatLng origin, LatLng destination) async {
    try {
      final result = await mapsService.getRoutePolylines(
        origin: origin,
        destination: destination,
        mode: mode,
      );

      bool isAvailable = result != null &&
          result.isNotEmpty &&
          !(result.length >= 4 &&
              result[3] is Map<String, dynamic> &&
              (result[3] as Map<String, dynamic>)['status'] == 'ZERO_RESULTS');

      _availableModes[mode] = isAvailable;
    } catch (e) {
      debugPrint('Error checking $mode availability: $e');
      _availableModes[mode] = true;
    }
  }

  Future<void> _updateAllModeEstimates() async {
    if (_state.destination == null) return;
    final modes = ["driving", "walking", "bicycling", "transit", "two_wheeler"];
    updateState((state) => state.copyWith(isLoading: true));
    for (final mode in modes) {
      try {
        final response = await mapsService.getLocationTimeAndDistance(
          _state.currentLocation,
          _state.destination!,
          mode: mode,
        );
        if (response != null) {
          final distance = response['distance'];
          final duration = response['duration'];
          final status = response['status'];
          if (distance != null && duration != null) {
            _modeEstimates[mode] = {"distance": distance, "duration": duration};
            if (status == 'ZERO_RESULTS') _availableModes[mode] = false;
            if (mode == _state.transportMode) {
              updateState((state) => state.copyWith(
                distance: () => distance,
                duration: () => duration,
              ));
            }
          }
        }
      } catch (e) {
        debugPrint('Error getting estimates for $mode: $e');
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    updateState((state) => state.copyWith(isLoading: false));
  }

  Future<void> _setupLocationTracking() async {
    try {
      await GeoLocationService.checkAndRequestLocationPermission();
      if (_locationSubscription == null) {
        _locationSubscription = GeoLocationService.getLocationStream().listen(_onLocationUpdate);
      }
    } catch (e) {
      debugPrint('Error setting up location tracking: $e');
    }
  }

  void _updateLocationHistory(LatLng location) {
    _previousLocations.add(location);
    _previousLocationTimes.add(DateTime.now());
    if (_previousLocations.length > _maxLocationHistorySize) {
      _previousLocations.removeAt(0);
      _previousLocationTimes.removeAt(0);
    }
  }

  void _checkNextTransitStop() {
    final currentStep = _getCurrentTransitStep();
    if (currentStep['isOnboard'] != true) return;
    try {
      if (!(currentStep.containsKey('endLocation'))) return;
      final endLocation = currentStep['endLocation'];
      if (endLocation is! Map || !endLocation.containsKey('lat') || !endLocation.containsKey('lng')) return;
      final stopLocation = LatLng(endLocation['lat'], endLocation['lng']);
      final double distanceToStop = _calculateDistance(
        _state.currentLocation.latitude,
        _state.currentLocation.longitude,
        stopLocation.latitude,
        stopLocation.longitude,
      );
      const double PROXIMITY_THRESHOLD = 50.0;
      const double ARRIVAL_THRESHOLD = 20.0;
      if (distanceToStop <= PROXIMITY_THRESHOLD && distanceToStop > ARRIVAL_THRESHOLD) {
        int currentIndex = -1;
        for (int i = 0; i < _state.transitDetails.length; i++) {
          final detail = _state.transitDetails[i];
          if (detail is Map &&
              detail['line'] == currentStep['line'] &&
              detail['type'] == currentStep['type'] &&
              detail['from'] == currentStep['from']) {
            currentIndex = i;
            break;
          }
        }
        if (currentIndex != -1) {
          final stopName = currentStep['to']?.toString() ?? 'next stop';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Approaching $stopName', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.blue.shade700,
            duration: const Duration(seconds: 3),
          ));
        }
      }
      if (distanceToStop <= ARRIVAL_THRESHOLD) {
        bool isLastSegment = true;
        int currentIndex = -1;
        for (int i = 0; i < _state.transitDetails.length; i++) {
          final detail = _state.transitDetails[i];
          if (detail is Map &&
              detail['line'] == currentStep['line'] &&
              detail['type'] == currentStep['type'] &&
              detail['from'] == currentStep['from']) {
            currentIndex = i;
            isLastSegment = (i == _state.transitDetails.length - 1);
            break;
          }
        }
        if (currentIndex != -1) {
          if (isLastSegment) {
            _exitPublicTransport();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text(
                'You have arrived at your final transit stop. Continue to your destination.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 5),
            ));
          } else {
            final nextSegment = _state.transitDetails[currentIndex + 1];
            if (nextSegment is Map) {
              final updatedTransitDetails = List.from(_state.transitDetails);
              final updatedCurrentDetail = Map<String, dynamic>.from(updatedTransitDetails[currentIndex]);
              updatedCurrentDetail['isOnboard'] = false;
              updatedTransitDetails[currentIndex] = updatedCurrentDetail;
              final updatedNextDetail = Map<String, dynamic>.from(nextSegment);
              updatedNextDetail['isOnboard'] = false;
              updatedTransitDetails[currentIndex + 1] = updatedNextDetail;
              updateState((state) => state.copyWith(
                transitDetails: updatedTransitDetails,
                currentTransitStep: updatedCurrentDetail,
              ));
              _isOnTransit = false;
              final nextLine = nextSegment['line']?.toString() ?? 'next';
              final nextType = nextSegment['type']?.toString() ?? 'transit';
              final nextStop = nextSegment['from']?.toString() ?? 'stop';
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  'Transfer to $nextLine $nextType at $nextStop',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.orange.shade700,
                duration: const Duration(seconds: 5),
              ));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking next transit stop: $e');
    }
  }

  void _focusOnFinalTransitDestination() {
    if (_state.transitDetails.isEmpty) return;
    if (!_isOnTransit && (_getCurrentTransitStep()['isOnboard'] != true)) return;
    try {
      final lastSegment = _state.transitDetails.last;
      if (lastSegment is! Map || !lastSegment.containsKey('endLocation')) {
        debugPrint('❌ Cannot focus on final destination: invalid transit segment data');
        return;
      }
      final finalStop = lastSegment['endLocation'];
      if (finalStop is! Map || !finalStop.containsKey('lat') || !finalStop.containsKey('lng')) {
        debugPrint('❌ Cannot focus on final destination: invalid location data');
        return;
      }
      _updateStopVisibility(showOnlyFinalStop: false, highlightFinalStop: true);
      int remainingStops = _countRemainingTransitStops();
      _showOnTransitMessageWithStopCount(remainingStops);
    } catch (e) {
      debugPrint('❌ Error focusing on final destination: $e');
    }
  }

  int _countRemainingTransitStops() {
    if (!_isOnTransit || _state.transitDetails.isEmpty) return 0;
    try {
      final currentStep = _getCurrentTransitStep();
      int currentIndex = -1;
      for (int i = 0; i < _state.transitDetails.length; i++) {
        final detail = _state.transitDetails[i];
        if (detail is Map &&
            detail['line'] == currentStep['line'] &&
            detail['type'] == currentStep['type'] &&
            detail['from'] == currentStep['from']) {
          currentIndex = i;
          break;
        }
      }
      if (currentIndex == -1) return 0;
      int remainingStops = 0;
      if (currentStep['stops'] != null) {
        try {
          remainingStops += int.parse(currentStep['stops'].toString());
        } catch (_) {}
      }
      for (int i = currentIndex + 1; i < _state.transitDetails.length; i++) {
        final detail = _state.transitDetails[i];
        if (detail is Map && detail['stops'] != null) {
          try {
            remainingStops += int.parse(detail['stops'].toString());
          } catch (_) {}
        }
      }
      return remainingStops;
    } catch (e) {
      return 0;
    }
  }

  void _showOnTransitMessageWithStopCount(int remainingStops) {
    if (!_isOnTransit || (_getCurrentTransitStep()['isOnboard'] != true)) return;
    final currentStep = _getCurrentTransitStep();
    final transitLine = currentStep['line'] ?? 'transit';
    final transitType = currentStep['type'] ?? 'vehicle';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'You are on $transitLine $transitType. $remainingStops stops remaining until destination.',
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.green.shade700,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'OK',
        textColor: Colors.white,
        onPressed: () {},
      ),
    ));
  }

  void _updateStopVisibility({bool showOnlyFinalStop = false, bool highlightFinalStop = false}) {
    if (_state.transitDetails.isEmpty) return;
    final updatedStops = <Circle>{};

    if (showOnlyFinalStop || highlightFinalStop) {
      final lastSegment = _state.transitDetails.last;
      if (lastSegment is Map && lastSegment.containsKey('endLocation')) {
        final endLocation = lastSegment['endLocation'];
        if (endLocation is Map && endLocation.containsKey('lat') && endLocation.containsKey('lng')) {
          final finalStopLocation = LatLng(endLocation['lat'], endLocation['lng']);
          updatedStops.add(Circle(
            circleId: const CircleId('final_transit_stop'),
            center: finalStopLocation,
            radius: 15,
            strokeWidth: 3,
            strokeColor: Colors.red.shade700,
            fillColor: Colors.red.shade200,
          ));
        }
      }
    }

    if (!showOnlyFinalStop) {
      for (int i = 0; i < _state.transitDetails.length; i++) {
        final transitDetail = _state.transitDetails[i];
        if (transitDetail is! Map) continue;
        if (transitDetail.containsKey('startLocation')) {
          final startLoc = transitDetail['startLocation'];
          if (startLoc is Map && startLoc.containsKey('lat') && startLoc.containsKey('lng')) {
            updatedStops.add(Circle(
              circleId: CircleId('transit_stop_start_$i'),
              center: LatLng(startLoc['lat'], startLoc['lng']),
              radius: 8,
              strokeWidth: 2,
              strokeColor: Colors.blue.shade700,
              fillColor: Colors.blue.shade100,
            ));
          }
        }
        if (i < _state.transitDetails.length - 1 && transitDetail.containsKey('endLocation')) {
          final endLoc = transitDetail['endLocation'];
          if (endLoc is Map && endLoc.containsKey('lat') && endLoc.containsKey('lng')) {
            updatedStops.add(Circle(
              circleId: CircleId('transit_stop_end_$i'),
              center: LatLng(endLoc['lat'], endLoc['lng']),
              radius: 8,
              strokeWidth: 2,
              strokeColor: Colors.orange.shade700,
              fillColor: Colors.orange.shade100,
            ));
          }
        }
      }
    }

    updateState((state) => state.copyWith(transitStops: updatedStops));
  }

  Map<String, dynamic> _getCurrentTransitStep() {
    if (_state.currentTransitStep == null) return {'isOnboard': false};
    if (_state.currentTransitStep is Map) return _state.currentTransitStep as Map<String, dynamic>;
    if (_state.currentTransitStep is int &&
        _state.transitDetails.isNotEmpty &&
        _state.currentTransitStep < _state.transitDetails.length) {
      return _state.transitDetails[_state.currentTransitStep as int];
    }
    return {'isOnboard': false};
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  void _updateRoute({bool preserveTransitDetails = false}) {
    if (_state.destination == null) return;
    final savedTransitDetails = preserveTransitDetails && _state.transitDetails.isNotEmpty
        ? List.from(_state.transitDetails)
        : null;
    updateState((state) => state.copyWith(isLoading: true));

    final origin = _state.currentLocation;
    final destination = _state.destination!;
    mapsService.getRoutePolylines(
      origin: origin,
      destination: destination,
      mode: _state.transportMode,
      includeTransitDetails: _state.transportMode == 'transit',
    ).then((result) {
      if (result != null && result.isNotEmpty && result[0] is Set<Polyline>) {
        final polylines = result[0] as Set<Polyline>;
        final transitDetails = savedTransitDetails ?? (result.length > 2 ? result[2] as List<dynamic> : []);
        updateState((state) => state.copyWith(
          polylines: polylines,
          isLoading: false,
          transitDetails: transitDetails,
        ));
        _updateAllModeEstimates();
      } else {
        updateState((state) => state.copyWith(isLoading: false));
      }
    }).catchError((error) {
      updateState((state) => state.copyWith(isLoading: false));
    });
  }

  void toggleAirQualityOverlay() {
    final showAirQuality = !_state.showAirQuality;
    
    _tileOverlays.clear();
    
    if (showAirQuality) {
      AirQualityService.preloadTilesForLocation(
        _state.currentLocation, 
        _currentAirQualityMapType
      );
      
      final airQualityOverlay = AirQualityService.getAirQualityOverlay(
        'air_quality_overlay',
        mapType: _currentAirQualityMapType,
        transparency: 0.35,
      );
      _tileOverlays.add(airQualityOverlay);
    } else {
    }

    updateState((state) => state.copyWith(
      tileOverlays: _tileOverlays,
      showAirQuality: showAirQuality,
    ));
  }
  
  void cycleAirQualityMapType() {
    _cycleToNextMapType();
    
    if (_state.showAirQuality) {
      _tileOverlays.clear();
      
      AirQualityService.preloadTilesForLocation(
        _state.currentLocation, 
        _currentAirQualityMapType
      );
      
      final airQualityOverlay = AirQualityService.getAirQualityOverlay(
        'air_quality_overlay',
        mapType: _currentAirQualityMapType,
      );
      _tileOverlays.add(airQualityOverlay);
      
      updateState((state) => state.copyWith(
        tileOverlays: _tileOverlays,
      ));
      
      _showMapTypeChangedMessage();
    }
  }
  
  void _cycleToNextMapType() {
    final currentIndex = _availableMapTypes.indexOf(_currentAirQualityMapType);
    final nextIndex = (currentIndex + 1) % _availableMapTypes.length;
    _currentAirQualityMapType = _availableMapTypes[nextIndex];
    
    if (_state.showAirQuality) {
      _tileOverlays.clear();
      final airQualityOverlay = AirQualityService.getAirQualityOverlay(
        'air_quality_overlay',
        mapType: _currentAirQualityMapType,
      );
      _tileOverlays.add(airQualityOverlay);
      
      updateState((state) => state.copyWith(
        tileOverlays: _tileOverlays,
      ));
      
      _showMapTypeChangedMessage();
      
      _fetchAirQualityConditions();
    }
  }
  
  void _showMapTypeChangedMessage() {
    if (!context.mounted) return;
    
    final mapTypeName = AirQualityService.mapTypes[_currentAirQualityMapType] ?? _currentAirQualityMapType;
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Air Quality Map: $mapTypeName'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }
  
  Future<void> _fetchAirQualityConditions() async {
    if (!_state.showAirQuality) return;
    
    try {
      final conditions = await AirQualityService.getCurrentConditions(
        location: _state.currentLocation,
        extraComputations: ["HEALTH_RECOMMENDATIONS"],
        universalAqi: true,
      );
      
      if (conditions != null && context.mounted) {
        String aqiMessage = "";
        int? aqiValue;
        String category = "";
        
        if (conditions.containsKey('indexes') && conditions['indexes'] is List) {
          final indexes = conditions['indexes'] as List;
          if (indexes.isNotEmpty && indexes[0] is Map) {
            final index = indexes[0] as Map;
            if (index.containsKey('aqi')) {
              aqiValue = index['aqi'] as int?;
            }
            
            if (index.containsKey('category')) {
              category = index['category'] as String? ?? "";
            }
          }
        }
        
        String recommendation = "";
        if (conditions.containsKey('healthRecommendations') && 
            conditions['healthRecommendations'] is Map) {
          final healthRecs = conditions['healthRecommendations'] as Map;
          if (healthRecs.containsKey('generalPopulation')) {
            final fullRec = healthRecs['generalPopulation'] as String? ?? "";
            recommendation = fullRec.split('.').first + '.';
          }
        }
        
        _currentAirQualityCategory = category;
        _currentAirQualityIndex = aqiValue;
        
        Color backgroundColor = Colors.blue;
        if (aqiValue != null) {
          if (aqiValue <= 50) {
            backgroundColor = Colors.green;
          } else if (aqiValue <= 100) {
            backgroundColor = Colors.yellow.shade800;
          } else if (aqiValue <= 150) {
            backgroundColor = Colors.orange;
          } else if (aqiValue <= 200) {
            backgroundColor = Colors.red;
          } else if (aqiValue <= 300) {
            backgroundColor = Colors.purple;
          } else {
            backgroundColor = Colors.brown;
          }
        }
        
        if (_currentAirQualityIndex != null && _currentAirQualityCategory.isNotEmpty) {
          updateState((state) => state.copyWith(showAirQuality: state.showAirQuality));
        }
        
        aqiMessage = "AQI ${aqiValue ?? '?'} - $category";
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                aqiMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (recommendation.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    recommendation,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(8),
        ));
      }
    } catch (e) {
      debugPrint('Error fetching air quality: $e');
    }
  }

  void clearAirQualityCaches() {
    if (!_state.showAirQuality) {
      AirQualityService.clearAllCaches();
    }
  }
}
