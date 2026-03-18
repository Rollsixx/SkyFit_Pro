import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import '../utils/constants.dart';

class ApiService {
  // ── Fetch weather by city name ─────────────────────────────────────────────
  Future<WeatherModel> getWeatherByCity(String city) async {
    final url = Uri.parse(
      '${Constants.weatherApiUrl}'
      '?q=$city'
      '&appid=${Constants.weatherApiKey}'
      '&units=metric',
    );
    return _fetchWeather(url);
  }

  // ── Fetch weather by coordinates ───────────────────────────────────────────
  Future<WeatherModel> getWeatherByCoords({
    required double lat,
    required double lon,
  }) async {
    final url = Uri.parse(
      '${Constants.weatherApiUrl}'
      '?lat=$lat&lon=$lon'
      '&appid=${Constants.weatherApiKey}'
      '&units=metric',
    );
    return _fetchWeather(url);
  }

  // ── Private ────────────────────────────────────────────────────────────────
  Future<WeatherModel> _fetchWeather(Uri url) async {
    try {
      final response = await http.get(url).timeout(
            const Duration(seconds: 10),
          );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // ignore: avoid_print
        print('[ApiService] Weather fetched: ${json['name']}');
        return WeatherModel.fromJson(json);
      } else {
        throw Exception(
            'Weather API error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[ApiService] Error: $e');
      rethrow;
    }
  }
}
