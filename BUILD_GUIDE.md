import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteAsync = ref.watch(siteDataProvider);
    final config = ref.watch(appConfigProvider).valueOrNull;
    final isDark = ref.watch(darkModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // ─── Event Info ───
        siteAsync.when(
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
          data: (site) {
            if (site == null) return const SizedBox();
            return _sectionCard(
              icon: Icons.event_outlined, iconColor: AppTheme.teal,
              title: site.event.name.isNotEmpty ? site.event.name : 'Event Details',
              subtitle: site.event.dates.isNotEmpty ? site.event.dates : 'India 2026',
              isDark: isDark);
          }),
        const SizedBox(height: 10),

        // ─── Dark Mode ───
        _sectionCard(
          icon: Icons.dark_mode_outlined, iconColor: Colors.indigo,
          title: 'Dark Mode', subtitle: isDark ? 'Currently on' : 'Currently off',
          isDark: isDark, trailing: Switch(
            value: isDark, onChanged: (_) => ref.read(darkModeProvider.notifier).toggle(),
            activeColor: AppTheme.teal)),

        const SizedBox(height: 24),

        // ─── App Info ───
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.grey[50],
            borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Image.asset('assets/logo.png', width: 48, height: 48),
            const SizedBox(height: 8),
            Text(config?.appName ?? "Audley Achievers' Incentive",
              style: TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.charcoal), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Version 1.0.0', style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
          ]),
        ),

        const SizedBox(height: 20),

        // ─── Sign Out ───
        SizedBox(width: double.infinity, height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context, ref),
            icon: const Icon(Icons.logout, size: 18, color: Colors.red),
            label: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _sectionCard({required IconData icon, required Color iconColor, required String title, required String subtitle, required bool isDark, VoidCallback? onTap, Widget? trailing}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border)),
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.charcoal)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.textMid)),
          ])),
          if (trailing != null) trailing
          else if (onTap != null) Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textLight),
        ])));
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () { Navigator.pop(ctx); ref.read(authProvider.notifier).logout(); },
          child: const Text('Sign Out', style: TextStyle(color: Colors.red))),
      ]));
  }
}
