import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverContactActions extends StatelessWidget {
  final String? driverPhone;
  final String? deviceType;

  const DriverContactActions({
    super.key,
    required this.driverPhone,
    this.deviceType,
  });

  @override
  Widget build(BuildContext context) {
    if (driverPhone == null || driverPhone!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Clean and normalize the phone number once
    String normalizedPhone = _normalizePhoneNumber(driverPhone!);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Driver',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: Icons.phone,
                label: 'Call',
                onPressed: () => _launchUrl(context, 'tel:$normalizedPhone'),
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[600]!],
                ),
              ),
              _buildActionButton(
                icon: Icons.message,
                label: 'SMS',
                onPressed: () async {
                  try {
                    // Simple SMS URL that works on both platforms
                    final Uri smsUri = Uri(
                      scheme: 'sms',
                      path: normalizedPhone,
                    );
                    
                    if (await canLaunchUrl(smsUri)) {
                      await launchUrl(smsUri, mode: LaunchMode.externalApplication);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to send SMS. Please check if the messaging app is available.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error launching SMS: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to send SMS. Please check if the messaging app is available.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                ),
              ),
              _buildActionButton(
                icon: Icons.chat,
                label: 'WhatsApp',
                onPressed: () async {
                  // Prepare the message
                  const message = "Hi, I need help with my order";
                  
                  // Remove the + for WhatsApp URL
                  String whatsappNumber = normalizedPhone.startsWith('+') 
                      ? normalizedPhone.substring(1) 
                      : normalizedPhone;
                  
                  // Always use the universal link which works on all platforms
                  final whatsappUrl = 'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}';
                  
                  try {
                    final uri = Uri.parse(whatsappUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to open WhatsApp. Please check if WhatsApp is installed.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error launching WhatsApp: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to open WhatsApp. Please check if WhatsApp is installed.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                gradient: LinearGradient(
                  colors: [Colors.green[500]!, Colors.green[700]!],
                ),
              ),
              if (!kIsWeb && Platform.isIOS && 
                  deviceType != null && 
                  deviceType!.toLowerCase().contains('ios'))
                _buildActionButton(
                  icon: Icons.videocam,
                  label: 'FaceTime',
                  onPressed: () async {
                    // FaceTime URL format: facetime:phoneNumber or facetime:email
                    final facetimeUrl = 'facetime:$normalizedPhone';
                    final uri = Uri.parse(facetimeUrl);
                    
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to open FaceTime. Please check if FaceTime is available.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[600]!],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Gradient gradient,
  }) {
    return Column(
      children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            gradient: gradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(24.w),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24.w,
              ),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      
      // Check if we can launch the URL
      if (!await canLaunchUrl(uri)) {
        debugPrint('Cannot launch URL: $url');
        // Try alternative approaches for specific URL types
        if (url.startsWith('sms:')) {
          // Try without body parameter
          final simpleSmsUrl = url.split('&')[0].split('?')[0];
          final simpleSmsUri = Uri.parse(simpleSmsUrl);
          if (await canLaunchUrl(simpleSmsUri)) {
            await launchUrl(
              simpleSmsUri,
              mode: LaunchMode.externalApplication,
            );
            return;
          }
        }
        
        // Show error to user
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getErrorMessage(url)),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      // Launch the URL with appropriate mode
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Error launching URL: $url, Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(url)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  String _getErrorMessage(String url) {
    if (url.startsWith('tel:')) {
      return 'Unable to make call. Please check if the phone app is available.';
    } else if (url.startsWith('sms:')) {
      return 'Unable to send SMS. Please check if the messaging app is available.';
    } else if (url.contains('wa.me')) {
      return 'Unable to open WhatsApp. Please check if WhatsApp is installed.';
    } else if (url.startsWith('facetime:')) {
      return 'Unable to open FaceTime. Please check if FaceTime is available.';
    }
    return 'Unable to perform this action.';
  }
  
  String _normalizePhoneNumber(String phone) {
    // Remove all non-numeric characters except +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Handle UAE numbers with extra 0 after country code
    // +9710... should be +971...
    if (cleaned.startsWith('+9710')) {
      cleaned = '+971' + cleaned.substring(5);
    }
    
    // Ensure proper formatting
    if (cleaned.isNotEmpty && !cleaned.startsWith('+')) {
      // If no country code, assume UAE
      if (cleaned.startsWith('0')) {
        // Remove leading 0 and add UAE code
        cleaned = '+971' + cleaned.substring(1);
      } else if (cleaned.length == 9 && (cleaned.startsWith('5') || cleaned.startsWith('4'))) {
        // UAE mobile number without country code
        cleaned = '+971' + cleaned;
      }
    }
    
    debugPrint('Normalized phone: $phone -> $cleaned');
    return cleaned;
  }
}