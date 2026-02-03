import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SavedPlacesEmptyState extends StatelessWidget {
  const SavedPlacesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_border,
              size: 32,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No saved places yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/discover'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD00B),
              foregroundColor: Colors.black,
            ),
            child: const Text('Discover Venues'),
          ),
        ],
      ),
    );
  }
}
