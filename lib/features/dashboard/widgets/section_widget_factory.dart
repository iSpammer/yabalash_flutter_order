import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/dashboard_section.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/category_grid.dart';
import '../widgets/yabalash_bags_section.dart';
import '../widgets/surprise_bags_section.dart';
import '../../restaurants/widgets/restaurant_card_v2.dart';
import '../../restaurants/models/restaurant_model.dart';
import '../../restaurants/models/product_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../../cart/widgets/addon_selection_dialog.dart';
import '../../cart/services/product_variant_service.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/cart_loading_dialog.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SectionWidgetFactory {
  static Widget buildSection(DashboardSection section,
      {BuildContext? context}) {
    final sectionType = DashboardSectionType.fromSlug(section.slug);
    // Debug: sections to be displayed ${sectionType!.name}
    switch (sectionType) {
      case DashboardSectionType.banner:
        return _buildBannerSection(section);

      case DashboardSectionType.navCategories:
        return _buildCategoriesSection(section, context: context);

      case DashboardSectionType.vendors:
      case DashboardSectionType.trendingVendors:
        return _buildVendorsSection(section, context: context);

      case DashboardSectionType.newProducts:
      case DashboardSectionType.featuredProducts:
      case DashboardSectionType.bestSellers:
      case DashboardSectionType.onSale:
      case DashboardSectionType.mostPopularProducts:
      case DashboardSectionType.selectedProducts:
      case DashboardSectionType.orderedProducts:
        return _buildProductsSection(section, context);

      case DashboardSectionType.brands:
        return _buildBrandsSection(section);

      case DashboardSectionType.spotlightDeals:
        return _buildSpotlightDealsSection(section);

      case DashboardSectionType.cities:
        return _buildCitiesSection(section);

      case DashboardSectionType.singleCategoryProducts:
        return _buildSingleCategoryProductsSection(section);

      case DashboardSectionType.recentlyViewed:
        return _buildRecentlyViewedSection(section);

      case DashboardSectionType.longTermService:
        return _buildLongTermServiceSection(section);

      case DashboardSectionType.recentOrders:
        return _buildRecentOrdersSection(section);

      case DashboardSectionType.topRated:
        return _buildTopRatedSection(section);

      case DashboardSectionType.dynamicHtml:
        return _buildDynamicHtmlSection(section);

      case DashboardSectionType.yabalashBags:
        return _buildYaBalashBagsSection(section);

      case DashboardSectionType.surpriseBags:
        return _buildSurpriseBagsSection(section);

      default:
        return _buildGenericSection(section);
    }
  }

  static Widget _buildBannerSection(DashboardSection section) {
    final banners = (section.bannerImage ?? section.data)
        .map((bannerJson) => BannerModel.fromJson(bannerJson))
        .toList();

    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(height: 16.h),
        BannerCarousel(
          banners: banners,
          onBannerTap: (banner) {
            if (banner.actionType == 'vendor' && banner.actionId != null) {
              // Navigate to restaurant
            } else if (banner.redirectionUrl != null) {
              // Handle external URL
            }
          },
        ),
      ],
    );
  }

  static Widget _buildCategoriesSection(DashboardSection section,
      {BuildContext? context}) {
    final categories = section.data
        .map((categoryJson) => CategoryModel.fromJson(categoryJson))
        .toList();

    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(height: 24.h),
        _buildSectionHeader(section.getLocalizedTitle()),
        SizedBox(height: 12.h),
        CategoryGrid(
          categories: categories,
          showMoreButton: true,
          onCategoryTap: (category) {
            if (context != null) {
              // Navigate to restaurants filtered by category
              context.push(
                  '/category/${category.id}?name=${Uri.encodeComponent(category.name ?? 'Category')}');
            }
          },
        ),
      ],
    );
  }

  static Widget _buildVendorsSection(DashboardSection section,
      {BuildContext? context}) {
    final restaurants = section.data
        .map((restaurantJson) => RestaurantModel.fromJson(restaurantJson))
        .toList();

    if (restaurants.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24.h),
        _buildSectionHeader(section.getLocalizedTitle()),
        SizedBox(height: 12.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          itemCount: restaurants.length,
          itemBuilder: (context, index) {
            final restaurant = restaurants[index];
            return RestaurantCardV2(
              restaurant: restaurant,
              isHorizontal: true,
              onTap: () {
                if (context != null) {
                  context.push('/restaurant/${restaurant.id}');
                }
              },
            );
          },
        ),
      ],
    );
  }

  static Widget _buildProductsSection(
      DashboardSection section, BuildContext? context) {
    final products = section.data
        .map((productJson) => ProductModel.fromJson(productJson))
        .toList();

    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24.h),
        _buildSectionHeaderWithViewAll(section),
        SizedBox(height: 12.h),
        SizedBox(
          height: 280.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Container(
                width: 200.w,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                child: _buildProductCard(product, section.slug, context),
              );
            },
          ),
        ),
      ],
    );
  }

  static Widget _buildProductCard(
      ProductModel product, String sectionType, BuildContext? context) {
    return GestureDetector(
      onTap: () {
        if (context != null) {
          context.push('/product/${product.id}');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                  child: _buildProductImage(product),
                ),
                _buildProductBadge(sectionType),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.description != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      product.description!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AED ${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: _getSectionColor(sectionType),
                        ),
                      ),
                      Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          final quantity =
                              cartProvider.getQuantityForProduct(product);

                          // Check if product is in stock
                          if (!product.isInStock) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'Out of Stock',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }

                          if (quantity > 0) {
                            // Show +/- controls
                            return Container(
                              decoration: BoxDecoration(
                                color: _getSectionColor(sectionType)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: _getSectionColor(sectionType),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      final currentQuantity = cartProvider.getQuantityForProduct(product);
                                      if (currentQuantity > 1) {
                                        final cartItem = cartProvider.getCartItem(product.id);
                                        if (cartItem?.id != null) {
                                          await cartProvider.updateQuantity(
                                            cartProductId: cartItem!.id!,
                                            quantity: currentQuantity - 1,
                                          );
                                        }
                                      } else {
                                        final cartItem = cartProvider.getCartItem(product.id);
                                        if (cartItem?.id != null) {
                                          await cartProvider.removeFromCart(cartProductId: cartItem!.id!);
                                        }
                                      }
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(4.w),
                                      child: Icon(
                                        Icons.remove,
                                        color: _getSectionColor(sectionType),
                                        size: 16.sp,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8.w),
                                    child: Text(
                                      quantity.toString(),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: _getSectionColor(sectionType),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _handleAddToCart(
                                        product, context, cartProvider),
                                    child: Container(
                                      padding: EdgeInsets.all(4.w),
                                      child: Icon(
                                        Icons.add,
                                        color: _getSectionColor(sectionType),
                                        size: 16.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // Show add button
                            return GestureDetector(
                              onTap: () => _handleAddToCart(
                                  product, context, cartProvider),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: _getSectionColor(sectionType),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildProductBadge(String sectionType) {
    String badgeText;
    Color badgeColor;

    switch (sectionType) {
      case 'new_products':
        badgeText = 'NEW';
        badgeColor = Colors.green[600]!;
        break;
      case 'featured_products':
        badgeText = 'FEATURED';
        badgeColor = Colors.blue[600]!;
        break;
      case 'on_sale':
        badgeText = 'SALE';
        badgeColor = Colors.red[600]!;
        break;
      case 'best_sellers':
        badgeText = 'BESTSELLER';
        badgeColor = Colors.orange[600]!;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Positioned(
      top: 8.h,
      left: 8.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          badgeText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  static Color _getSectionColor(String sectionType) {
    switch (sectionType) {
      case 'new_products':
        return Colors.green[600]!;
      case 'featured_products':
        return Colors.blue[600]!;
      case 'on_sale':
        return Colors.red[600]!;
      case 'best_sellers':
        return Colors.orange[600]!;
      default:
        return Colors.purple[600]!;
    }
  }

  // Enhanced implementations for other section types
  static Widget _buildBrandsSection(DashboardSection section) {
    if (section.data.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24.h),
        _buildSectionHeader(section.getLocalizedTitle()),
        SizedBox(height: 12.h),
        SizedBox(
          height: 100.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: section.data.length,
            itemBuilder: (context, index) {
              final brand = section.data[index];
              final imageUrl = brand['image'] ?? brand['image_url'] ?? '';
              final brandName = brand['name'] ?? 'Brand ${index + 1}';

              return Container(
                width: 80.w,
                margin: EdgeInsets.symmetric(horizontal: 6.w),
                child: GestureDetector(
                  onTap: () {
                    // Navigate to brand detail
                    debugPrint('Navigate to brand: ${brand['id']}');
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30.r),
                          child: imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl:
                                      ImageUtils.buildImageUrl(imageUrl) ?? '',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Icon(Icons.storefront, size: 24.sp),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.storefront, size: 24.sp),
                                )
                              : Icon(Icons.storefront,
                                  size: 24.sp, color: Colors.grey[600]),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        brandName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static Widget _buildSpotlightDealsSection(DashboardSection section) {
    // Treat spotlight deals similar to products but with special styling
    return _buildProductsSection(section, null);
  }

  static Widget _buildCitiesSection(DashboardSection section) {
    if (section.data.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24.h),
        _buildSectionHeader(section.getLocalizedTitle()),
        SizedBox(height: 12.h),
        SizedBox(
          height: 140.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: section.data.length,
            itemBuilder: (context, index) {
              final city = section.data[index];
              final imageUrl =
                  city['image']?['image_path'] ?? city['image'] ?? '';
              final cityName =
                  city['title'] ?? city['name'] ?? 'City ${index + 1}';

              return Container(
                width: 120.w,
                margin: EdgeInsets.symmetric(horizontal: 6.w),
                child: GestureDetector(
                  onTap: () {
                    // Handle city selection
                    debugPrint('Selected city: ${city['id']}');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12.r),
                              topRight: Radius.circular(12.r),
                            ),
                            child: imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl:
                                        ImageUtils.buildImageUrl(imageUrl) ??
                                            '',
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: Icon(Icons.location_city,
                                          size: 32.sp),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Colors.grey[200],
                                      child: Icon(Icons.location_city,
                                          size: 32.sp),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.location_city,
                                        size: 32.sp, color: Colors.grey[600]),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.w),
                          child: Text(
                            cityName,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static Widget _buildSingleCategoryProductsSection(DashboardSection section) {
    return _buildProductsSection(section, null);
  }

  static Widget _buildRecentlyViewedSection(DashboardSection section) {
    return _buildProductsSection(section, null);
  }

  static Widget _buildLongTermServiceSection(DashboardSection section) {
    return _buildGenericHorizontalSection(section, Icons.schedule);
  }

  static Widget _buildRecentOrdersSection(DashboardSection section) {
    return _buildGenericHorizontalSection(section, Icons.history);
  }

  static Widget _buildTopRatedSection(DashboardSection section) {
    return _buildVendorsSection(section);
  }

  static Widget _buildDynamicHtmlSection(DashboardSection section) {
    return _buildGenericSection(section);
  }

  static Widget _buildGenericHorizontalSection(
      DashboardSection section, IconData icon) {
    if (section.data.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24.h),
        _buildSectionHeader(section.getLocalizedTitle()),
        SizedBox(height: 12.h),
        SizedBox(
          height: 120.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: section.data.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120.w,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 32.sp, color: Colors.grey[600]),
                    SizedBox(height: 8.h),
                    Text(
                      'Item ${index + 1}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static Widget _buildGenericSection(DashboardSection section) {
    if (section.data.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(section.getLocalizedTitle()),
          SizedBox(height: 8.h),
          Text(
            'Section: ${section.slug} (${section.data.length} items)',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  static Widget _buildSectionHeaderWithViewAll(DashboardSection section) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            section.getLocalizedTitle(),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          TextButton(
            onPressed: () {
              // Navigate to see all
            },
            child: Text(
              'See All',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _handleAddToCart(
      ProductModel product, BuildContext context, CartProvider cartProvider) async {
    // Check if product is in stock
    if (!product.isInStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product is out of stock'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if product has multiple variants - if so, navigate to detail page
    if (product.variants != null && product.variants!.length > 1) {
      context.push('/product/${product.id}');
      return;
    }

    // Check if there's a vendor conflict using the improved check
    if (cartProvider.hasItemsFromDifferentVendor(product.vendorId ?? 0)) {
      _showVendorConflictDialog(context, product, cartProvider);
      return;
    }

    try {
      // Get product variant details to check for addons
      String sku = product.sku ?? 'SKU${product.id}';
      debugPrint('Getting variant details for product: ${product.name} (SKU: $sku)');
      
      // Show loading dialog while fetching variant details
      CartLoadingDialog.show(context);
      
      final variantDetails = await cartProvider.getProductVariantDetails(sku);
      
      if (variantDetails == null) {
        // Hide loading dialog
        if (context.mounted) {
          CartLoadingDialog.hide(context);
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load product details'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if product has addons
      if (variantDetails.addonSets.isNotEmpty) {
        // Hide loading dialog before showing addon dialog
        if (context.mounted) {
          CartLoadingDialog.hide(context);
        }
        
        // Show addon selection dialog
        final selectedAddons = await AddonSelectionDialog.show(
          context: context,
          variantDetails: variantDetails,
          product: product,
        );
        
        if (selectedAddons == null) {
          // User cancelled
          return;
        }
        
        // Show loading dialog again for adding to cart
        if (context.mounted) {
          CartLoadingDialog.show(context);
        }
        
        // Auto-select single variant if available
        int? variantId;
        if (variantDetails.variants.isNotEmpty) {
          variantId = variantDetails.variants.first.id;
        }
        
        // Add to cart with selected addons
        final success = await cartProvider.addToCart(
          product: product,
          quantity: 1,
          variantId: variantId,
          addons: selectedAddons,
          skipLoadCart: true, // Skip initial cart reload
        );
        
        // Now reload cart after dialog is shown
        if (success) {
          await cartProvider.loadCart();
        }
        
        // Add a small delay to ensure cart is fully loaded
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Hide loading dialog
        if (context.mounted) {
          CartLoadingDialog.hide(context);
        }
        
        // Add another small delay before showing snackbar
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Show result message
        if (context.mounted) {
          if (success) {
            // Force close any remaining dialogs before showing snackbar
            CartLoadingDialog.hideForce(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} added to cart'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'View Cart',
                  textColor: Colors.white,
                  onPressed: () => context.go('/cart'),
                ),
              ),
            );
          } else {
            // Force close dialog before checking error
            CartLoadingDialog.hideForce(context);
            
            // Check if this is a vendor conflict error from the server
            final errorMsg = cartProvider.errorMessage ?? 'Failed to add item to cart';
            if (errorMsg.toLowerCase().contains('vendor') || 
                errorMsg.toLowerCase().contains('another vendor') ||
                errorMsg.toLowerCase().contains('existing items')) {
              // Show vendor conflict dialog
              _showVendorConflictDialog(context, product, cartProvider);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMsg),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } else {
        // No addons, proceed with normal add to cart
        // Auto-select single variant if available
        int? variantId;
        if (variantDetails.variants.isNotEmpty) {
          variantId = variantDetails.variants.first.id;
          debugPrint('Auto-selecting variant ID: $variantId for product ${product.name}');
        }

        final success = await cartProvider.addToCart(
          product: product,
          quantity: 1,
          variantId: variantId,
          skipLoadCart: true, // Skip initial cart reload
        );
        
        // Now reload cart after dialog is shown
        if (success) {
          await cartProvider.loadCart();
        }
        
        // Add a small delay to ensure cart is fully loaded
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Hide loading dialog
        if (context.mounted) {
          CartLoadingDialog.hide(context);
        }
        
        // Add another small delay before showing snackbar
        await Future.delayed(const Duration(milliseconds: 200));

        // Show result message
        if (context.mounted) {
          if (success) {
            // Force close any remaining dialogs before showing snackbar
            CartLoadingDialog.hideForce(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} added to cart'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'View Cart',
                  textColor: Colors.white,
                  onPressed: () => context.go('/cart'),
                ),
              ),
            );
          } else {
            // Force close dialog before checking error
            CartLoadingDialog.hideForce(context);
            
            // Check if this is a vendor conflict error from the server
            final errorMsg = cartProvider.errorMessage ?? 'Failed to add item to cart';
            if (errorMsg.toLowerCase().contains('vendor') || 
                errorMsg.toLowerCase().contains('another vendor') ||
                errorMsg.toLowerCase().contains('existing items')) {
              // Show vendor conflict dialog
              _showVendorConflictDialog(context, product, cartProvider);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMsg),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error in _handleAddToCart: $e');
      
      // Hide loading dialog
      if (context.mounted) {
        CartLoadingDialog.hide(context);
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add item to cart'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static void _showVendorConflictDialog(
      BuildContext context, ProductModel product, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Different Restaurant'),
          content: const Text(
            'Your cart contains items from a different restaurant. You can only order from one restaurant at a time.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Navigate to current vendor's restaurant page
                if (cartProvider.currentVendorId != null) {
                  context.push('/restaurant/${cartProvider.currentVendorId}');
                }
              },
              child: const Text('Browse Current Restaurant'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                // If product has multiple variants, navigate to detail page
                if (product.variants != null && product.variants!.length > 1) {
                  await cartProvider.clearCart();
                  if (context.mounted) {
                    context.push('/product/${product.id}');
                  }
                  return;
                }
                
                try {
                  // Get product variant details to check for addons
                  String sku = product.sku ?? 'SKU${product.id}';
                  
                  // Show loading dialog
                  if (context.mounted) {
                    CartLoadingDialog.show(context, message: 'Clearing cart and loading product details...');
                  }
                  
                  // Clear cart first
                  debugPrint('Attempting to clear cart before adding new vendor item...');
                  final clearSuccess = await cartProvider.clearCart();
                  
                  if (!clearSuccess) {
                    // Force hide loading dialog
                    if (context.mounted) {
                      CartLoadingDialog.hideForce(context);
                    }
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(cartProvider.errorMessage ?? 'Failed to clear cart'),
                          duration: const Duration(seconds: 3),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }
                  
                  // Add extra delay to ensure server has fully processed the clear
                  debugPrint('Cart cleared, waiting for server sync...');
                  await Future.delayed(const Duration(milliseconds: 500));
                  
                  final variantDetails = await cartProvider.getProductVariantDetails(sku);
                  
                  if (variantDetails == null) {
                    // Force hide loading dialog
                    if (context.mounted) {
                      CartLoadingDialog.hideForce(context);
                    }
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to load product details'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  // Check if product has addons
                  if (variantDetails.addonSets.isNotEmpty) {
                    // Hide loading dialog before showing addon dialog
                    if (context.mounted) {
                      CartLoadingDialog.hideForce(context);
                    }
                    
                    // Small delay to ensure dialog is closed
                    await Future.delayed(const Duration(milliseconds: 100));
                    
                    // Show addon selection dialog
                    if (context.mounted) {
                      final selectedAddons = await AddonSelectionDialog.show(
                        context: context,
                        variantDetails: variantDetails,
                        product: product,
                      );
                      
                      if (selectedAddons == null) {
                        // User cancelled
                        return;
                      }
                      
                      // Show loading dialog again for adding to cart
                      if (context.mounted) {
                        CartLoadingDialog.show(context, message: 'Adding to cart...');
                      }
                      
                      // Auto-select single variant if available
                      int? variantId;
                      if (variantDetails.variants.isNotEmpty) {
                        variantId = variantDetails.variants.first.id;
                      }
                      
                      // Add to cart with selected addons
                      bool success = await cartProvider.addToCart(
                        product: product,
                        quantity: 1,
                        variantId: variantId,
                        addons: selectedAddons,
                        skipLoadCart: true,
                      );
                      
                      // If failed due to vendor conflict, it might be a timing issue
                      if (!success && cartProvider.errorMessage != null && 
                          (cartProvider.errorMessage!.toLowerCase().contains('vendor') || 
                           cartProvider.errorMessage!.toLowerCase().contains('existing items'))) {
                        debugPrint('Add to cart failed with vendor conflict after clear, retrying...');
                        
                        // Wait a bit more and retry once
                        await Future.delayed(const Duration(milliseconds: 1000));
                        
                        // Reload cart to ensure it's empty
                        await cartProvider.loadCart();
                        
                        if (cartProvider.itemCount == 0) {
                          // Try again
                          success = await cartProvider.addToCart(
                            product: product,
                            quantity: 1,
                            variantId: variantId,
                            addons: selectedAddons,
                            skipLoadCart: true,
                          );
                        }
                      }
                      
                      // Reload cart
                      if (success) {
                        await cartProvider.loadCart();
                      }
                      
                      // Ensure dialog is closed before showing result
                      if (context.mounted) {
                        CartLoadingDialog.hideForce(context);
                        // Wait for dialog to close
                        await Future.delayed(const Duration(milliseconds: 100));
                      }
                      
                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cart cleared and ${product.name} added'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.green,
                              action: SnackBarAction(
                                label: 'View Cart',
                                textColor: Colors.white,
                                onPressed: () => context.go('/cart'),
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(cartProvider.errorMessage ?? 'Failed to add item to cart'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  } else {
                    // No addons, proceed with normal add to cart
                    // Auto-select single variant if available
                    int? variantId;
                    if (variantDetails.variants.isNotEmpty) {
                      variantId = variantDetails.variants.first.id;
                    }

                    bool success = await cartProvider.addToCart(
                      product: product,
                      quantity: 1,
                      variantId: variantId,
                      skipLoadCart: true,
                    );
                    
                    // If failed due to vendor conflict, it might be a timing issue
                    if (!success && cartProvider.errorMessage != null && 
                        (cartProvider.errorMessage!.toLowerCase().contains('vendor') || 
                         cartProvider.errorMessage!.toLowerCase().contains('existing items'))) {
                      debugPrint('Add to cart failed with vendor conflict after clear, retrying...');
                      
                      // Wait a bit more and retry once
                      await Future.delayed(const Duration(milliseconds: 1000));
                      
                      // Reload cart to ensure it's empty
                      await cartProvider.loadCart();
                      
                      if (cartProvider.itemCount == 0) {
                        // Try again
                        success = await cartProvider.addToCart(
                          product: product,
                          quantity: 1,
                          variantId: variantId,
                          skipLoadCart: true,
                        );
                      }
                    }
                    
                    // Reload cart
                    if (success) {
                      await cartProvider.loadCart();
                    }

                    // Force hide loading dialog
                    if (context.mounted) {
                      CartLoadingDialog.hideForce(context);
                    }

                    // Add a small delay before showing snackbar
                    await Future.delayed(const Duration(milliseconds: 200));

                    if (context.mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Cart cleared and ${product.name} added'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.green,
                            action: SnackBarAction(
                              label: 'View Cart',
                              textColor: Colors.white,
                              onPressed: () => context.go('/cart'),
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(cartProvider.errorMessage ?? 'Failed to add item to cart'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                } catch (e) {
                  debugPrint('Error in clear cart & add: $e');
                  
                  // Force hide loading dialog on error
                  if (context.mounted) {
                    CartLoadingDialog.hideForce(context);
                  }
                  
                  // Add a small delay before showing error
                  await Future.delayed(const Duration(milliseconds: 200));

                  // Show error message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to add item to cart'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Clear Cart & Add'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildYaBalashBagsSection(DashboardSection section) {
    if (section.data.isEmpty) return const SizedBox.shrink();

    // Convert section data to ProductModel list
    final products = section.data
        .map((productJson) => ProductModel.fromJson(productJson))
        .toList();

    return YaBalashBagsSection(products: products);
  }

  static Widget _buildSurpriseBagsSection(DashboardSection section) {
    if (section.data.isEmpty) return const SizedBox.shrink();

    // Convert section data to ProductModel list
    final products = section.data
        .map((productJson) => ProductModel.fromJson(productJson))
        .toList();
    debugPrint("el product is $products");
    return SurpriseBagsSection(products: products);
  }

  static Widget _buildProductImage(ProductModel product) {
    final imageUrl = ImageUtils.buildImageUrl(product.image);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: 140.h,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 140.h,
          color: Colors.grey[200],
          child: Icon(Icons.fastfood, size: 40.sp),
        ),
        errorWidget: (context, url, error) => Container(
          height: 140.h,
          color: Colors.grey[200],
          child: Icon(Icons.fastfood, size: 40.sp),
        ),
      );
    } else {
      return Container(
        height: 140.h,
        width: double.infinity,
        color: Colors.grey[200],
        child: Icon(Icons.fastfood, size: 40.sp),
      );
    }
  }
}
