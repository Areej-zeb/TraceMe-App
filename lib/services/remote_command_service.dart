import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traceme/features/devices/data/device_repository.dart';
import 'package:traceme/services/device_identity_service.dart';
import 'package:traceme/services/background_tracking_service.dart';
import 'package:traceme/services/audio_service.dart';
import 'package:traceme/features/auth/data/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final remoteCommandServiceProvider = Provider<RemoteCommandService>((ref) {
  return RemoteCommandService(ref);
});

class RemoteCommandService {
  final Ref _ref;
  StreamSubscription? _commandsSub;
  StreamSubscription? _statusSub;

  RemoteCommandService(this._ref);

  void startListening() async {
    // If we're already listening, don't start again
    if (_commandsSub != null || _statusSub != null) return;

    final authState = _ref.read(authStateChangesProvider);
    final user = authState.value;
    if (user == null) {
      debugPrint('RemoteCommandService: No user logged in, skipping listeners.');
      return;
    }

    final deviceId = await _ref.read(deviceIdentityProvider).getDeviceId();
    final repo = _ref.read(deviceRepositoryProvider);

    debugPrint('RemoteCommandService: Starting listeners for device $deviceId');
    
    // 1. Listen for COMMANDS (Ring, etc.)
    _commandsSub?.cancel();
    _commandsSub = repo.commandsStream(deviceId, user.uid).listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          final commandType = data['type'];
          final status = data['status'];
          
          if (status != 'SENT') continue;
          
          debugPrint('Received Remote Command: $commandType');

          if (commandType == 'START_RING') {
             _ref.read(audioServiceProvider).playRing();
          } else if (commandType == 'STOP_RING') {
             _ref.read(audioServiceProvider).stopRing();
          } else if (commandType == 'START_LOST_MODE') {
             // In case it comes as a command instead of just status change
             _ref.read(backgroundTrackingServiceProvider).startTracking(isForeground: true);
          } else if (commandType == 'STOP_LOST_MODE') {
             _ref.read(backgroundTrackingServiceProvider).stopTracking();
          }

          // Mark command as PROCESSED so it doesn't trigger again
          change.doc.reference.update({'status': 'PROCESSED'});
        }
      }
    }, onError: (e) => debugPrint('Commands Stream Error: $e'));

    // 2. Listen for OWN DEVICE STATUS (Lost Mode)
    _statusSub?.cancel();
    _statusSub = repo.deviceStream(deviceId).listen((snapshot) {
      final data = snapshot.data();
      if (data == null) return;

      final status = data['status'];
      debugPrint('Device Status Updated: $status');

      if (status == 'LOST') {
        _ref.read(backgroundTrackingServiceProvider).startTracking(isForeground: true);
      } else {
        _ref.read(backgroundTrackingServiceProvider).stopTracking();
      }
    }, onError: (e) => debugPrint('Status Stream Error: $e'));
  }

  void stopListening() {
    _commandsSub?.cancel();
    _statusSub?.cancel();
  }
}
