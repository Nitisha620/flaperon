import 'dart:async';
import 'package:flaperon/features/navigation/data/helpers/marker_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/models/navigation_state.dart';
import '../data/services/directions_service.dart';
import '../data/services/geocoding_service.dart';
import '../../../core/utils/distance_utils.dart';

class NavigationController extends ChangeNotifier {
  NavigationState _state = const NavigationState();
  NavigationState get state => _state;
  BitmapDescriptor? bikeIcon;
  BitmapDescriptor? destinationIcon;
  final TextEditingController sourceController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  bool _userInteracted = false;
  bool get userInteracted => _userInteracted;

  void setUserInteracted() {
    if (_userInteracted) return;
    _userInteracted = true;
  }

  Timer? _timer;

  double _remainingDistance = 0;
  double get remainingDistance => _remainingDistance;

  GoogleMapController? mapController;

  @override
  void dispose() {
    sourceController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  void setLoading(bool value) {
    _state = _state.copyWith(isLoading: value);
    notifyListeners();
  }

  Future<void> startNavigation(
    String startAddress,
    String endAddress,
  ) async {
    setLoading(true);

    final start = await GeoCodingService.getLatLng(startAddress);
    final end = await GeoCodingService.getLatLng(endAddress);

    if (start == null || end == null) {
      setLoading(false);
      return;
    }

    final route = await DirectionsService.getRoutePoints(start, end);

    if (route.isEmpty) {
      setLoading(false);
      return;
    }

    final markers = await buildStartEndMarkers(
      start: start,
      end: end,
    );

    // Extract icons
    bikeIcon = markers.firstWhere((m) => m.markerId.value == 'start').icon;

    destinationIcon =
        markers.firstWhere((m) => m.markerId.value == 'dest').icon;

    _state = _state.copyWith(
      routePoints: route,
      remainingRoute: route,
      currentIndex: 0,
      isNavigating: true,
      isLoading: false,

      // ✅ ONLY ONE BIKE + DESTINATION
      markers: {
        Marker(
          markerId: const MarkerId('bike'),
          position: route.first,
          icon: bikeIcon!,
          anchor: const Offset(0.6, 0.5),
        ),
        Marker(
          markerId: const MarkerId('dest'),
          position: end,
          icon: destinationIcon!,
          anchor: const Offset(0.25, 0.5),
        ),
      },
    );

    notifyListeners();
  }

  void updatePosition(int speed) {
    if (_state.currentIndex >= _state.routePoints.length - 1) {
      // ✅ Reached destination → remove destination marker
      _state = _state.copyWith(
        markers: {
          _state.markers.firstWhere(
            (m) => m.markerId.value == 'bike',
          ),
        },
        remainingRoute: [],
        remainingDistance: 0,
        remainingTime: "Arrived",
      );
      notifyListeners();
      return;
    }

    final nextIndex = _state.currentIndex + 1;
    final currentPosition = _state.routePoints[nextIndex];

    final remaining = _state.routePoints.sublist(nextIndex);
    final distance = DistanceUtils.calculateDistance(remaining);
    final time = DistanceUtils.estimateTime(distance, speed);

    _state = _state.copyWith(
      currentIndex: nextIndex,
      remainingRoute: remaining,
      remainingDistance: distance,
      remainingTime: time,
      speed: speed,

      // ✅ MOVE SAME BIKE MARKER
      markers: {
        Marker(
          markerId: const MarkerId('bike'),
          position: currentPosition,
          icon: bikeIcon!,
          anchor: const Offset(0.6, 0.5),
        ),

        // keep destination until arrival
        if (nextIndex < _state.routePoints.length - 1)
          _state.markers.firstWhere(
            (m) => m.markerId.value == 'dest',
          ),
      },
    );
    final zoom = _zoomForDistance(distance);
    if (!_userInteracted) {
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentPosition,
            zoom: zoom,
            bearing: 0,
            tilt: 45,
          ),
        ),
      );
    }

    notifyListeners();
  }

  void startFakeMovement() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final remaining = _state.remainingRoute;

      if (remaining.isEmpty) {
        _timer?.cancel();
        return;
      }
      updatePosition(20);
    });
  }

  void fitRouteBounds() {
    if (_userInteracted) return;
    if (mapController == null || _state.routePoints.isEmpty) return;

    double minLat = _state.routePoints.first.latitude;
    double maxLat = minLat;
    double minLng = _state.routePoints.first.longitude;
    double maxLng = minLng;

    for (final p in _state.routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  double _zoomForDistance(double km) {
    if (km > 20) return 11.5;
    if (km > 10) return 12.5;
    if (km > 5) return 13.5;
    if (km > 2) return 14.5;
    if (km > 1) return 15.5;
    return 17.0; // very close
  }

  void reset() {
    _userInteracted = false;
    _state = const NavigationState();
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(26.2059, 78.1504), 12),
    );
    // Stop movement
    _timer?.cancel();
    _timer = null;

    // Reset values
    _remainingDistance = 0;

    // 🔥 Clear text fields
    sourceController.clear();
    destinationController.clear();
    notifyListeners();
  }
}
