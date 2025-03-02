import 'dart:convert';
import 'package:http/http.dart' as http;

const String defaultUrl = "http://10.0.2.2:8000/api/consumer";

class HttpService {
  final String baseUrl;

  HttpService({this.baseUrl = defaultUrl });

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

    http.Response response;

    try {
      if (method == 'POST') {
        response = await http.post(url, headers: headers, body: jsonEncode(body));
      } else if (method == 'PUT') {
        response = await http.put(url, headers: headers, body: jsonEncode(body));
      } else if (method == 'DELETE') {
        response = await http.delete(url, headers: headers);
      } else {
        response = await http.get(url, headers: headers);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body); // Return parsed JSON
      } else {
        throw Exception("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      throw Exception("HTTP Request failed: $e");
    }
  }
}
