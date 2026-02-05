import 'package:flutter/material.dart';

class InviteStats extends StatelessWidget {
  final int pendingCount;
  final int acceptedCount;
  final bool isDark;

  const InviteStats({
    super.key,
    required this.pendingCount,
    required this.acceptedCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final totalActiveInvitesCount = pendingCount + acceptedCount;
    final isLimitReached = totalActiveInvitesCount >= 2;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Invites: $totalActiveInvitesCount/2 ($pendingCount pending, $acceptedCount accepted)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isLimitReached
                  ? Colors.orange
                  : isDark
                  ? Colors.grey.shade300
                  : Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (isLimitReached) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You have reached the limit of 2 invites. Please revoke a pending invite to send a new invitation.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
