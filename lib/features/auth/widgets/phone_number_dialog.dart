import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/custom_country_picker.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/app_constants.dart';

class PhoneNumberDialog extends StatefulWidget {
  final String provider;
  final Map<String, dynamic> socialData;
  
  const PhoneNumberDialog({
    super.key,
    required this.provider,
    required this.socialData,
  });

  @override
  State<PhoneNumberDialog> createState() => _PhoneNumberDialogState();
}

class _PhoneNumberDialogState extends State<PhoneNumberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  
  String _selectedCountryCode = AppConstants.defaultCountryCode;
  String _selectedDialCode = AppConstants.defaultDialCode;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _getProviderIcon() {
    switch (widget.provider) {
      case 'google':
        return 'G';
      case 'facebook':
        return 'f';
      case 'apple':
        return '';
      default:
        return '';
    }
  }

  Color _getProviderColor() {
    switch (widget.provider) {
      case 'google':
        return const Color(0xFF4285F4);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'apple':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('PhoneNumberDialog build called');
    return WillPopScope(
      onWillPop: () async {
        // Prevent dialog from being dismissed
        debugPrint('Back button pressed - preventing dismissal');
        return false;
      },
      child: Material(
        type: MaterialType.transparency,
        child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: _getProviderColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: widget.provider == 'apple'
                          ? Icon(
                              Icons.apple,
                              size: 24.sp,
                              color: _getProviderColor(),
                            )
                          : Text(
                              _getProviderIcon(),
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: _getProviderColor(),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone Number Required',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Please enter your phone number to continue',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24.h),
              
              // User info from social login
              if (widget.socialData['email'] != null) ...[
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.socialData['name'] != null) ...[
                        Text(
                          widget.socialData['name'],
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4.h),
                      ],
                      Text(
                        widget.socialData['email'],
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
              ],
              
              // Phone number input
              Row(
                children: [
                  Container(
                    width: 110.w,
                    height: 56.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12.r),
                      color: Colors.grey[50],
                    ),
                    child: CustomCountryPicker(
                      onChanged: (country) {
                        setState(() {
                          _selectedCountryCode = country.code ?? 'IN';
                          _selectedDialCode = country.dialCode ?? '+91';
                        });
                      },
                      initialSelection: _selectedCountryCode,
                      favorite: const ['+91', 'IN'],
                      showCountryOnly: false,
                      showOnlyCountryWhenClosed: false,
                      alignLeft: false,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomTextField(
                      controller: _phoneController,
                      hintText: 'Phone number',
                      labelText: 'Phone',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return Validators.validatePhone(value);
                      },
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24.h),
              
              // Action button (no cancel option)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                          });
                          
                          // Return the phone data along with social data
                          Navigator.of(context).pop({
                            ...widget.socialData,
                            'phoneNumber': _phoneController.text,
                            'dialCode': _selectedDialCode.replaceAll('+', ''),
                            'countryCode': _selectedCountryCode,
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
      ),
    );
  }
}