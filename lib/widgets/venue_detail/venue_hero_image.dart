import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VenueHeroImage extends StatelessWidget {
  final String imageUrl;
  final bool isDark;

  const VenueHeroImage({
    super.key,
    required this.imageUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 320,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.image, size: 64),
            ),
          ),
        ),
        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  isDark ? Colors.black : const Color(0xFFF9FAFB),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
