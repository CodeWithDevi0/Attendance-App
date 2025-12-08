import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Checks permissions and service status.
  /// Returns true if everything is ready to get location.
  Future<bool> initialize() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled (GPS/Device location)
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled.
      print('Location services are disabled.');
      return false;
    }

    // 2. Check for permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // If denied, ask for permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied.');
      return false;
    }

    return true;
  }

  /// Internal helper to safely get position with a timeout
  Future<Position?> _getPosition() async {
    try {
      // We set a timeout so it doesn't hang forever if the browser is slow
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      print("Geolocator Error: $e");
      return null;
    }
  }

  // Wrappers to match your existing code structure
  Future<double?> getLatitude() async {
    final pos = await _getPosition();
    return pos?.latitude;
  }

  Future<double?> getLongitude() async {
    final pos = await _getPosition();
    return pos?.longitude;
  }
}
