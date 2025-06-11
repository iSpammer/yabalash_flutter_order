import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../widgets/app_shell.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/verify_account_screen.dart';
import '../../features/auth/screens/social_phone_screen.dart';
import '../../features/legal/screens/terms_of_service_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/restaurants/screens/restaurant_detail_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/add_address_screen.dart';
import '../../features/profile/screens/address_selection_screen.dart';
import '../../features/profile/screens/update_profile_screen.dart';
import '../../features/restaurants/screens/product_detail_screen.dart';
import '../../features/categories/screens/category_screen.dart';
import '../../features/payment/screens/payment_screen.dart';
import '../../features/orders/screens/order_success_screen.dart';
import '../../features/payment/screens/payment_webview_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/orders/screens/order_details_screen.dart';
import '../../features/orders/screens/order_tracking_screen.dart';
import '../../features/orders/screens/order_tracking_map_screen.dart';
import '../../features/orders/screens/webview_tracking_screen.dart';
import '../../features/profile/models/address_model.dart';
import '../../features/dashboard/screens/section_all_items_screen.dart';
import '../../features/dashboard/models/dashboard_section.dart';
import '../../features/help/screens/help_screen.dart';
import '../../features/about/screens/about_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  
  static GoRouter createRouter(BuildContext context) {
    // Set the navigator key for notifications
    NotificationService.setNavigatorKey(_navigatorKey);
    
    return GoRouter(
      navigatorKey: _navigatorKey,
      initialLocation: '/home',
      refreshListenable: context.read<AuthProvider>(),
      redirect: (context, state) {
        // Get authentication status from AuthProvider
        final authProvider = context.read<AuthProvider>();
        final isLoggedIn = authProvider.isLoggedIn;
        final user = authProvider.user;
        
        // Check if user needs phone number completion
        final needsPhoneNumber = user != null && 
            (user.phoneNumberRequired == true || 
             user.phoneNumber == null || 
             user.phoneNumber!.isEmpty);
      
      final isAuthRoute = state.matchedLocation == '/login' || 
                         state.matchedLocation == '/register' ||
                         state.matchedLocation == '/forgot-password' ||
                         state.matchedLocation == '/verify-account';
                         
      final isPhoneRoute = state.matchedLocation == '/social-phone';
      
      // Routes that require authentication
      final protectedRoutes = [
        '/cart',
        '/profile',
        '/orders',
        '/payment',
        '/addresses',
        '/order',
      ];
      
      // Check if current route is protected
      final isProtectedRoute = protectedRoutes.any((route) => 
        state.matchedLocation.startsWith(route));
      
      // Special handling for phone number requirement
      if (isLoggedIn && needsPhoneNumber && !isPhoneRoute) {
        // User is logged in but needs to complete phone number
        return '/social-phone';
      }
      
      // If user is not logged in and trying to access protected routes
      if (!isLoggedIn && isProtectedRoute) {
        return '/login';
      }
      
      // If user is logged in, has phone number, and on auth routes, redirect to home
      if (isLoggedIn && !needsPhoneNumber && isAuthRoute) {
        return '/home';
      }
      
      // Guest users can access guest-allowed routes
      return null; // No redirect needed
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-account',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return VerifyAccountScreen(
            phoneNumber: extras?['phoneNumber'],
            email: extras?['email'],
            authToken: extras?['authToken'],
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/social-phone',
        builder: (context, state) {
          final authProvider = context.read<AuthProvider>();
          final provider = authProvider.pendingSocialProvider;
          final socialData = authProvider.pendingSocialData;
          
          if (provider == null || socialData == null) {
            // Redirect to login if required data is missing
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/login');
            });
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return SocialPhoneScreen(
            provider: provider,
            socialData: socialData,
          );
        },
      ),
      GoRoute(
        path: '/terms-of-service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),

      // Main app routes (with shell)
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
          ),
        ],
      ),

      // Payment routes (no shell)
      GoRoute(
        path: '/payment',
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: '/payment/webview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final paymentUrl = extra?['paymentUrl'] as String? ?? '';
          final orderNumber = extra?['orderNumber'] as String?;
          return PaymentWebViewScreen(
            paymentUrl: paymentUrl,
            orderNumber: orderNumber,
          );
        },
      ),
      GoRoute(
        path: '/order/success',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OrderSuccessScreen(
            orderData: extra?['orderData'],
          );
        },
      ),
      GoRoute(
        path: '/order/details/:orderId/:trackingId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          final trackingId = state.pathParameters['trackingId'] ?? '';
          return OrderDetailsScreen(
            orderId: orderId,
            trackingId: trackingId,
          );
        },
      ),
      GoRoute(
        path: '/order-tracking/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderTrackingScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/order-tracking-map/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderTrackingMapScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/order-tracking-webview/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          final trackingUrl = state.uri.queryParameters['url'] ?? '';
          return WebViewTrackingScreen(
            orderId: orderId,
            trackingUrl: trackingUrl,
          );
        },
      ),

      // Profile routes (no shell)
      GoRoute(
        path: '/profile/add-address',
        builder: (context, state) {
          final existingAddress = state.extra as AddressModel?;
          return AddAddressScreen(existingAddress: existingAddress);
        },
      ),
      GoRoute(
        path: '/addresses/select',
        builder: (context, state) => const AddressSelectionScreen(),
      ),
      GoRoute(
        path: '/update-profile',
        builder: (context, state) => const UpdateProfileScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),

      // Detail routes (no shell)
      GoRoute(
        path: '/restaurant/:id',
        builder: (context, state) {
          final idParam = state.pathParameters['id'] ?? '';
          final restaurantId = int.tryParse(idParam);
          
          // Validate restaurant ID
          if (restaurantId == null || restaurantId <= 0) {
            return Scaffold(
              appBar: AppBar(title: const Text('Invalid Restaurant')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Invalid restaurant ID'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Go to Home'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return RestaurantDetailScreen(restaurantId: restaurantId);
        },
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final idParam = state.pathParameters['id'] ?? '';
          final productId = int.tryParse(idParam);
          
          // Validate product ID
          if (productId == null || productId <= 0) {
            return Scaffold(
              appBar: AppBar(title: const Text('Invalid Product')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Invalid product ID'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Go to Home'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return ProductDetailScreen(productId: productId);
        },
      ),
      GoRoute(
        path: '/category/:id',
        builder: (context, state) {
          final categoryId =
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final categoryName = state.uri.queryParameters['name'];
          final categoryImage = state.uri.queryParameters['image'];
          return CategoryScreen(
            categoryId: categoryId,
            categoryName: categoryName,
            categoryImage: categoryImage,
          );
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final query = state.uri.queryParameters['query'];
          return SearchScreen(initialQuery: query);
        },
      ),
      GoRoute(
        path: '/section-all',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final section = extra?['section'] as DashboardSection?;
          final sectionType = extra?['sectionType'] as String? ?? '';
          
          if (section == null) {
            return const Scaffold(
              body: Center(
                child: Text('Section not found'),
              ),
            );
          }
          
          return SectionAllItemsScreen(
            section: section,
            sectionType: sectionType,
          );
        },
      ),
      GoRoute(
        path: '/restaurants/category/:categoryId',
        builder: (context, state) {
          final categoryId =
              int.tryParse(state.pathParameters['categoryId'] ?? '') ?? 0;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Category Restaurants'),
            ),
            body: Center(
              child: Text('Category $categoryId - To be implemented'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/restaurants',
        builder: (context, state) {
          final categoryId =
              int.tryParse(state.uri.queryParameters['categoryId'] ?? '') ?? 0;
          final categoryName =
              state.uri.queryParameters['categoryName'] ?? 'Category';
          return Scaffold(
            appBar: AppBar(
              title: Text(categoryName),
            ),
            body: Center(
              child: Text(
                  'Restaurants for $categoryName (ID: $categoryId) - To be implemented'),
            ),
          );
        },
      ),
    ],
    errorBuilder: (context, state) {
      debugPrint('Router error: ${state.error}');
      debugPrint('Router location: ${state.uri}');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'URI: ${state.uri}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              if (state.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Error: ${state.error}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      );
    },
  );
  }
}
