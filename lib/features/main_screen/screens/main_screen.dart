import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/placeholder_tab_content_widget.dart';

// Main screen with bottom tab bar
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  // Current selected tab index
  int _currentIndex = 0;

  // Handle tab change
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Build tab data based on current localization
  List<Map<String, dynamic>> _buildTabs(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return [
      {
        'title': l10n.home,
        'icon': Icons.home,
      },
      {
        'title': l10n.search,
        'icon': Icons.search,
      },
      {
        'title': l10n.add,
        'icon': Icons.add_circle_outline,
      },
      {
        'title': l10n.notifications,
        'icon': Icons.notifications_outlined,
      },
      {
        'title': l10n.profile,
        'icon': Icons.person_outline,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state to get user info
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Get localized tab data
    final tabs = _buildTabs(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[_currentIndex]['title']),
        actions: [
          // User email display
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Center(
                child: Text(
                  user.email,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Sign out and return to login screen
              ref.read(authProvider.notifier).signOut();
            },
            tooltip: AppLocalizations.of(context)!.logout,
          ),
        ],
      ),
      
      body: PlaceholderTabContentWidget(
        tabName: tabs[_currentIndex]['title'],
        icon: tabs[_currentIndex]['icon'],
      ),
      
      // Bottom tab bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: tabs.map((tab) {
          return BottomNavigationBarItem(
            icon: Icon(tab['icon']),
            label: tab['title'],
          );
        }).toList(),
      ),
    );
  }
}

