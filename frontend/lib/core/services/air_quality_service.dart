import 'dart:convert';
import 'dart:typed_data';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class AirQualityService {
  static const String baseUrl = 'https://airquality.googleapis.com/v1';
  static const String mapType = 'UAQI_RED_GREEN';
  static const String apiKey = 'AIzaSyA-XTPqXuzaHM2EcpKaqd97Kg9sPzjrttA';

  static TileOverlay getAirQualityOverlay(String overlayId) {
    return TileOverlay(
      tileOverlayId: TileOverlayId(overlayId),
      tileProvider: _AirQualityTileProvider(
        mapType: mapType,
        apiKey: apiKey,
      ),
      transparency: 0.5,
    );
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
      final response = await http.post(
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

  _AirQualityTileProvider({
    required this.mapType,
    required this.apiKey,
  });

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    if (zoom == null) {
      return TileProvider.noTile;
    }

    final url = '${AirQualityService.baseUrl}/mapTypes/$mapType/heatmapTiles/$zoom/$x/$y?key=$apiKey';
    return Tile(256, 256, url.codeUnits as Uint8List?);
  }
}