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
    // context is passed here
    final String? imageUrl = category.image ?? category.icon;

    return GestureDetector(
      onTap: () => onCategoryTap?.call(category),
      child: Card(
        elevation: 3.0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        // context is available here from builder
                        color: _getCategoryColor(context, category.color)
                            .withOpacity(0.3), // Pass context
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: _getCategoryColor(
                                context, category.color), // Pass context
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildFallbackContent(
                              context, category), // Pass context
                    )
                  : _buildFallbackContent(context, category), // Pass context
            ),
            Container(
              height: 60.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.black.withOpacity(0.0),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              child: Text(
                category.name ?? 'Category',
                style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(1, 1),
                      )
                    ]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackContent(BuildContext context, CategoryModel category) {
    // context is passed here
    return Container(
      decoration: BoxDecoration(
        color: _getCategoryColor(context, category.color), // Pass context
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(category
              .type), // No context needed if not using Theme for icon color
          color: Colors.white.withOpacity(0.8),
          size: 30.sp,
        ),
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

  // _getCategoryIcon does not use context if icon colors are hardcoded or not theme-dependent
  IconData _getCategoryIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'food':
        return Icons.restaurant_menu_rounded;
      case 'grocery':
        return Icons.local_grocery_store_rounded;
      case 'pharmacy':
        return Icons.local_pharmacy_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'pizza':
        return Icons.local_pizza_rounded;
      case 'dessert':
        return Icons.cake_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }
}
