import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/material.dart';

class PlaceSuggestion {
  final String description;
  final String placeId;
  String? distance;
  String? duration;
  LatLng? location;

  PlaceSuggestion({
    required this.description,
    required this.placeId,
    this.distance,
    this.duration,
    this.location,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      description: json['description'],
      placeId: json['place_id'],
    );
  }
}

class MapsService {
  final String apiKey = "AIzaSyA-XTPqXuzaHM2EcpKaqd97Kg9sPzjrttA";
  final Map<String, dynamic> _cache = {};
  Timer? _autocompleteDebounce;
  String? _sessionToken;
  String? _lastQuery;
  bool _isOffline = false;
  DateTime? _lastConnectionCheck;
  final Duration _connectionCheckInterval = const Duration(seconds: 10);
  final Duration _cacheDuration = const Duration(minutes: 30);
  final int _minAutocompleteChars = 3;
  final List<String> _countryRestrictions = ['ro', 'nl'];

  void _addToCache(String key, dynamic data) {
    _cache[key] = {
      'timestamp': DateTime.now(),
      'data': data,
    };
  }

  dynamic _getFromCache(String key) {
    final cachedData = _cache[key];
    if (cachedData != null) {
      final cacheTime = cachedData['timestamp'] as DateTime;
      if (DateTime.now().difference(cacheTime) < _cacheDuration) {
        return cachedData['data'];
      } else {
        _cache.remove(key);
      }
    }
    return null;
  }

  String _getSessionToken() {
    _sessionToken ??= DateTime.now().millisecondsSinceEpoch.toString();
    return _sessionToken!;
  }

  void _resetSessionToken() {
    _sessionToken = null;
  }

  Future<bool> _isInternetAvailable() async {
    if (_lastConnectionCheck != null &&
        DateTime.now().difference(_lastConnectionCheck!) < _connectionCheckInterval) {
      return !_isOffline;
    }

    try {
      final result = await InternetAddress.lookup('8.8.8.8');
      _isOffline = result.isEmpty || result[0].rawAddress.isEmpty;
      _lastConnectionCheck = DateTime.now();
    } on SocketException catch (_) {
      _isOffline = true;
      _lastConnectionCheck = DateTime.now();
    }

    return !_isOffline;
  }

  Future<http.Response?> _safeHttpGet(String url, {String errorContext = ""}) async {
    try {
      if (!await _isInternetAvailable()) {
        return null;
      }

      final response = await http.get(
          Uri.parse(url),
          headers: {'Connection': 'keep-alive'}
      ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            return http.Response('Request timed out', 408);
          }
      );

      return response;
    } on SocketException catch (e) {
      _isOffline = true;
      _lastConnectionCheck = DateTime.now();
      return null;
    } on http.ClientException catch (e) {
      debugPrint('$errorContext: Client exception - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('$errorContext: Unexpected error - $e');
      return null;
    }
  }

  Future<Map<String, String>?> getDistanceMatrix(LatLng origin, LatLng destination, {String mode = "driving"}) async {
    final originRounded = _roundCoordinates(origin);
    final destinationRounded = _roundCoordinates(destination);
    final cacheKey = 'distance_${originRounded.latitude},${originRounded.longitude}_${destinationRounded.latitude},${destinationRounded.longitude}_$mode';

    final cachedResult = _getFromCache(cacheKey);
    if (cachedResult != null) {
      final Map<String, String> typedResult = {};
      (cachedResult as Map).forEach((key, value) {
        if (key is String && value is String) {
          typedResult[key] = value;
        }
      });
      return typedResult;
    }

    if (!await _isInternetAvailable()) {
      return null;
    }

    final url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}&'
        'mode=$mode&key=$apiKey&departure_time=1744449793';

