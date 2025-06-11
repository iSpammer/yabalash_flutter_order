import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _firebaseMessaging;
  
  // Navigation key for global navigation
  static GlobalKey<NavigatorState>? navigatorKey;
  
  // Order status monitoring
  Timer? _statusCheckTimer;
  Map<int, String> _lastKnownOrderStatus = {};
  
  // App state tracking
  bool _isAppInForeground = true;
  
  // Set navigator key for navigation from notifications
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }
  
  // Initialize notification service
  Future<void> initialize() async {
    try {
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize Firebase messaging only if Firebase is available
      try {
        _firebaseMessaging = FirebaseMessaging.instance;
        await _initializeFirebaseMessaging();
      } catch (e) {
        debugPrint('Firebase not available, notifications will be limited: $e');
      }
      
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Request permissions for notifications
    await _requestNotificationPermissions();
  }

  Future<void> _initializeFirebaseMessaging() async {
    if (_firebaseMessaging == null) return;
    
    // Request permission for Firebase messaging
    NotificationSettings settings = await _firebaseMessaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted notification permission');
      
      // Get and store FCM token
      await _getFcmToken();
      
      // Handle token refresh
      _firebaseMessaging!.onTokenRefresh.listen(_onTokenRefresh);
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      // Handle initial notification (app was terminated)
      _handleInitialMessage();
    } else {
      debugPrint('User denied notification permission');
    }
  }

  Future<void> _requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      // For Android 13+ (API level 33+)
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  // Show local notification
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'order_status_channel',
        'Order Status Updates',
        channelDescription: 'Notifications for order status changes',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  // Send order status notification
  Future<void> sendOrderStatusNotification({
    required int orderId,
    required String status,
    String? driverName,
    String? estimatedTime,
  }) async {
    String title = 'Order Update';
    String body = 'Your order #$orderId status has been updated to: $status';
    
    // Customize notification based on status
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'accepted':
        title = 'Order Confirmed! 🎉';
        body = 'Your order #$orderId has been confirmed and is being prepared.';
        break;
      case 'preparing':
      case 'in_preparation':
        title = 'Order Being Prepared 👨‍🍳';
        body = 'Your order #$orderId is being prepared with love!';
        break;
      case 'ready':
      case 'ready_for_pickup':
        title = 'Order Ready! 📦';
        body = 'Your order #$orderId is ready and will be picked up soon.';
        break;
      case 'picked_up':
      case 'out_for_delivery':
        title = 'On the Way! 🚀';
        body = driverName != null 
            ? 'Your order #$orderId is on the way with $driverName!'
            : 'Your order #$orderId is out for delivery!';
        if (estimatedTime != null) {
          body += ' ETA: $estimatedTime';
        }
        break;
      case 'delivered':
      case 'completed':
        title = 'Order Delivered! ✅';
        body = 'Your order #$orderId has been delivered. Enjoy your meal!';
        break;
      case 'cancelled':
        title = 'Order Cancelled ❌';
        body = 'Your order #$orderId has been cancelled.';
        break;
      default:
        body = 'Your order #$orderId status: $status';
    }
    
    await showLocalNotification(
      id: orderId,
      title: title,
      body: body,
      payload: 'order_$orderId',
    );
  }

  // Start monitoring order status (non-intrusive)
  void startOrderStatusMonitoring({
    required int orderId,
    required String currentStatus,
    Duration interval = const Duration(minutes: 2),
  }) {
    // Store the current status
    _lastKnownOrderStatus[orderId] = currentStatus;
    
    // Note: In a real implementation, you would set up proper polling
    // or use WebSocket/Server-Sent Events for real-time updates
    // For now, this is a placeholder for the monitoring logic
    debugPrint('Started monitoring order $orderId with status: $currentStatus');
  }

  // Stop monitoring specific order
  void stopOrderStatusMonitoring(int orderId) {
    _lastKnownOrderStatus.remove(orderId);
    debugPrint('Stopped monitoring order $orderId');
  }

  // Get and store FCM token
  Future<void> _getFcmToken() async {
    if (_firebaseMessaging == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      String? storedToken = prefs.getString('fcm_token');
      
      final token = await _firebaseMessaging!.getToken();
      if (token != null && token != storedToken) {
        await prefs.setString('fcm_token', token);
        debugPrint('FCM Token stored: $token');
        // TODO: Send token to backend API
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }
  
  // Handle token refresh
  void _onTokenRefresh(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
    debugPrint('FCM Token refreshed: $token');
    // TODO: Send updated token to backend API
  }
  
  // Handle initial notification when app was terminated
  void _handleInitialMessage() async {
    if (_firebaseMessaging == null) return;
    
    final initialMessage = await _firebaseMessaging!.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state via notification');
      _handleNotificationNavigation(initialMessage);
    }
  }
  
  // Handle foreground Firebase messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.notification?.title}');
    debugPrint('Message data: ${message.data}');
    
    if (_isAppInForeground && message.notification != null) {
      // Show local notification when app is in foreground
      _showForegroundNotification(message);
    }
  }
  
  // Show notification when app is in foreground
  void _showForegroundNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;
      
      // Create notification channel for Android
      const androidDetails = AndroidNotificationDetails(
        'foreground_channel',
        'Foreground Notifications',
        channelDescription: 'Notifications shown when app is in foreground',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
        styleInformation: BigTextStyleInformation(''),
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification.wav',
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(
        message.hashCode,
        notification?.title ?? 'New Notification',
        notification?.body ?? '',
        details,
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('Error showing foreground notification: $e');
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationNavigation(RemoteMessage(data: data));
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
        
        // Legacy payload handling
        if (response.payload!.startsWith('order_')) {
          final orderIdStr = response.payload!.replaceFirst('order_', '');
          final orderId = int.tryParse(orderIdStr);
          
          if (orderId != null) {
            _navigateToOrderDetails(orderId);
          }
        }
      }
    }
  }

  // Handle notification tap from Firebase (when app is closed/background)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Firebase notification tapped: ${message.data}');
    _handleNotificationNavigation(message);
  }
  
  // Unified notification navigation handler
  void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    
    try {
      // Extract navigation parameters
      final redirectType = data['redirect_type'];
      final redirectTypeValue = data['redirect_type_value'];
      final redirectData = data['redirect_data'];
      final clickActionUrl = data['click_action'] ?? data['url'];
      final orderId = data['order_id'];
      
      if (navigatorKey?.currentContext != null) {
        final context = navigatorKey!.currentContext!;
        
        // Handle different redirection types
        if (redirectType == '2' && redirectTypeValue != null) {
          _handleTypeBasedRedirection(context, redirectTypeValue, redirectData);
        } else if (clickActionUrl != null) {
          _handleUrlBasedRedirection(context, clickActionUrl);
        } else if (orderId != null) {
          final orderIdInt = int.tryParse(orderId.toString());
          if (orderIdInt != null) {
            _navigateToOrderDetails(orderIdInt);
          }
        } else {
          // Default: navigate to home
          context.go('/');
        }
      }
    } catch (e) {
      debugPrint('Error handling notification navigation: $e');
    }
  }
  
  // Handle type-based redirection (React Native style)
  void _handleTypeBasedRedirection(BuildContext context, String redirectTypeValue, String? redirectData) {
    switch (redirectTypeValue.toLowerCase()) {
      case 'subcategory':
      case 'vendor':
        if (redirectData != null) {
          try {
            final vendorData = jsonDecode(redirectData);
            final vendorId = vendorData['id'] ?? vendorData['vendor_id'];
            if (vendorId != null) {
              context.push('/restaurant/$vendorId', extra: {'fromNotification': true});
            }
          } catch (e) {
            debugPrint('Error parsing vendor data: $e');
          }
        }
        break;
        
      case 'product':
        if (redirectData != null) {
          try {
            final productData = jsonDecode(redirectData);
            final productId = productData['id'] ?? productData['product_id'];
            if (productId != null) {
              context.push('/product/$productId', extra: {'fromNotification': true});
            }
          } catch (e) {
            debugPrint('Error parsing product data: $e');
          }
        }
        break;
        
      case 'category':
        if (redirectData != null) {
          try {
            final categoryData = jsonDecode(redirectData);
            final categoryId = categoryData['id'] ?? categoryData['category_id'];
            if (categoryId != null) {
              context.push('/category/$categoryId', extra: {'fromNotification': true});
            }
          } catch (e) {
            debugPrint('Error parsing category data: $e');
          }
        }
        break;
        
      case 'order':
        if (redirectData != null) {
          try {
            final orderData = jsonDecode(redirectData);
            final orderId = orderData['id'] ?? orderData['order_id'];
            if (orderId != null) {
              _navigateToOrderDetails(int.parse(orderId.toString()));
            }
          } catch (e) {
            debugPrint('Error parsing order data: $e');
          }
        }
        break;
        
      default:
        context.go('/');
    }
  }
  
  // Handle URL-based redirection
  void _handleUrlBasedRedirection(BuildContext context, String clickActionUrl) {
    final urlParts = clickActionUrl.split('/');
    
    if (urlParts.length >= 3) {
      final type = urlParts[0].toLowerCase();
      final name = urlParts[1];
      final id = urlParts[2];
      
      switch (type) {
        case 'vendor':
        case 'restaurant':
          context.push('/restaurant/$id', extra: {
            'fromNotification': true,
            'name': name,
          });
          break;
          
        case 'product':
          context.push('/product/$id', extra: {
            'fromNotification': true,
            'name': name,
          });
          break;
          
        case 'category':
          context.push('/category/$id', extra: {
            'fromNotification': true,
            'name': name,
          });
          break;
          
        default:
          context.go('/');
      }
    } else {
      context.go('/');
    }
  }
  
  // Navigate to order details
  void _navigateToOrderDetails(int orderId) {
    if (navigatorKey?.currentContext != null) {
      final context = navigatorKey!.currentContext!;
      context.push('/orders/$orderId', extra: {'fromNotification': true});
    }
  }
  
  // Set app foreground state
  void setAppForegroundState(bool isInForeground) {
    _isAppInForeground = isInForeground;
  }

  // Get stored FCM token
  Future<String?> getFcmToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      debugPrint('Error getting stored FCM token: $e');
      return null;
    }
  }
  
  // Send auto-accept order notification (for vendor apps)
  Future<void> handleAutoAcceptOrder(Map<String, dynamic> orderData) async {
    try {
      final vendors = orderData['vendors'] as List?;
      if (vendors != null && vendors.isNotEmpty) {
        final vendor = vendors[0]['vendor'];
        final autoAccept = vendor['auto_accept_order'] == 1;
        
        if (autoAccept) {
          debugPrint('Auto-accepting order: ${orderData['id']}');
          // TODO: Implement auto-accept logic and printing
          // This would involve calling the backend API to accept the order
          // and potentially trigger printing for vendor receipt
        }
      }
    } catch (e) {
      debugPrint('Error handling auto-accept order: $e');
    }
  }
  
  // Show order status notification with rich formatting
  Future<void> showOrderNotification({
    required int orderId,
    required String status,
    String? title,
    String? body,
    String? driverName,
    String? estimatedTime,
    String? imageUrl,
  }) async {
    try {
      // Determine notification content based on status
      String notificationTitle = title ?? _getOrderStatusTitle(status);
      String notificationBody = body ?? _getOrderStatusBody(status, orderId, driverName, estimatedTime);
      
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'order_status_channel',
        'Order Status Updates',
        channelDescription: 'Notifications for order status changes',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('notification'),
        icon: '@mipmap/ic_launcher',
        styleInformation: imageUrl != null 
            ? BigPictureStyleInformation(
                FilePathAndroidBitmap(imageUrl),
                contentTitle: notificationTitle,
                htmlFormatContentTitle: true,
                summaryText: notificationBody,
                htmlFormatSummaryText: true,
              )
            : BigTextStyleInformation(
                notificationBody,
                htmlFormatBigText: true,
                contentTitle: notificationTitle,
                htmlFormatContentTitle: true,
              ),
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification.wav',
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(
        orderId,
        notificationTitle,
        notificationBody,
        details,
        payload: jsonEncode({
          'type': 'order',
          'order_id': orderId.toString(),
          'status': status,
        }),
      );
    } catch (e) {
      debugPrint('Error showing order notification: $e');
    }
  }
  
  // Get notification title based on order status
  String _getOrderStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'accepted':
        return 'Order Confirmed! 🎉';
      case 'preparing':
      case 'in_preparation':
        return 'Order Being Prepared 👨‍🍳';
      case 'ready':
      case 'ready_for_pickup':
        return 'Order Ready! 📦';
      case 'picked_up':
      case 'out_for_delivery':
        return 'On the Way! 🚀';
      case 'delivered':
      case 'completed':
        return 'Order Delivered! ✅';
      case 'cancelled':
        return 'Order Cancelled ❌';
      default:
        return 'Order Update';
    }
  }
  
  // Get notification body based on order status
  String _getOrderStatusBody(String status, int orderId, String? driverName, String? estimatedTime) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'accepted':
        return 'Your order #$orderId has been confirmed and is being prepared.';
      case 'preparing':
      case 'in_preparation':
        return 'Your order #$orderId is being prepared with love!';
      case 'ready':
      case 'ready_for_pickup':
        return 'Your order #$orderId is ready and will be picked up soon.';
      case 'picked_up':
      case 'out_for_delivery':
        String message = driverName != null 
            ? 'Your order #$orderId is on the way with $driverName!'
            : 'Your order #$orderId is out for delivery!';
        if (estimatedTime != null) {
          message += ' ETA: $estimatedTime';
        }
        return message;
      case 'delivered':
      case 'completed':
        return 'Your order #$orderId has been delivered. Enjoy your meal!';
      case 'cancelled':
        return 'Your order #$orderId has been cancelled.';
      default:
        return 'Your order #$orderId status: $status';
    }
  }
  
  // Dispose resources
  void dispose() {
    _statusCheckTimer?.cancel();
    _lastKnownOrderStatus.clear();
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Background message data: ${message.data}');
  
  // Handle background notification processing
  if (message.notification != null) {
    final orderId = int.tryParse(message.data['order_id'] ?? '0') ?? 0;
    final status = message.data['status'] ?? 'updated';
    
    if (orderId > 0) {
      debugPrint('Background order update: Order $orderId - $status');
      
      // Handle auto-accept orders for vendor apps
      if (Platform.isAndroid && 
          message.notification?.android?.sound == 'notification' &&
          message.data.containsKey('data')) {
        try {
          final orderData = jsonDecode(message.data['data']);
          await NotificationService().handleAutoAcceptOrder(orderData);
        } catch (e) {
          debugPrint('Error handling auto-accept in background: $e');
        }
      }
      
      // Store notification info for when app reopens
      final prefs = await SharedPreferences.getInstance();
      final pendingNotifications = prefs.getStringList('pending_notifications') ?? [];
      pendingNotifications.add(jsonEncode({
        'order_id': orderId,
        'status': status,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': message.data,
      }));
      await prefs.setStringList('pending_notifications', pendingNotifications);
    }
  }
}