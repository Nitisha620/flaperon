import 'package:geolocator/geolocator.dart';

class LocationService {
  Stream<Position> get positionStream async* {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    );
  }
}
