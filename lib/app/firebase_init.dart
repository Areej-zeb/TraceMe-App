import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> initFirebase({bool useEmulators = false}) async {
  // We use explicit options for Android to avoid issues with the native plugin 
  // failing to load resource files (values.xml) on some devices.
  const androidOptions = FirebaseOptions(
    apiKey: 'PASTE_YOUR_API_KEY_HERE',
    appId: '1:580517817508:android:c5de307675aab320854a31',
    messagingSenderId: '580517817508',
    projectId: 'traceme-a33f6',
    storageBucket: 'traceme-a33f6.firebasestorage.app',
  );

  if (defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp(options: androidOptions);
  } else {
    // For other platforms (iOS/Web), fallback to native discovery 
    // or placeholder if you add them later.
    await Firebase.initializeApp();
  }

  if (useEmulators) {
    debugPrint('Connecting to Firebase Emulators...');
    try {
      await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
      FirebaseFunctions.instance.useFunctionsEmulator('10.0.2.2', 5001);
    } catch (e) {
      debugPrint('Error connecting to emulators: $e');
    }
  }
}
