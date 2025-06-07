import '../../../core/utils/image_utils.dart';

class CategoryModel {
  final int? id;
  final String? name;
  final String? image;
  final String? icon;
  final bool? isActive;
  final int? sortOrder;
  final String? color;
  final String? type; // food, grocery, pharmacy, etc.

  CategoryModel({
    this.id,
    this.name,
    this.image,
    this.icon,
    this.isActive,
    this.sortOrder,
    this.color,
    this.type,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    // Handle nested translation array for name
    String? categoryName = json['name'];
    if (categoryName == null && json['translation'] is List) {
      final translations = json['translation'] as List;
      if (translations.isNotEmpty && translations[0] is Map) {
        categoryName = translations[0]['name'];
      }
    }
    
    // Handle nested image and icon objects from V2 API
    String? imageUrl = ImageUtils.buildImageUrl(json['image']);
    String? iconUrl = ImageUtils.buildCategoryIconUrl(json['icon']);
    
    // Safe parsing for integer fields
    int? categoryId;
    if (json['id'] is int) {
      categoryId = json['id'];
    } else if (json['id'] is String) {
      categoryId = int.tryParse(json['id']);
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
    
    return CategoryModel(
      id: categoryId,
      name: categoryName,
      image: imageUrl,
      icon: iconUrl,
      isActive: json['is_active'] == 1 || json['status'] == 1,
      sortOrder: sortOrderValue,
      color: json['color']?.toString(),
      type: json['type']?.toString() ?? json['slug']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'icon': icon,
      'is_active': isActive == true ? 1 : 0,
      'sort_order': sortOrder,
      'color': color,
      'type': type,
    };
  }
}