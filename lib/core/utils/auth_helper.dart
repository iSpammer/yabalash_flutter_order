import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';

class AuthHelper {
  static bool checkAuthAndShowPrompt(BuildContext context, {String? message}) {
    final authProvider = context.read<AuthProvider>();
    
    if (!authProvider.isLoggedIn) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Login Required'),
          content: Text(message ?? 'Please login to continue with this action.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Continue Browsing'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/login');
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }
}