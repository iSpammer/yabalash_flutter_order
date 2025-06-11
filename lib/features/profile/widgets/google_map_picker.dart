import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/services/google_maps_service.dart';
import '../../../core/constants/map_styles.dart';
import '../../../core/services/regional_maps_service.dart';

class GoogleMapPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double latitude, double longitude, String address, {Map<String, String>? parsedAddress}) onLocationSelected;

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
  GoogleGeocodingResponse? _geocodingResponse;
  
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
      // Get address for initial location
      _getAddressFromCoordinates(widget.initialLatitude!, widget.initialLongitude!);
    }
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
        setState(() {
          _selectedLocation = newLocation;
        });
        
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

  void _onCameraMove(CameraPosition position) {
    // Update selected location when camera moves
    _selectedLocation = position.target;
    // We don't update the address immediately to avoid too many API calls
  }

  void _onCameraIdle() {
    // Only update address when camera movement stops
    if (_selectedLocation != null) {
      _getAddressFromCoordinates(_selectedLocation!.latitude, _selectedLocation!.longitude);
    }
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
        
        // Store the geocoding response to pass back when confirming
        _geocodingResponse = geocodingResponse;
      } else {
        _selectedAddress = 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
        _geocodingResponse = null;
      }
      
      // Update UI with new address
      setState(() {
        _selectedLocation = LatLng(latitude, longitude);
      });
    } catch (e) {
      debugPrint('Error getting address from coordinates: $e');
      _selectedAddress = 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
      _geocodingResponse = null;
      setState(() {
        _selectedLocation = LatLng(latitude, longitude);
      });
    }
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      // Parse address components if we have geocoding response
      Map<String, String>? parsedAddress;
      if (_geocodingResponse != null && _geocodingResponse!.results.isNotEmpty) {
        parsedAddress = _parseAddressComponents(_geocodingResponse!.results.first);
      }
      
      widget.onLocationSelected(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
        _selectedAddress,
        parsedAddress: parsedAddress,
      );
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(msg: 'Please select a location');
    }
  }
  
  Map<String, String> _parseAddressComponents(GoogleGeocodingResult result) {
    final parsed = <String, String>{};
    
    for (final component in result.addressComponents) {
      final types = component.types;
      
      // Street number
      if (types.contains('street_number')) {
        parsed['street_number'] = component.longName;
      }
      
      // Street name/route
      if (types.contains('route')) {
        parsed['route'] = component.longName;
      }
      
      // Building/premise
      if (types.contains('premise') || types.contains('establishment')) {
        parsed['building'] = component.longName;
      }
      
      // Subpremise (apartment/unit)
      if (types.contains('subpremise')) {
        parsed['apartment'] = component.longName;
      }
      
      // Floor level
      if (types.contains('floor')) {
        parsed['floor'] = component.longName;
      }
      
      // Neighborhood/Area (multiple levels for better coverage)
      if (types.contains('neighborhood') || 
          types.contains('sublocality_level_1') || 
          types.contains('sublocality_level_2') ||
          types.contains('sublocality') ||
          types.contains('political')) {
        if (!parsed.containsKey('area')) { // Only set if not already set
          parsed['area'] = component.longName;
        }
      }
      
      // Landmark (point of interest)
      if (types.contains('point_of_interest') || types.contains('establishment')) {
        if (!parsed.containsKey('landmark')) { // Only set if not already set
          parsed['landmark'] = component.longName;
        }
      }
      
      // City (multiple possible types)
      if (types.contains('locality') || 
          types.contains('administrative_area_level_2') ||
          types.contains('administrative_area_level_3')) {
        if (!parsed.containsKey('city')) { // Prefer locality over admin areas
          parsed['city'] = component.longName;
        }
      }
      
      // State/Emirate
      if (types.contains('administrative_area_level_1')) {
        parsed['state'] = component.longName;
      }
      
      // Country
      if (types.contains('country')) {
        parsed['country'] = component.longName;
      }
      
      // Postal code (though not used in UAE)
      if (types.contains('postal_code')) {
        parsed['postal_code'] = component.longName;
      }
    }
    
    // Build comprehensive street address from components
    final streetParts = <String>[];
    
    if (parsed.containsKey('street_number')) {
      streetParts.add(parsed['street_number']!);
    }
    
    if (parsed.containsKey('route')) {
      streetParts.add(parsed['route']!);
    }
    
    // If no street components found, try to use area or landmark
    if (streetParts.isEmpty) {
      if (parsed.containsKey('area')) {
        streetParts.add(parsed['area']!);
      } else if (parsed.containsKey('landmark')) {
        streetParts.add(parsed['landmark']!);
      }
    }
    
    if (streetParts.isNotEmpty) {
      parsed['street'] = streetParts.join(' ');
    }
    
    // Fallback for missing city - use area if city is not found
    if (!parsed.containsKey('city') && parsed.containsKey('area')) {
      parsed['city'] = parsed['area']!;
    }
    
    // Fallback for missing state - common UAE emirates
    if (!parsed.containsKey('state') && parsed.containsKey('country')) {
      if (parsed['country']!.toLowerCase().contains('united arab emirates') || 
          parsed['country']!.toLowerCase().contains('uae')) {
        // Try to infer emirate from city
        final city = parsed['city']?.toLowerCase() ?? '';
        if (city.contains('dubai')) {
          parsed['state'] = 'Dubai';
        } else if (city.contains('abu dhabi')) {
          parsed['state'] = 'Abu Dhabi';
        } else if (city.contains('sharjah')) {
          parsed['state'] = 'Sharjah';
        } else if (city.contains('ajman')) {
          parsed['state'] = 'Ajman';
        } else if (city.contains('umm al quwain') || city.contains('umm al-quwain')) {
          parsed['state'] = 'Umm Al Quwain';
        } else if (city.contains('ras al khaimah') || city.contains('ras al-khaimah')) {
          parsed['state'] = 'Ras Al Khaimah';
        } else if (city.contains('fujairah')) {
          parsed['state'] = 'Fujairah';
        }
      }
    }
    
    return parsed;
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
            style: MapStyles.getMapStyle(governmentCompliant: true),
            onMapCreated: (controller) {
              _mapController = controller;
              // Log regional safety information
              RegionalMapsService.logMapSafetyInfo();
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            markers: const {}, // Remove markers since we use center pin
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
                          : 'Move map to select location',
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
          
          // Center pin marker
          Center(
            child: Transform.translate(
              offset: const Offset(0, -20), // Offset to center the pin tip
              child: Icon(
                Icons.location_pin,
                size: 40.sp,
                color: Theme.of(context).primaryColor,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(1, 1),
                    blurRadius: 3,
                  ),
                ],
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
    super.dispose();
  }

  @override
  void deactivate() {
    // Pause map rendering when widget is deactivated
    super.deactivate();
  }
}