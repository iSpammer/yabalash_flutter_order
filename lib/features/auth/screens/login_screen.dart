import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/social_login_service.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedCountryCode = AppConstants.defaultCountryCode;
  String _selectedDialCode = AppConstants.defaultDialCode;
  bool _isPhoneLogin = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMeData();
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _loadRememberMeData() async {
    final authProvider = context.read<AuthProvider>();
    final savedData = await authProvider.getRememberMeCredentials();
    
    if (savedData != null && savedData['username'] != null && savedData['password'] != null) {
      setState(() {
        _usernameController.text = savedData['username'];
        _passwordController.text = savedData['password'];
        _isPhoneLogin = savedData['isPhone'] ?? false;
        _selectedDialCode = savedData['dialCode'] ?? AppConstants.defaultDialCode;
        _selectedCountryCode = savedData['countryCode'] ?? AppConstants.defaultCountryCode;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 50.h),
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.h),
                Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 50.h),
                Row(
                  children: [
                    if (_isPhoneLogin) ...[
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: CountryCodePicker(
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
                      SizedBox(width: 10.w),
                    ],
                    Expanded(
                      child: CustomTextField(
                        controller: _usernameController,
                        hintText: 'Email or Phone Number',
                        labelText: 'Email or Phone',
                        prefixIcon: _isPhoneLogin ? Icons.phone : Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: _detectInputType,
                        validator: Validators.validateEmailOrPhone,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return CustomTextField(
                      controller: _passwordController,
                      hintText: 'Enter your password',
                      labelText: 'Password',
                      prefixIcon: Icons.lock,
                      obscureText: !authProvider.isPasswordVisible,
                      validator: Validators.validatePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          authProvider.isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          authProvider.togglePasswordVisibility();
                        },
                      ),
                    );
                  },
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return Row(
                          children: [
                            Checkbox(
                              value: authProvider.rememberMe,
                              onChanged: (_) {
                                authProvider.toggleRememberMe();
                              },
                              activeColor: Theme.of(context).primaryColor,
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
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return Column(
                      children: [
                        CustomButton(
                          text: 'Sign In',
                          onPressed: _handleLogin,
                          isLoading: authProvider.isLoading,
                        ),
                        if (authProvider.errorMessage != null) ...[
                          SizedBox(height: 10.h),
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              authProvider.errorMessage!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 14.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                SizedBox(height: 30.h),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey[300]),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey[300]),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                _buildSocialLoginButtons(),
                SizedBox(height: 30.h),
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
                    TextButton(
                      onPressed: () {
                        context.push('/register');
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        final success = await authProvider.socialLogin(
          provider: provider,
          socialData: socialData,
        );
        
        if (success && mounted) {
          context.go('/home');
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Social login cancelled or failed',
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

  Widget _buildSocialLoginButtons() {
    return Column(
      children: [
        CustomButton(
          text: 'Continue with Google',
          onPressed: () => _handleSocialLogin('google'),
          outlined: true,
          icon: Icon(
            Icons.g_mobiledata,
            size: 24.sp,
          ),
        ),
        SizedBox(height: 12.h),
        CustomButton(
          text: 'Continue with Facebook',
          onPressed: () => _handleSocialLogin('facebook'),
          outlined: true,
          icon: Icon(
            Icons.facebook,
            size: 24.sp,
            color: const Color(0xFF1877F2),
          ),
        ),
        if (Theme.of(context).platform == TargetPlatform.iOS) ...[
          SizedBox(height: 12.h),
          CustomButton(
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
    );
  }
}