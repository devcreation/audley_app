import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../data/models/models.dart';

class InfoScreen extends ConsumerWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    if (content.data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Information'),
          bottom: const TabBar(
            indicatorColor: AppTheme.goldLight,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [Tab(text: 'Hotels'), Tab(text: 'Fleet'), Tab(text: 'FAQ')],
          ),
        ),
        body: TabBarView(children: [
          _HotelsTab(hotels: content.data!.hotels, hotelContacts: content.data!.contacts.hotelContacts),
          _FleetTab(fleet: content.data!.fleet),
          _FaqTab(faqs: content.data!.faqs),
        ]),
      ),
    );
  }
}

class _HotelsTab extends StatelessWidget {
  final List<Hotel> hotels;
  final List<HotelContact> hotelContacts;
  const _HotelsTab({required this.hotels, required this.hotelContacts});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hotels.length,
      itemBuilder: (ctx, i) {
        final hotel = hotels[i];
        final contact = i < hotelContacts.length ? hotelContacts[i] : null;
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (hotel.image != null)
              CachedNetworkImage(imageUrl: hotel.image!, height: 180, width: double.infinity, fit: BoxFit.cover,
                  placeholder: (_, __) => Container(height: 180, color: AppTheme.teal.withValues(alpha: 0.1)),
                  errorWidget: (_, __, ___) => Container(height: 180, color: AppTheme.tealDark)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(hotel.name, style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(hotel.desc, style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.grey[400] : AppTheme.textMid)),
                if (contact != null) ...[
                  const Divider(height: 24),
                  _contactRow(Icons.phone_outlined, contact.phone, 'tel:${contact.phone.replaceAll(' ', '')}'),
                ],
                if (hotel.url != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(onPressed: () => _openUrl(hotel.url!), icon: const Icon(Icons.open_in_new, size: 16), label: const Text('Visit Hotel Website')),
                ],
              ]),
            ),
          ]),
        );
      },
    );
  }

  Widget _contactRow(IconData icon, String text, String url) {
    return GestureDetector(
      onTap: () => _openUrl(url),
      child: Row(children: [
        Icon(icon, size: 16, color: AppTheme.teal),
        const SizedBox(width: 8),
        Flexible(child: Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.teal))),
      ]),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }
}

class _FleetTab extends StatelessWidget {
  final List<FleetVehicle> fleet;
  const _FleetTab({required this.fleet});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: fleet.length,
      itemBuilder: (ctx, i) {
        final v = fleet[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 16), clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (v.image != null)
              CachedNetworkImage(imageUrl: v.image!, height: 180, width: double.infinity, fit: BoxFit.cover,
                  placeholder: (_, __) => Container(height: 180, color: AppTheme.teal.withValues(alpha: 0.1)),
                  errorWidget: (_, __, ___) => Container(height: 180, color: AppTheme.tealDark)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(v.name, style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(v.desc, style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.grey[400] : AppTheme.textMid)),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _FaqTab extends StatefulWidget {
  final List<Faq> faqs;
  const _FaqTab({required this.faqs});

  @override
  State<_FaqTab> createState() => _FaqTabState();
}

class _FaqTabState extends State<_FaqTab> {
  String _activeCat = 'all';
  int? _expandedIndex;

  static const _catLabels = {'all': 'All', 'travel': 'Travel', 'health': 'Health', 'culture': 'Culture', 'practical': 'Practical'};

  List<Faq> get _filtered => _activeCat == 'all' ? widget.faqs : widget.faqs.where((f) => f.cat == _activeCat).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      // Category chips with FIXED text color
      Container(
        height: 52, padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: _catLabels.entries.map((e) {
            final selected = e.key == _activeCat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (_) => setState(() { _activeCat = e.key; _expandedIndex = null; }),
                selectedColor: AppTheme.teal,
                backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
                labelStyle: TextStyle(
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.grey[300] : AppTheme.charcoal),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: selected ? AppTheme.teal : AppTheme.border, width: 0.5),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          itemCount: _filtered.length,
          itemBuilder: (ctx, i) {
            final faq = _filtered[i];
            final expanded = i == _expandedIndex;
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _expandedIndex = expanded ? null : i),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(faq.q, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: expanded ? AppTheme.teal : null))),
                      Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 22, color: AppTheme.textLight),
                    ]),
                    if (expanded) ...[
                      const SizedBox(height: 10),
                      Text(faq.a.replaceAll(RegExp(r'<[^>]*>'), ''),
                          style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.grey[400] : AppTheme.textMid)),
                    ],
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
