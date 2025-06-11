import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/widgets/custom_country_picker.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/social_login_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_auth_background.dart';
import '../widgets/animated_text_field.dart';
import '../widgets/animated_auth_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedCountryCode = AppConstants.defaultCountryCode;
  String _selectedDialCode = AppConstants.defaultDialCode;
  bool _isPhoneLogin = false;
  bool _showPassword = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadRememberMeData();

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
    _usernameController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberMeData() async {
    final authProvider = context.read<AuthProvider>();
    final savedData = await authProvider.getRememberMeCredentials();

    if (savedData != null &&
        savedData['username'] != null &&
        savedData['password'] != null) {
      setState(() {
        _usernameController.text = savedData['username'];
        _passwordController.text = savedData['password'];
        _isPhoneLogin = savedData['isPhone'] ?? false;
        _selectedDialCode =
            savedData['dialCode'] ?? AppConstants.defaultDialCode;
        _selectedCountryCode =
            savedData['countryCode'] ?? AppConstants.defaultCountryCode;
      });
    }
  }

  void _detectInputType(String value) {
    setState(() {
      _isPhoneLogin = Validators.isPhone(value);
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    bool success;

    if (_isPhoneLogin) {
      success = await authProvider.loginWithUsername(
        username: _usernameController.text,
        password: _passwordController.text,
        dialCode: _selectedDialCode.replaceAll('+', ''),
        countryCode: _selectedCountryCode,
      );
    } else {
      success = await authProvider.loginWithEmail(
        email: _usernameController.text,
        password: _passwordController.text,
      );
    }

    if (success && mounted) {
      context.go('/home');
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    try {
      Map<String, dynamic>? socialData;

      switch (provider) {
        case 'google':
          socialData = await SocialLoginService().signInWithGoogle();
          break;
        case 'facebook':
          socialData = await SocialLoginService().signInWithFacebook();
          break;
        case 'apple':
          socialData = await SocialLoginService().signInWithApple();
          break;
      }

      if (socialData != null && mounted) {
        final authProvider = context.read<AuthProvider>();

        // First attempt social login without phone number
        final success = await authProvider.socialLogin(
          provider: provider,
          socialData: socialData,
        );

        if (success && mounted) {
          // Debug logging
          debugPrint('Social login success');
          debugPrint('User phone: ${authProvider.user?.phoneNumber}');
          debugPrint(
              'Phone required flag: ${authProvider.user?.phoneNumberRequired}');

          // Check if phone number is required (either by flag or if phone is empty)
          final phoneIsEmpty = authProvider.user?.phoneNumber == null ||
              authProvider.user!.phoneNumber!.isEmpty;

          debugPrint('Phone is empty: $phoneIsEmpty');

          // Let the router redirect handle navigation based on phone number requirement
          if (authProvider.user?.phoneNumberRequired == true || phoneIsEmpty) {
            debugPrint('Phone number required - router will redirect to social phone screen');
          } else {
            debugPrint('Phone number not required - navigating to home');
            context.go('/home');
          }
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Social login cancelled',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (error) {
      Fluttertoast.showToast(
        msg: 'Social login error: $error',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedAuthBackground(
            child: SafeArea(
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
                    SizedBox(height: 60.h),

                    // Logo and Title with animation
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
                                Hero(
                                  tag: 'app_logo',
                                  child: Container(
                                    width: 100.w,
                                    height: 100.w,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.r),
                                        color: Colors.white,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12.r),
                                        child: Image.asset(
                                          'assets/icon/app_icon.png',
                                          width: 84.w,
                                          height: 84.w,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 84.w,
                                              height: 84.w,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).primaryColor,
                                                borderRadius: BorderRadius.circular(12.r),
                                              ),
                                              child: Icon(
                                                Icons.restaurant_menu,
                                                size: 42.sp,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 24.h),
                                Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontSize: 32.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Sign in to continue',
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

                    SizedBox(height: 50.h),

                    // Email/Phone field
                    Row(
                      children: [
                        if (_isPhoneLogin) ...[
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
                        ],
                        Expanded(
                          child: AnimatedTextField(
                            controller: _usernameController,
                            hintText: _isPhoneLogin
                                ? 'Phone number'
                                : 'Email or Phone',
                            labelText: _isPhoneLogin ? 'Phone' : 'Email/Phone',
                            prefixIcon: _isPhoneLogin
                                ? Icons.phone
                                : Icons.person_outline,
                            keyboardType: _isPhoneLogin
                                ? TextInputType.phone
                                : TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your ${_isPhoneLogin ? 'phone number' : 'email or phone'}';
                              }
                              if (_isPhoneLogin) {
                                return Validators.validatePhone(value);
                              }
                              return null;
                            },
                            onTap: () {
                              _detectInputType(_usernameController.text);
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    // Password field
                    AnimatedTextField(
                      controller: _passwordController,
                      hintText: 'Enter your password',
                      labelText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: !_showPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
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

                    // Remember me & Forgot password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, _) {
                            return Row(
                              children: [
                                Transform.scale(
                                  scale: 1.2,
                                  child: Checkbox(
                                    value: authProvider.rememberMe,
                                    onChanged: (value) {
                                      authProvider
                                          .setRememberMe(value ?? false);
                                    },
                                    activeColor: Theme.of(context).primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                  ),
                                ),
                                Text(
                                  'Remember me',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        TextButton(
                          onPressed: () {
                            context.push('/forgot-password');
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 30.h),

                    // Sign In button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return Column(
                          children: [
                            AnimatedAuthButton(
                              text: 'Sign In',
                              onPressed: _handleLogin,
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

                    SizedBox(height: 40.h),

                    // OR divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 30.h),

                    // Social login buttons
                    Column(
                      children: [
                        AnimatedAuthButton(
                          text: 'Continue with Google',
                          onPressed: () => _handleSocialLogin('google'),
                          outlined: true,
                          icon: Image.asset(
                            'assets/icons/google.png',
                            width: 24.w,
                            height: 24.w,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.g_mobiledata,
                                size: 24.sp,
                                color: Theme.of(context).primaryColor,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 12.h),
                        AnimatedAuthButton(
                          text: 'Continue with Facebook',
                          onPressed: () => _handleSocialLogin('facebook'),
                          outlined: true,
                          backgroundColor: const Color(0xFF1877F2),
                          textColor: const Color(0xFF1877F2),
                          icon: Icon(
                            Icons.facebook,
                            size: 24.sp,
                            color: const Color(0xFF1877F2),
                          ),
                        ),
                        if (Platform.isIOS) ...[
                          SizedBox(height: 12.h),
                          AnimatedAuthButton(
                            text: 'Continue with Apple',
                            onPressed: () => _handleSocialLogin('apple'),
                            backgroundColor: Colors.black,
                            icon: Icon(
                              Icons.apple,
                              size: 24.sp,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: 40.h),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[700],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            context.push('/register');
                          },
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 30.h),

                    // Removed duplicate social login section - already have social buttons above

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Removed duplicate social login methods - using _handleSocialLogin instead
}
