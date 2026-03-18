import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/weather_model.dart';
import '../services/api_service.dart';

/// Repository Pattern — Weather Data Decision Layer
/// Decides whether to fetch from API or return cached data
class WeatherRepository {
  final ApiService _api = ApiService();

  static const String _cacheKey = 'cached_weather';
  static const String _cacheTimeKey = 'cached_weather_time';
  static const int _cacheMins = 30; // cache for 30 minutes

  // ── Get Weather by coordinates ─────────────────────────────────────────────
  Future<WeatherModel> getWeather({
    required double lat,
    required double lon,
    bool forceRefresh = false,
  }) async {
    // Check cache first unless force refresh
    if (!forceRefresh) {
      final cached = await _getCachedWeather();
      if (cached != null) {
        // ignore: avoid_print
        print('[WeatherRepository] Returning cached weather');
        return cached;
      }
    }

    // Fetch from API
    // ignore: avoid_print
    print('[WeatherRepository] Fetching fresh weather from API...');
    final weather = await _api.getWeatherByCoords(lat: lat, lon: lon);

    // Cache the result
    await _cacheWeather(weather);
    return weather;
  }

  // ── Get Weather by city ────────────────────────────────────────────────────
  Future<WeatherModel> getWeatherByCity(String city) async {
    final weather = await _api.getWeatherByCity(city);
    await _cacheWeather(weather);
    return weather;
  }

  // ── Cache helpers ──────────────────────────────────────────────────────────
  Future<void> _cacheWeather(WeatherModel weather) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode({
        'temperature': weather.temperature,
        'feelsLike': weather.feelsLike,
        'humidity': weather.humidity,
        'condition': weather.condition,
        'description': weather.description,
        'icon': weather.icon,
        'cityName': weather.cityName,
        'windSpeed': weather.windSpeed,
      });
      await prefs.setString(_cacheKey, data);
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
      // ignore: avoid_print
      print('[WeatherRepository] Weather cached for ${weather.cityName}');
    } catch (e) {
      // ignore: avoid_print
      print('[WeatherRepository] Cache error: $e');
    }
  }

  Future<WeatherModel?> _getCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(_cacheKey);
      final cacheTime = prefs.getInt(_cacheTimeKey);

      if (cachedStr == null || cacheTime == null) return null;

      // Check if cache is still valid
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
      final maxAge = _cacheMins * 60 * 1000;
      if (cacheAge > maxAge) {
        // ignore: avoid_print
        print('[WeatherRepository] Cache expired');
        return null;
      }

      final data = jsonDecode(cachedStr) as Map<String, dynamic>;
      return WeatherModel(
        temperature: (data['temperature'] as num).toDouble(),
        feelsLike: (data['feelsLike'] as num).toDouble(),
        humidity: data['humidity'] as int,
        condition: data['condition'] as String,
        description: data['description'] as String,
        icon: data['icon'] as String,
        cityName: data['cityName'] as String,
        windSpeed: (data['windSpeed'] as num).toDouble(),
      );
    } catch (e) {
      // ignore: avoid_print
      print('[WeatherRepository] Cache read error: $e');
      return null;
    }
  }

  // ── Clear cache ────────────────────────────────────────────────────────────
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimeKey);
  }
}
