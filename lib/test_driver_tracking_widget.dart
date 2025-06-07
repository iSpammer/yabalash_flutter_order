import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'features/orders/services/dispatch_tracking_service.dart';

class TestDriverTrackingWidget extends StatefulWidget {
  const TestDriverTrackingWidget({Key? key}) : super(key: key);

  @override
  State<TestDriverTrackingWidget> createState() => _TestDriverTrackingWidgetState();
}

class _TestDriverTrackingWidgetState extends State<TestDriverTrackingWidget> {
  final DispatchTrackingService _dispatchService = DispatchTrackingService();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _driverPosition;
  bool _isLoading = false;
  String _statusText = 'Ready to test';

  // Test with known working URL
  final String _testTrackingUrl = 'https://dispatch.yabalash.com/order/tracking/976d51/nS7ueT';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Tracking Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDriverLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: $_statusText'),
                if (_driverPosition != null)
                  Text('Driver: ${_driverPosition!.latitude}, ${_driverPosition!.longitude}'),
                const SizedBox(height: 8),
                Text('Test URL: $_testTrackingUrl', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          // Map
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    // Fetch driver location immediately
                    _fetchDriverLocation();
                  },
                  markers: _markers,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(24.4539, 54.3773), // Abu Dhabi
                    zoom: 12,
                  ),
                ),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          // Test button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _fetchDriverLocation,
              child: const Text('Fetch Driver Location'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchDriverLocation() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Fetching driver location...';
    });

    try {
      final dispatchData = await _dispatchService.getDriverLocation(_testTrackingUrl);
      
      if (dispatchData != null && dispatchData['agent_location'] != null) {
        final agentLocation = dispatchData['agent_location'] as Map<String, dynamic>;
        final lat = double.tryParse(agentLocation['lat']?.toString() ?? '');
        final lng = double.tryParse(agentLocation['long']?.toString() ?? '');
        
        if (lat != null && lng != null) {
          setState(() {
            _driverPosition = LatLng(lat, lng);
            _statusText = '✅ Driver found! Last update: ${agentLocation['updated_at']}';
            
            // Update markers
            _markers = {
              Marker(
                markerId: const MarkerId('driver'),
                position: _driverPosition!,
                infoWindow: InfoWindow(
                  title: 'Driver',
                  snippet: 'Battery: ${agentLocation['battery_level']}%',
                ),
              ),
            };
          });
          
          // Move camera to driver
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_driverPosition!, 15),
          );
        } else {
          setState(() {
            _statusText = '❌ Failed to parse coordinates';
          });
        }
      } else {
        setState(() {
          _statusText = '❌ No driver location in response';
        });
      }
    } catch (e) {
      setState(() {
        _statusText = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}