import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class AirQualityService {
  static const String baseUrl = 'https://airquality.googleapis.com/v1';
  static const String defaultMapType = 'UAQI_RED_GREEN';
  static const String apiKey = 'AIzaSyA-XTPqXuzaHM2EcpKaqd97Kg9sPzjrttA';

  static const Map<String, String> mapTypes = {
    'UAQI_RED_GREEN': 'Universal AQI (Red-Green)',
    'US_AQI': 'US AQI',
    'UAQI_GREEN_BLUE': 'Universal AQI (Green-Blue)',
    'UAQI_PURPLE_GREEN': 'Universal AQI (Purple-Green)',
  };

  static final Map<String, _AirQualityTileProvider> _tileProviders = {};
  static final http.Client _httpClient = http.Client();
  
  static LatLng? _lastPreloadedLocation;
  static String? _lastPreloadedMapType;
  static bool _isLoadingTiles = false;
  
  static void clearAllCaches() {
    _tileProviders.forEach((_, provider) {
      provider.clearCache();
    });
    _lastPreloadedLocation = null;
    _lastPreloadedMapType = null;
  }
  
  static void refreshTileProvider(String mapType) {
    if (_tileProviders.containsKey(mapType)) {
      _tileProviders[mapType]!.clearCache();
    }
    _lastPreloadedLocation = null;
    _lastPreloadedMapType = null;
  }
  
  static void dispose() {
    _httpClient.close();
  }

  static TileOverlay getAirQualityOverlay(String overlayId, {String? mapType, double transparency = 0.1}) {
    final mapTypeToUse = mapType ?? defaultMapType;
    
    if (!_tileProviders.containsKey(mapTypeToUse)) {
      _tileProviders[mapTypeToUse] = _AirQualityTileProvider(
        mapType: mapTypeToUse,
        apiKey: apiKey,
        client: _httpClient,
      );
    }
    
    return TileOverlay(
      tileOverlayId: TileOverlayId(overlayId),
      tileProvider: _tileProviders[mapTypeToUse]!,
      transparency: transparency,
      zIndex: 1,
      fadeIn: true,
    );
  }
  
  static Future<void> preloadTilesForLocation(LatLng location, String mapType) async {
    if (_isLoadingTiles) {
      return;
    }
    
    _isLoadingTiles = true;
    
    try {
      if (_lastPreloadedLocation != null && 
          _lastPreloadedMapType == mapType &&
          _calculateDistance(
            _lastPreloadedLocation!.latitude, 
            _lastPreloadedLocation!.longitude,
            location.latitude, 
            location.longitude) < 200) {
        await _quickRefreshTiles(location, mapType);
        return;
      }

      if (!_tileProviders.containsKey(mapType)) {
        _tileProviders[mapType] = _AirQualityTileProvider(
          mapType: mapType,
          apiKey: apiKey,
          client: _httpClient,
        );
      }
      
      final tileProvider = _tileProviders[mapType]!;
      
      _lastPreloadedLocation = location;
      _lastPreloadedMapType = mapType;
      
      await _loadCriticalTilesImmediately(location, tileProvider);
      
      _loadAdditionalTilesInBackground(location, tileProvider);
    } finally {
      _isLoadingTiles = false;
    }
  }
  
  static Future<void> _quickRefreshTiles(LatLng location, String mapType) async {
    final tileProvider = _tileProviders[mapType]!;
    
    for (int zoom = 11; zoom <= 12; zoom++) {
      final tileCoords = _getTileCoordinatesForLocation(location, zoom);
      if (tileCoords != null) {
        final (x, y, _) = tileCoords;
        await tileProvider.priorityLoadTile(x, y, zoom);
      }
    }
  }
  
  static Future<void> _loadCriticalTilesImmediately(LatLng location, _AirQualityTileProvider tileProvider) async {
    final criticalZoomLevels = [11, 12];
    List<Future<void>> criticalTileFutures = [];
    
    for (final zoom in criticalZoomLevels) {
      final tileCoords = _getTileCoordinatesForLocation(location, zoom);
      if (tileCoords != null) {
        final (x, y, _) = tileCoords;
        
        criticalTileFutures.add(tileProvider.priorityLoadTile(x, y, zoom).then((_) {}));
        
        for (int dx = -1; dx <= 1; dx++) {
          for (int dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue;
            criticalTileFutures.add(tileProvider.prefetchTile(x + dx, y + dy, zoom));
          }
        }
      }
    }
    
    if (criticalTileFutures.isNotEmpty) {
      await Future.wait(criticalTileFutures);
    }
  }
  
  static void _loadAdditionalTilesInBackground(LatLng location, _AirQualityTileProvider tileProvider) {
    final backgroundZoomLevels = [7, 8, 9, 10, 13, 14]; 
    
    for (final zoom in backgroundZoomLevels) {
      final tileCoords = _getTileCoordinatesForLocation(location, zoom);
      if (tileCoords != null) {
        final (x, y, _) = tileCoords;
        
        final radius = zoom <= 10 ? 2 : 1;
        
        unawaited(tileProvider.prefetchTile(x, y, zoom));
        
        for (int r = 1; r <= radius; r++) {
          for (int i = -r; i <= r; i++) {
            unawaited(tileProvider.prefetchTile(x + i, y - r, zoom));
            unawaited(tileProvider.prefetchTile(x + i, y + r, zoom));
            
            if (i > -r && i < r) {
              unawaited(tileProvider.prefetchTile(x - r, y + i, zoom));
              unawaited(tileProvider.prefetchTile(x + r, y + i, zoom));
            }
          }
        }
      }
    }
    
    final baseZoom = 12;
    final baseTileCoords = _getTileCoordinatesForLocation(location, baseZoom);
    
    if (baseTileCoords != null) {
      final (baseX, baseY, _) = baseTileCoords;
      
      for (int projectedZoom = 15; projectedZoom <= 19; projectedZoom++) {
        final zoomDiff = projectedZoom - baseZoom;
        final scale = 1 << zoomDiff;
        
        final projectedX = baseX * scale;
        final projectedY = baseY * scale;
        
        tileProvider.projectTileForHigherZoom(baseZoom, baseX, baseY, projectedZoom, projectedX, projectedY);
      }
    }
  }
  
  static (int, int, int)? _getTileCoordinatesForLocation(LatLng location, int zoom) {
    try {
      final x = ((location.longitude + 180) / 360 * (1 << zoom)).floor();
      final y = ((1 - math.log(math.tan(location.latitude * math.pi / 180) + 
                 1 / math.cos(location.latitude * math.pi / 180)) / math.pi) / 
                 2 * (1 << zoom)).floor();
      return (x, y, zoom);
    } catch (e) {
      print('Error calculating tile coordinates: $e');
      return null;
    }
  }
  
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    
    final lat1Rad = lat1 * math.pi / 180;
    final lon1Rad = lon1 * math.pi / 180;
    final lat2Rad = lat2 * math.pi / 180;
    final lon2Rad = lon2 * math.pi / 180;
    
    final dLat = lat2Rad - lat1Rad;
    final dLon = lon2Rad - lon1Rad;
    final a = math.sin(dLat/2) * math.sin(dLat/2) +
              math.cos(lat1Rad) * math.cos(lat2Rad) *
              math.sin(dLon/2) * math.sin(dLon/2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
    
    return earthRadius * c;
  }

  static Future<Map<String, dynamic>?> getCurrentConditions({
    required LatLng location,
    List<String>? extraComputations,
    String? uaqiColorPalette,
    List<Map<String, dynamic>>? customLocalAqis,
    bool universalAqi = false,
    String? languageCode,
  }) async {
    final url = '$baseUrl/currentConditions:lookup?key=$apiKey';

    final body = {
      "location": {
        "latitude": location.latitude,
        "longitude": location.longitude,
      },
      if (extraComputations != null) "extraComputations": extraComputations,
      if (uaqiColorPalette != null) "uaqiColorPalette": uaqiColorPalette,
      if (customLocalAqis != null) "customLocalAqis": customLocalAqis,
      "universalAqi": universalAqi,
      if (languageCode != null) "languageCode": languageCode,
    };

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching current conditions: $e');
    }

    return null;
  }
}

