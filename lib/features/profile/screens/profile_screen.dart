import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/profile_menu_item.dart';
import '../widgets/address_selection_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final user = authProvider.user;
            
            return CustomScrollView(
              slivers: [
                _buildAppBar(context, user?.name ?? 'Guest'),
                _buildProfileHeader(context, user),
                _buildAddressSection(context),
                _buildMenuSection(context, authProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String name) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Profile',
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Colors.black87,
          size: 24.sp,
        ),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // Profile Avatar
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40.w),
              ),
              child: Icon(
                Icons.person,
                size: 40.sp,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 16.h),
            
            // User Name
            Text(
              user?.name ?? 'Guest User',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4.h),
            
            // User Email/Phone
            if (user?.email != null)
              Text(
                user.email,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
            if (user?.phoneNumber != null) ...[
              SizedBox(height: 2.h),
              Text(
                user.phoneNumber,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(top: 8.h),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
              child: Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const AddressSelectionWidget(),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, AuthProvider authProvider) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(top: 8.h),
        color: Colors.white,
        child: Column(
          children: [
            ProfileMenuItem(
              icon: Icons.edit,
              title: 'Update Profile',
              onTap: () {
                // Navigate to update profile
                context.push('/update-profile');
              },
            ),
            ProfileMenuItem(
              icon: Icons.history,
              title: 'Order History',
              onTap: () {
                // Navigate to order history
                context.push('/orders');
              },
            ),
            ProfileMenuItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                // Navigate to help
                context.push('/help');
              },
            ),
            ProfileMenuItem(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () {
                // Navigate to about
                context.push('/about');
              },
            ),
            ProfileMenuItem(
              icon: Icons.logout,
              title: 'Logout',
              isDestructive: true,
              onTap: () {
                _showLogoutDialog(context, authProvider);
              },
            ),
            SizedBox(height: 100.h), // Extra padding for transparent navigation bar
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                authProvider.logout();
                context.go('/login');
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}