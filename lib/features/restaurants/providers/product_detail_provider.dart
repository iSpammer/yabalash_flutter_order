import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../models/offer_model.dart';
import '../services/product_detail_service.dart';
import '../../orders/services/order_service.dart';

class ProductDetailProvider extends ChangeNotifier {
  final ProductDetailService _service = ProductDetailService();
  final OrderService _orderService = OrderService();
  
  ProductModel? _product;
  List<ReviewModel> _reviews = [];
  List<OfferModel> _offers = [];
  List<ProductModel> _relatedProducts = [];
  
  bool _isLoading = false;
  bool _isLoadingReviews = false;
  bool _isLoadingOffers = false;
  bool _isSubmittingReview = false;
  bool _isCheckingReviewEligibility = false;
  
  // Review eligibility
  bool _canUserReview = false;
  int? _orderIdForReview;
  int? _orderVendorProductIdForReview;
  String? _reviewEligibilityReason;
  
  String? _errorMessage;
  int _selectedImageIndex = 0;
  int _quantity = 1;
  String? _selectedVariantId;
  List<String> _selectedAddonIds = [];

  // Getters
  ProductModel? get product => _product;
  List<ReviewModel> get reviews => _reviews;
  List<OfferModel> get offers => _offers;
  List<ProductModel> get relatedProducts => _relatedProducts;
  
  bool get isLoading => _isLoading;
  bool get isLoadingReviews => _isLoadingReviews;
  bool get isLoadingOffers => _isLoadingOffers;
  bool get isSubmittingReview => _isSubmittingReview;
  bool get isCheckingReviewEligibility => _isCheckingReviewEligibility;
  
  // Review eligibility getters
  bool get canUserReview => _canUserReview;
  String? get reviewEligibilityReason => _reviewEligibilityReason;
  
  String? get errorMessage => _errorMessage;
  int get selectedImageIndex => _selectedImageIndex;
  int get quantity => _quantity;
  String? get selectedVariantId => _selectedVariantId;
  List<String> get selectedAddonIds => _selectedAddonIds;

  // Computed properties
  double get averageRating {
    if (_reviews.isEmpty) return _product?.rating ?? 0.0;
    return _reviews.fold(0.0, (sum, review) => sum + review.rating) / _reviews.length;
  }

  String get formattedPrice {
    if (_product == null) return '';
    
    final price = _product!.price;
    final comparePrice = _product!.compareAtPrice;
    
    if (comparePrice != null && comparePrice > price) {
      return 'AED ${price.toStringAsFixed(0)}';
    }
    
    return 'AED ${price.toStringAsFixed(0)}';
  }

  String? get formattedComparePrice {
    if (_product == null) return null;
    
    final price = _product!.price;
    final comparePrice = _product!.compareAtPrice;
    
    if (comparePrice != null && comparePrice > price) {
      return 'AED ${comparePrice.toStringAsFixed(0)}';
    }
    
    return null;
  }

  bool get hasDiscount {
    if (_product == null) return false;
    final comparePrice = _product!.compareAtPrice;
    return comparePrice != null && comparePrice > _product!.price;
  }

  String? get discountPercentage {
    if (!hasDiscount) return null;
    
    final price = _product!.price;
    final comparePrice = _product!.compareAtPrice!;
    final discount = ((comparePrice - price) / comparePrice * 100).round();
    
    return '$discount% OFF';
  }

  double get totalPrice {
    if (_product == null) return 0.0;
    return _product!.price * _quantity;
  }

  List<String> get productImages {
    if (_product == null) return [];
    
    List<String> images = [];
    
    // Extract images from media array first
    if (_product!.media != null && _product!.media!.isNotEmpty) {
      for (var media in _product!.media!) {
        final imageUrl = media.image?.path?.fullImageUrl;
        if (imageUrl != null) {
          images.add(imageUrl);
        }
      }
    }
    
    // Fallback to direct image fields if no media images
    if (images.isEmpty) {
      if (_product!.image != null) images.add(_product!.image!);
      if (_product!.thumbImage != null && _product!.thumbImage != _product!.image) {
        images.add(_product!.thumbImage!);
      }
    }
    
    return images;
  }

  void setSelectedImageIndex(int index) {
    _selectedImageIndex = index;
    notifyListeners();
  }

  void setQuantity(int quantity) {
    if (quantity > 0) {
      _quantity = quantity;
      notifyListeners();
    }
  }

  void incrementQuantity() {
    // Check stock if available
    if (_product?.stockQuantity != null && _quantity >= _product!.stockQuantity!) {
      return;
    }
    
    _quantity++;
    notifyListeners();
  }

  void decrementQuantity() {
    if (_quantity > 1) {
      _quantity--;
      notifyListeners();
    }
  }

