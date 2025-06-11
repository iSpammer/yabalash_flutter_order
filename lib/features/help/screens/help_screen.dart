import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Help & Support'),
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
          // Contact Support Card
          _buildContactCard(context),
          SizedBox(height: 20.h),

          // FAQ Sections
          _buildSectionTitle('Frequently Asked Questions'),
          SizedBox(height: 12.h),

          _buildFAQCard(
            'Order & Delivery',
            [
              FAQItem(
                question: 'How do I track my order?',
                answer:
                    'You can track your order in real-time from the "Orders" tab. You\'ll receive notifications about your order status and can see the delivery driver\'s location on the map.',
              ),
              FAQItem(
                question: 'What are the delivery charges?',
                answer:
                    'Delivery charges vary by restaurant and distance. You can see the exact delivery fee before placing your order in the cart summary.',
              ),
              FAQItem(
                question: 'Can I schedule my order for later?',
                answer:
                    'Yes! You can schedule your order for a specific time when placing your order. Just select "Schedule Order" option during checkout.',
              ),
            ],
          ),

          SizedBox(height: 16.h),

          _buildFAQCard(
            'Payment & Refunds',
            [
              FAQItem(
                question: 'What payment methods do you accept?',
                answer:
                    'We accept credit/debit cards, digital wallets, and cash on delivery. All online payments are secured and encrypted.',
              ),
              FAQItem(
                question: 'How do I get a refund?',
                answer:
                    'Refunds are processed automatically for cancelled orders. For other issues, please contact our support team and we\'ll process your refund within 3-5 business days.',
              ),
              FAQItem(
                question: 'Can I tip the delivery driver?',
                answer:
                    'Yes! You can add a tip for your delivery driver during checkout or pay in cash upon delivery.',
              ),
            ],
          ),

          SizedBox(height: 16.h),

          _buildFAQCard(
            'Account & Settings',
            [
              FAQItem(
                question: 'How do I update my delivery address?',
                answer:
                    'Go to your Profile > Delivery Address to add, edit, or remove delivery addresses. You can also select a different address during checkout.',
              ),
              FAQItem(
                question: 'How do I change my password?',
                answer:
                    'You can reset your password by using the "Forgot Password" option on the login screen or contact support for assistance.',
              ),
              FAQItem(
                question: 'Can I delete my account?',
                answer:
                    'Yes, you can request account deletion by contacting our support team. Please note this action is irreversible.',
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // App Information
          _buildAppInfoCard(context),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need Immediate Help?',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Our support team is here for you',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  icon: Icons.phone,
                  label: 'Call Support',
                  onTap: () => _launchPhone('+971-26410104'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildContactButton(
                  icon: Icons.email,
                  label: 'Email Us',
                  onTap: () => _launchEmail('support@yabalash.com'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildFAQCard(String category, List<FAQItem> faqs) {
    return Container(
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
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          ...faqs.asMap().entries.map((entry) {
            final isLast = entry.key == faqs.length - 1;
            return _buildFAQTile(entry.value, !isLast);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFAQTile(FAQItem faq, bool showDivider) {
    return ExpansionTile(
      title: Text(
        faq.question,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          child: Text(
            faq.answer,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }

  Widget _buildAppInfoCard(BuildContext context) {
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
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'App Information',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoRow('App Version', '1.0.0'),
          _buildInfoRow('Business Hours', '24/7 Available'),
          _buildInfoRow('Service Areas', 'UAE - Dubai, Abu Dhabi, Sharjah'),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoButton(
                  'Rate App',
                  Icons.star_border,
                  () => _launchAppStore(),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildInfoButton(
                  'Share App',
                  Icons.share,
                  () => _shareApp(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
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

  Widget _buildInfoButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey[700], size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=Support Request');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchAppStore() async {
    // Implement app store launch logic
    // For now, just show a message
  }

  Future<void> _shareApp() async {
    // Implement share functionality
    // For now, just show a message
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
