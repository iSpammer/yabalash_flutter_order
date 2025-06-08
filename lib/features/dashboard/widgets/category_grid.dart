import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/category_model.dart'; // Ensure this path is correct

// Assuming CategoryModel has:
// String? id;
// String? name;
// String? image; // Preferential URL for a larger, more detailed category image
// String? icon;  // URL for an icon or smaller image, used as fallback
// String? color; // Hex string for background color fallback
// String? type;  // For fallback icon type

class CategoryGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  final Function(CategoryModel)? onCategoryTap;
  final int crossAxisCount;
  final bool showMoreButton;

  const CategoryGrid({
    Key? key,
    required this.categories,
    this.onCategoryTap,
    this.crossAxisCount = 3, // Defaulted to 3 for potentially larger items
    this.showMoreButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // context is available here
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final int itemsBeforeMore = crossAxisCount * 2 - 1;
    final bool shouldShowMoreButtonAndLimit =
        showMoreButton && categories.length > itemsBeforeMore;

    final displayCategories = shouldShowMoreButtonAndLimit
        ? categories.take(itemsBeforeMore).toList()
        : categories;

    final itemCount =
        displayCategories.length + (shouldShowMoreButtonAndLimit ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.9,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // context is available here too
        if (shouldShowMoreButtonAndLimit && index == displayCategories.length) {
          return _buildMoreButton(context); // Pass context
        }

        final category = displayCategories[index];
        return _buildCategoryItem(context, category); // Pass context
      },
    );
  }

  Widget _buildCategoryItem(BuildContext context, CategoryModel category) {
    // Extract the image URL from the complex structure
    String? imageUrl;
    
    // Check if category has icon map with image_path
    if (category.icon is Map) {
      final iconMap = category.icon as Map;
      imageUrl = iconMap['image_path'] as String?;
    } else if (category.icon is String) {
      imageUrl = category.icon as String;
    }
    
    // Fallback to image field if icon doesn't have valid URL
    if (imageUrl == null || imageUrl.isEmpty) {
      if (category.image is Map) {
        final imageMap = category.image as Map;
        imageUrl = imageMap['image_path'] as String?;
      } else if (category.image is String) {
        imageUrl = category.image as String;
      }
    }

    return GestureDetector(
      onTap: () => onCategoryTap?.call(category),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Background image or color
              Positioned.fill(
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _getCategoryAccentColor(category.name),
                                _getCategoryAccentColor(category.name).withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _getCategoryIcon(category.name),
                              color: Colors.white.withOpacity(0.5),
                              size: 36.sp,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _buildFallbackContent(context, category),
                      )
                    : _buildFallbackContent(context, category),
              ),
              // Gradient overlay for better text visibility
              Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              // Category name with icon
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCategoryIcon(category.name),
                        color: Colors.white,
                        size: 24.sp,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        category.name ?? 'Category',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackContent(BuildContext context, CategoryModel category) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryAccentColor(category.name),
            _getCategoryAccentColor(category.name).withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              _getCategoryIcon(category.name),
              color: Colors.white.withOpacity(0.3),
              size: 48.sp,
            ),
          ),
          Positioned(
            bottom: 12.h,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category.name),
                  color: Colors.white,
                  size: 24.sp,
                ),
                SizedBox(height: 4.h),
                Text(
                  category.name ?? 'Category',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    // context is passed here
    return GestureDetector(
      onTap: () {
        print("More button tapped - Navigate to all categories");
        // Example: if (context.mounted) Navigator.pushNamed(context, '/all-categories');
      },
      child: Card(
        elevation: 2.0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest, // Using a more semantic color
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.apps_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 28.sp,
              ),
              SizedBox(height: 8.h),
              Text(
                'More', // Localize this
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Corrected: Added BuildContext parameter
  Color _getCategoryColor(BuildContext context, String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7);
    }

    try {
      final String colorHex =
          colorString.startsWith('#') ? colorString.substring(1) : colorString;

      final String finalHex = colorHex.length == 6
          ? 'FF$colorHex'
          : colorHex.length == 8
              ? colorHex
              : 'FFFF0000'; // Fallback red for malformed length

      if (finalHex.length == 8) {
        return Color(int.parse(finalHex, radix: 16));
      } else {
        print(
            "Invalid hex color format after processing: $finalHex from original: $colorString");
        return Theme.of(context).colorScheme.errorContainer;
      }
    } catch (e) {
      print("Error parsing color string '$colorString': $e");
      return Theme.of(context).colorScheme.errorContainer;
    }
  }

  // Get category-specific accent color
  Color _getCategoryAccentColor(String? categoryName) {
    switch (categoryName?.toLowerCase()) {
      case 'restaurants':
        return Colors.orange[700]!;
      case 'groceries':
      case 'supermarkets':
        return Colors.green[700]!;
      case 'bakeries':
        return Colors.brown[600]!;
      case 'coffee shops':
      case 'coffeeshops':
        return Colors.brown[800]!;
      case 'pharmacy':
        return Colors.teal[700]!;
      case 'desserts':
        return Colors.pink[400]!;
      default:
        return Colors.deepPurple[600]!;
    }
  }

  // Get category icon based on name
  IconData _getCategoryIcon(String? categoryName) {
    switch (categoryName?.toLowerCase()) {
      case 'restaurants':
        return Icons.restaurant_rounded;
      case 'groceries':
      case 'supermarkets':
        return Icons.shopping_basket_rounded;
      case 'bakeries':
        return Icons.bakery_dining_rounded;
      case 'coffee shops':
      case 'coffeeshops':
        return Icons.coffee_rounded;
      case 'pharmacy':
        return Icons.local_pharmacy_rounded;
      case 'desserts':
        return Icons.cake_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }
}
