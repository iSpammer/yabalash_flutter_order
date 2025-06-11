import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_auth_background.dart';
import '../../../core/widgets/animated_logo.dart';

class VerifyAccountScreen extends StatefulWidget {
  final String? phoneNumber;
  final String? email;
  final String? authToken;
  
  const VerifyAccountScreen({
    super.key,
    this.phoneNumber,
    this.email,
    this.authToken,
  });

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen>
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  StreamController<ErrorAnimationType>? _errorController;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _resendTimer = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _errorController = StreamController<ErrorAnimationType>();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    
    // Automatically send OTP when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendInitialOtp();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _errorController?.close();
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 30; // 30 seconds as per React Native
      _canResend = false;
    });
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }
  
  Future<void> _sendInitialOtp() async {
    // Determine verification type based on what's being verified
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    String verificationType = 'phone'; // Default to phone
    if (user != null) {
      if (user.needsEmailVerification && !user.needsPhoneVerification) {
        verificationType = 'email';
      }
    }
    
    // Send OTP with auth token
    final success = await authProvider.sendVerificationToken(
      type: verificationType,
      authToken: widget.authToken,
    );
    
    if (success) {
      _startResendTimer();
    }
  }

  Future<void> _handleVerification() async {
    if (_otpController.text.length != 6) {
      _errorController!.add(ErrorAnimationType.shake);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    // Determine verification type
    String verificationType = 'phone'; // Default to phone
    if (user != null) {
      if (user.needsEmailVerification && !user.needsPhoneVerification) {
        verificationType = 'email';
      }
    }
    
    final success = await authProvider.verifyAccount(
      otp: _otpController.text,
      type: verificationType,
    );

    if (success && mounted) {
      context.go('/home');
    } else if (!success && mounted) {
      _errorController!.add(ErrorAnimationType.shake);
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    String verificationType = 'phone'; // Default to phone
    if (user != null) {
      if (user.needsEmailVerification && !user.needsPhoneVerification) {
        verificationType = 'email';
      }
    }
    
    final success = await authProvider.sendVerificationToken(
      type: verificationType,
      authToken: widget.authToken,
    );

    if (success && mounted) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _getFormattedContact() {
    if (widget.phoneNumber != null) {
      // Mask phone number: +971 50 XXX XX67
      final phone = widget.phoneNumber!;
      if (phone.length > 4) {
        final lastTwo = phone.substring(phone.length - 2);
        return '${phone.substring(0, 6)} XXX XX$lastTwo';
      }
      return phone;
    } else if (widget.email != null) {
      // Mask email: jo****@example.com
      final email = widget.email!;
      final parts = email.split('@');
      if (parts.length == 2 && parts[0].length > 2) {
        final name = parts[0];
        final masked = '${name.substring(0, 2)}****';
        return '$masked@${parts[1]}';
      }
      return email;
    }
    return 'your registered contact';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedAuthBackground(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => context.pop(),
            ),
          ),
          body: FadeTransition(
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
                      SizedBox(height: 40.h),
                      
                      // Logo
                      const AnimatedYabalashLogo(
                        width: 80,
                        height: 80,
                        showAnimation: true,
                      ),
                      
                      SizedBox(height: 32.h),
                      
                      // Title
                      Text(
                        'Verify Your Account',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Description
                      Text(
                        'Enter the 6-digit code sent to ${_getFormattedContact()}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 40.h),
                      
                      // OTP Input
                      PinCodeTextField(
                        appContext: context,
                        length: 6,
                        controller: _otpController,
                        obscureText: false,
                        animationType: AnimationType.fade,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(12.r),
                          fieldHeight: 56.h,
                          fieldWidth: 48.w,
                          activeFillColor: Colors.white,
                          selectedFillColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          inactiveFillColor: Colors.grey[100]!,
                          activeColor: Theme.of(context).primaryColor,
                          selectedColor: Theme.of(context).primaryColor,
                          inactiveColor: Colors.grey[300]!,
                        ),
                        animationDuration: const Duration(milliseconds: 300),
                        backgroundColor: Colors.transparent,
                        enableActiveFill: true,
                        errorAnimationController: _errorController,
                        onCompleted: (v) {
                          _handleVerification();
                        },
                        onChanged: (value) {},
                        beforeTextPaste: (text) {
                          return true;
                        },
                      ),
                      
                      SizedBox(height: 32.h),
                      
                      // Verify button
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          return Column(
                            children: [
                              CustomButton(
                                text: 'Verify Account',
                                onPressed: _handleVerification,
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
                      
                      SizedBox(height: 32.h),
                      
                      // Resend code
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Didn\'t receive the code? ',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (_canResend)
                            InkWell(
                              onTap: _handleResendOtp,
                              child: Text(
                                'Resend',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Text(
                              'Resend in ${_resendTimer}s',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      
                      SizedBox(height: 40.h),
                      
                      // Change number/email
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(
                          'Change phone number or email',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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