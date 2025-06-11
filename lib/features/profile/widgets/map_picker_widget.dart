import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/google_maps_service.dart';

class MapPickerWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double latitude, double longitude, String? address, {Map<String, String>? parsedAddress}) onLocationSelected;

  const MapPickerWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
  });

  @override
  State<MapPickerWidget> createState() => _MapPickerWidgetState();
}

class _MapPickerWidgetState extends State<MapPickerWidget> {
  bool _isLoading = false;
  String? _selectedAddress;
  double? _selectedLatitude;
  double? _selectedLongitude;

  @override
  void initState() {
    super.initState();
    _selectedLatitude = widget.initialLatitude;
    _selectedLongitude = widget.initialLongitude;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable them.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are denied'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permissions are permanently denied'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Get address from coordinates using Google Geocoding
      String address = 'Current Location';
      Map<String, String>? parsedAddress;
      try {
        final geocodingResponse = await GoogleMapsService.reverseGeocode(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        
        if (geocodingResponse != null && geocodingResponse.results.isNotEmpty) {
          address = geocodingResponse.results.first.formattedAddress;
          parsedAddress = _parseAddressComponents(geocodingResponse.results.first);
        }
      } catch (e) {
        // If geocoding fails, continue with default address
        debugPrint('Error getting address from coordinates: $e');
      }

      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
        _selectedAddress = address;
        _isLoading = false;
      });

      // Notify parent widget
      widget.onLocationSelected(
        position.latitude,
        position.longitude,
        _selectedAddress,
        parsedAddress: parsedAddress,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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

  void _openMapPicker() {
    // Show dialog explaining map picker will be implemented
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Picker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map,
              size: 64.sp,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 16.h),
            const Text(
              'Interactive map picker will be implemented with Google Maps integration.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'For now, you can use "Get Current Location" or enter address manually.',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          // Map placeholder
          GestureDetector(
            onTap: _openMapPicker,
            child: Container(
              height: 200.h,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  topRight: Radius.circular(8.r),
                ),
              ),
              child: Stack(
                children: [
                  // Map background
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 48.sp,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Tap to open map',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Map pin
                  if (_selectedLatitude != null && _selectedLongitude != null)
                    Center(
                      child: Icon(
                        Icons.location_pin,
                        size: 40.sp,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Location info and actions
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8.r),
                bottomRight: Radius.circular(8.r),
              ),
            ),
            child: Column(
              children: [
                if (_selectedLatitude != null && _selectedLongitude != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16.sp,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedAddress ?? 'Selected Location',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Lat: ${_selectedLatitude!.toStringAsFixed(6)}, Lng: ${_selectedLongitude!.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _getCurrentLocation,
                        icon: _isLoading
                            ? SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(_isLoading ? 'Getting...' : 'Get Current Location'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openMapPicker,
                        icon: const Icon(Icons.map),
                        label: const Text('Pick on Map'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}