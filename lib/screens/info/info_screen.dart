import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../data/models/models.dart';
import '../../data/api_client.dart';

class InfoScreen extends ConsumerStatefulWidget {
  const InfoScreen({super.key});
  @override
  ConsumerState<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends ConsumerState<InfoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _faqCat = 'all';

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final siteAsync = ref.watch(siteDataProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Information'),
        bottom: TabBar(controller: _tabCtrl, indicatorColor: AppTheme.goldLight, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [Tab(text: 'Hotels'), Tab(text: 'Fleet'), Tab(text: 'FAQ'), Tab(text: 'Participant')])),
      body: siteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
        data: (site) {
          if (site == null) return const Center(child: Text('No data'));
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return TabBarView(controller: _tabCtrl, children: [
            _hotelsTab(site.hotels, site.contacts.hotelContacts, isDark),
            _fleetTab(site.fleet, isDark),
            _faqTab(site.faqs, isDark, site.travelGuidelinesUrl),
            const _ParticipantDirectory(),
          ]);
        },
      ),
    );
  }

  // ─── Hotels with phone ───
  Widget _hotelsTab(List<Hotel> hotels, List<HotelContact> hc, bool isDark) {
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: hotels.length,
      itemBuilder: (_, i) {
        final h = hotels[i];
        // Match hotel contact by name
        final contact = hc.where((c) => h.name.contains(c.name) || c.name.contains(h.name)).toList();
        final phone = contact.isNotEmpty ? contact.first.phone : '';
        final email = contact.isNotEmpty ? contact.first.email : '';
        return Card(margin: const EdgeInsets.only(bottom: 12), clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (h.image.isNotEmpty) CachedNetworkImage(imageUrl: h.image, height: 180, width: double.infinity, fit: BoxFit.cover),
            Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h.name, style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(h.desc, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : AppTheme.textMid, height: 1.5)),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 10),
                InkWell(onTap: () => launchUrl(Uri.parse('tel:$phone')),
                  child: Row(children: [
                    Icon(Icons.phone, size: 16, color: AppTheme.teal),
                    const SizedBox(width: 8),
                    Text(phone, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.teal)),
                  ])),
              ],
              if (h.url.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton.icon(onPressed: () => launchUrl(Uri.parse(h.url)), icon: const Icon(Icons.open_in_new, size: 16), label: const Text('Visit Website'))),
            ])),
          ]));
      });
  }

  // ─── Fleet ───
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

  // ─── FAQ with Travel Guidelines button ───
  Widget _faqTab(List<FaqItem> faqs, bool isDark, String? guidelinesUrl) {
    final cats = {'all': 'All', 'travel': 'Travel', 'practical': 'Practical', 'health': 'Health', 'culture': 'Culture'};
    final filtered = _faqCat == 'all' ? faqs : faqs.where((f) => f.cat == _faqCat).toList();
    return Column(children: [
      if (guidelinesUrl != null && guidelinesUrl.isNotEmpty)
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(width: double.infinity, height: 46,
            child: ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse(guidelinesUrl), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.picture_as_pdf, size: 20),
              label: const Text('Download Travel Guidelines', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))))),
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

// ─── Participant Directory ────────────────────────────
class _ParticipantDirectory extends StatefulWidget {
  const _ParticipantDirectory();
  @override State<_ParticipantDirectory> createState() => _ParticipantDirectoryState();
}

class _ParticipantDirectoryState extends State<_ParticipantDirectory> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;
  final _api = ApiClient();
  List<Map<String, dynamic>>? _participants;
  bool _loading = true; String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await _api.getParticipants();
    if (r['success'] == true && r['data'] != null) {
      _participants = (r['data'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) { super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_participants == null || _participants!.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.people_outline, size: 48, color: AppTheme.textLight),
      const SizedBox(height: 12),
      Text('No participants yet', style: TextStyle(color: AppTheme.textMid)),
      const SizedBox(height: 8),
      TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh, size: 18), label: const Text('Refresh')),
    ]));

    final filtered = _search.isEmpty ? _participants! :
      _participants!.where((p) => (p['name'] ?? '').toString().toLowerCase().contains(_search.toLowerCase())).toList();

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Row(children: [
        Text('${_participants!.length} participant${_participants!.length != 1 ? 's' : ''}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.teal)),
        const Spacer(),
        IconButton(onPressed: _load, icon: Icon(Icons.refresh, size: 20, color: AppTheme.textMid)),
      ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(hintText: 'Search by name', prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10)))),
      const SizedBox(height: 8),
      Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: filtered.length,
        itemBuilder: (_, i) {
          final p = filtered[i];
          final name = p['name']?.toString() ?? '';
          final job = p['job_title']?.toString() ?? '';
          final phone = p['mobile']?.toString() ?? '';
          final email = p['email']?.toString() ?? '';
          final ini = name.split(' ').where((s) => s.isNotEmpty).take(2).map((s) => s[0]).join().toUpperCase();
          return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border)),
            child: Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.teal, AppTheme.teal.withOpacity(0.7)]), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(ini, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.charcoal)),
                if (job.isNotEmpty) Text(job, style: TextStyle(fontSize: 12, color: AppTheme.textMid)),
                if (phone.isNotEmpty) InkWell(onTap: () => launchUrl(Uri.parse('tel:$phone')),
                  child: Text('📞 $phone', style: TextStyle(fontSize: 12, color: AppTheme.teal))),
                if (email.isNotEmpty) Text('✉ $email', style: TextStyle(fontSize: 11, color: AppTheme.textMid)),
              ])),
            ]));
        })),
    ]);
  }
}
