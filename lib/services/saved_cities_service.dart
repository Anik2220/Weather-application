import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather.dart';

class SavedCitiesService {
  static const _key = 'saved_cities';

  Future<List<GeoLocation>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((s) => jsonDecode(s) as Map<String, dynamic>)
        .map(GeoLocation.fromJson)
        .toList();
  }

  Future<List<GeoLocation>> add(GeoLocation loc) async {
    final cities = await load();
    if (cities.any((c) => _same(c, loc))) return cities;
    cities.add(loc);
    await _save(cities);
    return cities;
  }

  Future<List<GeoLocation>> remove(GeoLocation loc) async {
    final cities = await load();
    cities.removeWhere((c) => _same(c, loc));
    await _save(cities);
    return cities;
  }

  Future<void> _save(List<GeoLocation> cities) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, cities.map((c) => jsonEncode(c.toJson())).toList());
  }

  bool _same(GeoLocation a, GeoLocation b) =>
      a.latitude == b.latitude && a.longitude == b.longitude;
}
