import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as loc;
import 'dart:async';
import '../providers/telemetry_provider.dart';
import '../providers/location_history_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  bool _locationPermissionGranted = false;
  LatLng? _deviceLocation;  // Device's current GPS location
  loc.Location _location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;
  
  @override
  void initState() {
    super.initState();
    _startLocationTracking();  // Start location tracking FIRST (before permission, it will request internally)
    _requestLocationPermission();
  }
  
  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
  
  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (mounted) {
      setState(() {
        _locationPermissionGranted = status.isGranted;
      });
    }
  }
  
  // Get real device location using location package
  void _startLocationTracking() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        print('❌ Location service not enabled');
        return;
      }
    }
    
    // Get initial location
    try {
      final locationData = await _location.getLocation();
      print('📍 Device location: ${locationData.latitude}, ${locationData.longitude}');
      if (mounted) {
        setState(() {
          _deviceLocation = LatLng(locationData.latitude!, locationData.longitude!);
        });
        
        // ✅ Center map on device location immediately when location is acquired
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_deviceLocation!, 16.5),
          );
        }
      }
    } catch (e) {
      print('❌ Failed to get device location: $e');
    }
    
    // Listen to location updates
    _locationSubscription = _location.onLocationChanged.listen((locationData) {
      print('📍 Location update: ${locationData.latitude}, ${locationData.longitude}');
      if (mounted && locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          _deviceLocation = LatLng(locationData.latitude!, locationData.longitude!);
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final telemetry = ref.watch(telemetryProvider);
    final history = ref.watch(locationHistoryProvider);

    // Show loading until we have device location
    if (telemetry == null || _deviceLocation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Map')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Getting the location...'),
            ],
          ),
        ),
      );
    }

    // Check if Arduino is using fallback coordinates (14.074322, 121.326667)
    final isArduinoFallback = (telemetry.lat - 14.074322).abs() < 0.001 && 
                               (telemetry.lon - 121.326667).abs() < 0.001;
    
    // Arduino/pendant position
    final pendantPosition = LatLng(telemetry.lat, telemetry.lon);
    
    // Debug: Log marker decision
    print('🗺️ Map: Arduino fallback: $isArduinoFallback | Device location: ${_deviceLocation != null ? "${_deviceLocation!.latitude}, ${_deviceLocation!.longitude}" : "null"}');
    
    final markers = {
      // Always show blue marker at device location (when available)
      if (_deviceLocation != null)
        Marker(
          markerId: const MarkerId('device'),
          position: _deviceLocation!,
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: 'Mobile device GPS',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      
      // Show pendant marker ONLY if NOT at fallback location (real Arduino GPS)
      if (!isArduinoFallback)
        Marker(
          markerId: const MarkerId('pendant'),
          position: pendantPosition,
          infoWindow: InfoWindow(
            title: 'Pendant Location',
            snippet: 'Speed: ${telemetry.speed.toStringAsFixed(1)} m/s',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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
            tooltip: 'Center on your location',
            onPressed: () {
              if (_mapController != null && _deviceLocation != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(_deviceLocation!, 16.5),
                );
              }
            },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _deviceLocation!,  // Use device location (we wait for it now)
          zoom: 16.5,
        ),
        markers: markers,
        polylines: polylines,
        myLocationEnabled: false,  // Don't show blue dot - we have blue marker instead
        myLocationButtonEnabled: false,  // Don't show default button - we have custom button in AppBar
        onMapCreated: (controller) async {
          _mapController = controller;
          
          // Center on device location when map is ready (if location already acquired)
          if (_deviceLocation != null) {
            await Future.delayed(const Duration(milliseconds: 100));  // Small delay for map to initialize
            controller.animateCamera(
              CameraUpdate.newLatLngZoom(_deviceLocation!, 16.5),
            );
          }
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
