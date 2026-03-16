import 'dart:async';
import 'dart:math';
import 'package:flaperon/features/navigation/data/helpers/marker_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/services/location_service.dart';
import '../domain/models/navigation_state.dart';
import '../data/services/directions_service.dart';
import '../data/services/geocoding_service.dart';
import '../../../core/utils/distance_utils.dart';

final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>(
        (ref) => NavigationNotifier());

class NavigationNotifier extends StateNotifier<NavigationState> {
  BitmapDescriptor? bikeIcon;
  BitmapDescriptor? destinationIcon;
  final TextEditingController sourceController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  bool _userInteracted = false;
  bool get userInteracted => _userInteracted;
  final LocationService _locationService = LocationService();
  StreamSubscription<Position>? _positionSub;
  LatLng? _destinationLatLng;
  LatLng? _lastSnappedLatLng;
  final List<double> _speedBuffer = [];
  static const int _speedWindow = 5;

  void setUserInteracted() {
    if (_userInteracted) return;
    _userInteracted = true;
  }

  Timer? _timer;

  GoogleMapController? mapController;

  NavigationNotifier() : super(const NavigationState());
  @override
  void dispose() {
    sourceController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  void setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void _startLocationTracking() {
    _positionSub?.cancel();

    _positionSub = _locationService.positionStream.listen((position) {
      final speedMps = position.speed; // meters/sec
      if (speedMps > 0) {
        _speedBuffer.add(speedMps * 3.6); // km/h
        if (_speedBuffer.length > _speedWindow) {
          _speedBuffer.removeAt(0);
        }
      }
      final avgSpeed = _speedBuffer.isEmpty
          ? state.speed
          : _speedBuffer.reduce((a, b) => a + b) / _speedBuffer.length;

      final rawLatLng = LatLng(position.latitude, position.longitude);
      final index = DistanceUtils.findNearestIndex(
        rawLatLng,
        state.routePoints,
      );

      if (index == -1) {
        // User is off route
        state = state.copyWith(
          remainingTime: "Recalculating...",
        );

        _reRouteFrom(rawLatLng);
        return;
      }

      final snappedLatLng = state.routePoints[index];

      double? bearing;

      if (_lastSnappedLatLng != null) {
        bearing = _bearingBetween(_lastSnappedLatLng!, snappedLatLng);
      }

      _lastSnappedLatLng = snappedLatLng;

      final remainingRoute = state.routePoints.sublist(index);
      final remainingDistance = DistanceUtils.calculateDistance(remainingRoute);

      if (remainingDistance <= 0.03) {
        state = state.copyWith(
          isNavigating: false,
          remainingRoute: const [],
          remainingDistance: 0,
          remainingTime: "Arrived",
          markers: {
            Marker(
              markerId: const MarkerId('bike'),
              position: snappedLatLng,
              icon: bikeIcon!,
              anchor: const Offset(0.6, 0.5),
            ),
          },
        );

        _positionSub?.cancel();
        _positionSub = null;
        return;
      }

      final remainingTime = DistanceUtils.estimateTime(
        remainingDistance,
        avgSpeed.round(),
      );

      // TEMP: just move marker, no logic yet
      state = state.copyWith(
        currentIndex: index,
        remainingRoute: remainingRoute,
        remainingDistance: remainingDistance,
        remainingTime: remainingTime,
        speed: avgSpeed.round(),
        markers: {
          Marker(
            markerId: const MarkerId('bike'),
            position: snappedLatLng,
            icon: bikeIcon!,
            anchor: const Offset(0.6, 0.5),
          ),
          if (state.markers.any((m) => m.markerId.value == 'dest'))
            state.markers.firstWhere((m) => m.markerId.value == 'dest'),
        },
      );

      if (!_userInteracted && bearing != null && mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: snappedLatLng,
              zoom: 17,
              tilt: 45,
              bearing: bearing,
            ),
          ),
        );
      }
    });
  }

  Future<void> startNavigation(
    String startAddress,
    String endAddress,
  ) async {
    setLoading(true);

    final start = await GeoCodingService.getLatLng(startAddress);
    final end = await GeoCodingService.getLatLng(endAddress);
    _destinationLatLng = end;

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

    state = state.copyWith(
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
    _startLocationTracking();
  }

  Future<void> _reRouteFrom(LatLng currentPosition) async {
    if (_destinationLatLng == null) return;

    final newRoute = await DirectionsService.getRoutePoints(
      currentPosition,
      _destinationLatLng!,
    );

    if (newRoute.isEmpty) return;

    state = state.copyWith(
      routePoints: newRoute,
      remainingRoute: newRoute,
      currentIndex: 0,
      remainingTime: "--",
      remainingDistance: DistanceUtils.calculateDistance(newRoute),
      markers: {
        Marker(
          markerId: const MarkerId('bike'),
          position: currentPosition,
          icon: bikeIcon!,
          anchor: const Offset(0.6, 0.5),
        ),
        Marker(
          markerId: const MarkerId('dest'),
          position: _destinationLatLng!,
          icon: destinationIcon!,
          anchor: const Offset(0.25, 0.5),
        ),
      },
    );
  }

  void updatePosition(int speed) {
    if (state.currentIndex >= state.routePoints.length - 1) {
      // ✅ Reached destination → remove destination marker
      state = state.copyWith(
        markers: {
          state.markers.firstWhere(
            (m) => m.markerId.value == 'bike',
          ),
        },
        remainingRoute: [],
        remainingDistance: 0,
        remainingTime: "Arrived",
      );
      return;
    }

    final nextIndex = state.currentIndex + 1;
    final currentPosition = state.routePoints[nextIndex];

    final remaining = state.routePoints.sublist(nextIndex);
    final distance = DistanceUtils.calculateDistance(remaining);
    final time = DistanceUtils.estimateTime(distance, speed);

    state = state.copyWith(
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
        if (nextIndex < state.routePoints.length - 1)
          state.markers.firstWhere(
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
  }

  /* void startFakeMovement() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final remaining = state.remainingRoute;

      if (remaining.isEmpty) {
        _timer?.cancel();
        return;
      }
      updatePosition(20);
    });
  } */

  void fitRouteBounds() {
    if (_userInteracted) return;
    if (mapController == null || state.routePoints.isEmpty) return;

    double minLat = state.routePoints.first.latitude;
    double maxLat = minLat;
    double minLng = state.routePoints.first.longitude;
    double maxLng = minLng;

    for (final p in state.routePoints) {
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
    state = const NavigationState();
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(26.2059, 78.1504), 12),
    );
    // Stop movement
    _timer?.cancel();
    _timer = null;

    _positionSub?.cancel();
    _positionSub = null;
  }

  double _bearingBetween(LatLng from, LatLng to) {
    final lat1 = from.latitude * pi / 180;
    final lon1 = from.longitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final lon2 = to.longitude * pi / 180;

    final dLon = lon2 - lon1;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final bearing = atan2(y, x);
    return (bearing * 180 / pi + 360) % 360;
  }
}
