import 'dart:io';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialLoginService {
  static final SocialLoginService _instance = SocialLoginService._internal();
  factory SocialLoginService() => _instance;
  SocialLoginService._internal();

  // Google Sign-In Configuration
  static const String _googleWebClientId = '848426044866-4li9lq2l3ctie71bl9n2k9nq6jklh9a7.apps.googleusercontent.com';
  
  late final GoogleSignIn _googleSignIn;

  void initialize() {
    _googleSignIn = GoogleSignIn(
      clientId: Platform.isIOS 
          ? '848426044866-ec0690uavk1pks3dmj7totkd98ui8abk.apps.googleusercontent.com'
          : null,
      serverClientId: _googleWebClientId,
      scopes: ['email', 'profile'],
    );
  }

  // Google Sign-In
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      return {
        'provider': 'google',
        'id': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName,
        'photo': googleUser.photoUrl,
        'accessToken': googleAuth.accessToken,
        'idToken': googleAuth.idToken,
      };
    } catch (error) {
      print('Google Sign-In Error: $error');
      return null;
    }
  }

  // Facebook Sign-In
  Future<Map<String, dynamic>?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        
        return {
          'provider': 'facebook',
          'id': userData['id'],
          'email': userData['email'],
          'name': userData['name'],
          'photo': userData['picture']?['data']?['url'],
          'accessToken': result.accessToken?.tokenString,
        };
      }
      return null;
    } catch (error) {
      print('Facebook Sign-In Error: $error');
      return null;
    }
  }

  // Apple Sign-In (iOS only)
  Future<Map<String, dynamic>?> signInWithApple() async {
    try {
      if (!Platform.isIOS) return null;
      
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      return {
        'provider': 'apple',
        'id': credential.userIdentifier,
        'email': credential.email,
        'name': '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim(),
        'identityToken': credential.identityToken,
        'authorizationCode': credential.authorizationCode,
      };
    } catch (error) {
      print('Apple Sign-In Error: $error');
      return null;
    }
  }

  // Sign out from all social providers
  Future<void> signOutAll() async {
    try {
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
    } catch (error) {
      print('Sign out error: $error');
    }
  }

  // Check if Google is signed in
  Future<bool> isGoogleSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  // Check if Facebook is signed in
  Future<bool> isFacebookSignedIn() async {
    final accessToken = await FacebookAuth.instance.accessToken;
    return accessToken != null;
  }
}