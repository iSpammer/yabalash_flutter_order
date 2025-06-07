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
    return MenuCategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      image: json['image'],
      position: json['position'] ?? 0,
      isActive: json['is_active'] == 1,
      productCount: json['product_count'] ?? 0,
    );
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