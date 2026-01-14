import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:traceme/features/auth/data/auth_repository.dart';
import 'package:traceme/features/devices/data/device_repository.dart';

class DeviceListScreen extends ConsumerStatefulWidget {
  const DeviceListScreen({super.key});

  @override
  ConsumerState<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends ConsumerState<DeviceListScreen> {
  
  // In a real app, you'd trigger this via FCM setup + checks
  @override
  void initState() {
    super.initState();
    // Register device after frame to access provider safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
       final user = ref.read(authRepositoryProvider).currentUser;
       if (user != null) {
         ref.read(deviceRepositoryProvider).registerDevice(
           fcmToken: "TODO_GET_REAL_TOKEN",
           uid: user.uid,
         ); 
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());

    final devicesStream = ref.watch(deviceRepositoryProvider).userDevicesStream(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: devicesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = (snapshot.data as QuerySnapshot<Map<String, dynamic>>).docs;
          if (docs.isEmpty) return const Center(child: Text('No devices found'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final device = docs[index].data();
              final deviceId = docs[index].id;
              final isLost = device['status'] == 'LOST';
              final lastLoc = device['lastLocation'];

              return Card(
                color: isLost ? Colors.red.shade50 : null,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    isLost ? Icons.warning_amber_rounded : Icons.phone_android,
                    color: isLost ? Colors.red : Colors.green,
                  ),
                  title: Text(device['deviceName'] ?? 'Unknown'),
                  subtitle: Text(isLost 
                    ? 'LOST MODE ACTIVE' 
                    : 'Last seen: ${lastLoc != null ? "Recently" : "Unknown"}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLost)
                        IconButton(
                          icon: const Icon(Icons.map),
                          onPressed: () => context.push('/map/$deviceId'),
                        ),
                      IconButton(
                        icon: const Icon(Icons.notifications_active),
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            builder: (ctx) => SimpleDialog(
                              title: const Text('Remote Ring'),
                              children: [
                                SimpleDialogOption(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    ref.read(deviceRepositoryProvider).triggerRing(deviceId, user.uid);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Ring command sent')),
                                    );
                                  },
                                  child: const Text('Start Ringing'),
                                ),
                                SimpleDialogOption(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    ref.read(deviceRepositoryProvider).stopRing(deviceId, user.uid);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Stop Ring command sent')),
                                    );
                                  },
                                  child: const Text('Stop Ringing'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Switch(
                        value: isLost,
                        activeColor: Colors.red,
                        onChanged: (val) async {
                          if (val) {
                            await ref.read(deviceRepositoryProvider).triggerLostMode(deviceId, user.uid);
                          } else {
                            await ref.read(deviceRepositoryProvider).stopLostMode(deviceId, user.uid);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
