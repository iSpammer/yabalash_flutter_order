import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/routes/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_colors.dart';
import 'core/services/social_login_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/restaurants/providers/restaurant_provider.dart';
import 'features/restaurants/providers/product_detail_provider.dart';
import 'features/categories/providers/category_provider.dart';
import 'features/cart/providers/cart_provider.dart';
import 'features/search/providers/search_provider.dart';
import 'features/payment/providers/payment_provider.dart';
import 'features/orders/providers/order_provider.dart';
import 'features/profile/providers/address_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Add global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Handle platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };

  try {
    // Initialize Firebase - catch errors gracefully
    try {
      await FirebaseService.instance.initialize();
      
      // Set up background message handler - use our enhanced handler
      FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    } catch (e) {
      debugPrint('Firebase initialization failed, continuing without Firebase: $e');
      // App can still run without Firebase, just without push notifications
    }

    // Initialize social login service
    try {
      SocialLoginService().initialize();
    } catch (e) {
      debugPrint('Social login initialization failed: $e');
    }

    // Initialize notification service
    try {
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('Notification service initialization failed: $e');
    }

    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('Fatal error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    // Still run the app but with limited functionality
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            try {
              final authProvider = AuthProvider();
              authProvider.init();
              return authProvider;
            } catch (e) {
              debugPrint('Error initializing AuthProvider: $e');
              return AuthProvider(); // Return instance without init if it fails
            }
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            try {
              return DashboardProvider();
            } catch (e) {
              debugPrint('Error initializing DashboardProvider: $e');
              return DashboardProvider();
            }
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            try {
              return RestaurantProvider();
            } catch (e) {
              debugPrint('Error initializing RestaurantProvider: $e');
              return RestaurantProvider();
            }
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            try {
              return AddressProvider();
            } catch (e) {
              debugPrint('Error initializing AddressProvider: $e');
              return AddressProvider();
            }
          },
        ),
        ChangeNotifierProxyProvider<AddressProvider, CartProvider>(
          create: (context) => CartProvider(
            addressProvider: context.read<AddressProvider>(),
          ),
          update: (context, addressProvider, previous) =>
              previous ??
              CartProvider(
                addressProvider: addressProvider,
              ),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductDetailProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(),
        ),
        ChangeNotifierProxyProvider3<AuthProvider, CartProvider, AddressProvider, PaymentProvider>(
          create: (context) => PaymentProvider(
            authProvider: context.read<AuthProvider>(),
            cartProvider: context.read<CartProvider>(),
            addressProvider: context.read<AddressProvider>(),
          ),
          update: (context, auth, cart, address, previous) =>
              previous ??
              PaymentProvider(
                authProvider: auth,
                cartProvider: cart,
                addressProvider: address,
              ),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: AppColors.primaryColor,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryColor,
                primary: AppColors.primaryColor,
              ),
              textTheme: GoogleFonts.poppinsTextTheme(
                Theme.of(context).textTheme,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                ),
              ),
              appBarTheme: const AppBarTheme(
                elevation: 0,
                backgroundColor: Colors.white,
                iconTheme: IconThemeData(color: Colors.black),
                titleTextStyle: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              useMaterial3: true,
            ),
            routerConfig: AppRouter.createRouter(context),
          );
        },
      ),
    );
  }
}
