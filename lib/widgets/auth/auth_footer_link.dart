import 'package:flutter/material.dart';

/// Footer row with prompt text and action link (e.g. "Already have an account? Log In").
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.promptText,
    required this.linkLabel,
    required this.onTap,
  });

  final String promptText;
  final String linkLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            promptText,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              linkLabel,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
