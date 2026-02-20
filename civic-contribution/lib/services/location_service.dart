import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 30), // Increased timeout
        ),
      );
      
      // Validate the position coordinates
      if (position.latitude >= -90 && position.latitude <= 90 &&
          position.longitude >= -180 && position.longitude <= 180 &&
          !(position.latitude == 0 && position.longitude == 0)) {
        print('Location obtained: ${position.latitude}, ${position.longitude}');
        return position;
      }
      print('Invalid coordinates: ${position.latitude}, ${position.longitude}');
      return null;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters
      ),
    );
  }
}
