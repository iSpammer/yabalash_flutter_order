import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/utils/image_utils.dart';
import '../../../core/utils/html_utils.dart';
import '../../../core/utils/auth_helper.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/cart_loading_dialog.dart';
import '../providers/product_detail_provider.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../models/offer_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/delivery_pickup_toggle.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ProductDetailProvider _provider;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ProductDetailProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.loadProductDetails(widget.productId);
      // Also load cart to ensure we have the current vendor ID
      context.read<CartProvider>().loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer<ProductDetailProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.product == null) {
            return _buildLoadingState();
          }

          if (provider.errorMessage != null && provider.product == null) {
            return _buildErrorState();
          }

          if (provider.product == null) {
            return _buildNotFoundState();
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(provider.product!),
              _buildImageGallery(provider),
              _buildProductInfo(provider),
              _buildVariantsSection(provider),
              _buildOffersSection(provider),
              _buildDescription(provider.product!),
              _buildReviewsSection(provider),
              _buildRelatedProducts(provider),
              SliverToBoxAdapter(
                  child: SizedBox(height: 100.h)), // Space for bottom bar
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<ProductDetailProvider>(
        builder: (context, provider, _) {
          if (provider.product == null) return const SizedBox.shrink();
          return _buildBottomBar(provider);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image placeholder with shimmer
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 300.h,
                width: double.infinity,
                color: Colors.white,
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title placeholder
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 24.h,
                      width: 200.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Price placeholder
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 20.h,
                      width: 100.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Description placeholders
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 16.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 16.h,
                      width: 250.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Loading indicator
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        SizedBox(height: 16.h),
                        Text(
                          'Loading product details...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'Failed to load product',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _provider.errorMessage ?? 'Unknown error occurred',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            CustomButton(
              text: 'Try Again',
              onPressed: () => _provider.loadProductDetails(widget.productId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'Product not found',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'The product you\'re looking for doesn\'t exist or has been removed.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            CustomButton(
              text: 'Go Back',
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ProductModel product) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Colors.black87,
          size: 24.sp,
        ),
        onPressed: () => context.pop(),
      ),
      title: Text(
        product.name,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.share_outlined,
            color: Colors.black87,
            size: 24.sp,
          ),
          onPressed: () => _shareProduct(product),
        ),
      ],
    );
  }

  Widget _buildImageGallery(ProductDetailProvider provider) {
    final product = provider.product!;
    final List<String> images = [];

    // Extract images from media array
    if (product.media != null && product.media!.isNotEmpty) {
      for (var media in product.media!) {
        final imageUrl = media.image?.path?.fullImageUrl;
        if (imageUrl != null) {
          images.add(imageUrl);
        }
      }
    }

    // Fallback to product image if no media
    if (images.isEmpty && product.image != null) {
      images.add(product.image!);
    }

    if (images.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 300.h,
          color: Colors.grey[200],
          child: Icon(
            Icons.fastfood,
            size: 64.sp,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Container(
        height: 300.h,
        color: Colors.white,
        child: Stack(
          children: [
            CarouselSlider(
              carouselController: _carouselController,
              options: CarouselOptions(
                height: 300.h,
                viewportFraction: 1.0,
                enableInfiniteScroll: images.length > 1,
                autoPlay: images.length > 1,
                autoPlayInterval: const Duration(seconds: 5),
                onPageChanged: (index, reason) {
                  provider.setSelectedImageIndex(index);
                },
              ),
              items: images.map((imageUrl) {
                return GestureDetector(
                  onTap: () =>
                      _showImageViewer(images, provider.selectedImageIndex),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.fastfood,
                        size: 64.sp,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (images.length > 1)
              Positioned(
                bottom: 16.h,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: images.asMap().entries.map((entry) {
                    return Container(
                      width: 8.w,
                      height: 8.w,
                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: provider.selectedImageIndex == entry.key
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo(ProductDetailProvider provider) {
    final product = provider.product!;

    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tags/Badges
            Row(
              children: [
                if (product.isFeatured)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'FEATURED',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                if (product.isNew)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'NEW',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
              ],
            ),

            if (product.isFeatured || product.isNew) SizedBox(height: 8.h),

            // Product name
            Text(
              product.name,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: 8.h),

            // Vendor info
            if (product.vendor != null)
              InkWell(
                onTap: () {
                  context.push('/restaurant/${product.vendorId}');
                },
                child: Row(
                  children: [
                    if (product.vendor!.logo != null &&
                        product.vendor!.logo!.fullImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: CachedNetworkImage(
                          imageUrl: product.vendor!.logo!.fullImageUrl!,
                          width: 24.w,
                          height: 24.w,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            width: 24.w,
                            height: 24.w,
                            color: Colors.grey[300],
                            child: Icon(Icons.store,
                                size: 16.sp, color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    if (product.vendor!.logo != null) SizedBox(width: 8.w),
                    Text(
                      product.vendor!.name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (product.vendor!.description != null) ...[
                      Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[400],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          product.vendor!.description!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            SizedBox(height: 8.h),

            // Category
            if (product.categoryName != null)
              Text(
                product.categoryName!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),

            SizedBox(height: 12.h),

            // Time-based availability indicator
            if (product.isLimitedTime) ...[
              _buildTimeAvailabilityIndicator(product),
              SizedBox(height: 12.h),
            ],

            // Rating
            if (product.rating != null && product.rating! > 0)
              Row(
                children: [
                  RatingBarIndicator(
                    rating: product.rating!,
                    itemBuilder: (context, index) => Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    itemCount: 5,
                    itemSize: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${product.rating!.toStringAsFixed(1)} (${product.reviewCount ?? 0} reviews)',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

            SizedBox(height: 16.h),

            // Price section
            Row(
              children: [
                Text(
                  provider.formattedPrice,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                if (provider.hasDiscount) ...[
                  SizedBox(width: 8.w),
                  Text(
                    provider.formattedComparePrice!,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[500],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      provider.discountPercentage!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            SizedBox(height: 16.h),

            // Stock status
            if (!product.sellWhenOutOfStock && product.hasInventory)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: product.isInStock ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(
                    color: product.isInStock ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                // child: Text(
                //   product.isInStock
                //       ? product.stockQuantity != null &&
                //               product.stockQuantity! > 0
                //           ? 'In Stock (${product.stockQuantity} available)'
                //           : 'In Stock'
                //       : 'Out of Stock',

                child: Text(
                  product.isInStock
                      ? product.stockQuantity != null &&
                              product.stockQuantity! > 0
                          ? 'In Stock'
                          : 'In Stock'
                      : 'Out of Stock',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color:
                        product.isInStock ? Colors.green[800] : Colors.red[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Product details
            if (product.weight != null || product.preparationTime != null) ...[
              SizedBox(height: 16.h),
              Divider(height: 1, color: Colors.grey[300]),
              SizedBox(height: 16.h),
              Row(
                children: [
                  if (product.weight != null)
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.scale,
                              size: 16.sp, color: Colors.grey[600]),
                          SizedBox(width: 4.w),
                          Text(
                            '${product.weight} ${product.weightUnit ?? 'g'}',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (product.preparationTime != null)
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 16.sp, color: Colors.grey[600]),
                          SizedBox(width: 4.w),
                          Text(
                            product.preparationTime!,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],

            // SKU if available
            // if (product.sku != null) ...[
            //   SizedBox(height: 8.h),
            //   Text(
            //     'SKU: ${product.sku}',
            //     style: TextStyle(
            //       fontSize: 11.sp,
            //       color: Colors.grey[500],
            //     ),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }

  Widget _buildVariantsSection(ProductDetailProvider provider) {
    final product = provider.product!;

    if (!product.hasVariants ||
        product.variants == null ||
        product.variants!.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(top: 8.h),
        color: Colors.white,
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Variant',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            ...product.variants!.map((variant) {
              final isSelected =
                  provider.selectedVariantId == variant.id.toString();

              return GestureDetector(
                onTap: () {
                  provider.setSelectedVariant(variant.id.toString());
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              variant.displayName,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            if (variant.sku != null) ...[
                              SizedBox(height: 4.h),
                              Text(
                                'SKU: ${variant.sku}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'AED ${variant.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          if (variant.compareAtPrice != null &&
                              variant.compareAtPrice! > variant.price)
                            Text(
                              'AED ${variant.compareAtPrice!.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          if (variant.stockQuantity != null &&
                              variant.stockQuantity! <= 5)
                            Text(
                              variant.stockQuantity! > 0
                                  ? 'Only ${variant.stockQuantity} left'
                                  : 'Out of stock',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: variant.stockQuantity! > 0
                                    ? Colors.orange
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersSection(ProductDetailProvider provider) {
    if (provider.offers.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(top: 8.h),
        color: Colors.white,
        padding: EdgeInsets.all(16.w),
        child: GestureDetector(
          onTap: () => _showOffersDialog(provider.offers),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[100]!, Colors.orange[50]!],
              ),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.orange[300]!, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_offer,
                  color: Colors.orange[700],
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    '${provider.offers.length} offer${provider.offers.length > 1 ? 's' : ''} available',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
                Text(
                  'VIEW ALL',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange[700],
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.orange[700],
                  size: 14.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescription(ProductModel product) {
    final hasDescription =
        product.description != null && product.description!.isNotEmpty;
    final hasBodyHtml =
        product.bodyHtml != null && product.bodyHtml!.isNotEmpty;

    if (!hasDescription && !hasBodyHtml) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(top: 8.h),
        color: Colors.white,
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              hasBodyHtml
                  ? HtmlUtils.safeExtractText(product.bodyHtml)
                  : HtmlUtils.safeExtractText(product.description),
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(ProductDetailProvider provider) {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(top: 8.h),
        color: Colors.white,
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer Reviews',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                _buildReviewButton(provider),
              ],
            ),
            if (provider.reviews.isNotEmpty) ...[
              SizedBox(height: 12.h),

              // Average rating
              Row(
                children: [
                  RatingBarIndicator(
                    rating: provider.averageRating,
                    itemBuilder: (context, index) => Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    itemCount: 5,
                    itemSize: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${provider.averageRating.toStringAsFixed(1)} out of 5',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Review list
              ...provider.reviews
                  .take(3)
                  .map((review) => _buildReviewItem(review)),

              if (provider.reviews.length > 3)
                Center(
                  child: TextButton(
                    onPressed: () => _showAllReviews(provider.reviews),
                    child: Text('View All Reviews'),
                  ),
                ),
            ] else ...[
              SizedBox(height: 12.h),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 48.sp,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'No reviews yet',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Be the first to review this product!',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewButton(ProductDetailProvider provider) {
    if (provider.isCheckingReviewEligibility) {
      return SizedBox(
        width: 16.w,
        height: 16.w,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (provider.canUserReview) {
      return TextButton(
        onPressed: () => _showWriteReviewDialog(),
        child: Text(
          'Write Review',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      return Tooltip(
        message: provider.reviewEligibilityReason ??
            'Order this product to leave a review',
        child: TextButton(
          onPressed: null, // Disabled
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 16.sp,
                color: Colors.grey[400],
              ),
              SizedBox(width: 4.w),
              Text(
                'Review Locked',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildReviewItem(ReviewModel review) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: Colors.grey[300],
                child: Text(
                  review.userName?.isNotEmpty == true
                      ? review.userName![0].toUpperCase()
                      : 'A',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? 'Anonymous',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    RatingBarIndicator(
                      rating: review.rating,
                      itemBuilder: (context, index) => Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      itemCount: 5,
                      itemSize: 12.sp,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              review.reviewText!,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
          if (review.reviewImages != null &&
              review.reviewImages!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            SizedBox(
              height: 80.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.reviewImages!.length,
                itemBuilder: (context, index) {
                  final imageUrl = review.reviewImages![index];
                  return Container(
                    margin: EdgeInsets.only(right: 8.w),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 80.w,
                        height: 80.h,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80.w,
                          height: 80.h,
                          color: Colors.grey[200],
                          child: Icon(Icons.image, size: 24.sp),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 80.w,
                          height: 80.h,
                          color: Colors.grey[200],
                          child: Icon(Icons.broken_image, size: 24.sp),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRelatedProducts(ProductDetailProvider provider) {
    if (provider.relatedProducts.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(top: 8.h),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Related Products',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(
              height: 200.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                itemCount: provider.relatedProducts.length,
                itemBuilder: (context, index) {
                  final product = provider.relatedProducts[index];
                  return Container(
                    width: 140.w,
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    child: _buildRelatedProductCard(product),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        context.push('/product/${product.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                topRight: Radius.circular(8.r),
              ),
              child: CachedNetworkImage(
                imageUrl: ImageUtils.buildImageUrl(product.image) ?? '',
                width: double.infinity,
                height: 100.h,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 100.h,
                  color: Colors.grey[200],
                  child: Icon(Icons.fastfood, size: 32.sp),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 100.h,
                  color: Colors.grey[200],
                  child: Icon(Icons.fastfood, size: 32.sp),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'AED ${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ProductDetailProvider provider) {
    final product = provider.product!;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quantity selector
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: provider.quantity > 1
                        ? provider.decrementQuantity
                        : null,
                    icon: Icon(
                      Icons.remove,
                      size: 20.sp,
                      color: provider.quantity > 1
                          ? Colors.black87
                          : Colors.grey[400],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      provider.quantity.toString(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: provider.incrementQuantity,
                    icon: Icon(
                      Icons.add,
                      size: 20.sp,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 16.w),

            // Add to cart button
            Expanded(
              child: CustomButton(
                text: _isAddingToCart
                    ? 'Adding...'
                    : provider.totalPrice >= 100 
                        ? 'Add - ${provider.totalPrice.toStringAsFixed(0)}'
                        : 'Add to Cart - ${provider.totalPrice.toStringAsFixed(0)}',
                onPressed: product.isInStock && !_isAddingToCart
                    ? () => _addToCart(provider)
                    : null,
                icon: _isAddingToCart
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareProduct(ProductModel product) {
    // Generate the share URL in format: https://yabalash.com/{restaurant-slug}/product/{product-slug}
    String shareUrl = 'https://yabalash.com';

    if (product.vendor?.slug != null && product.urlSlug != null) {
      shareUrl =
          'https://yabalash.com/${product.vendor!.slug}/product/${product.urlSlug}';
    } else {
      // Fallback to basic product URL
      shareUrl = 'https://yabalash.com/product/${product.id}';
    }

    // Create comprehensive share text
    final vendorInfo =
        product.vendor?.name != null ? ' from ${product.vendor!.name}' : '';
    final priceInfo =
        product.price > 0 ? '\n💰 AED ${product.price.toStringAsFixed(2)}' : '';
    final originalPriceInfo = product.compareAtPrice != null &&
            product.compareAtPrice! > product.price
        ? ' (was AED ${product.compareAtPrice!.toStringAsFixed(2)})'
        : '';

    final shareText = '''🍽️ ${product.name}$vendorInfo

${product.description ?? 'Delicious food waiting for you!'}$priceInfo$originalPriceInfo

🔗 Order now: $shareUrl

📱 Download Yabalash app for the best food delivery experience!''';

    Share.share(shareText);
  }

  void _showImageViewer(List<String> images, int initialIndex) {
    // TODO: Implement full-screen image viewer
    // For now, we'll show a simple dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: SizedBox(
          height: 400.h,
          child: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: ImageUtils.buildImageUrl(images[index]) ?? '',
                fit: BoxFit.contain,
              );
            },
          ),
        ),
      ),
    );
  }

  void _showOffersDialog(List<OfferModel> offers) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Available Offers',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                    ),
                    if (offer.shortDescription != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        offer.shortDescription!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.r),
                              border: Border.all(
                                color: Colors.orange[300]!,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Text(
                              offer.promoCode ?? offer.name,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[800],
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(
                                text: offer.promoCode ?? offer.name));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Promo code copied!'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.orange[600],
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'TAP TO COPY',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showWriteReviewDialog() {
    double rating = 5.0;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Write a Review',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rating',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              RatingBar.builder(
                initialRating: rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: EdgeInsets.symmetric(horizontal: 4.w),
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (newRating) {
                  setState(() {
                    rating = newRating;
                  });
                },
              ),
              SizedBox(height: 16.h),
              Text(
                'Review',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: reviewController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your experience with this product...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            Consumer<ProductDetailProvider>(
              builder: (context, provider, _) => TextButton(
                onPressed: provider.isSubmittingReview
                    ? null
                    : () async {
                        if (reviewController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please write a review'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final success = await provider.submitReview(
                          rating: rating,
                          reviewText: reviewController.text.trim(),
                        );

                        if (!context.mounted) return;
                        Navigator.of(context).pop();

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Review submitted successfully!'
                                  : 'Failed to submit review. Please try again.',
                            ),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                          ),
                        );
                      },
                child: provider.isSubmittingReview
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllReviews(List<ReviewModel> reviews) {
    // TODO: Navigate to a dedicated reviews page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('All Reviews'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400.h,
          child: ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) => _buildReviewItem(reviews[index]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _addToCart(ProductDetailProvider provider) async {
    // Check if user is logged in
    if (!AuthHelper.checkAuthAndShowPrompt(context,
        message: 'Please login to add items to your cart.')) {
      return;
    }

    final cartProvider = context.read<CartProvider>();
    final dashboardProvider = context.read<DashboardProvider>();
    final product = provider.product!;

    // Sync delivery mode from dashboard without reloading
    if (dashboardProvider.deliveryMode != cartProvider.deliveryMode) {
      cartProvider.setDeliveryMode(dashboardProvider.deliveryMode,
          skipReload: true);
    }

    // Check if product is active first
    // if (!product.isActive) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('This product is currently unavailable'),
    //       backgroundColor: Colors.red,
    //       duration: Duration(seconds: 2),
    //     ),
    //   );
    //   return;
    // }

    // Check vendor conflict before trying to add
    if (cartProvider.currentVendorId != null &&
        cartProvider.currentVendorId != product.vendorId) {
      _showVendorConflictDialog(cartProvider, product, provider.quantity);
      return;
    }

    // Show loading indicator
    setState(() {
      _isAddingToCart = true;
    });

    // Show loading dialog
    CartLoadingDialog.show(context);

    try {
      // Parse variant ID to int if selected
      int? variantId;
      if (provider.selectedVariantId != null) {
        variantId = int.tryParse(provider.selectedVariantId!);
      }

      // Convert addon IDs to proper format
      List<Map<String, dynamic>>? addons;
      if (provider.selectedAddonIds.isNotEmpty && product.addons != null) {
        addons = provider.selectedAddonIds.map((addonId) {
          final addon = product.addons!.firstWhere(
            (a) => a.id.toString() == addonId,
            orElse: () => product.addons!.first,
          );
          return {
            'id': addon.id,
            'option_id': addon.options?.first.id ?? addon.id,
          };
        }).toList();
      }

      // Get delivery mode from dashboard provider
      final dashboardProvider = context.read<DashboardProvider>();

      // Call addToCart with all parameters including type
      final success = await cartProvider.addToCart(
        product: product,
        quantity: provider.quantity,
        variantId: variantId,
        addons: addons,
        type: dashboardProvider.deliveryMode == DeliveryMode.delivery
            ? 'delivery'
            : 'takeaway',
      );

      // Hide loading indicator and dialog
      if (mounted) {
        CartLoadingDialog.hide(context);
        setState(() {
          _isAddingToCart = false;
        });
      }

      if (!mounted) return;

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
        // Check if this is a vendor conflict error from the API
        if (cartProvider.errorMessage != null &&
            (cartProvider.errorMessage!.toLowerCase().contains('vendor') ||
                cartProvider.errorMessage!
                    .toLowerCase()
                    .contains('another vendor') ||
                cartProvider.errorMessage!
                    .toLowerCase()
                    .contains('existing items'))) {
          debugPrint(
              'Showing vendor conflict dialog for: ${cartProvider.errorMessage}');
          _showVendorConflictDialog(cartProvider, product, provider.quantity);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  cartProvider.errorMessage ?? 'Failed to add item to cart'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator and dialog
      if (mounted) {
        CartLoadingDialog.hide(context);
        setState(() {
          _isAddingToCart = false;
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add item to cart: ${e.toString()}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showVendorConflictDialog(
      CartProvider cartProvider, ProductModel product, int quantity) {
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
                if (cartProvider.currentVendorId != null) {
                  context.push('/restaurant/${cartProvider.currentVendorId}');
                }
              },
              child: const Text('Browse Current Restaurant'),
            ),
            TextButton(
              onPressed: () async {
                // Get the provider before any async operations
                final provider = context.read<ProductDetailProvider>();
                Navigator.of(dialogContext).pop();

                // Show loading dialog for clearing cart and adding new item
                CartLoadingDialog.show(context,
                    message: 'Clearing cart and adding item...');

                await cartProvider.clearCart();

                // Parse variant ID to int if selected
                int? variantId;
                if (provider.selectedVariantId != null) {
                  variantId = int.tryParse(provider.selectedVariantId!);
                }

                // Convert addon IDs to proper format
                List<Map<String, dynamic>>? addons;
                if (provider.selectedAddonIds.isNotEmpty &&
                    product.addons != null) {
                  addons = provider.selectedAddonIds.map((addonId) {
                    final addon = product.addons!.firstWhere(
                      (a) => a.id.toString() == addonId,
                      orElse: () => product.addons!.first,
                    );
                    return {
                      'id': addon.id,
                      'option_id': addon.options?.first.id ?? addon.id,
                    };
                  }).toList();
                }

                // Get delivery mode from dashboard provider
                final dashboardProvider = context.read<DashboardProvider>();

                final success = await cartProvider.addToCart(
                  product: product,
                  quantity: quantity,
                  variantId: variantId,
                  addons: addons,
                  type: dashboardProvider.deliveryMode == DeliveryMode.delivery
                      ? 'delivery'
                      : 'takeaway',
                );

                // Hide loading dialog
                if (mounted) {
                  CartLoadingDialog.hide(context);
                }

                if (!mounted) return;

                if (success) {
                  // Force close any remaining dialogs before showing snackbar
                  CartLoadingDialog.hideForce(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cart cleared and ${product.name} added'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(cartProvider.errorMessage ??
                          'Failed to add item to cart'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Clear Cart & Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeAvailabilityIndicator(ProductModel product) {
    if (!product.isLimitedTime) {
      return const SizedBox.shrink();
    }

    // Check if product is currently available
    if (product.isCurrentlyAvailable) {
      // Show expiry time if available
      final timeUntilExpires = product.timeUntilExpires;
      if (timeUntilExpires != null) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16.sp,
                    color: Colors.orange[700],
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Limited Time Offer',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'Available for ${_formatDuration(timeUntilExpires)} more',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.orange[600],
                ),
              ),
            ],
          ),
        );
      } else {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 16.sp,
                color: Colors.green[700],
              ),
              SizedBox(width: 8.w),
              Text(
                'Limited Time Offer Available Now!',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // Show when it will be available
      final timeUntilAvailable = product.timeUntilAvailable;
      if (timeUntilAvailable != null) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16.sp,
                    color: Colors.blue[700],
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'Available in ${_formatDuration(timeUntilAvailable)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
        );
      } else {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.cancel,
                size: 16.sp,
                color: Colors.red[700],
              ),
              SizedBox(width: 8.w),
              Text(
                'No Longer Available',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
