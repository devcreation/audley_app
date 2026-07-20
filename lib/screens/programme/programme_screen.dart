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
    final content = ref.watch(contentProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (content.data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final days = content.data!.programme.days;

    return Scaffold(
      appBar: AppBar(title: const Text('Programme')),
      body: RefreshIndicator(
        color: AppTheme.teal,
        onRefresh: () => ref.read(contentProvider.notifier).loadContent(forceRefresh: true),
        child: Column(
          children: [
            // Date pills (show actual dates like website)
            Container(
              height: 56,
              color: isDark ? AppTheme.darkSurface : AppTheme.bgWarm,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: days.length,
                itemBuilder: (ctx, i) {
                  final selected = i == _selectedDay;
                  final day = days[i];
                  // Show "day, date" like "Fri, 11 Sep"
                  final label = '${day.day.substring(0, 3)}, ${day.date}';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedDay = i),
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
                        side: BorderSide(
                          color: selected ? AppTheme.teal : AppTheme.border,
                          width: 0.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(child: _buildDayContent(days[_selectedDay], isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayContent(ProgrammeDay day, bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (day.image != null && day.image!.isNotEmpty)
          Stack(
            children: [
              CachedNetworkImage(
                imageUrl: day.image!,
                height: 180, width: double.infinity, fit: BoxFit.cover,
                placeholder: (_, __) => Container(height: 180, color: AppTheme.teal.withValues(alpha: 0.1), child: const Center(child: CircularProgressIndicator())),
                errorWidget: (_, __, ___) => Container(height: 180, color: AppTheme.tealDark),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(day.dateFull, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(day.location, style: TextStyle(color: AppTheme.goldLight, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          )
        else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day.dateFull, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(day.location, style: TextStyle(fontSize: 14, color: AppTheme.teal)),
              ],
            ),
          ),
        ...day.items.map((item) => _buildScheduleItem(item, isDark)),
      ],
    );
  }

  Widget _buildScheduleItem(ScheduleItem item, bool isDark) {
    Color? leftColor;
    Color? bgColor;
    if (item.type == 'highlight') {
      leftColor = AppTheme.gold;
      bgColor = AppTheme.gold.withValues(alpha: 0.06);
    } else if (item.type == 'gala') {
      leftColor = AppTheme.goldDark;
      bgColor = AppTheme.gold.withValues(alpha: 0.1);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? (bgColor != null ? AppTheme.gold.withValues(alpha: 0.08) : AppTheme.darkCard)
            : (bgColor ?? AppTheme.white),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: leftColor ?? (isDark ? Colors.grey.shade700 : AppTheme.border),
            width: 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.time.isNotEmpty)
              Text(item.time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.teal)),
            if (item.time.isNotEmpty) const SizedBox(height: 4),
            if (item.group != null && item.group!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(item.group!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.teal)),
              ),
            Text(item.title, style: TextStyle(fontSize: 14, height: 1.45, color: isDark ? Colors.grey[300] : AppTheme.textColor)),
            if (item.sub != null && item.sub!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : AppTheme.bgColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(item.sub!, style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.grey[400] : AppTheme.textMid)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
