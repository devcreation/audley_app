import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/providers.dart';
import 'home/home_screen.dart';
import 'programme/programme_screen.dart';
import 'forms/forms_screen.dart';
import 'info/info_screen.dart';
import 'contact/contact_screen.dart';
import 'more/more_screen.dart';
import 'auth/login_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _idx = 0;

  // Only Home(0) and More(5) are public — rest require login
  static const _loginRequiredTabs = {1, 2, 3, 4};

  final _screens = const [
    HomeScreen(),        // 0 - public
    ProgrammeScreen(),   // 1 - requires login
    InfoScreen(),        // 2 - requires login
    FormsScreen(),       // 3 - requires login
    ContactScreen(),     // 4 - requires login
    MoreScreen(),        // 5 - public (but hides sign out / delete if not logged in)
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState.status == AuthStatus.authenticated;

    return Scaffold(
      body: IndexedStack(index: _idx, children: [
        for (int i = 0; i < _screens.length; i++)
          if (_loginRequiredTabs.contains(i) && !isLoggedIn)
            const LoginScreen()
          else
            _screens[i],
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.teal,
        unselectedItemColor: isDark ? Colors.grey[600] : AppTheme.textLight,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Programme'),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), activeIcon: Icon(Icons.info), label: 'Details'),
          BottomNavigationBarItem(icon: Icon(Icons.person_add_outlined), activeIcon: Icon(Icons.person_add), label: 'Register'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts_outlined), activeIcon: Icon(Icons.contacts), label: 'Contact'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), activeIcon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
