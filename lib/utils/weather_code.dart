import 'package:flutter/material.dart';

/// Maps Open-Meteo WMO weather codes to a description and icon.
/// See: https://open-meteo.com/en/docs (Weather variable documentation)
class WeatherCode {
  final String description;
  final IconData icon;
  final IconData nightIcon;

  const WeatherCode(this.description, this.icon, [IconData? nightIcon])
      : nightIcon = nightIcon ?? icon;

  IconData iconFor({bool isDay = true}) => isDay ? icon : nightIcon;

  static const _sun = Icons.wb_sunny_rounded;
  static const _moon = Icons.nightlight_round;
  static const _cloud = Icons.cloud_rounded;
  static const _partlyDay = Icons.cloud_queue_rounded;
  static const _partlyNight = Icons.cloud_queue_rounded;
  static const _fog = Icons.blur_on_rounded;
  static const _drizzle = Icons.grain_rounded;
  static const _rain = Icons.water_drop_rounded;
  static const _snow = Icons.ac_unit_rounded;
  static const _storm = Icons.thunderstorm_rounded;

  static const Map<int, WeatherCode> _map = {
    0: WeatherCode('Clear sky', _sun, _moon),
    1: WeatherCode('Mainly clear', _sun, _moon),
    2: WeatherCode('Partly cloudy', _partlyDay, _partlyNight),
    3: WeatherCode('Overcast', _cloud),
    45: WeatherCode('Fog', _fog),
    48: WeatherCode('Depositing rime fog', _fog),
    51: WeatherCode('Light drizzle', _drizzle),
    53: WeatherCode('Moderate drizzle', _drizzle),
    55: WeatherCode('Dense drizzle', _drizzle),
    56: WeatherCode('Freezing drizzle', _drizzle),
    57: WeatherCode('Dense freezing drizzle', _drizzle),
    61: WeatherCode('Slight rain', _rain),
    63: WeatherCode('Moderate rain', _rain),
    65: WeatherCode('Heavy rain', _rain),
    66: WeatherCode('Freezing rain', _rain),
    67: WeatherCode('Heavy freezing rain', _rain),
    71: WeatherCode('Slight snow', _snow),
    73: WeatherCode('Moderate snow', _snow),
    75: WeatherCode('Heavy snow', _snow),
    77: WeatherCode('Snow grains', _snow),
    80: WeatherCode('Slight showers', _rain),
    81: WeatherCode('Moderate showers', _rain),
    82: WeatherCode('Violent showers', _rain),
    85: WeatherCode('Snow showers', _snow),
    86: WeatherCode('Heavy snow showers', _snow),
    95: WeatherCode('Thunderstorm', _storm),
    96: WeatherCode('Thunderstorm w/ hail', _storm),
    99: WeatherCode('Thunderstorm w/ heavy hail', _storm),
  };

  static WeatherCode of(int code) =>
      _map[code] ?? const WeatherCode('Unknown', _cloud);
}
