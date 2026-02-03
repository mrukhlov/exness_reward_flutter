import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VenueActionButtons extends StatelessWidget {
  final String venueId;

  const VenueActionButtons({super.key, required this.venueId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          context.go('/map?venueId=$venueId');
        },
        icon: const Icon(Icons.map, color: Colors.black),
        label: const Text(
          'Show on Map',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD00B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