  void setSelectedVariant(String? variantId) {
    _selectedVariantId = variantId;
    notifyListeners();
  }

  void toggleAddon(String addonId) {
    if (_selectedAddonIds.contains(addonId)) {
      _selectedAddonIds.remove(addonId);
    } else {
      _selectedAddonIds.add(addonId);
    }
    notifyListeners();
  }

  void clearSelections() {
    _selectedVariantId = null;
    _selectedAddonIds.clear();
    _quantity = 1;
    _selectedImageIndex = 0;
    notifyListeners();
  }

  Future<void> loadProductDetails(int productId, {double? latitude, double? longitude}) async {
    // Clear previous product data immediately to prevent showing old content
    _product = null;
    _reviews = [];
    _offers = [];
    _relatedProducts = [];
    _selectedImageIndex = 0;
    _quantity = 1;
    _selectedVariantId = null;
    _selectedAddonIds = [];
    _canUserReview = false;
    _orderIdForReview = null;
    _orderVendorProductIdForReview = null;
    _reviewEligibilityReason = null;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.getProductDetailsWithExtras(
        productId: productId,
        latitude: latitude,
        longitude: longitude,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        _product = data['product'] as ProductModel;
        _offers = data['offers'] as List<OfferModel>? ?? [];
        
        // Handle related products
        final relatedProductsData = data['relatedProducts'] as List?;
        if (relatedProductsData != null) {
          _relatedProducts = relatedProductsData
              .map((json) => ProductModel.fromJson(json))
              .toList();
        }
        
        // Auto-select first variant if available
        if (_product!.variants != null && _product!.variants!.isNotEmpty) {
          _selectedVariantId = _product!.variants!.first.id.toString();
          debugPrint('Auto-selected first variant: $_selectedVariantId');
        }
        
        _errorMessage = null;
        
        // Load reviews and check review eligibility
        _loadReviews(productId);
        _checkReviewEligibility(productId);
      } else {
        _errorMessage = response.message ?? 'Failed to load product details';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
      debugPrint('Error loading product details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadReviews(int productId) async {
    _isLoadingReviews = true;
    notifyListeners();

    try {
      final response = await _service.getProductRatings(productId: productId);

      if (response.success && response.data != null) {
        _reviews = response.data!;
        debugPrint('Loaded ${_reviews.length} reviews for product $productId');
      } else {
        debugPrint('Failed to load reviews: ${response.message}');
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    } finally {
      _isLoadingReviews = false;
      notifyListeners();
    }
  }

  Future<void> _checkReviewEligibility(int productId) async {
    _isCheckingReviewEligibility = true;
    notifyListeners();

    try {
      final response = await _orderService.checkProductReviewEligibility(
        productId: productId,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        _canUserReview = data['canReview'] ?? false;
        _orderIdForReview = data['orderId'];
        _orderVendorProductIdForReview = data['orderVendorProductId'];
        _reviewEligibilityReason = data['reason'];
        
        debugPrint('Review eligibility for product $productId: $_canUserReview');
        if (_canUserReview) {
          debugPrint('Order context - Order ID: $_orderIdForReview, Order Product ID: $_orderVendorProductIdForReview');
        } else {
          debugPrint('Cannot review: $_reviewEligibilityReason');
        }
      } else {
        _canUserReview = false;
        _reviewEligibilityReason = response.message ?? 'Failed to check review eligibility';
        debugPrint('Failed to check review eligibility: ${response.message}');
      }
    } catch (e) {
      _canUserReview = false;
      _reviewEligibilityReason = 'Error checking review eligibility';
      debugPrint('Error checking review eligibility: $e');
    } finally {
      _isCheckingReviewEligibility = false;
      notifyListeners();
    }
  }


  Future<bool> submitReview({
    required double rating,
    required String reviewText,
    List<String>? imageUrls,
  }) async {
    if (_product == null) return false;
    
    // Check if user can review this product
    if (!_canUserReview || _orderIdForReview == null || _orderVendorProductIdForReview == null) {
      debugPrint('Cannot submit review: User has not ordered this product or order not delivered');
      return false;
    }

    _isSubmittingReview = true;
    notifyListeners();

    try {
      final response = await _service.submitReview(
        productId: _product!.id,
        rating: rating,
        reviewText: reviewText,
        orderId: _orderIdForReview!,
        orderVendorProductId: _orderVendorProductIdForReview!,
        imageUrls: imageUrls,
      );

      if (response.success) {
        // Reload reviews to show the new one
        await _loadReviews(_product!.id);
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error submitting review: $e');
      return false;
    } finally {
      _isSubmittingReview = false;
      notifyListeners();
    }
  }

  void refresh() {
    if (_product != null) {
      loadProductDetails(_product!.id);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}