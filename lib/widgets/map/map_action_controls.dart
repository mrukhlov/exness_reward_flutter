import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_platform.dart';

class MapActionControls extends StatelessWidget {
  final bool isDark;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMyLocation;

  const MapActionControls({
    super.key,
    required this.isDark,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
  });

  Widget _buildControl(Widget child, VoidCallback onTap) {
    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E).withOpacity(0.9)
            : Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Theme Toggle (Google Maps with Custom Map Style only)
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            // Only show theme toggle when using Google Maps AND custom map style is enabled
            if (AppPlatform.isIOS && themeProvider.useAppleMaps) {
              return const SizedBox.shrink();
            }
            if (!themeProvider.useCustomMapStyle) {
              return const SizedBox.shrink();
            }

            return _buildControl(
              Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                size: 24,
                color: isDark ? Colors.white : Colors.black,
              ),
              () => themeProvider.toggleTheme(),
            );
          },
        ),

        // Map Provider Toggle (iOS only)
        if (AppPlatform.isIOS)
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return _buildControl(
                themeProvider.useAppleMaps
                    ? Icon(
                        Icons.apple,
                        size: 24,
                        color: isDark ? Colors.white : Colors.black,
                      )
                    : Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                () => themeProvider.toggleMapProvider(),
              );
            },
          ),

        // Zoom In
        _buildControl(
          Icon(
            Icons.add,
            size: 24,
            color: isDark ? Colors.white : Colors.black,
          ),
          onZoomIn,
        ),

        // Zoom Out
        _buildControl(
          Icon(
            Icons.remove,
            size: 24,
            color: isDark ? Colors.white : Colors.black,
          ),
          onZoomOut,
        ),

        // My Location
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD00B),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onMyLocation,
              borderRadius: BorderRadius.circular(24),
              child: const Icon(
                Icons.my_location,
                size: 24,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
