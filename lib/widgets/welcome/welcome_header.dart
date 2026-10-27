import 'package:flutter/material.dart';

class WelcomeHeader extends StatelessWidget {
  final double logoSize;
  final bool isDark;

  const WelcomeHeader({
    super.key,
    required this.logoSize,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
