import 'package:flutter/material.dart';

class WelcomeHeader extends StatelessWidget {
  final double iconSize;
  final double logoSize;
  final bool isDark;

  const WelcomeHeader({
    super.key,
    required this.iconSize,
    required this.logoSize,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.change_history,
          size: iconSize,
          color: const Color(0xFFFFD00B),
        ),
        const SizedBox(width: 8),
        Text(
          'exness',
          style: TextStyle(
            fontSize: logoSize,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
}
