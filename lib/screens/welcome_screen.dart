import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/welcome/welcome_header.dart';
import '../widgets/welcome/welcome_hero_image.dart';
import '../widgets/welcome/welcome_content.dart';
import '../widgets/welcome/welcome_actions.dart';

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
                logoSize +
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
                        // Header Logo
                        WelcomeHeader(
                          logoSize: logoSize,
                          isDark: isDark,
                        ),
                        SizedBox(height: sectionSpacing),
                        // Hero Card
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

                              return WelcomeHeroImage(
                                width: imageWidth,
                                height: finalImageHeight,
                                isDark: isDark,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: sectionSpacing),
                        // Text Content
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.06,
                          ),
                          child: WelcomeContent(
                            titleSize: titleSize,
                            subtitleSize: subtitleSize,
                            isDark: isDark,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                // Fixed Bottom Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                  child: WelcomeActions(
                    buttonHeight: buttonHeight,
                    buttonTextSize: buttonTextSize,
                    isSmallScreen: isSmallScreen,
                    isDark: isDark,
                    contentSpacing: contentSpacing,
                    screenHeight: screenHeight,
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
