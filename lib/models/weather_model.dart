class WeatherModel {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final String condition;
  final String description;
  final String icon;
  final String cityName;
  final double windSpeed;

  WeatherModel({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.condition,
    required this.description,
    required this.icon,
    required this.cityName,
    required this.windSpeed,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      condition: json['weather'][0]['main'] as String,
      description: json['weather'][0]['description'] as String,
      icon: json['weather'][0]['icon'] as String,
      cityName: json['name'] as String,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  bool get isClear => condition == 'Clear';
  bool get isRain => condition == 'Rain' || condition == 'Drizzle';
  bool get isSnow => condition == 'Snow';
  bool get isCloudy => condition == 'Clouds';
  bool get isExtreme => condition == 'Thunderstorm' || condition == 'Tornado';
  bool get isHot => temperature > 35;

  // ── Weather icon emoji ─────────────────────────────────────────────────────
  String get weatherEmoji {
    switch (condition) {
      case 'Clear':
        return '☀️';
      case 'Clouds':
        return '☁️';
      case 'Rain':
        return '🌧️';
      case 'Drizzle':
        return '🌦️';
      case 'Thunderstorm':
        return '⛈️';
      case 'Snow':
        return '❄️';
      case 'Mist':
      case 'Fog':
      case 'Haze':
        return '🌫️';
      default:
        return '🌤️';
    }
  }
}
