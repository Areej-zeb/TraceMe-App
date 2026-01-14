import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:traceme/features/devices/data/device_repository.dart';
import 'package:traceme/services/device_identity_service.dart';

final backgroundTrackingServiceProvider = Provider<BackgroundTrackingService>((ref) {
  return BackgroundTrackingService(ref);
});

class BackgroundTrackingService {
  final Ref _ref;
  StreamSubscription<Position>? _positionStream;

  BackgroundTrackingService(this._ref);

  /// Instance method for foreground/app-open usage
  Future<void> stopTracking() async {
    debugPrint("Stopping tracking service...");
    await _positionStream?.cancel();
    _positionStream = null;
  }

  /// Instance method for foreground/app-open usage
  Future<void> startTracking({bool isForeground = false}) async {
    // If already tracking, don't start again
    if (_positionStream != null) return;
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are denied');
      return;
    }

    final LocationSettings locationSettings;
    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0, // Update even for small movements in Lost Mode
        forceLocationManager: true, // More reliable for background on some devices
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "TraceMe Lost Mode Active",
          notificationText: "Location tracking is enabled because this device is marked as Lost.",
          enableWakeLock: true,
        ),
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.other,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true, 
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        debugPrint('Location Update: ${position.latitude}, ${position.longitude}');
        _updateLocationOnServer(position);
      },
      onError: (e) {
        debugPrint("Location Stream Error: $e");
      }
    );
  }
  
  void _updateLocationOnServer(Position position) async {
    try {
      final deviceId = await _ref.read(deviceIdentityProvider).getDeviceId();
      await _ref.read(deviceRepositoryProvider).updateLocation(
        deviceId: deviceId,
        lat: position.latitude,
        lng: position.longitude,
        accuracy: position.accuracy,
      );
    } catch(e) {
      debugPrint("Failed to update location to server: $e");
    }
  }
}
