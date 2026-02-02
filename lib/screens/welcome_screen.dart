import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Adaptive scaling factor based on screen height
    final isSmallScreen = screenHeight < 800;

    // Adaptive spacing
    final topSpacing = isSmallScreen
        ? 16.0
        : math.max(20.0, math.min(32.0, screenHeight * 0.04));
    final sectionSpacing = isSmallScreen
        ? 16.0
        : math.max(20.0, math.min(32.0, screenHeight * 0.04));
    final contentSpacing = isSmallScreen
        ? 20.0
        : math.max(24.0, math.min(40.0, screenHeight * 0.05));

    // Adaptive font sizes
    final logoSize = isSmallScreen ? 24.0 : 28.0;
    final iconSize = isSmallScreen ? 28.0 : 32.0;
    final titleSize = isSmallScreen ? 22.0 : 26.0;
    final subtitleSize = isSmallScreen ? 12.0 : 14.0;
    final buttonTextSize = isSmallScreen ? 14.0 : 16.0;
    final buttonHeight = isSmallScreen ? 50.0 : 56.0;

    // Adaptive aspect ratio - slightly taller on smaller screens to reduce width
    final imageAspectRatio = isSmallScreen
        ? 0.75
        : 0.8; // 3:4 on small, 4:5 on normal

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available space for image
            // Account for: top spacing, logo, section spacing, text content, buttons, bottom padding
            final estimatedOtherContentHeight =
                topSpacing +
                iconSize +
                sectionSpacing * 2 +
                titleSize * 1.3 +
                subtitleSize * 2.5 +
                (isSmallScreen ? 8.0 : 12.0) +
                contentSpacing +
                buttonHeight * 2 +
                (isSmallScreen ? 10.0 : 12.0) +
                (isSmallScreen ? 16.0 : 20.0) +
                30.0; // footer + bottom padding

            final availableHeight =
                constraints.maxHeight - estimatedOtherContentHeight;

            // Adaptive image constraints - use available space but with limits
            final imageHeightPercentage = isSmallScreen ? 0.28 : 0.38;
            final calculatedImageHeight = math.max(
              isSmallScreen ? 200.0 : 250.0, // Minimum height
              math.min(
                isSmallScreen ? 300.0 : 420.0, // Maximum height
                math.min(
                  availableHeight > 0
                      ? availableHeight * 0.9
                      : screenHeight *
                            imageHeightPercentage, // Use 90% of available space if positive
                  screenHeight *
                      imageHeightPercentage, // Or percentage of screen
                ),
              ),
            );
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: topSpacing),
                        // Header Logo - adaptive size
                        Row(
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
                        ),
                        SizedBox(height: sectionSpacing),
                        // Hero Card - adaptive size based on available space
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.06,
                          ),
                          child: LayoutBuilder(
                            builder: (context, imageConstraints) {
                              // Calculate image width based on available width
                              final imageWidth = imageConstraints.maxWidth;
                              // Use calculated height or aspect ratio, whichever is smaller
                              final finalImageHeight = math.min(
                                calculatedImageHeight,
                                imageWidth / imageAspectRatio,
                              );

                              return SizedBox(
                                width: imageWidth,
                                height: finalImageHeight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.grey.shade200,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    children: [
                                      Image.asset(
                                        'assets/images/welcome_image.png',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.error),
                                            ),
                                      ),
                                      Positioned(
                                        top: 16,
                                        right: 16,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.black.withOpacity(0.8)
                                                : Colors.white.withOpacity(0.95),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white.withOpacity(0.1)
                                                  : Colors.grey.shade100,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                size: 14,
                                                color: Color(0xFFFFD00B),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Near You',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: sectionSpacing),
                        // Text Content - adaptive font sizes
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.06,
                          ),
                          child: Column(
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
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                // Fixed Bottom Section
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                  ),
                  child: Column(
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
                                'Log In',
                                style: TextStyle(
                                  fontSize: buttonTextSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward,
                                size: buttonTextSize,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 10.0 : 12.0),
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: OutlinedButton(
                          onPressed: () => context.go('/register'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? Colors.white
                                : Colors.black,
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.grey.shade300,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: buttonTextSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16.0 : 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Terms of Service',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10.0 : 12.0,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500,
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
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500,
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
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
