import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/widgets/custom_country_picker.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../../../core/widgets/animated_logo.dart';

class SocialPhoneScreen extends StatefulWidget {
  final String provider;
  final Map<String, dynamic> socialData;
  
  const SocialPhoneScreen({
    super.key,
    required this.provider,
    required this.socialData,
  });

  @override
  State<SocialPhoneScreen> createState() => _SocialPhoneScreenState();
}

class _SocialPhoneScreenState extends State<SocialPhoneScreen> {
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

  Future<void> _handlePhoneSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    
    // Update phone number using the profile update endpoint
    final phoneSuccess = await authProvider.updateProfileWithPhone(
      phoneNumber: _phoneController.text,
      dialCode: _selectedDialCode.replaceAll('+', ''),
      countryCode: _selectedCountryCode,
    );
    
    if (phoneSuccess && mounted) {
      // Check if phone verification is required
      if (authProvider.user?.needsPhoneVerification == true) {
        context.go('/verify-account');
      } else {
        context.go('/home');
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: authProvider.errorMessage ?? 'Failed to update phone number',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 40.h),
                  
                  // Logo
                  const Center(
                    child: AnimatedYabalashLogo(
                      width: 80,
                      height: 80,
                      showAnimation: true,
                    ),
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Title
                  Text(
                    'One More Step',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  Text(
                    'Please add your phone number to complete registration',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 40.h),
                  
                  // User info card
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
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
                              if (widget.socialData['name'] != null)
                                Text(
                                  widget.socialData['name'],
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              if (widget.socialData['email'] != null)
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
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 40.h),
                  
                  // Phone number input
                  Text(
                    'Phone Number',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  Row(
                    children: [
                      Container(
                        width: 120.w,
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
                  
                  SizedBox(height: 40.h),
                  
                  // Continue button
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      return Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 56.h,
                            child: ElevatedButton(
                              onPressed: (_isLoading || authProvider.isLoading) 
                                  ? null 
                                  : _handlePhoneSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                elevation: 0,
                              ),
                              child: (_isLoading || authProvider.isLoading)
                                  ? SizedBox(
                                      width: 24.w,
                                      height: 24.h,
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
                          
                          if (authProvider.errorMessage != null) ...[
                            SizedBox(height: 16.h),
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red[700],
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      authProvider.errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Info text
                  Text(
                    'We need your phone number for order updates and delivery coordination',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}