import 'package:flutter/material.dart';

import 'views/dashboard_view.dart';
import 'views/catalog_view.dart';
import 'views/linkings_view.dart';
import 'views/chats_view.dart';
import 'package:swe_mobile/ui/settings/settings_view.dart';

// Entry point for the supplier experience with a bottom tab bar.
class SupplierShell extends StatefulWidget {
  const SupplierShell({super.key});

  @override
  State<SupplierShell> createState() => _SupplierShellState();
}

class _SupplierShellState extends State<SupplierShell> {
  // Keep track of the currently selected bottom tab index
  int _currentIndex = 0;

  // Pages for each tab, kept in order of the bottom bar items
  final List<Widget> _pages = const <Widget>[
    SupplierDashboardView(),
    SupplierCatalogView(),
    SupplierLinkingsView(),
    SupplierChatsView(),
    SettingsView(),
  ];

  // Titles for the AppBar corresponding to the selected tab
  final List<String> _titles = const <String>[
    'Home',
    'Catalog',
    'Linkings',
    'Chats',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),

      // Active tab content
      body: _pages[_currentIndex],

      // Bottom navigation bar with 5 tabs
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Catalog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.link_outlined),
            label: 'Linkings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
        onTap: (int newIndex) {
          setState(() {
            _currentIndex = newIndex;
          });
        },
      ),
    );
  }
}

