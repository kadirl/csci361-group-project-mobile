import 'package:flutter/material.dart';

// Placeholder content widget for tabs
class PlaceholderTabContentWidget extends StatelessWidget {
  final String tabName;
  final IconData icon;

  const PlaceholderTabContentWidget({
    super.key,
    required this.tabName,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          
          const SizedBox(height: 24),
          
          Text(
            tabName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Coming soon',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }
}

