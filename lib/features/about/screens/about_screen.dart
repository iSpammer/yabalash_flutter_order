import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // App Logo and Info
          _buildAppHeader(context),
          SizedBox(height: 24.h),

          // Company Information
          _buildCompanyInfo(context),
          SizedBox(height: 20.h),

          // Legal Documents
          _buildLegalSection(context),
          SizedBox(height: 20.h),

          // Social Links
          _buildSocialSection(context),
          SizedBox(height: 20.h),

          // Technical Information
          _buildTechnicalInfo(context),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // App Logo
          Hero(
            tag: 'app_logo',
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                    width: 64.w,
                    height: 64.w,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 64.w,
                        height: 64.w,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 32.sp,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // App Name
          Text(
            'YaBalash',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 6.h),

          // App Tagline
          Text(
            'Delicious food, delivered fast',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),

          // Version
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInfo(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.business,
                  color: Colors.blue,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Company Information',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'YaBalash is the premier food delivery platform connecting you with the best restaurants in your area. We\'re committed to providing fast, reliable, and delicious food delivery services across the UAE.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoItem('Founded', '2024'),
          _buildInfoItem('Headquarters', 'Dubai, UAE'),
          _buildInfoItem('Service Areas', 'Dubai, Abu Dhabi, Sharjah'),
          // _buildInfoItem('Partner Restaurants', '500+'),
          // _buildInfoItem('Active Users', '10,000+'),
        ],
      ),
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.gavel,
                  color: Colors.orange,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Legal & Policies',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildLegalItem(
            'Terms of Service',
            'Our terms and conditions for using YaBalash',
            Icons.description,
            () => _showLegalDocument(
                context, 'Terms of Service', _getTermsOfService()),
          ),
          _buildLegalItem(
            'Privacy Policy',
            'How we collect, use, and protect your data',
            Icons.privacy_tip,
            () => _showLegalDocument(
                context, 'Privacy Policy', _getPrivacyPolicy()),
          ),
          _buildLegalItem(
            'Cookie Policy',
            'Information about our cookie usage',
            Icons.cookie,
            () => _showLegalDocument(
                context, 'Cookie Policy', _getCookiePolicy()),
          ),
          _buildLegalItem(
            'Delivery Terms',
            'Terms and conditions for delivery services',
            Icons.local_shipping,
            () => _showLegalDocument(
                context, 'Delivery Terms', _getDeliveryTerms()),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.share,
                  color: Colors.purple,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Connect With Us',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSocialButton(
                'Facebook',
                Icons.facebook,
                Colors.blue[700]!,
                () => _launchSocial('https://facebook.com'),
              ),
              _buildSocialButton(
                'Instagram',
                Icons.camera_alt,
                Colors.pink[400]!,
                () => _launchSocial(
                    'https://www.instagram.com/yabalash.ae?igsh=enRyYXVkN3EyMjh6'),
              ),
              _buildSocialButton(
                'Twitter',
                Icons.flutter_dash,
                Colors.blue[400]!,
                () => _launchSocial('https://twitter.com'),
              ),
              _buildSocialButton(
                'LinkedIn',
                Icons.work,
                Colors.blue[800]!,
                () => _launchSocial('https://linkedin.com/company/yabalash'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalInfo(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.code,
                  color: Colors.green,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Technical Information',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          _buildInfoItem('App Version', '1.0.0 (Build 100)'),
          _buildInfoItem('Platform', 'Flutter 3.24.0'),
          _buildInfoItem('Min OS Version', 'iOS 12.0 / Android 6.0'),
          _buildInfoItem('Last Updated', 'June 2025'),
          _buildInfoItem('Supported Languages', 'English, Arabic'),

          SizedBox(height: 16.h),

          // Contact for Technical Issues
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.bug_report, color: Colors.orange, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Found a Bug?',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Report technical issues to info@yabalash.com',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalItem(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600], size: 20.sp),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13.sp,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSocialButton(
      String name, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            name,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  void _showLegalDocument(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchSocial(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getTermsOfService() {
    return '''
TERMS OF SERVICE

Last updated: December 2024

1. ACCEPTANCE OF TERMS
By accessing and using the YaBalash mobile application, you accept and agree to be bound by the terms and provision of this agreement.

2. DESCRIPTION OF SERVICE
YaBalash is a food delivery platform that connects users with local restaurants. We facilitate the ordering and delivery of food from participating restaurants.

3. USER ACCOUNTS
You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.

4. ORDERING AND PAYMENT
- All orders are subject to availability
- Prices are set by individual restaurants
- Payment processing is handled securely through our payment partners
- Delivery fees and taxes will be clearly displayed before order confirmation

5. DELIVERY
- Delivery times are estimates and may vary based on various factors
- We are not responsible for delays caused by weather, traffic, or other circumstances beyond our control
- You must be available to receive your order at the specified delivery address

6. CANCELLATION AND REFUNDS
- Orders can be cancelled within a limited time window after placement
- Refunds will be processed according to our refund policy
- We reserve the right to cancel orders in case of unavailability or other issues

7. PROHIBITED USES
You may not use our service:
- For any unlawful purpose or to solicit unlawful activity
- To violate any international, federal, provincial, or state regulations, rules, laws, or local ordinances
- To infringe upon or violate our intellectual property rights or the intellectual property rights of others

8. LIMITATION OF LIABILITY
YaBalash shall not be liable for any direct, indirect, incidental, special, consequential, or punitive damages resulting from your use of our service.

9. CHANGES TO TERMS
We reserve the right to modify these terms at any time. Changes will be effective immediately upon posting to the application.

10. CONTACT INFORMATION
If you have any questions about these Terms of Service, please contact us at legal@yabalash.com.
''';
  }

  String _getPrivacyPolicy() {
    return '''
PRIVACY POLICY

Last updated: December 2024

1. INFORMATION WE COLLECT
We collect information you provide directly to us, such as when you create an account, place an order, or contact us for support.

Types of information we collect:
- Personal Information: Name, email address, phone number, delivery address
- Payment Information: Payment method details (processed securely by our payment partners)
- Order Information: Order history, preferences, and delivery details
- Device Information: Device type, operating system, app version
- Location Information: GPS location for delivery purposes (with your permission)

2. HOW WE USE YOUR INFORMATION
We use the information we collect to:
- Process and fulfill your orders
- Provide customer support
- Send you order updates and notifications
- Improve our services and user experience
- Prevent fraud and ensure security

3. INFORMATION SHARING
We do not sell, trade, or otherwise transfer your personal information to third parties except:
- With restaurants to fulfill your orders
- With delivery partners to complete deliveries
- With payment processors to handle transactions
- When required by law or to protect our rights

4. DATA SECURITY
We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.

5. YOUR RIGHTS
You have the right to:
- Access your personal information
- Update or correct your information
- Delete your account and associated data
- Opt out of marketing communications

6. COOKIES AND TRACKING
We use cookies and similar technologies to enhance your experience and analyze app usage.

7. CHILDREN'S PRIVACY
Our service is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.

8. CHANGES TO PRIVACY POLICY
We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the app.

9. CONTACT US
If you have any questions about this Privacy Policy, please contact us at privacy@yabalash.com.
''';
  }

  String _getCookiePolicy() {
    return '''
COOKIE POLICY

Last updated: December 2024

1. WHAT ARE COOKIES
Cookies are small text files that are placed on your device when you use our application. They help us provide you with a better experience by remembering your preferences and analyzing how you use our service.

2. TYPES OF COOKIES WE USE
- Essential Cookies: Required for the app to function properly
- Performance Cookies: Help us understand how you interact with our app
- Functional Cookies: Remember your preferences and settings
- Analytics Cookies: Help us improve our service

3. HOW WE USE COOKIES
We use cookies to:
- Keep you logged in to your account
- Remember your delivery address and preferences
- Analyze app performance and usage patterns
- Provide personalized content and recommendations

4. MANAGING COOKIES
You can control and manage cookies through your device settings. Please note that disabling certain cookies may affect the functionality of our app.

5. THIRD-PARTY COOKIES
We may use third-party services that place cookies on your device for analytics and advertising purposes. These third parties have their own privacy policies.

6. UPDATES TO THIS POLICY
We may update this Cookie Policy from time to time. Any changes will be posted in the app.

For questions about our Cookie Policy, contact us at privacy@yabalash.com.
''';
  }

  String _getDeliveryTerms() {
    return '''
DELIVERY TERMS & CONDITIONS

Last updated: December 2024

1. DELIVERY AREAS
We currently deliver to selected areas in Dubai, Abu Dhabi, and Sharjah. Delivery availability may vary by restaurant and location.

2. DELIVERY TIMES
- Estimated delivery times are provided as guidance only
- Actual delivery times may vary due to weather, traffic, restaurant preparation time, and other factors
- We will notify you of any significant delays

3. DELIVERY FEES
- Delivery fees vary by restaurant and distance
- Fees are clearly displayed before order confirmation
- Additional fees may apply during peak hours or special events

4. DELIVERY PROCESS
- You must provide a valid delivery address
- Someone must be available to receive the order at the delivery address
- Delivery personnel may contact you if they cannot locate the address
- You may be required to meet the delivery person at the building entrance

5. FAILED DELIVERIES
If delivery fails due to:
- Incorrect address information
- No one available to receive the order
- Inability to contact you
- Unsafe delivery conditions

The order may be cancelled and refund policies will apply.

6. FOOD SAFETY
- We work with restaurants to ensure food safety standards
- Orders are delivered in sealed packaging when possible
- Report any food safety concerns immediately

7. COMPLAINTS
If you have any issues with your delivery, please contact our support team within 24 hours of delivery.

8. LIABILITY
Our liability for delivery issues is limited to the value of your order. We are not responsible for delays caused by circumstances beyond our control.

For delivery-related questions, contact us at delivery@yabalash.com.
''';
  }
}
