import '../../../core/utils/image_utils.dart';
import '../../../core/utils/html_utils.dart';

class CategoryDetailModel {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final String? bannerImage;
  final String? icon;
  final bool isActive;
  final int? sortOrder;
  final String? color;
  final String? type;
  final int? productCount;
  final Map<String, dynamic>? meta;

  CategoryDetailModel({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.bannerImage,
    this.icon,
    required this.isActive,
    this.sortOrder,
    this.color,
    this.type,
    this.productCount,
    this.meta,
  });

  factory CategoryDetailModel.fromJson(Map<String, dynamic> json) {
    // Handle nested translation array for name and description
    String? categoryName = json['name'];
    String? categoryDescription = json['description'];
    
    if (categoryName == null && json['translation'] is List) {
      final translations = json['translation'] as List;
      if (translations.isNotEmpty && translations[0] is Map) {
        categoryName = translations[0]['name'];
        categoryDescription = translations[0]['description'];
      }
    }
    
    // Handle nested image and icon objects
    String? imageUrl = ImageUtils.buildImageUrl(json['image']);
    String? bannerImageUrl = ImageUtils.buildImageUrl(json['banner_image'] ?? json['banner']);
    String? iconUrl = ImageUtils.buildCategoryIconUrl(json['icon']);
    
    // Safe parsing for integer fields
    int categoryId = 0;
    if (json['id'] is int) {
      categoryId = json['id'];
    } else if (json['id'] is String) {
      categoryId = int.tryParse(json['id']) ?? 0;
    }
    
    int? sortOrderValue;
    if (json['sort_order'] != null) {
      if (json['sort_order'] is int) {
        sortOrderValue = json['sort_order'];
      } else if (json['sort_order'] is String) {
        sortOrderValue = int.tryParse(json['sort_order']);
      }
    } else if (json['position'] != null) {
      if (json['position'] is int) {
        sortOrderValue = json['position'];
      } else if (json['position'] is String) {
        sortOrderValue = int.tryParse(json['position']);
      }
    }

    int? productCountValue;
    if (json['product_count'] != null) {
      if (json['product_count'] is int) {
        productCountValue = json['product_count'];
      } else if (json['product_count'] is String) {
        productCountValue = int.tryParse(json['product_count']);
      }
    } else if (json['products_count'] != null) {
      if (json['products_count'] is int) {
        productCountValue = json['products_count'];
      } else if (json['products_count'] is String) {
        productCountValue = int.tryParse(json['products_count']);
      }
    }
    
    return CategoryDetailModel(
      id: categoryId,
      name: categoryName ?? 'Unknown Category',
      description: HtmlUtils.safeExtractText(categoryDescription),
      image: imageUrl,
      bannerImage: bannerImageUrl,
      icon: iconUrl,
      isActive: json['is_active'] == 1 || json['status'] == 1 || json['is_active'] == true,
      sortOrder: sortOrderValue,
      color: json['color']?.toString(),
      type: json['type']?.toString() ?? json['slug']?.toString(),
      productCount: productCountValue,
      meta: json['meta'] is Map<String, dynamic> ? json['meta'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'banner_image': bannerImage,
      'icon': icon,
      'is_active': isActive,
      'sort_order': sortOrder,
      'color': color,
      'type': type,
      'product_count': productCount,
      'meta': meta,
    };
  }

  // Helper method to get display image (banner first, then regular image)
  String? get displayImage => bannerImage ?? image;
  
  // Helper method for sharing
  String get shareText => 'Check out $name category${description != null ? ': $description' : ''}';
}

// Model for category products API response
class CategoryProductsResponse {
  final List<Map<String, dynamic>> products;
  final CategoryPagination pagination;
  final CategoryFilters? appliedFilters;

  CategoryProductsResponse({
    required this.products,
    required this.pagination,
    this.appliedFilters,
  });

  factory CategoryProductsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    
    return CategoryProductsResponse(
      products: List<Map<String, dynamic>>.from(data['products'] ?? data['data'] ?? []),
      pagination: CategoryPagination.fromJson(data['pagination'] ?? {}),
      appliedFilters: data['filters'] != null 
          ? CategoryFilters.fromJson(data['filters']) 
          : null,
    );
  }
}

class CategoryPagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int perPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  CategoryPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.perPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory CategoryPagination.fromJson(Map<String, dynamic> json) {
    final currentPage = json['current_page'] ?? json['page'] ?? 1;
    final totalPages = json['total_pages'] ?? json['last_page'] ?? 1;
    final totalItems = json['total'] ?? json['total_items'] ?? 0;
    final perPage = json['per_page'] ?? json['limit'] ?? 20;

    return CategoryPagination(
      currentPage: currentPage is int ? currentPage : int.tryParse(currentPage.toString()) ?? 1,
      totalPages: totalPages is int ? totalPages : int.tryParse(totalPages.toString()) ?? 1,
      totalItems: totalItems is int ? totalItems : int.tryParse(totalItems.toString()) ?? 0,
      perPage: perPage is int ? perPage : int.tryParse(perPage.toString()) ?? 20,
      hasNextPage: currentPage < totalPages,
      hasPreviousPage: currentPage > 1,
    );
  }
}

class CategoryFilters {
  final String? sortBy;
  final String? sortOrder;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final bool? inStockOnly;

  CategoryFilters({
    this.sortBy,
    this.sortOrder,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.inStockOnly,
  });

  factory CategoryFilters.fromJson(Map<String, dynamic> json) {
    return CategoryFilters(
      sortBy: json['sort_by']?.toString(),
      sortOrder: json['sort_order']?.toString(),
      minPrice: _parseDouble(json['min_price']),
      maxPrice: _parseDouble(json['max_price']),
      minRating: _parseDouble(json['min_rating']),
      inStockOnly: json['in_stock_only'] == true || json['in_stock_only'] == 1,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> filters = {};
    
    if (sortBy != null) filters['sort_by'] = sortBy;
    if (sortOrder != null) filters['sort_order'] = sortOrder;
    if (minPrice != null) filters['min_price'] = minPrice;
    if (maxPrice != null) filters['max_price'] = maxPrice;
    if (minRating != null) filters['min_rating'] = minRating;
    if (inStockOnly != null) filters['in_stock_only'] = inStockOnly;
    
    return filters;
  }

  // Create query parameters for API calls
  Map<String, String> toQueryParameters() {
    Map<String, String> params = {};
    
    if (sortBy != null) params['sort'] = sortBy!;
    if (sortOrder != null) params['order'] = sortOrder!;
    if (minPrice != null) params['min_price'] = minPrice!.toString();
    if (maxPrice != null) params['max_price'] = maxPrice!.toString();
    if (minRating != null) params['min_rating'] = minRating!.toString();
    if (inStockOnly == true) params['in_stock_only'] = '1';
    
    return params;
  }

  CategoryFilters copyWith({
    String? sortBy,
    String? sortOrder,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? inStockOnly,
  }) {
    return CategoryFilters(
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      inStockOnly: inStockOnly ?? this.inStockOnly,
    );
  }
}

// Enum for sort options
enum CategorySortOption {
  nameAsc('name', 'asc', 'A to Z'),
  nameDesc('name', 'desc', 'Z to A'),
  priceAsc('price', 'asc', 'Cost: Low to High'),
  priceDesc('price', 'desc', 'Cost: High to Low'),
  popularity('popularity', 'desc', 'Popularity'),
  rating('rating', 'desc', 'Rating');

  const CategorySortOption(this.field, this.order, this.displayName);

  final String field;
  final String order;
  final String displayName;
}