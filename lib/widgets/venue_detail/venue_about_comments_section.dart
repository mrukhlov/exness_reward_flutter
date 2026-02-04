import 'package:flutter/material.dart';
import '../../models/venue.dart';

class VenueAboutCommentsSection extends StatelessWidget {
  final Venue venue;
  final bool isDark;

  const VenueAboutCommentsSection({
    super.key,
    required this.venue,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasAbout = venue.description != null && venue.description!.isNotEmpty;
    final hasComments = venue.comments != null && venue.comments!.isNotEmpty;

    if (!hasAbout && !hasComments) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Section
          if (hasAbout) ...[
            Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              venue.description!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
          // Divider if both sections exist
          if (hasAbout && hasComments) ...[
            const SizedBox(height: 24),
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade200,
            ),
            const SizedBox(height: 24),
          ],
          // Comments Section
          if (hasComments) ...[
            Text(
              'Comments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              venue.comments!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
