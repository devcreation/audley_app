import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    final partnersTitle = config?.uiString('section_partners', 'Our Partners') ?? 'Our Partners';

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
          const SizedBox(height: 12),
          Text('No content available', style: TextStyle(color: AppTheme.textMid)),
          const SizedBox(height: 8),
          TextButton.icon(onPressed: () => ref.invalidate(siteDataProvider), icon: const Icon(Icons.refresh, size: 18), label: const Text('Retry')),
        ]));
        final ev = site.event;
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(siteDataProvider),
          child: ListView(children: [
            // ─── Hero with bundled cover-bg.jpg + overlay ───
            SizedBox(height: 460, child: Stack(children: [
              // Background image - bundled asset
              SizedBox(width: double.infinity, height: 460,
                child: Image.asset('assets/cover-bg.jpg', fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppTheme.tealDark))),
              // Dark overlay gradient
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
              // Content
              SizedBox(width: double.infinity, height: 460, child: SafeArea(bottom: false,
                child: Padding(padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Image.asset('assets/logo.png', width: 90, height: 90, fit: BoxFit.contain),
                    const SizedBox(height: 16),
                    if (ev.badge.isNotEmpty) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.goldLight.withOpacity(0.5))),
                      child: Text(ev.badge, style: const TextStyle(color: AppTheme.goldLight, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600))),
                    const SizedBox(height: 14),
                    if (ev.name.isNotEmpty) Text(ev.name, textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'serif', fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2)),
                    const SizedBox(height: 6),
                    if (ev.subtitle.isNotEmpty) Text(ev.subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), letterSpacing: 1)),
                    const SizedBox(height: 12),
                    if (ev.dates.isNotEmpty) Text(ev.dates,
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  ])))),
            ])),

            // ─── Sponsors row ───
            if (site.sponsors.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                color: isDark ? AppTheme.darkCard : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(children: [
                  Text(partnersTitle.toUpperCase(),
                    style: TextStyle(fontSize: 10, letterSpacing: 2.5, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[500] : AppTheme.textLight)),
                  const SizedBox(height: 12),
                  SizedBox(height: 50, child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: site.sponsors.length,
                    itemBuilder: (_, i) {
                      final s = site.sponsors[i];
                      return Padding(padding: const EdgeInsets.only(right: 28),
                        child: CachedNetworkImage(imageUrl: s.image, height: 36, fit: BoxFit.contain,
                          placeholder: (_, __) => const SizedBox(width: 60),
                          errorWidget: (_, __, ___) => const SizedBox()));
                    })),
                ]),
              ),
            ],

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
