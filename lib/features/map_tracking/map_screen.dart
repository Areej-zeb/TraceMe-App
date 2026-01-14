import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:traceme/features/devices/data/device_repository.dart';

class MapScreen extends ConsumerStatefulWidget {
  final String deviceId;
  const MapScreen({super.key, required this.deviceId});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    final deviceStream = ref.watch(deviceRepositoryProvider).deviceStream(widget.deviceId);

    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking')),
      body: StreamBuilder(
        stream: deviceStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data();
          if (data == null) return const Center(child: Text('Device not found'));

          final lastLocation = data['lastLocation'];
          if (lastLocation == null) return const Center(child: Text('Location not available yet'));

          final lat = lastLocation['lat'] as double;
          final lng = lastLocation['lng'] as double;
          final pos = LatLng(lat, lng);
          
          final timestamp = (lastLocation['updatedAt'] as dynamic)?.toDate().toString() ?? 'Just now';

          _markers.clear();
          _markers.add(Marker(
            markerId: MarkerId(widget.deviceId),
            position: pos,
            infoWindow: InfoWindow(title: data['deviceName'], snippet: 'Last seen: $timestamp'),
          ));

          if (_mapController != null) {
            _mapController!.animateCamera(CameraUpdate.newLatLng(pos));
          }

          return GoogleMap(
            initialCameraPosition: CameraPosition(target: pos, zoom: 15),
            markers: _markers,
            onMapCreated: (controller) => _mapController = controller,
          );
        },
      ),
    );
  }
}
