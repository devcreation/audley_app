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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = ref.watch(contentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          // Emergency contact hero
          if (content.data != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.teal, AppTheme.tealDark]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Icon(Icons.phone_in_talk,
                      size: 32, color: AppTheme.goldLight),
                  const SizedBox(height: 8),
                  const Text('24/7 Emergency Helpline',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          letterSpacing: 1)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _call(content.data!.contacts.emergency),
                    child: Text(
                      content.data!.contacts.emergency,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Menu items
          _menuTile(
            context,
            icon: Icons.people_outline,
            title: 'Participant Directory',
            subtitle: 'View fellow travellers',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const _DirectoryScreen())),
          ),
          _menuTile(
            context,
            icon: Icons.contacts_outlined,
            title: 'Contacts',
            subtitle: 'Ground team & hotel contacts',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const _ContactsScreen())),
          ),
          if (content.data?.travelGuidelinesUrl != null)
            _menuTile(
              context,
              icon: Icons.description_outlined,
              title: 'Travel Guidelines',
              subtitle: 'Essential info for your trip',
              onTap: () async {
                final uri = Uri.parse(content.data!.travelGuidelinesUrl!);
                if (await canLaunchUrl(uri)) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          const Divider(indent: 16, endIndent: 16),

          // Dark mode toggle
          SwitchListTile(
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                color: AppTheme.teal),
            title: const Text('Dark Mode'),
            value: isDark,
            activeColor: AppTheme.teal,
            onChanged: (_) => ref.read(darkModeProvider.notifier).toggle(),
          ),

          const Divider(indent: 16, endIndent: 16),

          // Logout
          _menuTile(
            context,
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Log out of your account',
            color: Colors.red.shade600,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content:
                      const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600),
                        child: const Text('Sign Out')),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(authProvider.notifier).logout();
              }
            },
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'Audley Achievers\' Incentive v1.0.0\nby Distant Frontiers',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight,
                  height: 1.6),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _menuTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.teal),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: color, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  void _call(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }
}

// ─── Participant Directory ──────────────────────────────────
class _DirectoryScreen extends ConsumerWidget {
  const _DirectoryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participants = ref.watch(participantsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Participant Directory')),
      body: participants.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.textLight),
              const SizedBox(height: 12),
              const Text('Could not load participants'),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: () => ref.invalidate(participantsProvider),
                  child: const Text('Retry')),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No participants yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(participantsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (ctx, i) {
                final p = list[i];
                final initials = p.name
                    .split(' ')
                    .where((s) => s.isNotEmpty)
                    .take(2)
                    .map((s) => s[0])
                    .join()
                    .toUpperCase();

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.teal,
                      child: Text(initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ),
                    title: Text(p.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${p.mobile}\n${p.email}',
                        style: const TextStyle(fontSize: 12, height: 1.5)),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.phone_outlined,
                          color: AppTheme.teal, size: 20),
                      onPressed: () async {
                        final uri = Uri.parse(
                            'tel:${p.mobile.replaceAll(RegExp(r'[^\d+]'), '')}');
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── Contacts Screen ────────────────────────────────────────
class _ContactsScreen extends ConsumerWidget {
  const _ContactsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    if (content.data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final c = content.data!.contacts;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ground team
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business, color: AppTheme.teal),
                      const SizedBox(width: 8),
                      Text(c.office,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const Text('Ground Handling Partner',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textMid)),
                  const Divider(height: 24),
                  ...c.people.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.role,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.gold,
                                          fontWeight: FontWeight.w700)),
                                  Text(p.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone_outlined,
                                  color: AppTheme.teal, size: 20),
                              onPressed: () => _call(p.phone),
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 8),
                  _contactRow(Icons.email_outlined, c.email,
                      'mailto:${c.email}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text('Hotel Contacts',
              style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          ...c.hotelContacts.map((h) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(h.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${h.city}\n${h.phone}',
                      style: const TextStyle(fontSize: 12, height: 1.5)),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.phone_outlined,
                        color: AppTheme.teal, size: 20),
                    onPressed: () => _call(h.phone),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  static Widget _contactRow(IconData icon, String text, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) launchUrl(uri);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.teal),
            const SizedBox(width: 8),
            Flexible(
              child: Text(text,
                  style: const TextStyle(fontSize: 13, color: AppTheme.teal)),
            ),
          ],
        ),
      ),
    );
  }

  static void _call(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }
}
