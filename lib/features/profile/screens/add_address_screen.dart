import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../models/address_model.dart';
import '../providers/address_provider.dart';
import '../widgets/map_picker_widget.dart';
import '../widgets/google_map_picker.dart';

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
            name: 'label',
            initialValue: widget.existingAddress?.label,
            decoration: InputDecoration(
              labelText: 'Address Label',
              hintText: 'e.g., My Home, Office',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            validator: FormBuilderValidators.required(),
          ),
          SizedBox(height: 16.h),
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
          Row(
            children: [
              Expanded(
                child: FormBuilderTextField(
                  name: 'country',
                  initialValue: widget.existingAddress?.country ?? 'India',
                  decoration: InputDecoration(
                    labelText: 'Country',
                    hintText: 'Enter country',
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
                  name: 'pincode',
                  initialValue: widget.existingAddress?.pincode,
                  decoration: InputDecoration(
                    labelText: 'Pincode',
                    hintText: 'Enter pincode',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  validator: FormBuilderValidators.required(),
                ),
              ),
            ],
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
          GestureDetector(
            onTap: () => _showMapPickerOptions(),
            child: Container(
              height: 200.h,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _selectedLatitude != null && _selectedLongitude != null
                  ? Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 40.sp,
                                color: Theme.of(context).primaryColor,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Location Selected',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Lat: ${_selectedLatitude!.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Lng: ${_selectedLongitude!.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
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
                    )
                  : Center(
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
                widget.existingAddress != null ? 'Update Address' : 'Save Address',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
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
              leading: Icon(Icons.my_location, color: Theme.of(context).primaryColor),
              title: Text('Use Current Location'),
              subtitle: Text('Get GPS coordinates'),
              onTap: () {
                Navigator.pop(context);
                _openSimpleMapPicker();
              },
            ),
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
          onLocationSelected: (latitude, longitude, address) {
            setState(() {
              _selectedLatitude = latitude;
              _selectedLongitude = longitude;
            });
            
            // Update form fields if address is provided
            if (address.isNotEmpty) {
              _formKey.currentState?.fields['landmark']?.didChange(address);
            }
          },
        ),
      ),
    );
  }

  void _openSimpleMapPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(20.w),
        child: MapPickerWidget(
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
          onLocationSelected: (latitude, longitude, address) {
            setState(() {
              _selectedLatitude = latitude;
              _selectedLongitude = longitude;
            });
            Navigator.pop(context);
            
            // Update form fields if address is provided
            if (address != null && address.isNotEmpty) {
              _formKey.currentState?.fields['landmark']?.didChange(address);
            }
          },
        ),
      ),
    );
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
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);

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
        formData['pincode'],
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

      bool success;
      
      if (widget.existingAddress != null) {
        // Update existing address
        success = await addressProvider.updateAddress(
          addressId: widget.existingAddress!.id,
          label: formData['label'],
          fullAddress: fullAddress,
          street: formData['street'],
          city: formData['city'],
          state: formData['state'],
          country: formData['country'],
          pincode: formData['pincode'],
          latitude: widget.existingAddress?.latitude ?? 0.0,
          longitude: widget.existingAddress?.longitude ?? 0.0,
          type: _selectedAddressType,
          countryId: widget.existingAddress?.countryId ?? 99, // Default to India
          building: formData['building'],
          floor: formData['floor'],
          apartment: formData['apartment'],
          landmark: formData['landmark'],
        );
      } else {
        // Add new address
        success = await addressProvider.addAddress(
          label: formData['label'],
          fullAddress: fullAddress,
          street: formData['street'],
          city: formData['city'],
          state: formData['state'],
          country: formData['country'],
          pincode: formData['pincode'],
          latitude: _selectedLatitude ?? 0.0,
          longitude: _selectedLongitude ?? 0.0,
          type: _selectedAddressType,
          countryId: 99, // Default to India country ID
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