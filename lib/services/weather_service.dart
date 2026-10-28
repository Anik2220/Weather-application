import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);
  @override
  String toString() => message;
}

class WeatherService {
  static const _geoUrl = 'https://geocoding-api.open-meteo.com/v1/search';
  static const _forecastUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<List<GeoLocation>> searchCity(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse(_geoUrl).replace(queryParameters: {
      'name': query.trim(),
      'count': '6',
      'language': 'en',
      'format': 'json',
    });
    final res = await _get(uri);
    final results = res['results'] as List?;
    if (results == null) return [];
    return results
        .map((e) => GeoLocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WeatherBundle> fetchWeather(GeoLocation location) async {
    final uri = Uri.parse(_forecastUrl).replace(queryParameters: {
      'latitude': location.latitude.toString(),
      'longitude': location.longitude.toString(),
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m',
      'hourly': 'temperature_2m,weather_code',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'timezone': 'auto',
      'forecast_days': '7',
    });
    final res = await _get(uri);

    final current =
        CurrentWeather.fromJson(res['current'] as Map<String, dynamic>);

    final hourlyJson = res['hourly'] as Map<String, dynamic>;
    final hourCount = (hourlyJson['time'] as List).length;
    final nowHour = DateTime.now();
    final hourly = <HourlyForecast>[];
    for (var i = 0; i < hourCount && hourly.length < 24; i++) {
      final h = HourlyForecast.fromJson(hourlyJson, i);
      if (!h.time.isBefore(DateTime(nowHour.year, nowHour.month, nowHour.day))) {
        hourly.add(h);
      }
    }

    final dailyJson = res['daily'] as Map<String, dynamic>;
    final dayCount = (dailyJson['time'] as List).length;
    final daily = <DailyForecast>[];
    for (var i = 0; i < dayCount; i++) {
      daily.add(DailyForecast.fromJson(dailyJson, i));
    }

    return WeatherBundle(current: current, hourly: hourly, daily: daily);
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw WeatherException('Request failed (${res.statusCode}). Try again.');
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on WeatherException {
      rethrow;
    } catch (_) {
      throw WeatherException('Could not reach the weather service. Check your connection.');
    }
  }
}
