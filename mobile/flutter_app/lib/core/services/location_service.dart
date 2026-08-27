import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService instance = LocationService._init();
  StreamSubscription<Position>? _positionSubscription;
  final ValueNotifier<Position?> currentPosition = ValueNotifier<Position?>(null);
  final ValueNotifier<bool> isTracking = ValueNotifier<bool>(false);

  LocationService._init();

  Future<bool> checkPermission() async {
    if (kIsWeb) return true;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      currentPosition.value = pos;
      return pos;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return await Geolocator.getLastKnownPosition();
    }
  }

  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  void startPositionStream(Function(Position) onPositionUpdate) {
    _positionSubscription?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      // In browsers, IP geolocation accuracy is typically 100m-200m; on mobile, GPS is < 65m
      final maxAllowedAccuracy = kIsWeb ? 500.0 : 65.0;
      if (position.accuracy > maxAllowedAccuracy) {
        debugPrint('Ignored inaccurate GPS update: accuracy ${position.accuracy}m');
        return;
      }

      currentPosition.value = position;
      onPositionUpdate(position);
    }, onError: (error) {
      debugPrint('Location stream error: $error');
    });

    isTracking.value = true;
  }

  void stopPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    isTracking.value = false;
  }
}
