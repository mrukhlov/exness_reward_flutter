import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../models/venue.dart';
import 'marker_helper.dart';

/// Cluster data class to represent a group of venues
class Cluster {
  final List<Venue> venues;
  final double lat;
  final double lng;

  Cluster(this.venues, this.lat, this.lng);

  int get count => venues.length;
}

class ClusteringHelper {
  // Clustering configuration
  static const double clusterZoomThreshold =
      14.0; // Show clusters below this zoom level
  static const double clusterDistanceThreshold =
      0.01; // Distance threshold for clustering (in degrees)

  /// Group nearby venues into clusters based on zoom level
  static List<Cluster> createClusters(List<Venue> venues, double? zoom) {
    // If zoomed in enough, don't cluster (show individual markers)
    if (zoom != null && zoom >= clusterZoomThreshold) {
      return venues.map((v) => Cluster([v], v.lat, v.lng)).toList();
    }

    // Calculate distance threshold based on zoom level
    // Lower zoom = larger threshold (more clustering)
    final distanceThreshold = zoom != null
        ? clusterDistanceThreshold * (15.0 - zoom) / 5.0
        : clusterDistanceThreshold * 2.0;

    final clusters = <Cluster>[];
    final processed = <int>{};

    for (int i = 0; i < venues.length; i++) {
      if (processed.contains(i)) continue;

      final venue = venues[i];
      final clusterVenues = <Venue>[venue];
      processed.add(i);

      // Find nearby venues to cluster together
      for (int j = i + 1; j < venues.length; j++) {
        if (processed.contains(j)) continue;

        final otherVenue = venues[j];
        final distance =
            ((venue.lat - otherVenue.lat).abs() +
            (venue.lng - otherVenue.lng).abs());

        if (distance < distanceThreshold) {
          clusterVenues.add(otherVenue);
          processed.add(j);
        }
      }

      // Calculate cluster center (average of all venues in cluster)
      final avgLat =
          clusterVenues.map((v) => v.lat).reduce((a, b) => a + b) /
          clusterVenues.length;
      final avgLng =
          clusterVenues.map((v) => v.lng).reduce((a, b) => a + b) /
          clusterVenues.length;

      clusters.add(Cluster(clusterVenues, avgLat, avgLng));
    }

    return clusters;
  }

  /// Create a cluster marker icon with count
  static Future<gmaps.BitmapDescriptor> createClusterIcon(int count) async {
    final size = clusterMarkerCanvasSize();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - 1;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, radius, shadowPaint);

    // Draw circle background (white for clusters)
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, borderPaint);

    // Draw count text
    final textStyle = TextStyle(
      fontSize: clusterMarkerFontSize(count),
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: count.toString(), style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return gmaps.BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }
}
