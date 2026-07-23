import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../data/models/models.dart';

class InfoScreen extends ConsumerStatefulWidget {
  const InfoScreen({super.key});
  @override
  ConsumerState<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends ConsumerState<InfoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _faqCat = 'all';

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final siteAsync = ref.watch(siteDataProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Information'),
        bottom: TabBar(controller: _tabCtrl, indicatorColor: AppTheme.goldLight, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Hotels'), Tab(text: 'Fleet'), Tab(text: 'FAQ')])),
      body: siteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
        data: (site) {
          if (site == null) return const Center(child: Text('No data'));
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return TabBarView(controller: _tabCtrl, children: [
            _hotelsTab(site.hotels, isDark),
            _fleetTab(site.fleet, isDark),
            _faqTab(site.faqs, isDark, site.travelGuidelinesUrl),
          ]);
        },
      ),
    );
  }

  Widget _hotelsTab(List<Hotel> hotels, bool isDark) {
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: hotels.length,
      itemBuilder: (_, i) {
        final h = hotels[i];
        return Card(margin: const EdgeInsets.only(bottom: 12), clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (h.image.isNotEmpty) CachedNetworkImage(imageUrl: h.image, height: 180, width: double.infinity, fit: BoxFit.cover),
            Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h.name, style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(h.desc, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : AppTheme.textMid, height: 1.5)),
              if (h.url.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton.icon(onPressed: () => launchUrl(Uri.parse(h.url)), icon: const Icon(Icons.open_in_new, size: 16), label: const Text('Visit Website'))),
            ])),
          ]));
      });
  }

  Widget _fleetTab(List<FleetVehicle> fleet, bool isDark) {
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: fleet.length,
      itemBuilder: (_, i) {
        final f = fleet[i];
        return Card(margin: const EdgeInsets.only(bottom: 12), clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (f.image.isNotEmpty) CachedNetworkImage(imageUrl: f.image, height: 180, width: double.infinity, fit: BoxFit.cover),
            Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.name, style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(f.desc, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : AppTheme.textMid, height: 1.5)),
            ])),
          ]));
      });
  }

  Widget _faqTab(List<FaqItem> faqs, bool isDark, String? guidelinesUrl) {
    final cats = {'all': 'All', 'travel': 'Travel', 'practical': 'Practical', 'health': 'Health', 'culture': 'Culture'};
    final filtered = _faqCat == 'all' ? faqs : faqs.where((f) => f.cat == _faqCat).toList();
    return Column(children: [
      // Travel Guidelines button
      if (guidelinesUrl != null && guidelinesUrl.isNotEmpty)
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(width: double.infinity, height: 46,
            child: ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse(guidelinesUrl), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.picture_as_pdf, size: 20),
              label: const Text('Download Travel Guidelines', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))))),
      // Category chips
      SizedBox(height: 52, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: cats.entries.map((e) {
          final sel = e.key == _faqCat;
          return Padding(padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : (isDark ? Colors.grey[300] : AppTheme.charcoal))),
              selected: sel, selectedColor: AppTheme.teal, backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: sel ? AppTheme.teal : AppTheme.border)),
              onSelected: (_) => setState(() => _faqCat = e.key)));
        }).toList())),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: filtered.length,
        itemBuilder: (_, i) {
          final f = filtered[i];
          return Card(margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(title: Text(f.q, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text(f.a.replaceAll(RegExp(r'<[^>]*>'), ''), style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : AppTheme.textMid, height: 1.5)))]));
        })),
    ]);
  }
}
