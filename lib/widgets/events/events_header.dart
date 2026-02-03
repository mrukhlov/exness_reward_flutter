import 'package:flutter/material.dart';

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
        ],
      ),
    );
  }
}
