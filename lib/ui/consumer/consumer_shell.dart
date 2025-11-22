import 'package:flutter/material.dart';

import 'views/companies_view.dart';
import 'views/linkings_view.dart';
import 'views/orders_view.dart';
import 'views/cart_view.dart';
import 'package:swe_mobile/ui/settings/settings_view.dart';

// Entry point for the consumer experience with a bottom tab bar.
class ConsumerShell extends StatefulWidget {
  const ConsumerShell({super.key});

  @override
  State<ConsumerShell> createState() => _ConsumerShellState();
}

class _ConsumerShellState extends State<ConsumerShell> {
  // Keep track of the currently selected bottom tab index
  int _currentIndex = 0;

  // Pages for each tab, kept in order of the bottom bar items
  final List<Widget> _pages = const <Widget>[
    ConsumerOrdersView(),
    ConsumerCompaniesView(),
    ConsumerLinkingsView(),
    ConsumerCartView(),
    SettingsView(),
  ];

  // Titles for the AppBar corresponding to the selected tab
  final List<String> _titles = const <String>[
    'Orders',
    'Companies',
    'Linkings',
    'Cart',
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
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_outlined),
            label: 'Companies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.link_outlined),
            label: 'Linkings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Cart',
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

