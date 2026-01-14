import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traceme/app/app_router.dart';
import 'package:traceme/app/firebase_init.dart';
import 'package:traceme/app/app_theme.dart';
import 'package:traceme/services/audio_service.dart';
import 'package:traceme/features/auth/data/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traceme/services/remote_command_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await initFirebase(useEmulators: false);

  runApp(
    const ProviderScope(
      child: TraceMeApp(),
    ),
  );
}

class TraceMeApp extends ConsumerWidget {
  const TraceMeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    // Start listening for remote commands (Ring, Lost Mode)
    // We use ref.listen to start it once when the provider is ready
    ref.listen(remoteCommandServiceProvider, (prev, next) {
      next.startListening();
    });
    
    // Trigger initialization if not already done
    ref.read(remoteCommandServiceProvider).startListening();

    return MaterialApp.router(
      title: 'TraceMe',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
