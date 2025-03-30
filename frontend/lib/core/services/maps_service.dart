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
  final List<String> _countryRestrictions = ['ro', 'md'];
  
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
        'mode=$mode&key=$apiKey';
    
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
      String modeParam = mode;
      
      switch (mode) {
        case "bicycling":
          modeParam = "bicycling";
          break;
        case "two_wheeler":
          modeParam = "two_wheeler";
          break;
        case "walking":
          modeParam = "walking";
          break;
        case "transit":
          modeParam = "transit";
          
          final alternatives = await getTransitAlternatives(origin, destination);
          if (alternatives != null && alternatives.isNotEmpty) {
            alternatives.sort((a, b) {
              final aInfo = a[3] as Map<String, dynamic>;
              final bInfo = b[3] as Map<String, dynamic>;
              
              final aDuration = aInfo['totalDuration'];
              final bDuration = bInfo['totalDuration'];
              
              if (aDuration.contains('min') && bDuration.contains('min')) {
                final aMinutes = int.tryParse(aDuration.split(' ')[0]) ?? 0;
                final bMinutes = int.tryParse(bDuration.split(' ')[0]) ?? 0;
                return aMinutes.compareTo(bMinutes);
              }
              
              return 0;
            });
            
            final bestRoute = alternatives.first;
            final routeInfo = bestRoute[3] as Map<String, dynamic>;
            
            return {
              'distance': 'Varies',
              'duration': routeInfo['totalDuration'],
              'status': 'OK'
            };
          }
          break;
        case "driving":
        default:
          modeParam = "driving";
          break;
      }
      
      if (mode == "bicycling") {
        final directUrl = 'https://maps.googleapis.com/maps/api/directions/json?'
            'origin=${origin.latitude},${origin.longitude}&'
            'destination=${destination.latitude},${destination.longitude}&'
            'mode=bicycling&key=$apiKey';
            
        final directResponse = await _safeHttpGet(directUrl, errorContext: 'getBicyclingDirections');
        if (directResponse != null && directResponse.statusCode == 200) {
          final data = json.decode(directResponse.body);
          if (data['status'] == 'ZERO_RESULTS') {
            return {'status': 'ZERO_RESULTS', 'distance': 'N/A', 'duration': 'N/A'};
          }
        }
      }
      
      final result = await getDistanceMatrix(origin, destination, mode: modeParam);
      
      if (result == null && mode == "bicycling") {
        return {'status': 'ZERO_RESULTS', 'distance': 'N/A', 'duration': 'N/A'};
      }
      
      if (result != null) {
        final Map<String, String> resultWithStatus = Map.from(result);
        resultWithStatus['status'] = 'OK';
        return resultWithStatus;
      }
      
      return result;
    } catch (e) {
      debugPrint('Error in getLocationTimeAndDistance: $e');
      if (mode == "bicycling") {
        return {'status': 'ZERO_RESULTS', 'distance': 'N/A', 'duration': 'N/A'};
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
      final cacheKey = 'autocomplete_$input';
      final cachedSuggestions = _getFromCache(cacheKey);
      if (cachedSuggestions != null) {
        try {
          List<PlaceSuggestion> suggestions = [];
          for (var item in (cachedSuggestions as List)) {
            if (item is PlaceSuggestion) {
              suggestions.add(item);
            }
          }
          
          if (suggestions.isNotEmpty) {
            return suggestions;
          }
        } catch (e) {
          debugPrint('Error retrieving cached suggestions: $e');
        }
      }
    }
    
    _lastQuery = input;
    
    _autocompleteDebounce?.cancel();
    
    final completer = Completer<List<PlaceSuggestion>>();
    
    _autocompleteDebounce = Timer(const Duration(milliseconds: 1000), () async {
      final cacheKey = 'autocomplete_$input';
      
      List<PlaceSuggestion>? suggestions;
      final cachedSuggestions = _getFromCache(cacheKey);
      
      if (cachedSuggestions != null) {
        try {
          suggestions = [];
          for (var item in (cachedSuggestions as List)) {
            if (item is PlaceSuggestion) {
              suggestions.add(item);
            }
          }
          
          if (suggestions.isEmpty) {
            throw Exception('Failed to convert cached suggestions');
          }
        } catch (e) {
          debugPrint('Error converting cached suggestions: $e');
          suggestions = null;
        }
      }
      
      if (suggestions == null) {
        if (!await _isInternetAvailable()) {
          completer.complete([]);
          return;
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
          completer.complete([]);
          return;
        }
        
      if (response.statusCode == 200) {
          try {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final List predictions = data['predictions'];
              suggestions = predictions
              .map((json) => PlaceSuggestion.fromJson(json))
              .toList();
              
              _addToCache(cacheKey, suggestions);
            } else {
              debugPrint('Autocomplete error: ${data['status']}');
              completer.complete([]);
              return;
            }
          } catch (e) {
            debugPrint('Error parsing autocomplete data: $e');
            completer.complete([]);
            return;
          }
        } else {
          debugPrint('HTTP error: ${response.statusCode}');
          completer.complete([]);
          return;
        }
      }
      
      if (currentLocation != null && suggestions.isNotEmpty && await _isInternetAvailable()) {
        final suggestionsToProcess = suggestions.take(3).toList();
        
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
            
        if (locationsToProcess.isNotEmpty) {
          try {
            final firstSuggestion = locationsToProcess.first;
            final distanceInfo = await getDistanceMatrix(
              currentLocation, 
              firstSuggestion.location!
            );
            
            if (distanceInfo != null) {
              firstSuggestion.distance = distanceInfo['distance'];
              firstSuggestion.duration = distanceInfo['duration'];
            }
          } catch (e) {
            debugPrint('Error getting distance for first suggestion: $e');
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
      }
      
      completer.complete(suggestions ?? []);
    });
    
    return completer.future;
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
    
    if (mode == "transit") {
      _cache.remove(cacheKey);
    } else {
      final cachedResult = _getFromCache(cacheKey);
      if (cachedResult != null) {
        try {
          return cachedResult as List<dynamic>;
        } catch (e) {
          debugPrint('Error converting cached route data: $e');
        }
      }
    }

    final url = mode == "transit" 
        ? 'https://maps.googleapis.com/maps/api/directions/json?'
            'origin=${origin.latitude},${origin.longitude}&'
            'destination=${destination.latitude},${destination.longitude}&'
            'alternatives=true&mode=$mode&transit_mode=bus|tram&transit_routing_preference=fewer_transfers&key=$apiKey'
        : 'https://maps.googleapis.com/maps/api/directions/json?'
            'origin=${origin.latitude},${origin.longitude}&'
            'destination=${destination.latitude},${destination.longitude}&'
            'alternatives=true&mode=$mode&key=$apiKey';

    final response = await _safeHttpGet(url, errorContext: 'getRoutePolylines');
    if (response == null) return null;

    final data = jsonDecode(response.body);
    if (data['status'] != 'OK' || data['routes'].isEmpty) {
      debugPrint('Route API error: ${data['status']}');
      return null;
    }

    try {
      List<dynamic> alternatives = [];
      
      final points = _decodePoly(data['routes'][0]['overview_polyline']['points']);
      alternatives.add(points);
      
      if (mode == "transit") {
        List<LatLng> stopsLocations = [];
        List<Map<String, dynamic>> transitDetails = [];
        
        if (data['routes'][0]['legs'] != null && data['routes'][0]['legs'].isNotEmpty) {
          final legs = data['routes'][0]['legs'][0];
          
          stopsLocations.add(LatLng(
            legs['start_location']['lat'],
            legs['start_location']['lng']
          ));
          
          if (legs['steps'] != null && includeTransitDetails) {
            for (var step in legs['steps']) {
              if (step['transit_details'] != null) {
                final transitDetail = step['transit_details'];
                final vehicle = transitDetail['line']['vehicle'];
                final vehicleType = vehicle['type']?.toString().toLowerCase() ?? 'bus';
                
                String transportType = 'Bus';
                
                if (vehicleType.contains('tram')) {
                  transportType = 'Tram';
                } else if (vehicleType.contains('subway') || vehicleType.contains('metro')) {
                  transportType = 'Subway';
                } else if (vehicleType.contains('train') || vehicleType.contains('rail')) {
                  transportType = 'Train';
                }
                
                final lineName = transitDetail['line']['short_name'] ??
                                transitDetail['line']['name'] ?? '';
                
                int colorValue = Colors.blue.value;
                if (transitDetail['line']['color'] != null) {
                  try {
                    final colorHex = transitDetail['line']['color'];
                    final color = Color(int.parse('0xFF${colorHex.substring(1)}'));
                    colorValue = color.value;
                  } catch (e) {
                    debugPrint('Error parsing transit color: $e');
                  }
                }
                
                String duration = '';
                if (transitDetail['duration'] != null) {
                  try {
                    final mins = transitDetail['duration']['value'] ~/ 60;
                    duration = '$mins min';
                  } catch (e) {
                    debugPrint('Error parsing transit duration: $e');
                    duration = '? min';
                  }
                }
                
                int stopsCount = 0;
                if (transitDetail['num_stops'] != null) {
                  stopsCount = transitDetail['num_stops'];
                }
                
                final from = transitDetail['departure_stop']['name'] ?? 'Unknown stop';
                final to = transitDetail['arrival_stop']['name'] ?? 'Unknown stop';
                
                String extra = '';
                if (transitDetail['headway'] != null) {
                  final headwayMins = transitDetail['headway'] ~/ 60;
                  extra = 'Every $headwayMins minutes';
                } else if (transitDetail['line']['agencies'] != null && 
                         transitDetail['line']['agencies'].length > 0) {
                  extra = transitDetail['line']['agencies'][0]['name'] ?? '';
                }
                
                transitDetails.add({
                  'type': transportType,
                  'line': lineName,
                  'color': colorValue,
                  'from': from,
                  'to': to,
                  'duration': duration,
                  'stops': stopsCount,
                  'extra': extra,
                });
                
                if (transitDetail['departure_stop'] != null) {
                  stopsLocations.add(LatLng(
                    transitDetail['departure_stop']['location']['lat'],
                    transitDetail['departure_stop']['location']['lng']
                  ));
                }
                
                if (transitDetail['arrival_stop'] != null) {
                  stopsLocations.add(LatLng(
                    transitDetail['arrival_stop']['location']['lat'],
                    transitDetail['arrival_stop']['location']['lng']
                  ));
                }
              }
            }
          }
          
          stopsLocations.add(LatLng(
            legs['end_location']['lat'],
            legs['end_location']['lng']
          ));
          
          alternatives.add(stopsLocations);
          
          if (includeTransitDetails) {
            alternatives.add(transitDetails);
          }
        }
      }
      
      alternatives.add({'status': data['status']});
      
      _addToCache(cacheKey, alternatives);
      
      return alternatives;
    } catch (e) {
      debugPrint('Error processing route polyline: $e');
      return null;
    }
  }
  
  void clearCache() {
    _cache.clear();
  }

  Future<List<List<dynamic>>?> getTransitAlternatives(LatLng origin, LatLng destination) async {
    if (!await _isInternetAvailable()) {
      return null;
    }
    
    final List<String> routingPreferences = [
      'bus',
      'less_walking',
      'fewer_transfers',
    ];
    
    List<List<dynamic>> allRoutes = [];
    
    for (final preference in routingPreferences) {
      final url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'alternatives=true&mode=transit&transit_routing_preference=$preference&key=$apiKey';
      
      final response = await _safeHttpGet(url, errorContext: 'getTransitAlternatives:$preference');
      
      if (response == null) continue;
      
      final data = jsonDecode(response.body);
      if (data['status'] != 'OK' || data['routes'].isEmpty) {
        debugPrint('Route API error for $preference: ${data['status']}');
        continue;
      }
      
      try {
        for (final route in data['routes']) {
          List<dynamic> routeDetails = [];
          
          final points = _decodePoly(route['overview_polyline']['points']);
          routeDetails.add(points);
          
          List<LatLng> stopsLocations = [];
          List<Map<String, dynamic>> transitDetails = [];
          
          if (route['legs'] != null && route['legs'].isNotEmpty) {
            final legs = route['legs'][0];
            
            stopsLocations.add(LatLng(
              legs['start_location']['lat'],
              legs['start_location']['lng']
            ));
            
            if (legs['steps'] != null) {
              for (var step in legs['steps']) {
                if (step['transit_details'] != null) {
                  final transitDetail = step['transit_details'];
                  final vehicle = transitDetail['line']['vehicle'];
                  final vehicleType = vehicle['type']?.toString().toLowerCase() ?? 'bus';
                  
                  String transportType = 'Bus';
                  
                  if (vehicleType.contains('tram')) {
                    transportType = 'Tram';
                  } else if (vehicleType.contains('subway') || vehicleType.contains('metro')) {
                    transportType = 'Subway';
                  } else if (vehicleType.contains('train') || vehicleType.contains('rail')) {
                    transportType = 'Train';
                  }
                  
                  final lineName = transitDetail['line']['short_name'] ??
                                  transitDetail['line']['name'] ?? '';
                  
                  int colorValue = Colors.blue.value;
                  if (transitDetail['line']['color'] != null) {
                    try {
                      final colorHex = transitDetail['line']['color'];
                      final color = Color(int.parse('0xFF${colorHex.substring(1)}'));
                      colorValue = color.value;
                    } catch (e) {
                      debugPrint('Error parsing transit color: $e');
                    }
                  }
                  
                  String duration = '';
                  if (transitDetail['duration'] != null) {
                    try {
                      final mins = transitDetail['duration']['value'] ~/ 60;
                      duration = '$mins min';
                    } catch (e) {
                      debugPrint('Error parsing transit duration: $e');
                      duration = '? min';
                    }
                  }
                  
                  int stopsCount = 0;
                  if (transitDetail['num_stops'] != null) {
                    stopsCount = transitDetail['num_stops'];
                  }
                  
                  final from = transitDetail['departure_stop']['name'] ?? 'Unknown stop';
                  final to = transitDetail['arrival_stop']['name'] ?? 'Unknown stop';
                  
                  String extra = '';
                  if (transitDetail['headway'] != null) {
                    final headwayMins = transitDetail['headway'] ~/ 60;
                    extra = 'Every $headwayMins minutes';
                  } else if (transitDetail['line']['agencies'] != null && 
                           transitDetail['line']['agencies'].length > 0) {
                    extra = transitDetail['line']['agencies'][0]['name'] ?? '';
                  }
                  
                  transitDetails.add({
                    'type': transportType,
                    'line': lineName,
                    'color': colorValue,
                    'from': from,
                    'to': to,
                    'duration': duration,
                    'stops': stopsCount,
                    'extra': extra,
                  });
                  
                  if (transitDetail['departure_stop'] != null) {
                    stopsLocations.add(LatLng(
                      transitDetail['departure_stop']['location']['lat'],
                      transitDetail['departure_stop']['location']['lng']
                    ));
                  }
                  
                  if (transitDetail['arrival_stop'] != null) {
                    stopsLocations.add(LatLng(
                      transitDetail['arrival_stop']['location']['lat'],
                      transitDetail['arrival_stop']['location']['lng']
                    ));
                  }
                }
              }
            }
            
            stopsLocations.add(LatLng(
              legs['end_location']['lat'],
              legs['end_location']['lng']
            ));
            
            routeDetails.add(stopsLocations);
            routeDetails.add(transitDetails);
            
            if (transitDetails.isNotEmpty) {
              bool containsBus = transitDetails.any((detail) => detail['type'] == 'Bus');
              String totalDuration = legs['duration']['text'] ?? '';
              
              debugPrint('Found route with ${transportType(preference)}: ${transitDetails.length} segments, ${containsBus ? "HAS BUS" : "NO BUS"}, duration: $totalDuration');
              
              routeDetails.add({
                'preference': preference,
                'containsBus': containsBus,
                'totalDuration': totalDuration
              });
              
              allRoutes.add(routeDetails);
            }
          }
        }
      } catch (e) {
        debugPrint('Error processing $preference route: $e');
      }
    }
    
    if (allRoutes.isEmpty) {
      return null;
    }
    
    return allRoutes;
  }
  
  String transportType(String preference) {
    switch (preference) {
      case 'bus': return 'Bus Preference';
      case 'less_walking': return 'Less Walking';
      case 'fewer_transfers': return 'Fewer Transfers';
      default: return preference;
    }
  }
}
