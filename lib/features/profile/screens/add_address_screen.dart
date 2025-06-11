import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/address_model.dart';
import '../providers/address_provider.dart';
import '../widgets/google_map_picker.dart';
import '../../../core/services/google_maps_service.dart';
import '../../../core/constants/map_styles.dart';

class AddAddressScreen extends StatefulWidget {
  final AddressModel? existingAddress;

  const AddAddressScreen({super.key, this.existingAddress});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  String _selectedAddressType = 'other';
  bool _isLoading = false;
  double? _selectedLatitude;
  double? _selectedLongitude;

  @override
  void initState() {
    super.initState();
    if (widget.existingAddress != null) {
      _selectedAddressType = widget.existingAddress!.type;
      _selectedLatitude = widget.existingAddress!.latitude;
      _selectedLongitude = widget.existingAddress!.longitude;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingAddress != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Address' : 'Add New Address',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black87,
            size: 24.sp,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAddressTypeSelector(),
                SizedBox(height: 24.h),
                _buildFormFields(),
                SizedBox(height: 32.h),
                _buildMapSection(),
                SizedBox(height: 32.h),
                _buildSaveButton(),
                SizedBox(height: 80.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressTypeSelector() {
    final types = [
      {'value': 'home', 'label': 'Home', 'icon': Icons.home},
      {'value': 'work', 'label': 'Work', 'icon': Icons.work},
      {'value': 'hotel', 'label': 'Hotel', 'icon': Icons.hotel},
      {'value': 'other', 'label': 'Other', 'icon': Icons.location_on},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Address Type',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: types.map((type) {
            final isSelected = _selectedAddressType == type['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAddressType = type['value'] as String;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: type != types.last ? 8.w : 0,
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        type['icon'] as IconData,
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: 20.sp,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        type['label'] as String,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          FormBuilderTextField(
            name: 'street',
            initialValue: widget.existingAddress?.street,
            decoration: InputDecoration(
              labelText: 'Street Address',
              hintText: 'Enter street name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            validator: FormBuilderValidators.required(),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: FormBuilderTextField(
                  name: 'building',
                  initialValue: widget.existingAddress?.building,
                  decoration: InputDecoration(
                    labelText: 'Building',
                    hintText: 'Building name/no',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: FormBuilderTextField(
                  name: 'floor',
                  initialValue: widget.existingAddress?.floor,
                  decoration: InputDecoration(
                    labelText: 'Floor',
                    hintText: 'Floor no',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          FormBuilderTextField(
            name: 'apartment',
            initialValue: widget.existingAddress?.apartment,
            decoration: InputDecoration(
              labelText: 'Apartment/Unit',
              hintText: 'Apartment or unit number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          FormBuilderTextField(
            name: 'landmark',
            initialValue: widget.existingAddress?.landmark,
            decoration: InputDecoration(
              labelText: 'Landmark (Optional)',
              hintText: 'Nearby landmark',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: FormBuilderTextField(
                  name: 'city',
                  initialValue: widget.existingAddress?.city,
                  decoration: InputDecoration(
                    labelText: 'City',
                    hintText: 'Enter city',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  validator: FormBuilderValidators.required(),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: FormBuilderTextField(
                  name: 'state',
                  initialValue: widget.existingAddress?.state,
                  decoration: InputDecoration(
                    labelText: 'State',
                    hintText: 'Enter state',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  validator: FormBuilderValidators.required(),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          FormBuilderDropdown<String>(
            name: 'country',
            initialValue:
                widget.existingAddress?.country ?? 'United Arab Emirates',
            decoration: InputDecoration(
              labelText: 'Country',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            validator: FormBuilderValidators.required(),
            items: _getCountryDropdownItems(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pin Location on Map',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          // Mini map preview container
          GestureDetector(
            onTap: () => _showMapPickerOptions(),
            child: Container(
              height: 200.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _selectedLatitude != null && _selectedLongitude != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Stack(
                        children: [
                          // Mini Google Map
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                  _selectedLatitude!, _selectedLongitude!),
                              zoom: 15,
                            ),
                            style: MapStyles.getMapStyle(
                                governmentCompliant: true),
                            markers: {
                              Marker(
                                markerId: const MarkerId('selected'),
                                position: LatLng(
                                    _selectedLatitude!, _selectedLongitude!),
                                infoWindow: const InfoWindow(
                                    title: 'Selected Location'),
                              ),
                            },
                            zoomGesturesEnabled: false,
                            scrollGesturesEnabled: false,
                            rotateGesturesEnabled: false,
                            tiltGesturesEnabled: false,
                            mapToolbarEnabled: false,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            compassEnabled: false,
                          ),
                          // Overlay to show it's tappable
                          Positioned.fill(
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                          // Edit button
                          Positioned(
                            top: 8.h,
                            right: 8.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'Tap to change',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_location_alt,
                              size: 40.sp,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Tap to select location',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          // Location action buttons
          if (_selectedLatitude == null || _selectedLongitude == null) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _getCurrentLocationDirectly,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use Current Location'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveAddress,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                widget.existingAddress != null
                    ? 'Update Address'
                    : 'Save Address',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _getCurrentLocationDirectly() async {
    setState(() => _isLoading = true);

    try {
      // Check location permission
      final permission = await Permission.location.request();

      if (permission == PermissionStatus.granted) {
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enable location services'),
                backgroundColor: Colors.red,
              ),
            );
          }
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

        setState(() {
          _selectedLatitude = position.latitude;
          _selectedLongitude = position.longitude;
        });

        // Get address for the location using Google Geocoding
        try {
          final geocodingResponse = await GoogleMapsService.reverseGeocode(
            latitude: position.latitude,
            longitude: position.longitude,
          );

          if (geocodingResponse != null &&
              geocodingResponse.results.isNotEmpty) {
            final parsedAddress =
                _parseAddressComponents(geocodingResponse.results.first);
            _populateAddressFields(parsedAddress);
          }
        } catch (e) {
          debugPrint('Error getting address from coordinates: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (permission == PermissionStatus.permanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Location permission permanently denied. Please enable from settings.'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get current location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
        if (!parsed.containsKey('area')) {
          // Only set if not already set
          parsed['area'] = component.longName;
        }
      }

      // Landmark (point of interest)
      if (types.contains('point_of_interest') ||
          types.contains('establishment')) {
        if (!parsed.containsKey('landmark')) {
          // Only set if not already set
          parsed['landmark'] = component.longName;
        }
      }

      // City (multiple possible types)
      if (types.contains('locality') ||
          types.contains('administrative_area_level_2') ||
          types.contains('administrative_area_level_3')) {
        if (!parsed.containsKey('city')) {
          // Prefer locality over admin areas
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
        } else if (city.contains('umm al quwain') ||
            city.contains('umm al-quwain')) {
          parsed['state'] = 'Umm Al Quwain';
        } else if (city.contains('ras al khaimah') ||
            city.contains('ras al-khaimah')) {
          parsed['state'] = 'Ras Al Khaimah';
        } else if (city.contains('fujairah')) {
          parsed['state'] = 'Fujairah';
        }
      }
    }

    return parsed;
  }

  void _showMapPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Location Method',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20.h),
            ListTile(
              leading: Icon(Icons.map, color: Theme.of(context).primaryColor),
              title: Text('Use Google Maps'),
              subtitle: Text('Pick location on interactive map'),
              onTap: () {
                Navigator.pop(context);
                _openGoogleMapPicker();
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.my_location,
                  color: Theme.of(context).primaryColor),
              title: Text('Use Current Location'),
              subtitle: Text('Get GPS coordinates immediately'),
              onTap: () {
                Navigator.pop(context);
                _getCurrentLocationDirectly();
              },
            ),
            SizedBox(height: 80.h),
          ],
        ),
      ),
    );
  }

  void _openGoogleMapPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleMapPicker(
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
          onLocationSelected: (latitude, longitude, address, {parsedAddress}) {
            setState(() {
              _selectedLatitude = latitude;
              _selectedLongitude = longitude;
            });

            // Auto-fill form fields with parsed address components
            if (parsedAddress != null) {
              _populateAddressFields(parsedAddress);
            }

            // Update landmark field with full address if no parsed address
            if (parsedAddress == null && address.isNotEmpty) {
              _formKey.currentState?.fields['landmark']?.didChange(address);
            }
          },
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getCountryDropdownItems() {
    final countries = [
      // Arab countries
      'Algeria', 'Bahrain', 'Comoros', 'Djibouti', 'Egypt', 'Iraq', 'Jordan',
      'Kuwait', 'Lebanon', 'Libya', 'Mauritania', 'Morocco', 'Oman',
      'Palestine',
      'Qatar', 'Saudi Arabia', 'Somalia', 'Sudan', 'Syria', 'Tunisia',
      'United Arab Emirates', 'Yemen',

      // Muslim-majority countries
      'Afghanistan', 'Albania', 'Azerbaijan', 'Bangladesh', 'Brunei',
      'Burkina Faso',
      'Chad', 'Gambia', 'Guinea', 'Indonesia', 'Iran', 'Kazakhstan',
      'Kyrgyzstan', 'Kosovo',
      'Malaysia', 'Maldives', 'Mali', 'Niger', 'Pakistan', 'Senegal',
      'Sierra Leone',
      'Turkmenistan', 'Turkey', 'Uzbekistan'
    ];

    return countries
        .map((country) => DropdownMenuItem<String>(
              value: country,
              child: Text(country),
            ))
        .toList();
  }

  void _populateAddressFields(Map<String, String> parsedAddress) {
    // Auto-fill street field
    if (parsedAddress.containsKey('street')) {
      _formKey.currentState?.fields['street']
          ?.didChange(parsedAddress['street']);
    }

    // Auto-fill building field
    if (parsedAddress.containsKey('building')) {
      _formKey.currentState?.fields['building']
          ?.didChange(parsedAddress['building']);
    }

    // Auto-fill floor field
    if (parsedAddress.containsKey('floor')) {
      _formKey.currentState?.fields['floor']?.didChange(parsedAddress['floor']);
    }

    // Auto-fill apartment field
    if (parsedAddress.containsKey('apartment')) {
      _formKey.currentState?.fields['apartment']
          ?.didChange(parsedAddress['apartment']);
    }

    // Auto-fill landmark field (prefer landmark over area)
    if (parsedAddress.containsKey('landmark')) {
      _formKey.currentState?.fields['landmark']
          ?.didChange(parsedAddress['landmark']);
    } else if (parsedAddress.containsKey('area')) {
      _formKey.currentState?.fields['landmark']
          ?.didChange(parsedAddress['area']);
    }

    // Auto-fill city
    if (parsedAddress.containsKey('city')) {
      _formKey.currentState?.fields['city']?.didChange(parsedAddress['city']);
    }

    // Auto-fill state
    if (parsedAddress.containsKey('state')) {
      _formKey.currentState?.fields['state']?.didChange(parsedAddress['state']);
    }

    // Auto-fill country
    if (parsedAddress.containsKey('country')) {
      _formKey.currentState?.fields['country']
          ?.didChange(parsedAddress['country']);
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.saveAndValidate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final formData = _formKey.currentState!.value;
      final addressProvider =
          Provider.of<AddressProvider>(context, listen: false);

      // Create full address string
      final fullAddress = [
        formData['street'],
        formData['building'],
        formData['floor'],
        formData['apartment'],
        formData['landmark'],
        formData['city'],
        formData['state'],
        formData['country'],
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

      bool success;

      if (widget.existingAddress != null) {
        // Update existing address
        success = await addressProvider.updateAddress(
          addressId: widget.existingAddress!.id,
          label: _selectedAddressType,
          fullAddress: fullAddress,
          street: formData['street'],
          city: formData['city'],
          state: formData['state'],
          country: formData['country'],
          pincode: '', // No longer using pincode
          latitude: widget.existingAddress?.latitude ?? 0.0,
          longitude: widget.existingAddress?.longitude ?? 0.0,
          type: _selectedAddressType,
          countryId: widget.existingAddress?.countryId ?? 1, // Default to UAE
          building: formData['building'],
          floor: formData['floor'],
          apartment: formData['apartment'],
          landmark: formData['landmark'],
        );
      } else {
        // Add new address
        success = await addressProvider.addAddress(
          label: _selectedAddressType,
          fullAddress: fullAddress,
          street: formData['street'],
          city: formData['city'],
          state: formData['state'],
          country: formData['country'],
          pincode: '', // No longer using pincode
          latitude: _selectedLatitude ?? 0.0,
          longitude: _selectedLongitude ?? 0.0,
          type: _selectedAddressType,
          countryId: 1, // Default to UAE country ID
          building: formData['building'],
          floor: formData['floor'],
          apartment: formData['apartment'],
          landmark: formData['landmark'],
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.existingAddress != null
                    ? 'Address updated successfully'
                    : 'Address saved successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(addressProvider.error ?? 'Failed to save address'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
