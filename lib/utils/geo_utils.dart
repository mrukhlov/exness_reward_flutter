import 'dart:math';

/// Calculate distance between two coordinates in kilometers
double getDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const double R = 6371; // Radius of the earth in km
  final double dLat = _deg2rad(lat2 - lat1);
  final double dLon = _deg2rad(lon2 - lon1);
  final double a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c; // Distance in km
}

/// Calculate distance and return formatted string
String calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  final double d = getDistanceKm(lat1, lon1, lat2, lon2);

  if (d < 1) {
    return '${(d * 1000).round()} m';
  }
  return '${d.toStringAsFixed(1)} km';
}

double _deg2rad(double deg) {
  return deg * (pi / 180);
}
