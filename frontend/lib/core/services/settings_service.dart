import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsService {
  static const String _themeKey = 'theme_mode';
  static const String _trafficUpdatesKey = 'traffic_updates';
  static const String _distanceUnitKey = 'distance_unit';
  static const String _preferredTransportKey = 'preferred_transport';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _locationHistoryKey = 'location_history_enabled';
  static const String _soundEffectsKey = 'sound_effects_enabled';

  static const bool defaultTrafficUpdates = true;
  static const String defaultDistanceUnit = 'Kilometers';
  static const String defaultPreferredTransport = 'Car';
  static const ThemeMode defaultThemeMode = ThemeMode.system;
  static const bool defaultNotifications = true;
  static const bool defaultLocationHistory = true;
  static const bool defaultSoundEffects = true;

  static final SettingsService _instance = SettingsService._internal();
  
  factory SettingsService() => _instance;
  
  SettingsService._internal();

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
  }

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeModeString = prefs.getString(_themeKey);
    
    if (themeModeString == null) {
      return defaultThemeMode;
    }

    switch (themeModeString) {
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveTrafficUpdates(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trafficUpdatesKey, value);
  }

  Future<bool> loadTrafficUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_trafficUpdatesKey) ?? defaultTrafficUpdates;
  }

  Future<void> saveDistanceUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_distanceUnitKey, unit);
  }

  Future<String> loadDistanceUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_distanceUnitKey) ?? defaultDistanceUnit;
  }

  Future<void> savePreferredTransport(String transport) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferredTransportKey, transport);
  }

  Future<String> loadPreferredTransport() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_preferredTransportKey) ?? defaultPreferredTransport;
  }

  Future<void> saveNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }

  Future<bool> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? defaultNotifications;
  }

  Future<void> saveLocationHistory(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationHistoryKey, value);
  }

  Future<bool> loadLocationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationHistoryKey) ?? defaultLocationHistory;
  }

  Future<void> saveSoundEffects(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEffectsKey, value);
  }

  Future<bool> loadSoundEffects() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEffectsKey) ?? defaultSoundEffects;
  }
}