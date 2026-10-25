import 'package:flutter/material.dart';

class ProfileLogoutButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const ProfileLogoutButton({
    super.key,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Red accent — logout is destructive, and yellow reads poorly on gray
    final accent = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1E1E).withOpacity(0.2)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? const Color(0xFF1E1E1E).withOpacity(0.2)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20, color: accent),
            const SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
