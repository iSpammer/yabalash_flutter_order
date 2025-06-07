import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/category_provider.dart';
import '../../../core/widgets/custom_button.dart';

class CategoryFiltersWidget extends StatefulWidget {
  final CategoryProvider provider;
  final int categoryId;
  final ScrollController scrollController;

  const CategoryFiltersWidget({
    super.key,
    required this.provider,
    required this.categoryId,
    required this.scrollController,
  });

  @override
  State<CategoryFiltersWidget> createState() => _CategoryFiltersWidgetState();
}

class _CategoryFiltersWidgetState extends State<CategoryFiltersWidget> {
  late double _tempMinPrice;
  late double _tempMaxPrice;
  double? _tempMinRating;
  bool _tempInStockOnly = false;

  @override
  void initState() {
    super.initState();
    _tempMinPrice = widget.provider.currentMinPrice;
    _tempMaxPrice = widget.provider.currentMaxPrice;
    _tempMinRating = widget.provider.filters.minRating;
    _tempInStockOnly = widget.provider.filters.inStockOnly ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 8.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: Colors.grey[200]),
          
          // Filters content
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: EdgeInsets.all(20.w),
              children: [
                _buildPriceRangeSection(),
                SizedBox(height: 24.h),
                _buildRatingSection(),
                SizedBox(height: 24.h),
                _buildAvailabilitySection(),
                SizedBox(height: 40.h),
              ],
            ),
          ),
          
          // Apply button
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Apply Filters',
                      onPressed: _applyFilters,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        
        // Price display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'AED ${_tempMinPrice.toInt()}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 12.w),
              width: 20.w,
              height: 2.h,
              color: Colors.grey[300],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'AED ${_tempMaxPrice.toInt()}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16.h),
        
        // Price range slider
        RangeSlider(
          values: RangeValues(_tempMinPrice, _tempMaxPrice),
          min: widget.provider.minPrice,
          max: widget.provider.maxPrice,
          divisions: 50,
          labels: RangeLabels(
            'AED ${_tempMinPrice.toInt()}',
            'AED ${_tempMaxPrice.toInt()}',
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _tempMinPrice = values.start;
              _tempMaxPrice = values.end;
            });
          },
        ),
        
        // Quick price options
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _buildPriceChip('Under AED 100', 0, 100),
            _buildPriceChip('AED 100 - AED 250', 100, 250),
            _buildPriceChip('AED 250 - AED 500', 250, 500),
            _buildPriceChip('Above AED 500', 500, widget.provider.maxPrice),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceChip(String label, double minPrice, double maxPrice) {
    final isSelected = _tempMinPrice <= minPrice && _tempMaxPrice >= maxPrice;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _tempMinPrice = minPrice;
          _tempMaxPrice = maxPrice;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _buildRatingChip('Any', null),
            _buildRatingChip('4.0+', 4.0),
            _buildRatingChip('4.5+', 4.5),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingChip(String label, double? rating) {
    final isSelected = _tempMinRating == rating;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _tempMinRating = rating;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rating != null) ...[
              Icon(
                Icons.star,
                size: 16.sp,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
              ),
              SizedBox(width: 4.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: SwitchListTile(
            title: Text(
              'In stock only',
              style: TextStyle(fontSize: 14.sp),
            ),
            subtitle: Text(
              'Show only products that are currently available',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
            value: _tempInStockOnly,
            onChanged: (value) {
              setState(() {
                _tempInStockOnly = value;
              });
            },
            activeColor: Theme.of(context).primaryColor,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
          ),
        ),
      ],
    );
  }

  void _applyFilters() {
    // Apply price range
    widget.provider.applyPriceRange(
      widget.categoryId,
      _tempMinPrice,
      _tempMaxPrice,
    );
    
    // Apply rating filter
    widget.provider.applyRatingFilter(widget.categoryId, _tempMinRating);
    
    // Apply in-stock filter
    if (_tempInStockOnly != (widget.provider.filters.inStockOnly ?? false)) {
      widget.provider.toggleInStockFilter(widget.categoryId);
    }
    
    Navigator.pop(context);
  }

  void _clearAllFilters() {
    setState(() {
      _tempMinPrice = widget.provider.minPrice;
      _tempMaxPrice = widget.provider.maxPrice;
      _tempMinRating = null;
      _tempInStockOnly = false;
    });
    
    widget.provider.clearAllFilters(widget.categoryId);
    Navigator.pop(context);
  }
}