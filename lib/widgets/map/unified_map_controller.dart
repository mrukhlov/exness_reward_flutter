abstract class UnifiedMapController {
  Future<void> animateTo(double lat, double lng, double zoom);
  Future<void> zoomIn();
  Future<void> zoomOut();
}
