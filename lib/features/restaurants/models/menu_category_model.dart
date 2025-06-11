class MenuCategoryModel {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final int position;
  final bool isActive;
  final int productCount;

  MenuCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.position,
    required this.isActive,
    required this.productCount,
  });

  factory MenuCategoryModel.fromJson(Map<String, dynamic> json) {
    // Handle vendor category structure where category details are nested
    int? categoryId = json['category_id'] ?? json['id'];
    String? categoryName;
    
    // Try to get name from category detail
    if (json['category'] != null && json['category'] is Map) {
      final categoryDetail = json['category'];
      
      // Check for category_detail nested structure
      if (categoryDetail['category_detail'] != null && categoryDetail['category_detail'] is Map) {
        final detail = categoryDetail['category_detail'];
        categoryId = detail['id'] ?? categoryId;
        
        // Check for translation
        if (detail['translation'] != null && detail['translation'] is List && (detail['translation'] as List).isNotEmpty) {
          final translation = (detail['translation'] as List).first;
          if (translation is Map) {
            categoryName = translation['name']?.toString();
          }
        }
      }
    }
    
    // Fallback to direct name field
    categoryName = categoryName ?? json['name']?.toString() ?? 'Category';
    
    // Count products if present
    int productCount = json['product_count'] ?? json['products_count'] ?? 0;
    if (json['products'] != null && json['products'] is List) {
      productCount = (json['products'] as List).length;
    }
    
    return MenuCategoryModel(
      id: _parseInt(categoryId) ?? 0,
      name: categoryName,
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      position: _parseInt(json['position']) ?? 0,
      isActive: json['status'] == 1 || json['is_active'] == 1,
      productCount: productCount,
    );
  }
  
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'position': position,
      'is_active': isActive ? 1 : 0,
      'product_count': productCount,
    };
  }
}