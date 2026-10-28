class GeoLocation {
  final String name;
  final String? admin1;
  final String? country;
  final double latitude;
  final double longitude;

  const GeoLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.admin1,
    this.country,
  });

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      name: json['name'] as String? ?? 'Unknown',
      admin1: json['admin1'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'admin1': admin1,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
      };

  String get label {
    final parts = [name, admin1, country].where((p) => p != null && p.isNotEmpty);
    return parts.join(', ');
  }
}

class CurrentWeather {
  final double temperature;
  final double apparentTemperature;
  final int weatherCode;
  final double windSpeed;
  final int humidity;
  final double precipitation;
  final bool isDay;
  final DateTime time;

  const CurrentWeather({
    required this.temperature,
    required this.apparentTemperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.humidity,
    required this.precipitation,
    required this.isDay,
    required this.time,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature_2m'] as num).toDouble(),
      apparentTemperature: (json['apparent_temperature'] as num).toDouble(),
      weatherCode: (json['weather_code'] as num).toInt(),
      windSpeed: (json['wind_speed_10m'] as num).toDouble(),
      humidity: (json['relative_humidity_2m'] as num).toInt(),
      precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0,
      isDay: (json['is_day'] as num?)?.toInt() != 0,
      time: DateTime.parse(json['time'] as String),
    );
  }
}

class DailyForecast {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final int weatherCode;
  final int precipitationProbability;

  const DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.weatherCode,
    required this.precipitationProbability,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json, int index) {
    final probList = json['precipitation_probability_max'] as List?;
    return DailyForecast(
      date: DateTime.parse((json['time'] as List)[index] as String),
      tempMax: ((json['temperature_2m_max'] as List)[index] as num).toDouble(),
      tempMin: ((json['temperature_2m_min'] as List)[index] as num).toDouble(),
      weatherCode: ((json['weather_code'] as List)[index] as num).toInt(),
      precipitationProbability:
          (probList != null ? probList[index] as num? : null)?.toInt() ?? 0,
    );
  }
}

class HourlyForecast {
  final DateTime time;
  final double temperature;
  final int weatherCode;

  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json, int index) {
    return HourlyForecast(
      time: DateTime.parse((json['time'] as List)[index] as String),
      temperature: ((json['temperature_2m'] as List)[index] as num).toDouble(),
      weatherCode: ((json['weather_code'] as List)[index] as num).toInt(),
    );
  }
}

class WeatherBundle {
  final CurrentWeather current;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;

  const WeatherBundle({
    required this.current,
    required this.hourly,
    required this.daily,
  });
}
