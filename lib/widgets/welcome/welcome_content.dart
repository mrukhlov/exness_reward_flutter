import 'package:flutter/material.dart';

class WelcomeContent extends StatelessWidget {
  final double titleSize;
  final double subtitleSize;
  final bool isDark;
  final bool isSmallScreen;

  const WelcomeContent({
    super.key,
    required this.titleSize,
    required this.subtitleSize,
    required this.isDark,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Your City, Your Rewards.',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isSmallScreen ? 8.0 : 12.0),
        Text(
          'Access exclusive corporate discounts and find top-rated venues near you on the Exness map.',
          style: TextStyle(
            fontSize: subtitleSize,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
