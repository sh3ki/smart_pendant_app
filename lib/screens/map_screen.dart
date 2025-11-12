import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/telemetry_provider.dart';
import '../providers/location_history_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  
  @override
  Widget build(BuildContext context) {
    final telemetry = ref.watch(telemetryProvider);
    final history = ref.watch(locationHistoryProvider);

    if (telemetry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Map')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentPosition = LatLng(telemetry.lat, telemetry.lon);
    final markers = {
      Marker(
        markerId: const MarkerId('current'),
        position: currentPosition,
        infoWindow: InfoWindow(
          title: 'Current Location',
          snippet: 'Speed: ${telemetry.speed.toStringAsFixed(1)} m/s',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };

    final polylines = {
      if (history.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('path'),
          points: history.map((t) => LatLng(t.lat, t.lon)).toList(),
          color: Colors.blue,
          width: 3,
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(currentPosition, 16),
                );
              }
            },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentPosition,
          zoom: 16.5,
        ),
        markers: markers,
        polylines: polylines,
        myLocationButtonEnabled: false,
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Open external maps for navigation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Open in Google Maps (TODO: url_launcher)')),
          );
        },
        icon: const Icon(Icons.navigation),
        label: const Text('Navigate'),
      ),
    );
  }
}
