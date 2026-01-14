import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Provider for the DeviceIdentityService
final deviceIdentityProvider = Provider<DeviceIdentityService>((ref) {
  return DeviceIdentityService();
});

/// Manages a persistent Device ID that survives app restarts and potentially installs (via Keychain/Keystore).
class DeviceIdentityService {
  static const String _deviceIdKey = 'com.traceme.device_id';
  final _secureStorage = const FlutterSecureStorage();
  final _uuid = const Uuid();

  String? _cachedDeviceId;

  /// Returns the persistent Device ID. Initializes one if it doesn't exist.
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    // Try reading from secure storage first (more persistent)
    String? id = await _secureStorage.read(key: _deviceIdKey);

    // Fallback to SharedPrefs if secure storage fails or is empty check (optional, mostly for older migrations but good for redundancy)
    if (id == null) {
      final prefs = await SharedPreferences.getInstance();
      id = prefs.getString(_deviceIdKey);
    }

    if (id == null) {
      // Generate new ID
      id = _uuid.v4();
      
      // Save to secure storage
      await _secureStorage.write(key: _deviceIdKey, value: id);
      
      // Save to prefs as backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_deviceIdKey, id);
    }

    _cachedDeviceId = id;
    return id;
  }

  /// Returns a friendly device name (e.g., "Android Phone" or the OS model).
  /// In a real app, this would be editable by the user.
  Future<String> getDeviceName() async {
    // Basic implementation - in production, use device_info_plus to get actual model
    if (Platform.isAndroid) return 'Android Device';
    if (Platform.isIOS) return 'iOS Device';
    return 'Unknown Device';
  }
  
  String getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}
