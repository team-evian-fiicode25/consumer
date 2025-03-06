import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

const String defaultUrl = "http://10.0.2.2:8000/api/consumer";

class HttpService {
  final String baseUrl;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  HttpService({this.baseUrl = defaultUrl});

  Future<Map<String, dynamic>> request({
    required String endpoint,
    String method = 'GET',
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    headers ??= {
      'Content-Type': 'application/json',
    };

    final sessionToken = await secureStorage.read(key: 'session_id');
    if (sessionToken != null && sessionToken.isNotEmpty) {
      headers['Session-Id'] = sessionToken;
    }

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(url, headers: headers, body: body != null ? jsonEncode(body) : null);
          break;
        case 'PUT':
          response = await http.put(url, headers: headers, body: body != null ? jsonEncode(body) : null);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        case 'GET':
        default:
          response = await http.get(url, headers: headers);
          break;
      }

      return _handleResponse(response);
    } catch (e) {
      throw Exception("HTTP Request failed: $e");
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      } else {
        return {};
      }
    } else {
      throw Exception("Error ${response.statusCode}: ${response.body}");
    }
  }
}
