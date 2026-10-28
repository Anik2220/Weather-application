import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../services/saved_cities_service.dart';
import '../services/weather_service.dart';
import '../utils/weather_code.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = WeatherService();
  final _savedService = SavedCitiesService();
  final _controller = TextEditingController();

  GeoLocation? _location;
  WeatherBundle? _bundle;
  bool _loading = false;
  String? _error;
  List<GeoLocation> _suggestions = [];
  List<GeoLocation> _savedCities = [];

  @override
  void initState() {
    super.initState();
    _loadSaved();
    _loadDefault();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final cities = await _savedService.load();
    if (mounted) setState(() => _savedCities = cities);
  }

  bool _isSaved(GeoLocation loc) => _savedCities.any(
      (c) => c.latitude == loc.latitude && c.longitude == loc.longitude);

  Future<void> _toggleSave(GeoLocation loc) async {
    final cities = _isSaved(loc)
        ? await _savedService.remove(loc)
        : await _savedService.add(loc);
    if (mounted) setState(() => _savedCities = cities);
  }

  Future<void> _loadDefault() async {
    try {
      final results = await _service.searchCity('Dhaka');
      if (results.isNotEmpty && mounted) {
        _selectLocation(results.first);
      }
    } on WeatherException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    try {
      final results = await _service.searchCity(query);
      if (mounted) setState(() => _suggestions = results);
    } catch (_) {
      if (mounted) setState(() => _suggestions = []);
    }
  }

  Future<void> _selectLocation(GeoLocation loc) async {
    setState(() {
      _location = loc;
      _loading = true;
      _error = null;
      _suggestions = [];
      _controller.clear();
    });
    try {
      final bundle = await _service.fetchWeather(loc);
      if (mounted) setState(() => _bundle = bundle);
    } on WeatherException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    if (_location != null) await _selectLocation(_location!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _backgroundGradient(),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(theme),
              if (_suggestions.isNotEmpty) _buildSuggestions(theme),
              Expanded(child: _buildBody(theme)),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _backgroundGradient() {
    final isDay = _bundle?.current.isDay ?? true;
    final code = _bundle?.current.weatherCode ?? 0;
    final wc = WeatherCode.of(code);
    final stormy = code >= 95;
    final rainy = (code >= 51 && code <= 67) || (code >= 80 && code <= 82);
    final snowy = (code >= 71 && code <= 77) || code == 85 || code == 86;

    List<Color> colors;
    if (!isDay) {
      colors = const [Color(0xFF1A2980), Color(0xFF26305C)];
    } else if (stormy) {
      colors = const [Color(0xFF3E5151), Color(0xFF7F8C8D)];
    } else if (rainy) {
      colors = const [Color(0xFF4B79A1), Color(0xFF283E51)];
    } else if (snowy) {
      colors = const [Color(0xFF83A4D4), Color(0xFFB6FBFF)];
    } else if (wc.description.contains('Overcast') ||
        wc.description.contains('cloudy') ||
        wc.description.contains('Fog')) {
      colors = const [Color(0xFF606C88), Color(0xFF3F4C6B)];
    } else {
      colors = const [Color(0xFF2193B0), Color(0xFF6DD5ED)];
    }
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _controller,
        onChanged: _search,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search for a city...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loading ? null : _refresh,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: _suggestions
            .map((loc) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(loc.name),
                  subtitle: Text(loc.label),
                  onTap: () => _selectLocation(loc),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_error != null) {
      return _CenteredMessage(
        icon: Icons.cloud_off_rounded,
        text: _error!,
      );
    }
    if (_loading && _bundle == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    final bundle = _bundle;
    final location = _location;
    if (bundle == null || location == null) {
      return const _CenteredMessage(
        icon: Icons.explore_outlined,
        text: 'Search for a city to see its weather.',
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_savedCities.isNotEmpty) ...[
            _SavedCitiesRow(
              cities: _savedCities,
              current: location,
              onSelect: _selectLocation,
              onRemove: _toggleSave,
            ),
            const SizedBox(height: 16),
          ],
          _CurrentWeatherCard(
            location: location,
            current: bundle.current,
            isSaved: _isSaved(location),
            onToggleSave: () => _toggleSave(location),
          ),
          const SizedBox(height: 16),
          _HourlyStrip(hourly: bundle.hourly),
          const SizedBox(height: 16),
          _DailyList(daily: bundle.daily),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  const _CenteredMessage({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.white70),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentWeatherCard extends StatelessWidget {
  final GeoLocation location;
  final CurrentWeather current;
  final bool isSaved;
  final VoidCallback onToggleSave;
  const _CurrentWeatherCard({
    required this.location,
    required this.current,
    required this.isSaved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final wc = WeatherCode.of(current.weatherCode);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                location.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: onToggleSave,
              tooltip: isSaved ? 'Remove from saved' : 'Save city',
              icon: Icon(
                isSaved ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isSaved ? Colors.amber : Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
        if (location.country != null)
          Text(
            location.country!,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15),
          ),
        const SizedBox(height: 8),
        Icon(wc.iconFor(isDay: current.isDay), size: 96, color: Colors.white),
        Text(
          '${current.temperature.round()}°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 76,
            fontWeight: FontWeight.w200,
          ),
        ),
        Text(
          wc.description,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        Text(
          'Feels like ${current.apparentTemperature.round()}°',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Metric(
              icon: Icons.water_drop_outlined,
              label: 'Humidity',
              value: '${current.humidity}%',
            ),
            _Metric(
              icon: Icons.air,
              label: 'Wind',
              value: '${current.windSpeed.round()} km/h',
            ),
            _Metric(
              icon: Icons.umbrella_outlined,
              label: 'Precip.',
              value: '${current.precipitation.toStringAsFixed(1)} mm',
            ),
          ],
        ),
      ],
    );
  }
}

class _SavedCitiesRow extends StatelessWidget {
  final List<GeoLocation> cities;
  final GeoLocation current;
  final ValueChanged<GeoLocation> onSelect;
  final ValueChanged<GeoLocation> onRemove;
  const _SavedCitiesRow({
    required this.cities,
    required this.current,
    required this.onSelect,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cities.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = cities[i];
          final active =
              c.latitude == current.latitude && c.longitude == current.longitude;
          return InputChip(
            avatar: Icon(
              active ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 18,
              color: active ? Colors.amber : Colors.white,
            ),
            label: Text(c.name, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.white.withValues(alpha: active ? 0.3 : 0.15),
            side: BorderSide.none,
            onPressed: () => onSelect(c),
            onDeleted: () => onRemove(c),
            deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Metric({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        Text(label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
      ],
    );
  }
}

class _HourlyStrip extends StatelessWidget {
  final List<HourlyForecast> hourly;
  const _HourlyStrip({required this.hourly});

  @override
  Widget build(BuildContext context) {
    if (hourly.isEmpty) return const SizedBox.shrink();
    return _SectionCard(
      title: 'Next 24 hours',
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: hourly.length,
          separatorBuilder: (_, _) => const SizedBox(width: 16),
          itemBuilder: (context, i) {
            final h = hourly[i];
            final wc = WeatherCode.of(h.weatherCode);
            return Column(
              children: [
                Text(
                  i == 0 ? 'Now' : '${h.time.hour}:00',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 8),
                Icon(wc.icon, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Text(
                  '${h.temperature.round()}°',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DailyList extends StatelessWidget {
  final List<DailyForecast> daily;
  const _DailyList({required this.daily});

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '7-day forecast',
      child: Column(
        children: List.generate(daily.length, (i) {
          final d = daily[i];
          final wc = WeatherCode.of(d.weatherCode);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 46,
                  child: Text(
                    i == 0 ? 'Today' : _dayNames[d.date.weekday - 1],
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(wc.icon, color: Colors.white, size: 26),
                const SizedBox(width: 12),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${d.precipitationProbability}%',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                  ),
                ),
                const Spacer(),
                Text(
                  '${d.tempMin.round()}°',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
                ),
                const SizedBox(width: 12),
                Text(
                  '${d.tempMax.round()}°',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
