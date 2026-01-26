import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationState {
  final List<LatLng> routePoints;
  final List<LatLng> remainingRoute;
  final Set<Marker> markers;
  final bool isNavigating;
  final bool isLoading;
  final double remainingDistance;
  final String remainingTime;
  final int speed;
  final int currentIndex;

  const NavigationState({
    this.routePoints = const [],
    this.remainingRoute = const [],
    this.markers = const {},
    this.isNavigating = false,
    this.isLoading = false,
    this.remainingDistance = 0,
    this.remainingTime = '--',
    this.speed = 0,
    this.currentIndex = 0,
  });

  NavigationState copyWith({
    List<LatLng>? routePoints,
    List<LatLng>? remainingRoute,
    Set<Marker>? markers,
    bool? isNavigating,
    bool? isLoading,
    double? remainingDistance,
    String? remainingTime,
    int? speed,
    int? currentIndex,
  }) {
    return NavigationState(
      routePoints: routePoints ?? this.routePoints,
      remainingRoute: remainingRoute ?? this.remainingRoute,
      markers: markers ?? this.markers,
      isNavigating: isNavigating ?? this.isNavigating,
      isLoading: isLoading ?? this.isLoading,
      remainingDistance: remainingDistance ?? this.remainingDistance,
      remainingTime: remainingTime ?? this.remainingTime,
      speed: speed ?? this.speed,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}
