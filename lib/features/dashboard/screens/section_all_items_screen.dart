import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/dashboard_section.dart';
import '../../restaurants/models/product_model.dart';
import '../../restaurants/models/restaurant_model.dart';
import '../../restaurants/widgets/restaurant_card_v2.dart';
import '../../cart/providers/cart_provider.dart';
import '../../cart/widgets/addon_selection_dialog.dart';
import '../../../core/widgets/cart_loading_dialog.dart';
import '../../../core/utils/image_utils.dart';
import '../widgets/section_widget_factory.dart';

class SectionAllItemsScreen extends StatefulWidget {
  final DashboardSection section;
  final String sectionType;

  const SectionAllItemsScreen({
    Key? key,
    required this.section,
    required this.sectionType,
  }) : super(key: key);

  @override
  State<SectionAllItemsScreen> createState() => _SectionAllItemsScreenState();
}

class _SectionAllItemsScreenState extends State<SectionAllItemsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _buildViewToggle(),
          ),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180.h,
      floating: false,
      pinned: true,
      backgroundColor: _getSectionColor(widget.sectionType),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.section.getLocalizedTitle(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getSectionColor(widget.sectionType),
                _getSectionColor(widget.sectionType).withOpacity(0.7),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Pattern overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: PatternPainter(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              // Section icon
              Center(
                child: Icon(
                  _getSectionIcon(widget.sectionType),
                  size: 80.sp,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20.sp,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Text(
            '${widget.section.data.length} items',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildToggleButton(
                  icon: Icons.grid_view_rounded,
                  isSelected: _isGridView,
                  onTap: () => setState(() => _isGridView = true),
                ),
                _buildToggleButton(
                  icon: Icons.view_list_rounded,
                  isSelected: !_isGridView,
                  onTap: () => setState(() => _isGridView = false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: isSelected ? _getSectionColor(widget.sectionType) : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[600],
          size: 20.sp,
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Check if this is a vendor/restaurant section
    if (widget.sectionType == 'vendors' || 
        widget.sectionType == 'trending_vendors' ||
        widget.sectionType == 'top_rated') {
      return _buildRestaurantsList();
    } else {
      // Product sections
      return _buildProductsList();
    }
  }

  Widget _buildProductsList() {
    final products = widget.section.data
        .map((productJson) => ProductModel.fromJson(productJson))
        .toList();

    if (_isGridView) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 0.75,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final product = products[index];
              return _buildProductGridCard(product);
            },
            childCount: products.length,
          ),
        ),
      );
    } else {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final product = products[index];
              return _buildProductListCard(product);
            },
            childCount: products.length,
          ),
        ),
      );
    }
  }

  Widget _buildProductGridCard(ProductModel product) {
    final hasDiscount = product.compareAtPrice != null && 
                       product.compareAtPrice! > product.price;
    final discountPercentage = hasDiscount 
        ? ((product.compareAtPrice! - product.price) / product.compareAtPrice! * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    topRight: Radius.circular(20.r),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: _buildProductImage(product),
                  ),
                ),
                // Badges
                Positioned(
                  top: 8.h,
                  left: 8.w,
                  child: _buildProductBadge(widget.sectionType),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '-$discountPercentage%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Product info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.vendor?.name != null) ...[
                      Text(
                        product.vendor!.name,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: _getSectionColor(widget.sectionType),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                    ],
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.rating != null && product.rating! > 0) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14.sp,
                            color: Colors.amber[600],
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            product.rating!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    // Price and add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasDiscount)
                              Text(
                                'AED ${product.compareAtPrice!.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey[500],
                                  decoration: TextDecoration.lineThrough,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            Text(
                              'AED ${product.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: hasDiscount ? Colors.red[600] : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        _buildAddToCartButton(product),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListCard(ProductModel product) {
    final hasDiscount = product.compareAtPrice != null && 
                       product.compareAtPrice! > product.price;
    final discountPercentage = hasDiscount 
        ? ((product.compareAtPrice! - product.price) / product.compareAtPrice! * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    bottomLeft: Radius.circular(20.r),
                  ),
                  child: Container(
                    width: 120.w,
                    height: 120.h,
                    child: _buildProductImage(product),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '-$discountPercentage%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.vendor?.name != null) ...[
                                Text(
                                  product.vendor!.name,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: _getSectionColor(widget.sectionType),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2.h),
                              ],
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
                            ],
                          ),
                        ),
                        _buildProductBadge(widget.sectionType),
                      ],
                    ),
                    if (product.description != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        product.description!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasDiscount)
                                  Text(
                                    'AED ${product.compareAtPrice!.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey[500],
                                      decoration: TextDecoration.lineThrough,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                Text(
                                  'AED ${product.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: hasDiscount ? Colors.red[600] : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            if (product.rating != null && product.rating! > 0) ...[
                              SizedBox(width: 16.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: Colors.amber[50],
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 14.sp,
                                      color: Colors.amber[600],
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      product.rating!.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.amber[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        _buildAddToCartButton(product),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddToCartButton(ProductModel product) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final quantity = cartProvider.getQuantityForProduct(product);

        if (!product.isInStock) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'Out of Stock',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        if (quantity > 0) {
          return Container(
            decoration: BoxDecoration(
              color: _getSectionColor(widget.sectionType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _getSectionColor(widget.sectionType),
                width: 1.5,
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
                    padding: EdgeInsets.all(6.w),
                    child: Icon(
                      Icons.remove,
                      color: _getSectionColor(widget.sectionType),
                      size: 18.sp,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Text(
                    quantity.toString(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: _getSectionColor(widget.sectionType),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => SectionWidgetFactory.handleAddToCart(
                    product, 
                    context, 
                    cartProvider
                  ),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    child: Icon(
                      Icons.add,
                      color: _getSectionColor(widget.sectionType),
                      size: 18.sp,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return GestureDetector(
            onTap: () => SectionWidgetFactory.handleAddToCart(
              product, 
              context, 
              cartProvider
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: _getSectionColor(widget.sectionType),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: _getSectionColor(widget.sectionType).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_shopping_cart_rounded,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildRestaurantsList() {
    final restaurants = widget.section.data
        .map((restaurantJson) => RestaurantModel.fromJson(restaurantJson))
        .toList();

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final restaurant = restaurants[index];
            return RestaurantCardV2(
              restaurant: restaurant,
              isHorizontal: true,
              onTap: () => context.push('/restaurant/${restaurant.id}'),
            );
          },
          childCount: restaurants.length,
        ),
      ),
    );
  }

  Widget _buildProductImage(ProductModel product) {
    final imageUrl = ImageUtils.buildImageUrl(product.image);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: Center(
            child: Icon(
              Icons.fastfood_rounded,
              size: 32.sp,
              color: Colors.grey[400],
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: Center(
            child: Icon(
              Icons.fastfood_rounded,
              size: 32.sp,
              color: Colors.grey[400],
            ),
          ),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            Icons.fastfood_rounded,
            size: 32.sp,
            color: Colors.grey[400],
          ),
        ),
      );
    }
  }

  Widget _buildProductBadge(String sectionType) {
    String badgeText;
    Color badgeColor;
    IconData badgeIcon;

    switch (sectionType) {
      case 'new_products':
        badgeText = 'NEW';
        badgeColor = Colors.green[600]!;
        badgeIcon = Icons.new_releases_rounded;
        break;
      case 'featured_products':
        badgeText = 'FEATURED';
        badgeColor = Colors.blue[600]!;
        badgeIcon = Icons.star_rounded;
        break;
      case 'on_sale':
        badgeText = 'SALE';
        badgeColor = Colors.red[600]!;
        badgeIcon = Icons.local_offer_rounded;
        break;
      case 'best_sellers':
        badgeText = 'BESTSELLER';
        badgeColor = Colors.orange[600]!;
        badgeIcon = Icons.trending_up_rounded;
        break;
      case 'yabalash_bags':
        badgeText = 'YABALASH';
        badgeColor = Colors.purple[600]!;
        badgeIcon = Icons.shopping_bag_rounded;
        break;
      case 'surprise_bags':
        badgeText = 'SURPRISE';
        badgeColor = Colors.orange[600]!;
        badgeIcon = Icons.card_giftcard_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            color: Colors.white,
            size: 14.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            badgeText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSectionColor(String sectionType) {
    switch (sectionType) {
      case 'new_products':
        return Colors.green[600]!;
      case 'featured_products':
        return Colors.blue[600]!;
      case 'on_sale':
        return Colors.red[600]!;
      case 'best_sellers':
        return Colors.orange[600]!;
      case 'yabalash_bags':
        return Colors.purple[600]!;
      case 'surprise_bags':
        return Colors.orange[600]!;
      case 'vendors':
      case 'trending_vendors':
      case 'top_rated':
        return Colors.indigo[600]!;
      default:
        return Colors.purple[600]!;
    }
  }

  IconData _getSectionIcon(String sectionType) {
    switch (sectionType) {
      case 'new_products':
        return Icons.new_releases_rounded;
      case 'featured_products':
        return Icons.star_rounded;
      case 'on_sale':
        return Icons.local_offer_rounded;
      case 'best_sellers':
        return Icons.trending_up_rounded;
      case 'yabalash_bags':
        return Icons.shopping_bag_rounded;
      case 'surprise_bags':
        return Icons.card_giftcard_rounded;
      case 'vendors':
      case 'trending_vendors':
      case 'top_rated':
        return Icons.restaurant_rounded;
      default:
        return Icons.shopping_cart_rounded;
    }
  }
}

// Custom painter for pattern
class PatternPainter extends CustomPainter {
  final Color color;

  PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 30.0;
    
    // Draw diagonal lines
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}