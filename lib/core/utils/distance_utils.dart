import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DistanceUtils {
  static double calculateDistance(List<LatLng> points) {
    double distance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      distance += _coordDistance(
        points[i],
        points[i + 1],
      );
    }
    return distance;
  }

  static int findNearestIndex(LatLng current, List<LatLng> route) {
    double min = double.infinity;
    int index = -1;

    for (int i = 0; i < route.length; i++) {
      final d = _coordDistance(current, route[i]);
      if (d < min) {
        min = d;
        index = i;
      }
    }

    return min < 0.05 ? index : -1;
  }

  static String estimateTime(double distance, int speed) {
    if (speed <= 0) return '--';
    final minutes = ((distance / speed) * 60).ceil();
    return "${minutes ~/ 60}h ${minutes % 60}min";
  }

  static double _coordDistance(LatLng a, LatLng b) {
    const p = 0.017453292519943295;
    final lat1 = a.latitude;
    final lon1 = a.longitude;
    final lat2 = b.latitude;
    final lon2 = b.longitude;

    final x = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(x));
  }
}
