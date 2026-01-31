import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple_maps;
import 'category_icons.dart';

/// Creates a custom marker icon for Google Maps
/// Matches the React Native design: circular with category icon
Future<gmaps.BitmapDescriptor> createCustomMarkerIcon({
  required String category,
  required bool isSelected,
  double size = 80.0, // Increased from 42.0 to make markers bigger
}) async {
  final iconSize = isSelected ? 50.0 : 38.0; // Increased proportionally (was 28.0/20.0)

  // Background color: yellow if selected, white if not
  final backgroundColor = isSelected
      ? const Color(0xFFFFD00B) // exness-yellow
      : Colors.white;

  final iconData = getCategoryIcon(category);

  // Create a picture recorder
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final center = Offset(size / 2, size / 2);
  final radius = size / 2 - 1;

  // Draw shadow
  final shadowPaint = Paint()
    ..color = Colors.black.withOpacity(0.1)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  canvas.drawCircle(center, radius, shadowPaint);

  // Draw circle background
  final backgroundPaint = Paint()
    ..color = backgroundColor
    ..style = PaintingStyle.fill;
  canvas.drawCircle(center, radius, backgroundPaint);

  // Draw border
  final borderPaint = Paint()
    ..color = Colors.black.withOpacity(0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  canvas.drawCircle(center, radius, borderPaint);

  // Draw icon using TextPainter with Material Icons font
  // Material Icons use 'MaterialIcons' font family
  final textStyle = TextStyle(
    fontFamily: iconData.fontFamily ?? 'MaterialIcons',
    package: iconData.fontPackage,
    fontSize: iconSize,
    color: Colors.black,
  );

  final textPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: textStyle,
    ),
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

/// Creates a custom marker icon for Apple Maps
/// Matches the React Native design: circular with category icon
Future<apple_maps.BitmapDescriptor> createCustomAppleMarkerIcon({
  required String category,
  required bool isSelected,
  double size = 80.0, // Increased from 42.0 to make markers bigger
}) async {
  final iconSize = isSelected ? 50.0 : 38.0; // Increased proportionally (was 28.0/20.0)

  // Background color: yellow if selected, white if not
  final backgroundColor = isSelected
      ? const Color(0xFFFFD00B) // exness-yellow
      : Colors.white;

  final iconData = getCategoryIcon(category);

  // Create a picture recorder
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final center = Offset(size / 2, size / 2);
  final radius = size / 2 - 1;

  // Draw shadow
  final shadowPaint = Paint()
    ..color = Colors.black.withOpacity(0.1)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  canvas.drawCircle(center, radius, shadowPaint);

  // Draw circle background
  final backgroundPaint = Paint()
    ..color = backgroundColor
    ..style = PaintingStyle.fill;
  canvas.drawCircle(center, radius, backgroundPaint);

  // Draw border
  final borderPaint = Paint()
    ..color = Colors.black.withOpacity(0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  canvas.drawCircle(center, radius, borderPaint);

  // Draw icon using TextPainter with Material Icons font
  final textStyle = TextStyle(
    fontFamily: iconData.fontFamily ?? 'MaterialIcons',
    package: iconData.fontPackage,
    fontSize: iconSize,
    color: Colors.black,
  );

  final textPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: textStyle,
    ),
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

  return apple_maps.BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}

/// Creates a blue marker icon for user location on Apple Maps
/// Matches Google Maps blue marker style
Future<apple_maps.BitmapDescriptor> createBlueUserLocationMarker({
  double size = 40.0,
}) async {
  // Blue color matching Google Maps hueBlue
  const backgroundColor = Color(0xFF2196F3); // Material Blue

  // Create a picture recorder
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final center = Offset(size / 2, size / 2);
  final radius = size / 2 - 1;

  // Draw shadow
  final shadowPaint = Paint()
    ..color = Colors.black.withOpacity(0.2)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  canvas.drawCircle(center, radius, shadowPaint);

  // Draw circle background (blue)
  final backgroundPaint = Paint()
    ..color = backgroundColor
    ..style = PaintingStyle.fill;
  canvas.drawCircle(center, radius, backgroundPaint);

  // Draw white border
  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  canvas.drawCircle(center, radius - 1, borderPaint);

  // Convert to image
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  return apple_maps.BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}
