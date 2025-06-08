import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_country_picker.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_auth_background.dart';
import '../widgets/animated_text_field.dart';
import '../widgets/animated_auth_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();

  String _selectedCountryCode = AppConstants.defaultCountryCode;
  String _selectedDialCode = AppConstants.defaultDialCode;
  bool _acceptTerms = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the terms and conditions'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          margin: EdgeInsets.all(20.w),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      dialCode: _selectedDialCode.replaceAll('+', ''),
      password: _passwordController.text,
      countryCode: _selectedCountryCode,
      referralCode: _referralCodeController.text.trim(),
    );

    if (success && mounted) {
      // Navigate to verification screen if needed
      context.go('/verify-account');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedAuthBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.black87,
                size: 24.sp,
              ),
            ),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 20.h),
                      
                      // Title with animation
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1200),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Opacity(
                              opacity: value,
                              child: Column(
                                children: [
                                  Container(
                                    width: 80.w,
                                    height: 80.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).primaryColor,
                                          Theme.of(context).primaryColor.withValues(alpha: 0.7),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                          blurRadius: 30,
                                          offset: const Offset(0, 15),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.person_add,
                                      size: 40.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 24.h),
                                  Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 32.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Sign up to get started',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.grey[600],
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 40.h),
                      
                      // Name field
                      AnimatedTextField(
                        controller: _nameController,
                        hintText: 'Enter your full name',
                        labelText: 'Full Name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          if (value.length < 3) {
                            return 'Name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // Email field
                      AnimatedTextField(
                        controller: _emailController,
                        hintText: 'Enter your email',
                        labelText: 'Email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // Phone field
                      Row(
                        children: [
                          Container(
                            width: 120.w,
                            height: 64.h,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(16.r),
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
                            child: AnimatedTextField(
                              controller: _phoneController,
                              hintText: 'Phone number',
                              labelText: 'Phone',
                              prefixIcon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              validator: Validators.validatePhone,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // Password field
                      AnimatedTextField(
                        controller: _passwordController,
                        hintText: 'Create a strong password',
                        labelText: 'Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: !_showPassword,
                        validator: Validators.validatePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // Confirm Password field
                      AnimatedTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm your password',
                        labelText: 'Confirm Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: !_showConfirmPassword,
                        validator: (value) => Validators.validateConfirmPassword(
                          value,
                          _passwordController.text,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                        ),
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // Referral code field
                      AnimatedTextField(
                        controller: _referralCodeController,
                        hintText: 'Enter referral code (optional)',
                        labelText: 'Referral Code',
                        prefixIcon: Icons.card_giftcard,
                        textCapitalization: TextCapitalization.characters,
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // Terms and conditions
                      InkWell(
                        onTap: () {
                          setState(() {
                            _acceptTerms = !_acceptTerms;
                          });
                        },
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: _acceptTerms
                                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: _acceptTerms
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300]!,
                              width: _acceptTerms ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24.w,
                                height: 24.w,
                                decoration: BoxDecoration(
                                  color: _acceptTerms
                                      ? Theme.of(context).primaryColor
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: Border.all(
                                    color: _acceptTerms
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                ),
                                child: _acceptTerms
                                    ? Icon(
                                        Icons.check,
                                        size: 16.sp,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey[700],
                                    ),
                                    children: [
                                      const TextSpan(text: 'I agree to the '),
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            // TODO: Navigate to terms
                                          },
                                      ),
                                      const TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            // TODO: Navigate to privacy
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 30.h),
                      
                      // Sign Up button
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          return Column(
                            children: [
                              AnimatedAuthButton(
                                text: 'Sign Up',
                                onPressed: _handleRegister,
                                isLoading: authProvider.isLoading,
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
                      
                      SizedBox(height: 30.h),
                      
                      // Sign in link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[700],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              context.pop();
                            },
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}