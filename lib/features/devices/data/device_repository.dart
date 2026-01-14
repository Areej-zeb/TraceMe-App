import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traceme/services/device_identity_service.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(
    FirebaseFirestore.instance,
    FirebaseFunctions.instance,
    ref.read(deviceIdentityProvider),
  );
});

class DeviceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final DeviceIdentityService _identityService;

  DeviceRepository(this._firestore, this._functions, this._identityService);



  // RE-WRITING method entirely below with correct imports via replacement.
  
  /// Registers the current device directly to Firestore (Free Tier).
  Future<void> registerDevice({required String fcmToken, required String uid}) async {
    final deviceId = await _identityService.getDeviceId();
    final deviceName = await _identityService.getDeviceName();
    final platform = _identityService.getPlatform();

    final docRef = _firestore.collection('devices').doc(deviceId);
    
    // We use set with merge to create or update
    await docRef.set({
      'ownerUid': uid,
      'deviceName': deviceName,
      'fcmToken': fcmToken,
      'platform': platform,
      'updatedAt': FieldValue.serverTimestamp(),
      // Initialize defaults if they don't exist is tricky with set-merge.
      // Firestore merge doesn't support "set if missing".
      // We'll just set status to ACTIVE if it's a new write, or we can read first.
      // For MVP Free Tier, forcing ACTIVE on registration is acceptable/safe.
    }, SetOptions(merge: true));
    
    // Check if status exists, if not set it.
    final doc = await docRef.get();
    if (doc.exists && !doc.data()!.containsKey('status')) {
       await docRef.update({'status': 'ACTIVE', 'lostMode.enabled': false});
    } else if (!doc.exists) {
       await docRef.set({'status': 'ACTIVE', 'lostMode.enabled': false}, SetOptions(merge: true));
    }
  }

  /// Triggers Lost Mode by updating Firestore directly.
  Future<void> triggerLostMode(String targetDeviceId, String uid) async {
    // 1. Update status to LOST
    await _firestore.collection('devices').doc(targetDeviceId).update({
      'status': 'LOST',
      'lostMode.enabled': true,
      'lostMode.enabledAt': FieldValue.serverTimestamp(),
      'lostMode.enabledByUid': uid
    });

    // 2. Create Command (so the target might pick it up if listening to commands collection, although status update is usually enough)
    await _firestore.collection('commands').add({
      'targetDeviceId': targetDeviceId,
      'createdByUid': uid,
      'type': 'START_LOST_MODE',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'SENT'
    });
  }

  /// Stops Lost Mode directly.
  Future<void> stopLostMode(String targetDeviceId, String uid) async {
    await _firestore.collection('devices').doc(targetDeviceId).update({
      'status': 'ACTIVE',
      'lostMode.enabled': false,
      'lostMode.disabledAt': FieldValue.serverTimestamp()
    });

    await _firestore.collection('commands').add({
      'targetDeviceId': targetDeviceId,
      'createdByUid': uid,
      'type': 'STOP_LOST_MODE',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'SENT'
    });
  }

  /// Triggers Ring directly.
  Future<void> triggerRing(String targetDeviceId, String uid) async {
    await _firestore.collection('commands').add({
      'targetDeviceId': targetDeviceId,
      'targetOwnerUid': uid, // The owner of the target device (same as current user here)
      'createdByUid': uid,
      'type': 'START_RING',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'SENT'
    });
  }

  /// Stops Ring directly.
  Future<void> stopRing(String targetDeviceId, String uid) async {
    await _firestore.collection('commands').add({
      'targetDeviceId': targetDeviceId,
      'targetOwnerUid': uid,
      'createdByUid': uid,
      'type': 'STOP_RING',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'SENT'
    });
  }
  
  /// Listens to commands targeting this specific device.
  Stream<QuerySnapshot<Map<String, dynamic>>> commandsStream(String deviceId, String uid) {
    return _firestore
        .collection('commands')
        .where('targetDeviceId', isEqualTo: deviceId)
        .where('targetOwnerUid', isEqualTo: uid) // Filter by owner to satisfy security rules
        .where('status', isEqualTo: 'SENT')
        .snapshots();
  }

  /// Listens to all devices owned by the current user.

  Stream<QuerySnapshot<Map<String, dynamic>>> userDevicesStream(String uid) {
    return _firestore
        .collection('devices')
        .where('ownerUid', isEqualTo: uid)
        .snapshots();
  }

  /// Listen to a specific device (for map tracking).
  Stream<DocumentSnapshot<Map<String, dynamic>>> deviceStream(String deviceId) {
    return _firestore.collection('devices').doc(deviceId).snapshots();
  }
  
  /// Update location (Restricted by Security Rules to only allow when Status=LOST)
  Future<void> updateLocation({
    required String deviceId, 
    required double lat, 
    required double lng,
    required double accuracy,
  }) async {
    // Note: This relies on the security rule allowing writes to 'lastLocation' 
    // IF status == LOST.
    await _firestore.collection('devices').doc(deviceId).update({
      'lastLocation': {
        'lat': lat,
        'lng': lng,
        'accuracy': accuracy,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'isOnline': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