    final response = await _safeHttpGet(url, errorContext: 'getDistanceMatrix');
    if (response == null) return null;

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'].isNotEmpty &&
            data['routes'][0]['legs'].isNotEmpty) {

          final leg = data['routes'][0]['legs'][0];
          final distance = leg['distance']['text'];
          final duration = leg['duration']['text'];

          final Map<String, String> result = {
            'distance': distance,
            'duration': duration,
          };

          _addToCache(cacheKey, result);

          return result;
        } else {
          debugPrint('Directions API error: ${data['status']}');
        }
      } catch (e) {
        debugPrint('Error parsing distance data: $e');
      }
    } else {
      debugPrint('HTTP error: ${response.statusCode}');
    }

    return null;
  }

  LatLng _roundCoordinates(LatLng coord) {
    return LatLng(
        (coord.latitude * 10000).round() / 10000,
        (coord.longitude * 10000).round() / 10000
    );
  }

  Future<Map<String, String>?> getLocationTimeAndDistance(
      LatLng origin,
      LatLng destination, {
        String mode = "driving",
      }) async {
    try {
      if (mode == "transit") {
        final result = await getDistanceMatrix(origin, destination, mode: mode);
        if (result != null) {
          final Map<String, String> resultWithStatus = Map.from(result);
          resultWithStatus['status'] = 'OK';
          return resultWithStatus;
        }
      }

      if (mode == "bicycling") {
        final result = await getDistanceMatrix(origin, destination, mode: mode);
        if (result == null) {
          return {
            'status': 'ZERO_RESULTS',
            'distance': 'Not available',
            'duration': 'Not available'
          };
        }

        final Map<String, String> resultWithStatus = Map.from(result);
        resultWithStatus['status'] = 'OK';
        return resultWithStatus;
      }

      final result = await getDistanceMatrix(origin, destination, mode: mode);

      if (result != null) {
        final Map<String, String> resultWithStatus = Map.from(result);
        resultWithStatus['status'] = 'OK';
        return resultWithStatus;
      }

      return null;
    } catch (e) {
      debugPrint('Error in getLocationTimeAndDistance: $e');
      if (mode == "bicycling") {
        return {
          'status': 'ZERO_RESULTS',
          'distance': 'Not available',
          'duration': 'Not available'
        };
      }
      return null;
    }
  }

  Future<LatLng?> searchPlace(String query) async {
    final cacheKey = 'place_$query';

    final cachedResult = _getFromCache(cacheKey);
    if (cachedResult != null) {
      if (cachedResult is LatLng) {
        return cachedResult;
      }
    }

    if (!await _isInternetAvailable()) {
      return null;
    }

    final sessionToken = _getSessionToken();

    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=$apiKey&sessiontoken=$sessionToken';

    final response = await _safeHttpGet(url, errorContext: 'searchPlace');
    if (response == null) return null;

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          final result = LatLng(location['lat'], location['lng']);

          _addToCache(cacheKey, result);

          _resetSessionToken();

          return result;
        } else {
          debugPrint('Geocoding error: ${data['status']}');
        }
      } catch (e) {
        debugPrint('Error parsing search place data: $e');
        }
      } else {
      debugPrint('HTTP error: ${response.statusCode}');
    }

    return null;
  }

  Future<LatLng?> getPlaceDetails(String placeId) async {
    final cacheKey = 'details_$placeId';

    final cachedResult = _getFromCache(cacheKey);
    if (cachedResult != null) {
      if (cachedResult is LatLng) {
        return cachedResult;
      }
    }

    if (!await _isInternetAvailable()) {
      return null;
    }

    final sessionToken = _getSessionToken();

    final url = 'https://maps.googleapis.com/maps/api/place/details/json?'
        'place_id=$placeId&'
        'fields=geometry&'
        'sessiontoken=$sessionToken&'
        'key=$apiKey';

    final response = await _safeHttpGet(url, errorContext: 'getPlaceDetails');
    if (response == null) return null;

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['result'] != null) {
          final location = data['result']['geometry']['location'];
          final result = LatLng(location['lat'], location['lng']);

          _addToCache(cacheKey, result);

          _resetSessionToken();

          return result;
        } else {
          debugPrint('Place details error: ${data['status']}');
      }
    } catch (e) {
        debugPrint('Error parsing place details data: $e');
      }
    } else {
      debugPrint('HTTP error: ${response.statusCode}');
    }

    return null;
  }

  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(String input, {LatLng? currentLocation}) async {
    if (input.length < _minAutocompleteChars) {
      return [];
    }

    if (_lastQuery == input) {
      final suggestions = _getSuggestionsFromCache('autocomplete_$input');
      if (suggestions.isNotEmpty) {
        return suggestions;
      }
    }

    _lastQuery = input;
    _autocompleteDebounce?.cancel();

    final completer = Completer<List<PlaceSuggestion>>();

    _autocompleteDebounce = Timer(const Duration(milliseconds: 1000), () async {
      final cacheKey = 'autocomplete_$input';

      List<PlaceSuggestion> suggestions = _getSuggestionsFromCache(cacheKey);

      if (suggestions.isEmpty) {
        suggestions = await _fetchSuggestionsFromApi(input, currentLocation, cacheKey);
      }

      if (currentLocation != null && suggestions.isNotEmpty && await _isInternetAvailable()) {
        await _enrichSuggestionsWithLocationData(suggestions, currentLocation);
      }

      completer.complete(suggestions);
    });

    return completer.future;
  }

  List<PlaceSuggestion> _getSuggestionsFromCache(String cacheKey) {
    final cachedSuggestions = _getFromCache(cacheKey);
    if (cachedSuggestions != null) {
      try {
        List<PlaceSuggestion> suggestions = [];
        for (var item in (cachedSuggestions as List)) {
          if (item is PlaceSuggestion) {
            suggestions.add(item);
          }
        }
        return suggestions;
      } catch (e) {
        debugPrint('Error retrieving cached suggestions: $e');
      }
    }
    return [];
  }

  Future<List<PlaceSuggestion>> _fetchSuggestionsFromApi(
      String input, LatLng? currentLocation, String cacheKey) async {
    if (!await _isInternetAvailable()) {
      return [];
    }

    final sessionToken = _getSessionToken();
    var url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$apiKey&sessiontoken=$sessionToken';

    if (_countryRestrictions.isNotEmpty) {
      url += '&components=country:${_countryRestrictions.join('|country:')}';
    }

    if (currentLocation != null) {
      url += '&location=${currentLocation.latitude},${currentLocation.longitude}&radius=50000';
    }

    final response = await _safeHttpGet(url, errorContext: 'getAutocompleteSuggestions');
    if (response == null) {
      return [];
    }

      if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final List predictions = data['predictions'];
          final suggestions = predictions
              .map((json) => PlaceSuggestion.fromJson(json))
              .toList();

          _addToCache(cacheKey, suggestions);
          return suggestions;
        } else {
          debugPrint('Autocomplete error: ${data['status']}');
        }
      } catch (e) {
        debugPrint('Error parsing autocomplete data: $e');
      }
    } else {
      debugPrint('HTTP error: ${response.statusCode}');
    }

    return [];
  }

  Future<void> _enrichSuggestionsWithLocationData(
      List<PlaceSuggestion> suggestions, LatLng currentLocation) async {
    final suggestionsToProcess = suggestions.take(5).toList();

    for (var suggestion in suggestionsToProcess) {
      final locationCacheKey = 'details_${suggestion.placeId}';
      final cachedLocation = _getFromCache(locationCacheKey);
      if (cachedLocation != null && cachedLocation is LatLng) {
        suggestion.location = cachedLocation;
      }
    }

    final suggestionsNeedingLocations = suggestionsToProcess
        .where((s) => s.location == null)
        .toList();

    if (suggestionsNeedingLocations.isNotEmpty) {
      try {
        await Future.wait(
            suggestionsNeedingLocations.map((suggestion) async {
              suggestion.location = await getPlaceDetails(suggestion.placeId);
            })
        );
      } catch (e) {
        debugPrint('Error fetching place details: $e');
      }
    }

    final locationsToProcess = suggestionsToProcess
        .where((s) => s.location != null)
        .toList();

    if (locationsToProcess.isEmpty) return;

    final suggestion = locationsToProcess[0];
    final distanceInfo = await getDistanceMatrix(
        currentLocation,
        suggestion.location!
    );

    if (distanceInfo != null) {
      suggestion.distance = distanceInfo['distance'];
      suggestion.duration = distanceInfo['duration'];
    }

    Future.delayed(Duration.zero, () async {
      for (int i = 1; i < locationsToProcess.length; i++) {
        if (!await _isInternetAvailable()) break;

        try {
          final suggestion = locationsToProcess[i];
          final distanceInfo = await getDistanceMatrix(
              currentLocation,
              suggestion.location!
          );

          if (distanceInfo != null) {
            suggestion.distance = distanceInfo['distance'];
            suggestion.duration = distanceInfo['duration'];
          }
        } catch (e) {
          debugPrint('Error getting distance for suggestion $i: $e');
        }

        await Future.delayed(const Duration(milliseconds: 100));
      }
    });
  }

  List<LatLng> _decodePoly(String poly) {
    List<LatLng> polyline = [];
    int index = 0, len = poly.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  Future<List<dynamic>?> getRoutePolylines({
    required LatLng origin,
    required LatLng destination,
    String mode = "driving",
    bool includeTransitDetails = false,
  }) async {
    if (!await _isInternetAvailable()) {
      return null;
    }

    final originRounded = _roundCoordinates(origin);
    final destinationRounded = _roundCoordinates(destination);
    final cacheKey = 'route_${originRounded.latitude},${originRounded.longitude}_${destinationRounded.latitude},${destinationRounded.longitude}_$mode';

    return mode == "transit"
        ? await _getTransitRoutePolylines(origin, destination, cacheKey)
        : await _getStandardRoutePolylines(origin, destination, mode, cacheKey);
  }

  Future<List<dynamic>?> _getTransitRoutePolylines(
      LatLng origin, LatLng destination, String cacheKey) async {
    _cache.remove(cacheKey);

    final url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}&'
        'mode=transit&alternatives=true&key=$apiKey&departure_time=1744449793';

    final response = await _safeHttpGet(url, errorContext: 'getTransitRoutePolylines');
    if (response == null) return null;

    final data = jsonDecode(response.body);
    if (data['status'] != 'OK' || data['routes'].isEmpty) {
      debugPrint('Transit route API error: ${data['status']}');
      return null;
    }

    try {
      final route = data['routes'][0];
      final points = _decodePoly(route['overview_polyline']['points']);
      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: Colors.purple.shade700,
        width: 5,
      );

      final leg = route['legs'][0];
      final List<LatLng> stops = [LatLng(leg['start_location']['lat'], leg['start_location']['lng'])];
      final List<Map<String, dynamic>> transitDetails = [];

      for (final step in leg['steps']) {
        if (step['travel_mode'] == 'TRANSIT') {
          final transitDetail = _extractTransitDetail(step);
          transitDetails.add(transitDetail);

          final transit = step['transit_details'];
          final departure = transit['departure_stop'];
          final arrival = transit['arrival_stop'];

          stops.add(LatLng(departure['location']['lat'], departure['location']['lng']));
          stops.add(LatLng(arrival['location']['lat'], arrival['location']['lng']));
        }
      }

      stops.add(LatLng(leg['end_location']['lat'], leg['end_location']['lng']));

      final Set<Polyline> polylines = {polyline};
      final List<dynamic> result = [
        polylines,
        stops,
        transitDetails,
        {
          'status': 'OK',
          'totalDuration': leg['duration']['text'],
          'distance': leg['distance']['text'],
        }
      ];

      return result;
    } catch (e) {
      debugPrint('Error processing transit route polyline: $e');
      return null;
    }
  }

  Map<String, dynamic> _extractTransitDetail(Map<String, dynamic> step) {
    final transit = step['transit_details'];
    final vehicle = transit['line']['vehicle'];
    final departure = transit['departure_stop'];
    final arrival = transit['arrival_stop'];

    String transportType = 'Bus';
    final vehicleType = vehicle['type'].toString().toLowerCase();
    if (vehicleType.contains('tram')) {
      transportType = 'Tram';
    } else if (vehicleType.contains('subway') || vehicleType.contains('metro')) {
      transportType = 'Subway';
    } else if (vehicleType.contains('train') || vehicleType.contains('rail')) {
      transportType = 'Train';
    }

    final lineName = transit['line']['short_name'] ?? transit['line']['name'] ?? 'Line';
    int colorValue = Colors.purple.shade700.value;

    if (transit['line']['color'] != null) {
      try {
        final colorHex = transit['line']['color'];
        colorValue = int.parse('0xFF${colorHex.substring(1)}');
      } catch (e) {
        debugPrint('Error parsing transit color: $e');
      }
    }

    return {
      'line': lineName,
      'color': colorValue,
      'type': transportType,
      'stops': transit['num_stops']?.toString() ?? '?',
      'duration': step['duration']?['text'] ?? '? min',
      'from': departure['name'] ?? 'Unknown',
      'to': arrival['name'] ?? 'Unknown',
      'startLocation': {
        'lat': departure['location']['lat'],
        'lng': departure['location']['lng']
      },
      'endLocation': {
        'lat': arrival['location']['lat'],
        'lng': arrival['location']['lng']
      },
      'isOnboard': false,
    };
  }

  Future<List<dynamic>?> _getStandardRoutePolylines(
      LatLng origin, LatLng destination, String mode, String cacheKey) async {
    final cachedResult = _getFromCache(cacheKey);
    if (cachedResult != null) {
      try {
        return cachedResult as List<dynamic>;
      } catch (e) {
        debugPrint('Error converting cached route data: $e');
      }
    }

    final url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}&'
        'mode=$mode&key=$apiKey&departure_time=1744449793';

    final response = await _safeHttpGet(url, errorContext: 'getRoutePolylines');
    if (response == null) return null;

    final data = jsonDecode(response.body);
    if (data['status'] != 'OK' || data['routes'].isEmpty) {
      debugPrint('Route API error: ${data['status']}');
      return [<LatLng>[], <LatLng>[], <Map<String, dynamic>>[], {'status': data['status']}];
    }

    try {
      final points = _decodePoly(data['routes'][0]['overview_polyline']['points']);
      final Set<Polyline> polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: _getColorForTransportMode(mode),
          width: 5,
        )
      };

      final List<dynamic> result = [
        polylines,
        <LatLng>[],
        <Map<String, dynamic>>[],
        {'status': data['status']}
      ];

      _addToCache(cacheKey, result);
      return result;
    } catch (e) {
      debugPrint('Error processing route polyline: $e');
    return null;
  }
}

  void clearCache() {
    _cache.clear();
  }

  Color _getColorForTransportMode(String mode) {
    switch (mode) {
      case 'driving':
        return Colors.blue.shade700;
      case 'walking':
        return Colors.green.shade700;
      case 'bicycling':
        return Colors.orange.shade700;
      case 'transit':
        return Colors.purple.shade700;
      case 'two_wheeler':
        return Colors.red.shade700;
      default:
        return Colors.blue.shade700;
    }
  }
}