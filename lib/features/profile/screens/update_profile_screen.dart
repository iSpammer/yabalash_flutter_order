import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/widgets/custom_country_picker.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/animated_text_field.dart';
import '../../auth/widgets/animated_auth_button.dart';
import '../services/profile_service.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({Key? key}) : super(key: key);

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedCountryCode = AppConstants.defaultCountryCode;
  String _selectedDialCode = AppConstants.defaultDialCode;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isUpdatingProfile = false;
  bool _isChangingPassword = false;
  
  late ProfileService _profileService;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phoneNumber ?? '';
      
      // Set country code first
      _selectedCountryCode = user.countryCode ?? AppConstants.defaultCountryCode;
      
      // If dial code is available, use it; otherwise map from country code
      if (user.dialCode != null && user.dialCode!.isNotEmpty) {
        _selectedDialCode = user.dialCode!;
      } else {
        _selectedDialCode = _getDialCodeFromCountryCode(_selectedCountryCode);
      }
    }
  }

  String _getDialCodeFromCountryCode(String countryCode) {
    // Map common country codes to their dial codes
    const countryDialCodeMap = {
      'AL': '+355', // Albania
      'AE': '+971', // UAE
      'US': '+1',   // United States
      'UK': '+44',  // United Kingdom
      'IN': '+91',  // India
      'EG': '+20',  // Egypt
      'SA': '+966', // Saudi Arabia
      'KW': '+965', // Kuwait
      'QA': '+974', // Qatar
      'BH': '+973', // Bahrain
      'OM': '+968', // Oman
      'JO': '+962', // Jordan
      'LB': '+961', // Lebanon
      'SY': '+963', // Syria
      'IQ': '+964', // Iraq
      'YE': '+967', // Yemen
      'PS': '+970', // Palestine
      'IL': '+972', // Israel
      'TR': '+90',  // Turkey
      'IR': '+98',  // Iran
      'PK': '+92',  // Pakistan
      'BD': '+880', // Bangladesh
      'LK': '+94',  // Sri Lanka
      'MY': '+60',  // Malaysia
      'SG': '+65',  // Singapore
      'TH': '+66',  // Thailand
      'PH': '+63',  // Philippines
      'ID': '+62',  // Indonesia
      'VN': '+84',  // Vietnam
      'KH': '+855', // Cambodia
      'MM': '+95',  // Myanmar
      'LA': '+856', // Laos
      'CN': '+86',  // China
      'JP': '+81',  // Japan
      'KR': '+82',  // South Korea
      'TW': '+886', // Taiwan
      'HK': '+852', // Hong Kong
      'MO': '+853', // Macau
      'AU': '+61',  // Australia
      'NZ': '+64',  // New Zealand
      'FJ': '+679', // Fiji
      'CA': '+1',   // Canada
      'MX': '+52',  // Mexico
      'BR': '+55',  // Brazil
      'AR': '+54',  // Argentina
      'CL': '+56',  // Chile
      'CO': '+57',  // Colombia
      'PE': '+51',  // Peru
      'VE': '+58',  // Venezuela
      'UY': '+598', // Uruguay
      'PY': '+595', // Paraguay
      'BO': '+591', // Bolivia
      'EC': '+593', // Ecuador
      'GY': '+592', // Guyana
      'SR': '+597', // Suriname
      'GF': '+594', // French Guiana
      'FR': '+33',  // France
      'DE': '+49',  // Germany
      'IT': '+39',  // Italy
      'ES': '+34',  // Spain
      'PT': '+351', // Portugal
      'NL': '+31',  // Netherlands
      'BE': '+32',  // Belgium
      'CH': '+41',  // Switzerland
      'AT': '+43',  // Austria
      'LU': '+352', // Luxembourg
      'MC': '+377', // Monaco
      'AD': '+376', // Andorra
      'SM': '+378', // San Marino
      'VA': '+379', // Vatican City
      'MT': '+356', // Malta
      'CY': '+357', // Cyprus
      'GR': '+30',  // Greece
      'BG': '+359', // Bulgaria
      'RO': '+40',  // Romania
      'MD': '+373', // Moldova
      'UA': '+380', // Ukraine
      'BY': '+375', // Belarus
      'RU': '+7',   // Russia
      'KZ': '+7',   // Kazakhstan
      'UZ': '+998', // Uzbekistan
      'TM': '+993', // Turkmenistan
      'KG': '+996', // Kyrgyzstan
      'TJ': '+992', // Tajikistan
      'AF': '+93',  // Afghanistan
      'GE': '+995', // Georgia
      'AM': '+374', // Armenia
      'AZ': '+994', // Azerbaijan
      'FI': '+358', // Finland
      'EE': '+372', // Estonia
      'LV': '+371', // Latvia
      'LT': '+370', // Lithuania
      'PL': '+48',  // Poland
      'CZ': '+420', // Czech Republic
      'SK': '+421', // Slovakia
      'HU': '+36',  // Hungary
      'SI': '+386', // Slovenia
      'HR': '+385', // Croatia
      'BA': '+387', // Bosnia and Herzegovina
      'RS': '+381', // Serbia
      'ME': '+382', // Montenegro
      'MK': '+389', // North Macedonia
      'XK': '+383', // Kosovo
      'NO': '+47',  // Norway
      'SE': '+46',  // Sweden
      'DK': '+45',  // Denmark
      'IS': '+354', // Iceland
      'IE': '+353', // Ireland
      'ZA': '+27',  // South Africa
      'NG': '+234', // Nigeria
      'KE': '+254', // Kenya
      'TZ': '+255', // Tanzania
      'UG': '+256', // Uganda
      'RW': '+250', // Rwanda
      'BI': '+257', // Burundi
      'ET': '+251', // Ethiopia
      'SO': '+252', // Somalia
      'DJ': '+253', // Djibouti
      'ER': '+291', // Eritrea
      'SD': '+249', // Sudan
      'SS': '+211', // South Sudan
      'LY': '+218', // Libya
      'TN': '+216', // Tunisia
      'DZ': '+213', // Algeria
      'MA': '+212', // Morocco
      'EH': '+212', // Western Sahara
      'MR': '+222', // Mauritania
      'ML': '+223', // Mali
      'BF': '+226', // Burkina Faso
      'NE': '+227', // Niger
      'TD': '+235', // Chad
      'CF': '+236', // Central African Republic
      'CM': '+237', // Cameroon
      'GQ': '+240', // Equatorial Guinea
      'GA': '+241', // Gabon
      'CG': '+242', // Republic of the Congo
      'CD': '+243', // Democratic Republic of the Congo
      'AO': '+244', // Angola
      'ZM': '+260', // Zambia
      'MW': '+265', // Malawi
      'MZ': '+258', // Mozambique
      'ZW': '+263', // Zimbabwe
      'BW': '+267', // Botswana
      'NA': '+264', // Namibia
      'SZ': '+268', // Eswatini
      'LS': '+266', // Lesotho
      'MG': '+261', // Madagascar
      'MU': '+230', // Mauritius
      'RE': '+262', // Réunion
      'YT': '+262', // Mayotte
      'SC': '+248', // Seychelles
      'KM': '+269', // Comoros
    };
    
    return countryDialCodeMap[countryCode] ?? AppConstants.defaultDialCode;
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdatingProfile = true;
    });

    try {
      final success = await _profileService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        countryCode: _selectedCountryCode,
        callingCode: _selectedDialCode.replaceAll('+', ''),
      );

      if (success && mounted) {
        // Update auth provider with new data
        await context.read<AuthProvider>().refreshUser();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to update profile';
        if (e.toString().contains('Exception: ')) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        } else {
          errorMessage = e.toString();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfile = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all password fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final success = await _profileService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (success && mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to change password';
        if (e.toString().contains('Exception: ')) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        } else {
          errorMessage = e.toString();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    // Image picker functionality temporarily disabled
    // TODO: Add image_picker dependency and implement
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image picker feature coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _shareReferralCode() async {
    if (!mounted) return;
    
    final user = context.read<AuthProvider>().user;
    if (user?.referralCode != null) {
      await Share.share(
        'Join YaBalash using my referral code: ${user!.referralCode}',
        subject: 'Join YaBalash',
      );
    }
  }

  Future<void> _sendReferralCode() async {
    final referralCodeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Referral Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter email to send referral code:'),
            SizedBox(height: 16.h),
            TextField(
              controller: referralCodeController,
              decoration: const InputDecoration(
                hintText: 'friend@email.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (referralCodeController.text.isNotEmpty) {
                Navigator.pop(context);
                
                try {
                  final success = await _profileService.sendReferralCode(
                    referralCodeController.text.trim(),
                  );
                  
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Referral code sent successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    String errorMessage = 'Failed to send referral code';
                    if (e.toString().contains('Exception: ')) {
                      errorMessage = e.toString().replaceFirst('Exception: ', '');
                    } else {
                      errorMessage = e.toString();
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Update Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Image Section
                  _buildProfileImageSection(user),
                  SizedBox(height: 24.h),

                  // Basic Info Section
                  _buildBasicInfoSection(),
                  SizedBox(height: 24.h),

                  // Referral Code Section - Always show
                  _buildReferralSection(user?.referralCode),
                  SizedBox(height: 24.h),

                  // Change Password Section
                  _buildPasswordSection(),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileImageSection(dynamic user) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50.w),
                ),
                child: user?.image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(50.w),
                            child: Image.network(
                              user.image,
                              width: 100.w,
                              height: 100.w,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 50.sp,
                                  color: Theme.of(context).primaryColor,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 50.sp,
                            color: Theme.of(context).primaryColor,
                          ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(16.w),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 16.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Tap camera icon to change profile picture',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 20.h),

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
              if (value.length < 3 || value.length > 50) {
                return 'Name must be 3-50 characters';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),

          // Email field
          AnimatedTextField(
            controller: _emailController,
            hintText: 'Enter your email',
            labelText: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),
          SizedBox(height: 16.h),

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
                      _selectedCountryCode = country.code ?? 'AE';
                      _selectedDialCode = country.dialCode ?? '+971';
                    });
                  },
                  initialSelection: _selectedCountryCode,
                  favorite: const ['+971', 'AE'],
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
          SizedBox(height: 24.h),

          // Update Profile Button
          AnimatedAuthButton(
            text: 'Update Profile',
            onPressed: _updateProfile,
            isLoading: _isUpdatingProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildReferralSection(String? referralCode) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Referral Code',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        referralCode != null ? 'Your Referral Code' : 'Referral Code',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        referralCode ?? 'Not available',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: referralCode != null ? Colors.black87 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (referralCode != null)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'share') {
                        _shareReferralCode();
                      } else if (value == 'send') {
                        _sendReferralCode();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share),
                            SizedBox(width: 8),
                            Text('Share'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'send',
                        child: Row(
                          children: [
                            Icon(Icons.email),
                            SizedBox(width: 8),
                            Text('Send via Email'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change Password',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 20.h),

          // Current Password
          AnimatedTextField(
            controller: _currentPasswordController,
            hintText: 'Enter current password',
            labelText: 'Current Password',
            prefixIcon: Icons.lock_outline,
            obscureText: !_showCurrentPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _showCurrentPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _showCurrentPassword = !_showCurrentPassword;
                });
              },
            ),
          ),
          SizedBox(height: 16.h),

          // New Password
          AnimatedTextField(
            controller: _newPasswordController,
            hintText: 'Enter new password',
            labelText: 'New Password',
            prefixIcon: Icons.lock_outline,
            obscureText: !_showNewPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _showNewPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _showNewPassword = !_showNewPassword;
                });
              },
            ),
          ),
          SizedBox(height: 16.h),

          // Confirm New Password
          AnimatedTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirm new password',
            labelText: 'Confirm New Password',
            prefixIcon: Icons.lock_outline,
            obscureText: !_showConfirmPassword,
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
          SizedBox(height: 24.h),

          // Change Password Button
          AnimatedAuthButton(
            text: 'Change Password',
            onPressed: _changePassword,
            isLoading: _isChangingPassword,
            outlined: true,
          ),
        ],
      ),
    );
  }
}