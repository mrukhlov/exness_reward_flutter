import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider with ChangeNotifier {
  Position? _location;
  String? _error;
  bool _isLoading = true;

  Position? get location => _location;
  String? get error => _error;
  bool get isLoading => _isLoading;

  double? get latitude => _location?.latitude;
  double? get longitude => _location?.longitude;

  LocationProvider() {
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!kIsWeb) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _error = 'Location services are disabled';
          return;
        }
      }

      LocationPermission permission = LocationPermission.denied;
      try {
        permission = await Geolocator.checkPermission();
      } catch (e) {
        debugPrint('Location checkPermission failed: $e');
      }

      if (permission == LocationPermission.denied) {
        try {
          permission = await Geolocator.requestPermission();
        } catch (e) {
          debugPrint('Location requestPermission failed: $e');
        }
      }

      if (!kIsWeb &&
          (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever)) {
        _error = 'Permission to access location was denied';
        return;
      }

      // Web needs WebSettings. LocationAccuracy.high often times out in
      // desktop Chrome (no GPS). getCurrentPosition itself shows the prompt.
      final locationSettings = kIsWeb
          ? WebSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 15),
              maximumAge: const Duration(minutes: 5),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 15),
            );

      _location = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      _error = null;
    } catch (e) {
      _error = 'Failed to get location: ${e.toString()}';
      debugPrint('Location error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshLocation() async {
    _isLoading = true;
    notifyListeners();
    await _getCurrentLocation();
  }
}
