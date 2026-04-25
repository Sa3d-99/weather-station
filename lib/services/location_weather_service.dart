import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import 'dart:async';

class LocationWeatherService {
  double? _lat;
  double? _lon;
  String _locationName = 'Locating...';
  bool _permissionDeniedForever = false;

  double? get lat => _lat;
  double? get lon => _lon;
  String get locationName => _locationName;
  bool get permissionDeniedForever => _permissionDeniedForever;

  /// Returns true if location was obtained successfully.
  /// Handles all permission states, including "denied forever" on Android.
  Future<bool> init() async {
    try {
      // ── Step 1: Check if location services are enabled ──────
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationName = 'GPS Off';
        return false;
      }

      // ── Step 2: Check current permission ────────────────────
      LocationPermission perm = await Geolocator.checkPermission();

      // ── Step 3: Request if not yet granted ──────────────────
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      // ── Step 4: Handle denied states ────────────────────────
      if (perm == LocationPermission.denied) {
        _locationName = 'Location Denied';
        return false;
      }

      if (perm == LocationPermission.deniedForever) {
        _locationName = 'Open Settings';
        _permissionDeniedForever = true;
        return false;
      }

      // ── Step 5: Permission granted — get position ────────────
      // Use a timeout so the app never hangs waiting for GPS
      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.reduced, // faster than 'medium'
          timeLimit: const Duration(seconds: 8),
        );
      } on TimeoutException {
        // Fall back to last known position (instant)
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) {
          _locationName = 'GPS Timeout';
          return false;
        }
        pos = last;
      }

      _lat = pos.latitude;
      _lon = pos.longitude;

      // ── Step 6: Reverse geocode to city name ─────────────────
      await _reverseGeocode(_lat!, _lon!);
      return true;
    } catch (e) {
      debugPrint('[LocationService] Error: $e');
      _locationName = 'Location Error';
      return false;
    }
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon)
          .timeout(const Duration(seconds: 5));
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // Build city name: prefer locality (city) → subAdminArea → adminArea
        final parts = [
          p.locality,
          p.subAdministrativeArea,
          p.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).toList();
        _locationName = parts.take(2).join(', ');
        if (_locationName.isEmpty) {
          _locationName = '${lat.toStringAsFixed(2)}°, ${lon.toStringAsFixed(2)}°';
        }
      }
    } catch (_) {
      // Fallback: show raw coordinates
      _locationName = '${lat.toStringAsFixed(2)}°, ${lon.toStringAsFixed(2)}°';
    }
  }

  /// Opens app settings so the user can grant location permission manually.
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Opens the device location settings screen.
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Fetch current weather from Open-Meteo (free, no API key).
  Future<InternetWeather?> fetchInternetWeather() async {
    if (_lat == null || _lon == null) return null;
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$_lat'
        '&longitude=$_lon'
        '&current_weather=true'
        '&hourly=relativehumidity_2m,surface_pressure'
        '&timezone=auto'
        '&forecast_days=1',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;

      final json    = jsonDecode(res.body) as Map<String, dynamic>;
      final cw      = json['current_weather'] as Map<String, dynamic>;
      final hourly  = json['hourly'] as Map<String, dynamic>;
      final humList  = (hourly['relativehumidity_2m'] as List).cast<num>();
      final presList = (hourly['surface_pressure'] as List).cast<num>();

      return InternetWeather(
        temp:        (cw['temperature'] as num).toDouble(),
        hum:         humList.isNotEmpty ? humList[0].toDouble() : 0,
        windSpeed:   (cw['windspeed'] as num).toDouble() / 3.6,
        pressure:    presList.isNotEmpty ? presList[0].toDouble() : 1013,
        weatherCode: (cw['weathercode'] as num).toInt(),
        location:    _locationName,
        fetchedAt:   DateTime.now(),
      );
    } catch (e) {
      debugPrint('[LocationService] Weather fetch error: $e');
      return null;
    }
  }
}
