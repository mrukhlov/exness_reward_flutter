import 'package:flutter/material.dart';

class EventActionFooter extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAddToCalendar;

  const EventActionFooter({
    super.key,
    required this.isDark,
    required this.onAddToCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade200,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: onAddToCalendar,
          icon: const Icon(Icons.event, color: Colors.black),
          label: const Text(
            'ADD TO CALENDAR',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD00B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
