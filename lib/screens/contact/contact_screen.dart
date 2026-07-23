import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';

class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteAsync = ref.watch(siteDataProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Contact')),
      body: siteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Unable to load contacts')),
        data: (site) {
          if (site == null) return const Center(child: Text('No data'));
          final c = site.contacts;
          return ListView(padding: const EdgeInsets.all(16), children: [

              // ─── Emergency Card ───
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.red.shade700, Colors.red.shade600]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
                child: InkWell(
                  onTap: () => launchUrl(Uri.parse('tel:${c.emergency}')),
                  child: Row(children: [
                    Container(width: 52, height: 52,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.emergency, color: Colors.white, size: 28)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('24/7 Emergency', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(c.emergency, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ])),
                    const Icon(Icons.phone, color: Colors.white70, size: 24),
                  ])),
              ),
              const SizedBox(height: 20),

              // ─── Email ───
              if (c.email.isNotEmpty) ...[
                _contactTile(
                  icon: Icons.email_rounded, iconColor: AppTheme.gold,
                  title: 'Email Us', subtitle: c.email, isDark: isDark,
                  onTap: () => launchUrl(Uri.parse('mailto:${c.email}'))),
                const SizedBox(height: 20),
              ],

              // ─── Team Contacts ───
              Text('Your Trip Team', style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.charcoal)),
              const SizedBox(height: 4),
              Text('Reach out to our team for any assistance', style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
              const SizedBox(height: 12),
              ...c.people.map((p) => Padding(padding: const EdgeInsets.only(bottom: 10),
                child: _personCard(name: p.name, role: p.role, phone: p.phone, isDark: isDark))),

              const SizedBox(height: 24),

              // ─── Hotel Contacts ───
              Text('Hotel Contacts', style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.charcoal)),
              const SizedBox(height: 4),
              Text('Direct lines to your accommodation', style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
              const SizedBox(height: 12),
              ...c.hotelContacts.map((h) => Padding(padding: const EdgeInsets.only(bottom: 10),
                child: _hotelCard(name: h.name, city: h.city, phone: h.phone, email: h.email, isDark: isDark))),

              const SizedBox(height: 20),

              // ─── Office ───
              if (c.office.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.teal.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.teal.withOpacity(0.15))),
                  child: Row(children: [
                    Icon(Icons.business, color: AppTheme.teal, size: 20),
                    const SizedBox(width: 12),
                    Text('Organised by ${c.office}', style: TextStyle(fontSize: 13, color: AppTheme.teal, fontWeight: FontWeight.w600)),
                  ]),
                ),
              const SizedBox(height: 24),
            ]);
        },
      ),
    );
  }

  Widget _contactTile({required IconData icon, required Color iconColor, required String title, required String subtitle, required bool isDark, VoidCallback? onTap}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border)),
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : AppTheme.textLight, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.charcoal)),
          ])),
          Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textLight),
        ])));
  }

  Widget _personCard({required String name, required String role, required String phone, required bool isDark}) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse('tel:$phone')),
      borderRadius: BorderRadius.circular(12),
      child: Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border)),
        child: Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.teal, AppTheme.teal.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(name.isNotEmpty ? name[0] : '?',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.charcoal)),
            const SizedBox(height: 2),
            Text(role, style: TextStyle(fontSize: 12, color: AppTheme.textMid)),
          ])),
          Container(width: 38, height: 38,
            decoration: BoxDecoration(color: AppTheme.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.phone_outlined, color: AppTheme.teal, size: 18)),
        ])),
    );
  }

  Widget _hotelCard({required String name, required String city, required String phone, required String email, required bool isDark}) {
    return Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.hotel, color: AppTheme.gold, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.charcoal)),
            Text(city, style: TextStyle(fontSize: 12, color: AppTheme.textMid)),
          ])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: InkWell(
            onTap: () => launchUrl(Uri.parse('tel:$phone')),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: AppTheme.teal.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.phone, size: 14, color: AppTheme.teal),
                const SizedBox(width: 6),
                Text('Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.teal)),
              ])))),
          const SizedBox(width: 8),
          if (email.isNotEmpty) Expanded(child: InkWell(
            onTap: () => launchUrl(Uri.parse('mailto:$email')),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.email, size: 14, color: AppTheme.gold),
                const SizedBox(width: 6),
                Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.gold)),
              ])))),
        ]),
      ]));
  }
}
