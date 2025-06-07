import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/services/google_maps_service.dart';

class GoogleMapPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double latitude, double longitude, String address) onLocationSelected;

  const GoogleMapPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
  });

  @override
  State<GoogleMapPicker> createState() => _GoogleMapPickerState();
}

class _GoogleMapPickerState extends State<GoogleMapPicker> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoading = false;
  Set<Marker> _markers = {};
  
  // Default to Abu Dhabi if no initial location
  static const LatLng _defaultLocation = LatLng(24.4539, 54.3773);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  void _initializeLocation() {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _updateMarker(_selectedLocation!);
    }
  }

  void _updateMarker(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: location,
          infoWindow: InfoWindow(
            title: 'Selected Location',
            snippet: _selectedAddress.isNotEmpty ? _selectedAddress : 'Tap to confirm',
          ),
        ),
      };
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      // Check location permission
      final permission = await Permission.location.request();
      
      if (permission == PermissionStatus.granted) {
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          Fluttertoast.showToast(msg: 'Please enable location services');
          setState(() => _isLoading = false);
          return;
        }

        // Get current position
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        );

        final newLocation = LatLng(position.latitude, position.longitude);
        _updateMarker(newLocation);
        
        // Move camera to new location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newLocation, 16),
        );
        
        // Get address for the location using Google Geocoding
        await _getAddressFromCoordinates(position.latitude, position.longitude);
        
      } else if (permission == PermissionStatus.permanentlyDenied) {
        Fluttertoast.showToast(msg: 'Location permission permanently denied. Please enable from settings.');
        openAppSettings();
      } else {
        Fluttertoast.showToast(msg: 'Location permission denied');
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      Fluttertoast.showToast(msg: 'Failed to get current location');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onMapTapped(LatLng location) {
    _updateMarker(location);
    _getAddressFromCoordinates(location.latitude, location.longitude);
  }

  /// Get address from coordinates using Google Geocoding API
  /// Replicates the reverse geocoding functionality from React Native app
  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final geocodingResponse = await GoogleMapsService.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );

      if (geocodingResponse != null && geocodingResponse.results.isNotEmpty) {
        _selectedAddress = geocodingResponse.results.first.formattedAddress;
      } else {
        _selectedAddress = 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
      }
      
      // Update the marker with the new address
      _updateMarker(LatLng(latitude, longitude));
    } catch (e) {
      debugPrint('Error getting address from coordinates: $e');
      _selectedAddress = 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
      _updateMarker(LatLng(latitude, longitude));
    }
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      widget.onLocationSelected(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
        _selectedAddress,
      );
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(msg: 'Please select a location');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          TextButton(
            onPressed: _confirmLocation,
            child: const Text(
              'Confirm',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? _defaultLocation,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              // Map styling is now handled via the style property
            },
            onTap: _onMapTapped,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            // Add these properties to reduce buffer issues
            compassEnabled: false,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: false,
            zoomGesturesEnabled: true,
            // Optimize rendering
            indoorViewEnabled: false,
            trafficEnabled: false,
            buildingsEnabled: false,
            // Set map type to normal to reduce rendering complexity
            mapType: MapType.normal,
          ),
          
          // Location info card
          Positioned(
            top: 16.h,
            left: 16.w,
            right: 16.w,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Location',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _selectedAddress.isNotEmpty 
                          ? _selectedAddress 
                          : 'Tap on map to select location',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Current location button
          Positioned(
            bottom: 100.h,
            right: 16.w,
            child: FloatingActionButton(
              onPressed: _isLoading ? null : _getCurrentLocation,
              mini: true,
              backgroundColor: Colors.white,
              child: _isLoading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.my_location,
                      color: Theme.of(context).primaryColor,
                    ),
            ),
          ),
          
          // Center marker
          Center(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Icon(
                Icons.location_pin,
                size: 40.sp,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _confirmLocation,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Text(
            'Confirm Location',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Properly dispose of map controller to prevent memory leaks
    _mapController?.dispose();
    _mapController = null;
    // Clear markers to free memory
    _markers.clear();
    super.dispose();
  }

  @override
  void deactivate() {
    // Pause map rendering when widget is deactivated
    super.deactivate();
  }
}