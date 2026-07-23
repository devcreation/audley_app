import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../../core/theme.dart';
import '../../providers/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteAsync = ref.watch(siteDataProvider);
    final config = ref.watch(appConfigProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final updatesTitle = config?.uiString('section_updates', 'Trip Updates') ?? 'Trip Updates';

    return siteAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off, size: 48, color: AppTheme.textLight),
        const SizedBox(height: 12),
        Text('Unable to load content', style: TextStyle(color: AppTheme.textMid, fontSize: 15)),
        const SizedBox(height: 8),
        TextButton.icon(onPressed: () => ref.invalidate(siteDataProvider), icon: const Icon(Icons.refresh, size: 18), label: const Text('Retry')),
      ])),
      data: (site) {
        if (site == null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.info_outline, size: 48, color: AppTheme.textLight),
          const SizedBox(height: 12), Text('No content available', style: TextStyle(color: AppTheme.textMid)),
          const SizedBox(height: 8),
          TextButton.icon(onPressed: () => ref.invalidate(siteDataProvider), icon: const Icon(Icons.refresh, size: 18), label: const Text('Retry')),
        ]));
        final ev = site.event;
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(siteDataProvider),
          child: ListView(children: [
            // ─── Hero ───
            SizedBox(height: 460, child: Stack(children: [
              SizedBox(width: double.infinity, height: 460,
                child: Image.asset('assets/cover-bg.jpg', fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppTheme.tealDark))),
              Container(width: double.infinity, height: 460,
                decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  stops: const [0.0, 0.3, 0.7, 1.0],
                  colors: [
                    const Color(0xFF0F1F1D).withOpacity(0.7),
                    const Color(0xFF1A3330).withOpacity(0.45),
                    const Color(0xFF1A3330).withOpacity(0.5),
                    const Color(0xFF0F1F1D).withOpacity(0.85),
                  ]))),
              SizedBox(width: double.infinity, height: 460, child: SafeArea(bottom: false,
                child: Padding(padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Image.asset('assets/icon.png', width: 90, height: 90, fit: BoxFit.contain),
                    const SizedBox(height: 16),
                    if (ev.badge.isNotEmpty) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.goldLight.withOpacity(0.5))),
                      child: Text(ev.badge, style: const TextStyle(color: AppTheme.goldLight, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600))),
                    const SizedBox(height: 14),
                    Text(ev.heroTitle.isNotEmpty ? ev.heroTitle : ev.name, textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'serif', fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2)),
                    const SizedBox(height: 6),
                    if (ev.subtitle.isNotEmpty) Text(ev.subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), letterSpacing: 1)),
                    const SizedBox(height: 12),
                    if (ev.dates.isNotEmpty) Text(ev.dates,
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  ])))),
            ])),

            // ─── Sponsors marquee ───
            if (site.sponsors.isNotEmpty) _SponsorMarquee(sponsors: site.sponsors, isDark: isDark),

            // ─── Weather ───
            _WeatherRow(isDark: isDark),

            // ─── Updates ───
            if (site.updates.isNotEmpty) ...[
              Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(updatesTitle, style: TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.charcoal))),
              ...site.updates.map((u) => _updateCard(u, isDark)),
            ],
            const SizedBox(height: 24),
          ]),
        );
      },
    );
  }

  Widget _updateCard(dynamic u, bool isDark) {
    final tagColors = {'Action': Colors.orange, 'Info': Colors.blue, 'Reminder': AppTheme.teal, 'Alert': Colors.red};
    final color = tagColors[u.tag] ?? AppTheme.teal;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(u.tag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
          if (u.pinned) ...[const SizedBox(width: 8), Icon(Icons.push_pin, size: 14, color: color)],
          const Spacer(),
          Text(u.date, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[500] : AppTheme.textLight)),
        ]),
        const SizedBox(height: 10),
        Text(u.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppTheme.charcoal)),
        const SizedBox(height: 6),
        Text(u.body, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : AppTheme.textMid, height: 1.5)),
      ]),
    );
  }
}

// ─── Animated Sponsor Marquee ───────────────────────
class _SponsorMarquee extends StatefulWidget {
  final List sponsors; final bool isDark;
  const _SponsorMarquee({required this.sponsors, required this.isDark});
  @override State<_SponsorMarquee> createState() => _SponsorMarqueeState();
}

