import 'package:flutter/material.dart';

import 'views/dashboard_view.dart';
import 'views/catalog/catalog_view.dart';
import 'views/linkings_view.dart';
import 'views/orders_view.dart';
import 'views/complaints_view.dart';
import 'package:swe_mobile/ui/settings/settings_view.dart';
import 'package:swe_mobile/l10n/app_localizations.dart';

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
    SupplierOrdersView(),
    SupplierComplaintsView(),
    SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Titles for the AppBar corresponding to the selected tab
    final List<String> _titles = <String>[
      l10n.navigationDashboard,
      l10n.navigationCatalog,
      l10n.navigationLinkings,
      l10n.navigationOrders,
      l10n.navigationComplaints,
      l10n.navigationSettings,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),

      // Active tab content
      body: _pages[_currentIndex],

      // Bottom navigation bar with 6 tabs
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            label: l10n.navigationDashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2_outlined),
            label: l10n.navigationCatalog,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.link_outlined),
            label: l10n.navigationLinkings,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart_outlined),
            label: l10n.navigationOrders,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.report_problem_outlined),
            label: l10n.navigationComplaints,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            label: l10n.navigationSettings,
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

