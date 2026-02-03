import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SavedPlacesHeader extends StatelessWidget {
  const SavedPlacesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Always return to profile page
              context.go('/profile');
            },
            color: Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Text(
            'Saved Places',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
