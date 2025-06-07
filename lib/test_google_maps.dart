import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TestGoogleMapsScreen extends StatefulWidget {
  const TestGoogleMapsScreen({Key? key}) : super(key: key);

  @override
  State<TestGoogleMapsScreen> createState() => _TestGoogleMapsScreenState();
}

class _TestGoogleMapsScreenState extends State<TestGoogleMapsScreen> {
  GoogleMapController? _controller;
  
  // Abu Dhabi coordinates
  static const LatLng _center = LatLng(24.4539, 54.3773);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Test'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
                debugPrint('Map created successfully');
              },
              initialCameraPosition: const CameraPosition(
                target: _center,
                zoom: 11.0,
              ),
              mapType: MapType.normal,
              myLocationEnabled: false,
              compassEnabled: true,
              zoomControlsEnabled: true,
              onCameraMove: (position) {
                debugPrint('Camera moved to: ${position.target}');
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'If you see this text but no map above, there\'s an issue with Google Maps initialization.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}