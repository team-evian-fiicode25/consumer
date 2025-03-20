import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class AuthCallbackPage extends StatefulWidget {
  final Map<String, String> queryParameters;
  const AuthCallbackPage({super.key, required this.queryParameters});

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final code = widget.queryParameters['code'];
    if (code != null) {
      _exchangeCodeForToken(code);
    } else {
      setState(() {
        _errorMessage = 'Authorization code not found.';
        _isLoading = false;
      });
    }
  }

  Future<void> _exchangeCodeForToken(String code) async {
    const clientId = "ukmJzWxQtoHFLeS8tR1ano6G5fwTPG6m";
    const clientSecret = "0SoaDVxuql9qrOPqHlvfYXMB5mFeF_gd0pZrVGQv";
    const redirectUri = "ride://uber";
    const tokenUrl = "https://sandbox-login.uber.com/oauth/v2/token";

    try {
      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
          'code': code,
        },
      );

      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body);
        final accessToken = tokenData['access_token'];
        final refreshToken = tokenData['refresh_token'];
        final expiresIn = tokenData['expires_in'];

        if (accessToken != null && refreshToken != null) {
          final expirationTimestamp =
              DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);

          await secureStorage.write(key: 'uber_access_token', value: accessToken);
          await secureStorage.write(key: 'uber_refresh_token', value: refreshToken);
          await secureStorage.write(
            key: 'uber_token_expiration',
            value: expirationTimestamp.toString(),
          );

          context.goNamed('home');
        } else {
          setState(() {
            _errorMessage = 'Access or Refresh token not found in response.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
          'Error exchanging code: ${response.statusCode} ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Authenticating")),
        body: const Center(child: CircularProgressIndicator()),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text("Authentication Error")),
        body: Center(child: Text(_errorMessage ?? 'Unknown error')),
        floatingActionButton: OutlinedButton(
          onPressed: () => context.goNamed('home'),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Log in'),
        ),
      );
    }
  }
}
