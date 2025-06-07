import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  
  FirebaseService._();
  
  FirebaseMessaging? _messaging;
  String? _fcmToken;
  
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      
      // Request permission for iOS
      await _requestPermission();
      
      // Get FCM token
      await _getToken();
      
      // Listen to token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
      });
      
      // Configure message handlers
      _configureMessageHandlers();
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }
  
  Future<void> _requestPermission() async {
    final settings = await _messaging?.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    debugPrint('Notification permission status: ${settings?.authorizationStatus}');
  }
  
  Future<void> _getToken() async {
    try {
      _fcmToken = await _messaging?.getToken();
      debugPrint('FCM Token: $_fcmToken');
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }
  
  String? get fcmToken => _fcmToken;
  
  Future<String> getDeviceToken() async {
    if (_fcmToken != null) return _fcmToken!;
    
    try {
      _fcmToken = await _messaging?.getToken();
      return _fcmToken ?? 'device_token_placeholder';
    } catch (e) {
      debugPrint('Error getting device token: $e');
      return 'device_token_placeholder';
    }
  }
  
  void _configureMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
      
      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        // Show local notification or update UI
      }
    });
    
    // Handle messages when app is in background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message clicked!');
      // Navigate to specific screen based on message data
    });
  }
  
  // Handle background messages
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    debugPrint("Handling a background message: ${message.messageId}");
  }
}