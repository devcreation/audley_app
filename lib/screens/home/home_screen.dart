import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../data/models/models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final content = ref.read(contentProvider);
    if (content.data == null) return;
    final target = DateTime.tryParse(content.data!.event.targetDate);
    if (target == null) return;
    final now = DateTime.now();
    if (target.isAfter(now)) {
      setState(() => _remaining = target.difference(now));
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentProvider);

    return RefreshIndicator(
      color: AppTheme.teal,
      onRefresh: () =>
          ref.read(contentProvider.notifier).loadContent(forceRefresh: true),
      child: content.data == null
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.teal),
                  SizedBox(height: 16),
                  Text('Loading...', style: TextStyle(color: AppTheme.textMid, fontSize: 14)),
                ],
              ),
            )
          : _buildContent(content.data!),
    );
  }

  Widget _buildContent(SiteData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHero(data, isDark)),
        if (_remaining > Duration.zero)
          SliverToBoxAdapter(child: _buildCountdown(isDark)),
        if (data.updates.isNotEmpty) ...[
          _sectionHeader('Trip Updates', Icons.campaign_outlined),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _buildUpdateCard(data.updates[i], isDark),
              childCount: data.updates.length,
            ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  Widget _buildHero(SiteData data, bool isDark) {
    return Stack(
      children: [
        // Background image from bundled asset
        SizedBox(
          width: double.infinity,
          height: 440,
          child: Image.asset(
            'assets/cover-bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(height: 440, color: AppTheme.tealDark),
          ),
        ),

        // Dark overlay
        Container(
          width: double.infinity,
          height: 440,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A3330).withValues(alpha: 0.82),
                const Color(0xFF1A3330).withValues(alpha: 0.70),
                const Color(0xFF0F1F1D).withValues(alpha: 0.88),
              ],
            ),
          ),
        ),

        // Content
        SizedBox(
          width: double.infinity,
          height: 440,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo - no background color behind it
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/icon.png', width: 76, height: 76, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      data.event.badge.toUpperCase(),
                      style: TextStyle(fontSize: 9, letterSpacing: 2.5, fontWeight: FontWeight.w700, color: AppTheme.goldLight.withValues(alpha: 0.95)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(data.event.name, textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'serif', fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, height: 1.15)),
                  const SizedBox(height: 6),

                  // Gold line
                  Container(
                    width: 60, height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.transparent, AppTheme.gold.withValues(alpha: 0.6), Colors.transparent]),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  Text(data.event.subtitle,
                    style: TextStyle(fontFamily: 'serif', fontSize: 34, fontStyle: FontStyle.italic, color: AppTheme.goldLight.withValues(alpha: 0.95), height: 1.0)),
                  const SizedBox(height: 14),

                  // Dates - plain text, no background
                  Text(
                    data.event.dates,
                    style: TextStyle(fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdown(bool isDark) {
    final d = _remaining.inDays;
    final h = _remaining.inHours % 24;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text('COUNTDOWN TO DEPARTURE', style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700, color: AppTheme.gold)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _cdUnit(d.toString().padLeft(2, '0'), 'DAYS'), _cdSep(),
              _cdUnit(h.toString().padLeft(2, '0'), 'HRS'), _cdSep(),
              _cdUnit(m.toString().padLeft(2, '0'), 'MIN'), _cdSep(),
              _cdUnit(s.toString().padLeft(2, '0'), 'SEC'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cdUnit(String value, String label) => SizedBox(width: 60, child: Column(children: [
    Text(value, style: const TextStyle(fontFamily: 'serif', fontSize: 28, fontWeight: FontWeight.w700)),
    Text(label, style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
  ]));

  Widget _cdSep() => Padding(padding: const EdgeInsets.only(bottom: 14),
    child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: AppTheme.gold.withValues(alpha: 0.4))));

  Widget _buildUpdateCard(TripUpdate update, bool isDark) {
    Color tagColor;
    switch (update.tag.toLowerCase()) {
      case 'action': tagColor = Colors.orange.shade700; break;
      case 'reminder': tagColor = AppTheme.teal; break;
      case 'alert': tagColor = Colors.red.shade600; break;
      default: tagColor = Colors.blue.shade600;
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: tagColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
            child: Text(update.tag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tagColor))),
          if (update.pinned) ...[const SizedBox(width: 8), Icon(Icons.push_pin, size: 14, color: AppTheme.gold)],
          const Spacer(),
          Text(update.date, style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
        ]),
        const SizedBox(height: 10),
        Text(update.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(update.body, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : AppTheme.textMid, height: 1.5)),
      ])),
    );
  }

  SliverToBoxAdapter _sectionHeader(String title, IconData icon) => SliverToBoxAdapter(
    child: Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(children: [Icon(icon, size: 20, color: AppTheme.gold), const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700))])));
}