class _AirQualityTileProvider implements TileProvider {
  final String mapType;
  final String apiKey;
  final http.Client client;
  final Map<String, Uint8List> _tileCache = {};
  final Set<String> _requestedTiles = {};
  
  final Set<int> _validZoomLevels = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19};
  final int _maxNativeZoom = 12;
  final int _minValidZoom = 0;
  
  static const int _maxCacheSize = 200;
  final List<String> _cacheAccessOrder = [];

  _AirQualityTileProvider({
    required this.mapType,
    required this.apiKey,
    required this.client,
  });

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    if (zoom == null) {
      return TileProvider.noTile;
    }

    final requestedKey = '$zoom-$x-$y';
    if (_tileCache.containsKey(requestedKey)) {
      _updateCacheAccessOrder(requestedKey);
      return Tile(256, 256, _tileCache[requestedKey]!);
    }
    
    if (zoom > _maxNativeZoom) {
      if (_tileCache.containsKey(requestedKey)) {
        _updateCacheAccessOrder(requestedKey);
        return Tile(256, 256, _tileCache[requestedKey]!);
      }
      
      final bestTile = _findBestAvailableTile(x, y, zoom);
      if (bestTile != null) {
        _tileCache[requestedKey] = bestTile;
        _updateCacheAccessOrder(requestedKey);
        return Tile(256, 256, bestTile);
      }
      
      final nativeZoom = _maxNativeZoom;
      final nativeCoords = _getParentTileCoordinates(x, y, zoom, nativeZoom);
      final nativeKey = '$nativeZoom-${nativeCoords.$1}-${nativeCoords.$2}';
      
      if (_requestedTiles.contains(nativeKey)) {
        return TileProvider.noTile;
      }
      
      _requestedTiles.add(nativeKey);
      _fetchTile(nativeCoords.$1, nativeCoords.$2, nativeZoom, nativeKey, requestedKey);
      
      return TileProvider.noTile;
    }
    
    if (_requestedTiles.contains(requestedKey)) {
      return TileProvider.noTile;
    }
    
    _requestedTiles.add(requestedKey);
    _fetchTile(x, y, zoom, requestedKey, requestedKey);
    
    return TileProvider.noTile;
  }
  
  Uint8List? _findBestAvailableTile(int x, int y, int zoom) {
    for (int z = zoom - 1; z >= _maxNativeZoom; z--) {
      final parentCoords = _getParentTileCoordinates(x, y, zoom, z);
      final parentKey = '$z-${parentCoords.$1}-${parentCoords.$2}';
      
      if (_tileCache.containsKey(parentKey)) {
        return _tileCache[parentKey];
      }
    }
    
    for (int z = _maxNativeZoom; z >= 7; z--) {
      final parentCoords = _getParentTileCoordinates(x, y, zoom, z);
      final parentKey = '$z-${parentCoords.$1}-${parentCoords.$2}';
      
      if (_tileCache.containsKey(parentKey)) {
        return _tileCache[parentKey];
      }
    }
    
    return null;
  }
  
  (int, int) _getParentTileCoordinates(int x, int y, int fromZoom, int toZoom) {
    if (fromZoom <= toZoom) return (x, y);
    
    final zoomDiff = fromZoom - toZoom;
    final scale = 1 << zoomDiff;
    return (x ~/ scale, y ~/ scale);
  }
  
  Future<void> _fetchTile(int x, int y, int zoom, String cacheKey, String requestedKey) async {
    if (_tileCache.containsKey(cacheKey)) {
      _requestedTiles.remove(cacheKey);
      return;
    }
    
    try {
      final url = '${AirQualityService.baseUrl}/mapTypes/$mapType/heatmapTiles/$zoom/$x/$y?key=$apiKey';
      
      final response = await client.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
          
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        _tileCache[cacheKey] = response.bodyBytes;
        _updateCacheAccessOrder(cacheKey);
        
        if (cacheKey != requestedKey && !_tileCache.containsKey(requestedKey)) {
          _tileCache[requestedKey] = response.bodyBytes;
          _updateCacheAccessOrder(requestedKey);
        }
        
        if (zoom == _maxNativeZoom) {
          _projectTileToHigherZooms(x, y, zoom, response.bodyBytes);
        }
      } else if (response.statusCode == 404) {
        _validZoomLevels.remove(zoom);
      }
    } catch (e) {
      print('Error fetching tile: $e');
    } finally {
      _requestedTiles.remove(cacheKey);
    }
  }
  
  void _projectTileToHigherZooms(int x, int y, int fromZoom, Uint8List tileData) {
    for (int toZoom = fromZoom + 1; toZoom <= fromZoom + 3; toZoom++) {
      final zoomDiff = toZoom - fromZoom;
      final scale = 1 << zoomDiff;
      
      final baseX = x * scale;
      final baseY = y * scale;
      
      final centerKey = '$toZoom-$baseX-$baseY';
      if (!_tileCache.containsKey(centerKey)) {
        _tileCache[centerKey] = tileData;
        _updateCacheAccessOrder(centerKey);
      }
    }
  }
  
  void projectTileForHigherZoom(int fromZoom, int fromX, int fromY, int toZoom, int toX, int toY) {
    final sourceKey = '$fromZoom-$fromX-$fromY';
    final targetKey = '$toZoom-$toX-$toY';
    
    if (_tileCache.containsKey(targetKey) || !_tileCache.containsKey(sourceKey)) {
      return;
    }
    
    _tileCache[targetKey] = _tileCache[sourceKey]!;
    _updateCacheAccessOrder(targetKey);
  }
  
  Future<void> prefetchTile(int x, int y, int zoom) async {
    final cacheKey = '$zoom-$x-$y';
    
    if (_tileCache.containsKey(cacheKey) || _requestedTiles.contains(cacheKey)) {
      return;
    }
    
    _requestedTiles.add(cacheKey);
    
    try {
      final url = '${AirQualityService.baseUrl}/mapTypes/$mapType/heatmapTiles/$zoom/$x/$y?key=$apiKey';
      
      final response = await client.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
          
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        _tileCache[cacheKey] = response.bodyBytes;
        _updateCacheAccessOrder(cacheKey);
        
        if (zoom == _maxNativeZoom) {
          _projectTileToHigherZooms(x, y, zoom, response.bodyBytes);
        }
      }
    } catch (e) {
      print('Error prefetching tile: $e');
    } finally {
      _requestedTiles.remove(cacheKey);
    }
  }
  
  Future<Uint8List?> priorityLoadTile(int x, int y, int zoom) async {
    final cacheKey = '$zoom-$x-$y';
    
    if (_tileCache.containsKey(cacheKey)) {
      _updateCacheAccessOrder(cacheKey);
      return _tileCache[cacheKey];
    }
    
    if (_requestedTiles.contains(cacheKey)) {
      return null;
    }
    
    _requestedTiles.add(cacheKey);
    
    try {
      final url = '${AirQualityService.baseUrl}/mapTypes/$mapType/heatmapTiles/$zoom/$x/$y?key=$apiKey';
      
      final response = await client.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
          
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        _tileCache[cacheKey] = response.bodyBytes;
        _updateCacheAccessOrder(cacheKey);
        
        if (zoom == _maxNativeZoom) {
          _projectTileToHigherZooms(x, y, zoom, response.bodyBytes);
        }
        
        return response.bodyBytes;
      }
    } catch (e) {
      print('Error loading priority tile: $e');
    } finally {
      _requestedTiles.remove(cacheKey);
    }
    
    return null;
  }
  
  void _updateCacheAccessOrder(String cacheKey) {
    _cacheAccessOrder.remove(cacheKey);
    _cacheAccessOrder.add(cacheKey);
    
    while (_cacheAccessOrder.length > _maxCacheSize) {
      final oldestKey = _cacheAccessOrder.removeAt(0);
      _tileCache.remove(oldestKey);
    }
  }
  
  void clearCache() {
    _tileCache.clear();
    _requestedTiles.clear();
    _cacheAccessOrder.clear();
  }
}