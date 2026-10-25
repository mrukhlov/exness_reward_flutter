import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EventsHeader extends StatelessWidget {
  const EventsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Events',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.normal,
              letterSpacing: 0.5,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          TextButton.icon(
            onPressed: () => context.go('/suggest-event'),
            icon: Icon(Icons.add, size: 18, color: isDark ? Colors.white : Colors.black),
            label: Text(
              'Suggest',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
