import '../models/user_profile.dart';
import '../models/user_register.dart';
import 'http_service.dart' as http;

const String loginEndpoint = "/auth/login";
const String registerEndpoint = "/auth/register";

class AuthService {
  final http.HttpService httpService = http.HttpService();

  Future<UserProfile> login(String identifier, String password) async {
    final response = await httpService.request(
      endpoint: loginEndpoint,
      method: 'POST',
      body: {"identifier": identifier, "password": password},
    );

    final Map<String, dynamic> data = response;

    if (data.containsKey("error")) {
      throw Exception(data["error"]);
    }

    return UserProfile.fromJson(data);
  }

  Future<UserProfile> register(UserRegister user) async {
    final response = await httpService.request(
      endpoint: registerEndpoint,
      method: 'POST',
      body: user.toJson(),
    );

    final Map<String, dynamic> data = response;

    if (data.containsKey("error")) {
      throw Exception(data["error"]);
    }

    return UserProfile.fromJson(data);
  }
}
