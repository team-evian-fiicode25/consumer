import 'dart:convert';
import 'http_service.dart' as http;

const String loginEndpoint = "/auth/login";
const String registerEndpoint = "/auth/register";


class AuthService {
  final httpService = http.HttpService();
  Future<bool> login(String identifier, String password) async {
    try {
      final response = await httpService.request(endpoint: loginEndpoint,
          method: 'POST',
          body: {'username': identifier, 'password': password});
      return true;
    }
    catch(e) {
      return false;
    }
  }

  Future<bool> register(String username, String email, String password, String nickname, String phoneNumber) async {
    try {
      final response = await httpService.request(endpoint: registerEndpoint,
          method: 'POST',
          body: {
            'email': email,
            'username': username,
            'password': password,
            'nickname': nickname,
            'phone_number': phoneNumber
          });
      return true;
    }
    catch (e) {
      return false;
    }
  }
}
