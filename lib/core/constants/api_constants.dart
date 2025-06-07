class ApiConstants {
  static const String baseUrl = 'https://yabalash.com';
  static const String apiVersion = '/api/v1';
  static const String apiVersionV2 = '/api/v2';
  static const String fullBaseUrl = '$baseUrl$apiVersion';
  static const String fullBaseUrlV2 = '$baseUrl$apiVersionV2';

  // Company code header (required for API calls)
  static const String companyCode = '2b5f69';

  // Google Maps API key (from React Native app investigation)
  static const String googleMapsApiKey =
      'AIzaSyC7WBZBclqbZ2VKbM2MFlsAWIAx2X3mNJA';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String loginViaUsername = '/auth/loginViaUsername';
  static const String register = '/auth/register';
  static const String verifyPhoneLoginOtp = '/auth/verify/phoneLoginOtp';
  static const String verifyAccount = '/auth/verifyAccount';
  static const String forgotPassword = '/auth/forgotPassword';
  static const String sendToken = '/auth/sendToken';
  static const String countryList = '/auth/country-list';
  static const String shortCode = '/auth/shortCode';

  // Headers
  static const String header = '/header';

  // Social login
  static String socialLogin(String provider) => '/social/login/$provider';

  // Restaurant/Vendor endpoints
  static String vendor(int id) => '/vendor/$id';
  static const String vendorCategory = '/vendorCategory';
  static const String productList = '/productList';
  static const String vendorProducts = '/vendorProducts';

  // V2 endpoints (optimized versions from Postman collection)
  static String vendorOptimize(int id) => '/v2/vendor-optimize/$id';
  static String vendorOptimizeCategory(int id) =>
      '/v2/vendor-optimize-category/$id';
  static const String vendorProductsFilterOptimize =
      '/v2/vendor/vendorProductsFilterOptimize';

  // Cart endpoints (based on React Native investigation)
  static const String cartList = '/cart/list';
  static const String addToCart = '/cart/add';
  static const String updateCart = '/cart/updateQuantity';
  static const String removeCartProducts = '/cart/remove';
  static const String clearCart = '/cart/empty';
  static const String cartTotalItems = '/cart/totalItems';
  static const String scheduleOrder = '/cart/schedule/update';
  static const String updateCartCheckedStatus = '/cart/updateCartCheckedStatus';
  static const String getLastAddedProductVariant = '/cart/product/lastAdded';

  // Promo code endpoints
  static const String verifyPromoCode = '/promo-code/verify';
  static const String removePromoCode = '/promo-code/remove';
  static const String promoCodeList = '/promo-code/list';

  // Vendor endpoints
  static const String vendorSlots = '/vendor/slots';

  // Payment endpoints
  static const String paymentOptions = '/payment/options/cart';
  static const String getWebUrl = '/payment';
  static const String orderAfterPayment = '/order/after/payment';

  // Order endpoints
  static const String placeOrder = '/place/order';
  static const String orders = '/orders';
  static String orderDetail(int id) => '/order-detail/$id';

  // Address endpoints
  static const String addressBook = '/addressBook';
  static const String addAddress = '/user/address';
  static const String deleteAddress = '/delete/address';
  static const String setPrimaryAddress = '/primary/address';
}
