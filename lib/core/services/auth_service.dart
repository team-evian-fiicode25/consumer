import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'http_service.dart' as http;
import '../models/user_register.dart';

const String loginEndpoint = "/auth/login";
const String registerEndpoint = "/auth/register";

class AuthService {
  final http.HttpService httpService = http.HttpService();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Future<String> login(String identifier, String password) async {
    final response = await httpService.request(
      endpoint: loginEndpoint,
      method: 'POST',
      body: {"identifier": identifier, "password": password},
    );

    final Map<String, dynamic> data = response;
    if (data.containsKey("error")) {
      throw Exception(data["error"]);
    }

    final String? sessionToken = data["session_id"];
    if (sessionToken == null) {
      throw Exception("No session token received");
    }

    await secureStorage.write(key: "session_id", value: sessionToken);

    return sessionToken;
  }

  Future<String> register(UserRegister user) async {
    final response = await httpService.request(
      endpoint: registerEndpoint,
      method: 'POST',
      body: user.toJson(),
    );

    final Map<String, dynamic> data = response;
    if (data.containsKey("error")) {
      throw Exception(data["error"]);
    }

    final String? sessionToken = data["session_id"];
    if (sessionToken == null) {
      throw Exception("No session token received");
    }

    await secureStorage.write(key: "session_id", value: sessionToken);

    return sessionToken;
  }

  Future<String?> getSessionToken() async {
    return await secureStorage.read(key: "session_id");
  }

  Future<void> clearSession() async {
    await secureStorage.delete(key: "session_id");
  }
}
