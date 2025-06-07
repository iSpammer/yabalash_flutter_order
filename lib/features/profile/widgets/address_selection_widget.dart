import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../models/address_model.dart';
import '../screens/add_address_screen.dart';
import '../providers/address_provider.dart';

class AddressSelectionWidget extends StatefulWidget {
  const AddressSelectionWidget({Key? key}) : super(key: key);

  @override
  State<AddressSelectionWidget> createState() => _AddressSelectionWidgetState();
}

class _AddressSelectionWidgetState extends State<AddressSelectionWidget> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);
      if (addressProvider.addresses.isEmpty) {
        addressProvider.fetchAddresses();
      }
      addressProvider.addCurrentLocationOption();
    });
  }

  void _selectAddress(AddressModel? address, bool useCurrent) {
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    
    if (useCurrent || address == null) {
      addressProvider.selectAddress(AddressModel.currentLocation());
    } else {
      addressProvider.selectAddress(address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddressProvider>(
      builder: (context, addressProvider, child) {
        if (addressProvider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (addressProvider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Error: ${addressProvider.error}',
                    style: TextStyle(color: Colors.red, fontSize: 14.sp),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  ElevatedButton(
                    onPressed: () => addressProvider.fetchAddresses(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final currentLocation = AddressModel.currentLocation();
        final isCurrentLocationSelected = addressProvider.selectedAddress?.id == 'current_location';
        
        return Column(
          children: [
            // Current Location Option
            _buildAddressOption(
              icon: Icons.my_location,
              title: 'Use Current Location',
              subtitle: 'Auto-detect your location',
              isSelected: isCurrentLocationSelected,
              onTap: () => _selectAddress(null, true),
            ),
            
            // Saved Addresses
            ...addressProvider.savedAddresses.map((address) => _buildAddressOption(
              icon: _getAddressIcon(address.type),
              title: address.label,
              subtitle: address.fullAddress,
              isSelected: !isCurrentLocationSelected && addressProvider.selectedAddress?.id == address.id,
              onTap: () => _selectAddress(address, false),
              onEdit: () => _editAddress(address),
              onDelete: () => _deleteAddress(address),
            )).toList(),
            
            // Add New Address Button
            _buildAddNewAddressButton(),
          ],
        );
      },
    );
  }

  Widget _buildAddressOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Selection Radio
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12.sp,
                    )
                  : null,
            ),
            SizedBox(width: 12.w),
            
            // Address Icon
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            
            // Address Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Action Buttons for saved addresses
            if (onEdit != null || onDelete != null) ...[
              SizedBox(width: 8.w),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit' && onEdit != null) {
                    onEdit();
                  } else if (value == 'delete' && onDelete != null) {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
                child: Icon(
                  Icons.more_vert,
                  color: Colors.grey[600],
                  size: 20.sp,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewAddressButton() {
    return InkWell(
      onTap: _addNewAddress,
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            SizedBox(width: 32.w), // Space for radio button
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                ),
              ),
              child: Icon(
                Icons.add,
                color: Colors.grey[600],
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Add New Address',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAddressIcon(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'hotel':
        return Icons.hotel;
      default:
        return Icons.location_on;
    }
  }

  void _addNewAddress() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddAddressScreen(),
      ),
    ).then((_) {
      if (mounted) {
        final addressProvider = Provider.of<AddressProvider>(context, listen: false);
        addressProvider.fetchAddresses();
      }
    });
  }

  void _editAddress(AddressModel address) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddAddressScreen(existingAddress: address),
      ),
    ).then((_) {
      if (mounted) {
        final addressProvider = Provider.of<AddressProvider>(context, listen: false);
        addressProvider.fetchAddresses();
      }
    });
  }

  Future<void> _deleteAddress(AddressModel address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete "${address.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);
      final success = await addressProvider.deleteAddress(address.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(addressProvider.error ?? 'Failed to delete address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}