class _SponsorMarqueeState extends State<_SponsorMarquee> {
  late ScrollController _sc;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sc = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMarquee());
  }

  void _startMarquee() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!_sc.hasClients) return;
      final max = _sc.position.maxScrollExtent;
      if (_sc.offset >= max) { _sc.jumpTo(0); }
      else { _sc.jumpTo(_sc.offset + 0.5); }
    });
  }

  @override
  void dispose() { _timer?.cancel(); _sc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    // Double the list for seamless loop
    final doubled = [...widget.sponsors, ...widget.sponsors];
    return Container(
      color: widget.isDark ? AppTheme.darkCard : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      height: 64,
      child: ListView.builder(
        controller: _sc, scrollDirection: Axis.horizontal, physics: const NeverScrollableScrollPhysics(),
        itemCount: doubled.length,
        itemBuilder: (_, i) {
          final s = doubled[i];
          final h = _logoHeight(s.name);
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(height: h, child: CachedNetworkImage(imageUrl: s.image, height: h, fit: BoxFit.contain,
              placeholder: (_, __) => SizedBox(width: h * 2),
              errorWidget: (_, __, ___) => const SizedBox())));
        }),
    );
  }

  /// Match website mobile CSS heights per sponsor
  double _logoHeight(String name) {
    final n = name.toLowerCase();
    if (n.contains('distant') || n.contains(' df')) return 30;
    if (n.contains('turkish')) return 52;
    if (n.contains('british')) return 24;
    if (n.contains('amadeus')) return 10;
    if (n.contains('silversea')) return 10;
    if (n.contains('dept')) return 10;
    return 18; // default
  }
}

// ─── Weather Row ────────────────────────────────────
class _WeatherRow extends StatefulWidget {
  final bool isDark;
  const _WeatherRow({required this.isDark});
  @override State<_WeatherRow> createState() => _WeatherRowState();
}

class _WeatherRowState extends State<_WeatherRow> {
  Map<String, dynamic>? _delhi, _jaipur;
  bool _loading = true;

  static const _cities = [
    {'name': 'Delhi', 'lat': 28.61, 'lon': 77.21, 'typ': '34°C day · 25°C night'},
    {'name': 'Jaipur', 'lat': 26.91, 'lon': 75.79, 'typ': '33°C day · 24°C night'},
  ];

  static String _wxIcon(int code) {
    if (code == 0) return '☀️'; if (code <= 2) return '🌤️'; if (code == 3) return '☁️';
    if (code <= 48) return '🌫️'; if (code <= 55) return '🌦️'; if (code <= 65) return '🌧️';
    if (code <= 82) return '🌦️'; return '⛈️';
  }

  static String _wxDesc(int code) {
    if (code == 0) return 'Clear'; if (code <= 2) return 'Mostly Clear'; if (code == 3) return 'Overcast';
    if (code <= 48) return 'Foggy'; if (code <= 55) return 'Drizzle'; if (code <= 65) return 'Rain';
    if (code <= 82) return 'Showers'; return 'Thunderstorm';
  }

  @override
  void initState() { super.initState(); _loadWeather(); }

  Future<void> _loadWeather() async {
    try {
      for (final c in _cities) {
        final url = 'https://api.open-meteo.com/v1/forecast?latitude=${c['lat']}&longitude=${c['lon']}&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&timezone=Asia%2FKolkata';
        final r = await http.get(Uri.parse(url));
        if (r.statusCode == 200) {
          final j = json.decode(r.body);
          final cur = j['current'];
          final data = {'temp': cur['temperature_2m'], 'humidity': cur['relative_humidity_2m'], 'code': cur['weather_code'], 'wind': cur['wind_speed_10m']};
          if (c['name'] == 'Delhi') _delhi = data; else _jaipur = data;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.isDark ? const Color(0xFF1A2332) : const Color(0xFFF0F4F8),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.thermostat, size: 16, color: AppTheme.teal),
          const SizedBox(width: 6),
          Text('WEATHER WATCH', style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700, color: AppTheme.teal)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _wxCard('Delhi', _delhi, _cities[0]['typ'] as String, widget.isDark)),
          const SizedBox(width: 10),
          Expanded(child: _wxCard('Jaipur', _jaipur, _cities[1]['typ'] as String, widget.isDark)),
        ]),
      ]),
    );
  }

  Widget _wxCard(String city, Map<String, dynamic>? data, String typ, bool isDark) {
    final hasData = data != null;
    final code = hasData ? (data['code'] as num).toInt() : 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(city, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppTheme.charcoal)),
        const SizedBox(height: 6),
        if (_loading) Text('Loading…', style: TextStyle(fontSize: 12, color: AppTheme.textMid))
        else if (hasData) ...[
          Row(children: [
            Text(_wxIcon(code), style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${data['temp'].round()}°C', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppTheme.charcoal)),
              Text(_wxDesc(code), style: TextStyle(fontSize: 11, color: AppTheme.textMid)),
            ]),
          ]),
          const SizedBox(height: 4),
          Text('💧 ${data['humidity']}%  💨 ${data['wind'].round()} km/h', style: TextStyle(fontSize: 10, color: AppTheme.textMid)),
          const SizedBox(height: 4),
          Row(children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
            const SizedBox(width: 4),
            Text('Live now', style: TextStyle(fontSize: 9, color: Colors.green.shade600, fontWeight: FontWeight.w600)),
          ]),
        ] else ...[
          Text('Offline', style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
          const SizedBox(height: 2),
          Text('Typical Sep: $typ', style: TextStyle(fontSize: 10, color: AppTheme.textMid)),
        ],
      ]),
    );
  }
}
