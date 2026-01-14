import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/devices/device_list_screen.dart';
import '../features/map_tracking/map_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Watch auth state to trigger router rebuilds on login/logout
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/devices',
        builder: (context, state) => const DeviceListScreen(),
      ),
      GoRoute(
        path: '/map/:deviceId',
        builder: (context, state) {
           final id = state.pathParameters['deviceId']!;
           return MapScreen(deviceId: id);
        },
      ),
    ],
    redirect: (context, state) {
      // Use the watched authState
      final user = authState.value;
      final loggingIn = state.uri.toString() == '/login';
      
      if (user == null && !loggingIn) return '/login';
      if (user != null && loggingIn) return '/devices';
      
      return null;
    },
  );
});
