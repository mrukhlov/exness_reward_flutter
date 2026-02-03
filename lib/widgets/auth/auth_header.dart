import 'package:flutter/material.dart';

/// Logo and brand name header for auth screens.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, this.logoSize = 36});

  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.change_history,
          size: logoSize,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'exness',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
