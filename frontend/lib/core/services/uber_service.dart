
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'http_service.dart' as http;

class UberService {
  final http.HttpService httpService = http.HttpService(baseUrl: '');
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  Future<void> launchUberAuth() async {
    final Uri url = Uri.parse(
        'https://sandbox-login.uber.com/oauth/v2/authorize?'
            'client_id=ukmJzWxQtoHFLeS8tR1ano6G5fwTPG6m&'
            'redirect_uri=ride://uber&'
            'response_type=code&'
    );

    // final String url = 'https://sandbox-login.uber.com/oauth/v2/token';
    //
    // final Map<String, String> body = {
    //   'client_secret': '0SoaDVxuql9qrOPqHlvfYXMB5mFeF_gd0pZrVGQv',
    //   'client_id': 'ukmJzWxQtoHFLeS8tR1ano6G5fwTPG6m',
    //   'grant_type': 'client_credentials',
    //   'scope': 'guests.trips',
    // };
    //
    // final request = await httpService.request(body: body, endpoint: url, method: 'POST');

    if (await launchUrl(url)) {
    }
    else {
      throw 'Could not launch $url';
    }
  }

  Future<void> getProducts({
    required double latitude,
    required double longitude,
  }) async {
    final accessToken = await refreshTokenIfNeeded();
    // await launchUberAuth();
    // if (accessToken == null) {
    //   await launchUberAuth();
    //   return;
    // }
    //
    final String url = 'https://test-api.uber.com/v1.2/products?latitude=$latitude&longitude=$longitude';
    final headers = {'Authorization': 'Bearer $accessToken' };
    final response = await httpService.request(endpoint: url, headers: headers);
  }

  Future<String?> refreshTokenIfNeeded() async {
    final accessToken = await secureStorage.read(key: 'uber_access_token');
    final refreshToken = await secureStorage.read(key: 'uber_refresh_token');
    final expirationStr = await secureStorage.read(key: 'uber_token_expiration');

    if (accessToken == null || expirationStr == null) {
      return null;
    }

    final expiration = int.tryParse(expirationStr) ?? 0;
    final currentTimestamp = DateTime.now().millisecondsSinceEpoch;

    if (currentTimestamp < expiration) {
      return accessToken;
    }

    if (refreshToken == null) {
      return null;
    }

    const tokenUrl = "https://sandbox-login.uber.com/oauth/v2/token";

    try {
      final response = await httpService.request(
        endpoint: tokenUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': "ukmJzWxQtoHFLeS8tR1ano6G5fwTPG6m",
          'client_secret': "0SoaDVxuql9qrOPqHlvfYXMB5mFeF_gd0pZrVGQv",
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
        method: 'POST'
      );

        final newAccessToken = response['access_token'];
        final newRefreshToken = response['refresh_token'] ?? refreshToken;
        final newExpiresIn = response['expires_in'];

        final newExpirationTimestamp =
            DateTime.now().millisecondsSinceEpoch + (newExpiresIn * 1000);

        await secureStorage.write(key: 'uber_access_token', value: newAccessToken);
        await secureStorage.write(key: 'uber_refresh_token', value: newRefreshToken);
        await secureStorage.write(
          key: 'uber_token_expiration',
          value: newExpirationTimestamp.toString(),
        );

        return newAccessToken;
    } catch (e) {
      return null;
    }
  }

}
