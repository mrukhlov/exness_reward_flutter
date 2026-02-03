import 'package:flutter/material.dart';

class EventHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback? onShare;

  const EventHeader({
    super.key,
    required this.title,
    required this.isDark,
    required this.onBack,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            onPressed: onBack,
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // Placeholder for alignment if share is not present
          if (onShare == null)
            const SizedBox(width: 48)
          else
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.share,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              onPressed: onShare,
            ),
        ],
      ),
    );
  }
}
