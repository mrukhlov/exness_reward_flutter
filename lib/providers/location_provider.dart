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
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Permission to access location was denied';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions are permanently denied';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get current position
      _location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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

