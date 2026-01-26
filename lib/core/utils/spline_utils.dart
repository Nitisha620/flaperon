import 'package:flutter/animation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

List<LatLng> getCurvedPoints(List<LatLng> points) {
  if (points.length < 4) return points;

  final offsets = points.map((p) => Offset(p.latitude, p.longitude)).toList();

  final spline = CatmullRomSpline(offsets, tension: 0.3);
  const samplesPerSegment = 15;
  final totalSamples = (points.length - 1) * samplesPerSegment;

  return List.generate(totalSamples + 1, (i) {
    final t = i / totalSamples;
    final o = spline.transform(t);
    return LatLng(o.dx, o.dy);
  });
}
