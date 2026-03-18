import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/activity_model.dart';
import '../models/user_model.dart';
import '../models/weather_model.dart';
import '../repositories/weather_repository.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherRepository _repo = WeatherRepository();

  WeatherModel? _weather;
  ActivityModel? _activity;
  bool _busy = false;
  String? _error;

  WeatherModel? get weather => _weather;
  ActivityModel? get activity => _activity;
  bool get isBusy => _busy;
  String? get error => _error;

  // ── Fetch weather + compute activity ──────────────────────────────────────
  Future<void> fetchWeather(UserModel? user,
      {bool forceRefresh = false}) async {
    _setBusy(true);
    _error = null;
    try {
      // Step 1 — Get location
      final position = await _determinePosition();

      // Step 2 — Fetch weather via repository (API or cache)
      _weather = await _repo.getWeather(
        lat: position.latitude,
        lon: position.longitude,
        forceRefresh: forceRefresh,
      );

      // Step 3 — Compute activity suggestion
      _activity = ActivitySuggestionEngine.suggest(
        weatherCondition: _weather!.condition,
        temperature: _weather!.temperature,
        age: user?.age ?? 25,
        weight: user?.weight ?? 70.0,
      );

      notifyListeners();
    } catch (e) {
      _error = 'Could not fetch weather: $e';
      // ignore: avoid_print
      print('[WeatherViewModel] Error: $e');
    } finally {
      _setBusy(false);
    }
  }

  // ── Force refresh ──────────────────────────────────────────────────────────
  Future<void> refresh(UserModel? user) async {
    await fetchWeather(user, forceRefresh: true);
  }

  // ── Location helper ────────────────────────────────────────────────────────
  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied. '
          'Please enable it in Settings.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }
}
