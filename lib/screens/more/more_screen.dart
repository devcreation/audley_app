import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../data/models/models.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteAsync = ref.watch(siteDataProvider);
    final config = ref.watch(appConfigProvider).valueOrNull;
    final isDark = ref.watch(darkModeProvider);

    // UI strings from API
    final emergencyTitle = config?.uiString('section_emergency', 'Emergency Helpline') ?? 'Emergency Helpline';
    final contactsTitle = config?.uiString('section_contacts', 'Contact Directory') ?? 'Contact Directory';
    final hotelsTitle = config?.uiString('section_hotels', 'Hotel Contacts') ?? 'Hotel Contacts';

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: siteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _fallback(context, ref, isDark),
        data: (site) {
          if (site == null) return _fallback(context, ref, isDark);
          final c = site.contacts;
          return ListView(padding: const EdgeInsets.all(16), children: [
            // Emergency
            Card(color: Colors.red.shade50, child: ListTile(
              leading: const Icon(Icons.emergency, color: Colors.red),
              title: Text(emergencyTitle, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.red)),
              subtitle: Text(c.emergency, style: const TextStyle(color: Colors.red)),
              onTap: () => launchUrl(Uri.parse('tel:${c.emergency}')))),
            const SizedBox(height: 16),

            // Contact directory
            Text(contactsTitle, style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppTheme.charcoal)),
            const SizedBox(height: 8),
            if (c.email.isNotEmpty) ListTile(leading: const Icon(Icons.email, color: AppTheme.teal), title: Text(c.email), onTap: () => launchUrl(Uri.parse('mailto:${c.email}'))),
            ...c.people.map((p) => ListTile(leading: const Icon(Icons.person, color: AppTheme.teal),
              title: Text(p.name), subtitle: Text('${p.role} • ${p.phone}'),
              onTap: () => launchUrl(Uri.parse('tel:${p.phone}')))),

            const SizedBox(height: 16),
            Text(hotelsTitle, style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppTheme.charcoal)),
            const SizedBox(height: 8),
            ...c.hotelContacts.map((h) => Card(child: ListTile(
              title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${h.city} • ${h.phone}'),
              trailing: const Icon(Icons.phone, color: AppTheme.teal, size: 20),
              onTap: () => launchUrl(Uri.parse('tel:${h.phone}'))))),

            const SizedBox(height: 24),
            SwitchListTile(title: const Text('Dark Mode'), secondary: const Icon(Icons.dark_mode),
              value: isDark, onChanged: (_) => ref.read(darkModeProvider.notifier).toggle()),
            const Divider(),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () => ref.read(authProvider.notifier).logout()),
          ]);
        },
      ),
    );
  }

  Widget _fallback(BuildContext context, WidgetRef ref, bool isDark) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      SwitchListTile(title: const Text('Dark Mode'), secondary: const Icon(Icons.dark_mode),
        value: isDark, onChanged: (_) => ref.read(darkModeProvider.notifier).toggle()),
      const Divider(),
      ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
        onTap: () => ref.read(authProvider.notifier).logout()),
    ]);
  }
}
