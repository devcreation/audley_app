import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../data/models/models.dart';

class ProgrammeScreen extends ConsumerStatefulWidget {
  const ProgrammeScreen({super.key});
  @override
  ConsumerState<ProgrammeScreen> createState() => _ProgrammeScreenState();
}

class _ProgrammeScreenState extends ConsumerState<ProgrammeScreen> {
  int _selectedDay = 0;

  @override
  Widget build(BuildContext context) {
    final siteAsync = ref.watch(siteDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Programme')),
      body: siteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load')),
        data: (site) {
          if (site == null || site.programme.isEmpty) return const Center(child: Text('No programme'));
          final days = site.programme;
          if (_selectedDay >= days.length) _selectedDay = 0;
          final day = days[_selectedDay];
          return Column(children: [
            // Day chips
            SizedBox(height: 52, child: ListView.builder(
              scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: days.length,
              itemBuilder: (_, i) {
                final d = days[i];
                final sel = i == _selectedDay;
                final label = '${d.day.substring(0, 3)}, ${d.date}';
                return Padding(padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : (isDark ? Colors.grey[300] : AppTheme.charcoal))),
                    selected: sel, selectedColor: AppTheme.teal, backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: sel ? AppTheme.teal : AppTheme.border)),
                    onSelected: (_) => setState(() => _selectedDay = i)));
              },
            )),
            // Day header with image
            if (day.image.isNotEmpty) SizedBox(height: 160, width: double.infinity,
              child: Stack(children: [
                CachedNetworkImage(imageUrl: day.image, fit: BoxFit.cover, width: double.infinity, height: 160, errorWidget: (_, __, ___) => Container(color: AppTheme.tealDark)),
                Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.6)]))),
                Positioned(bottom: 12, left: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(day.dateFull, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(day.location, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ])),
              ])),
            // Items
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.all(16), itemCount: day.items.length,
              itemBuilder: (_, i) => _itemCard(day.items[i], isDark))),
          ]);
        },
      ),
    );
  }

  Widget _itemCard(ProgrammeItem item, bool isDark) {
    final isHighlight = item.type == 'highlight' || item.type == 'gala';
    final borderColor = isHighlight ? AppTheme.gold : (isDark ? AppTheme.darkBorder : AppTheme.border);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor), boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (item.time.isNotEmpty) Text(item.time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isHighlight ? AppTheme.gold : AppTheme.teal)),
        const SizedBox(height: 4),
        Text(item.title, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppTheme.charcoal, height: 1.4)),
        if (item.group.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppTheme.teal.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
            child: Text(item.group, style: TextStyle(fontSize: 11, color: AppTheme.teal)))),
        if (item.sub.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(item.sub, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : AppTheme.textMid, height: 1.5))),
      ]),
    );
  }
}
