import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';

class WelcomeActions extends StatelessWidget {
  final double buttonHeight;
  final double buttonTextSize;
  final bool isSmallScreen;
  final bool isDark;
  final double contentSpacing;
  final double screenHeight;

  const WelcomeActions({
    super.key,
    required this.buttonHeight,
    required this.buttonTextSize,
    required this.isSmallScreen,
    required this.isDark,
    required this.contentSpacing,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: contentSpacing),
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD00B),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Log In with email and password',
                  style: TextStyle(
                    fontSize: buttonTextSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: buttonTextSize),
              ],
            ),
          ),
        ),
        // SizedBox(height: isSmallScreen ? 10.0 : 12.0),
        // SizedBox(
        //   width: double.infinity,
        //   height: buttonHeight,
        //   child: OutlinedButton(
        //     onPressed: () => context.go('/register'),
        //     style: OutlinedButton.styleFrom(
        //       foregroundColor: isDark ? Colors.white : Colors.black,
        //       side: BorderSide(
        //         color: isDark
        //             ? Colors.white.withOpacity(0.2)
        //             : Colors.grey.shade300,
        //       ),
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(12),
        //       ),
        //     ),
        //     child: Text(
        //       'Create Account',
        //       style: TextStyle(
        //         fontSize: buttonTextSize,
        //         fontWeight: FontWeight.bold,
        //       ),
        //     ),
        //   ),
        // ),
        SizedBox(height: isSmallScreen ? 16.0 : 20.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: isSmallScreen ? 10.0 : 12.0,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
            Container(
              width: 1,
              height: isSmallScreen ? 10.0 : 12.0,
              margin: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12.0 : 16.0,
              ),
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.grey.shade300,
            ),
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: isSmallScreen ? 10.0 : 12.0,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
        // Bottom padding for safe scrolling protection or just visual
        SizedBox(
          height: isSmallScreen
              ? 16.0
              : math.max(16.0, math.min(24.0, screenHeight * 0.02)),
        ),
      ],
    );
  }
}
