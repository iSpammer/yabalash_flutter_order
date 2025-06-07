class ReviewModel {
  final int? id;
  final String? userName;
  final String? userAvatar;
  final double rating;
  final String? reviewText;
  final List<String>? reviewImages;
  final String? reviewDate;

  ReviewModel({
    this.id,
    this.userName,
    this.userAvatar,
    required this.rating,
    this.reviewText,
    this.reviewImages,
    this.reviewDate,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Parse review images with better error handling
    List<String>? reviewImages;
    if (json['review_files'] != null) {
      final files = json['review_files'];
      if (files is List) {
        reviewImages = files
            .map((img) {
              if (img is Map<String, dynamic>) {
                return img['image_path'] ?? img['url'] ?? img['path'] ?? '';
              } else if (img is String) {
                return img;
              }
              return '';
            })
            .where((url) => url.isNotEmpty)
            .cast<String>()
            .toList();
      }
    }

    return ReviewModel(
      id: json['id'],
      userName: json['name'] ?? json['user']?['name'] ?? 'Anonymous',
      userAvatar: json['avatar'] ?? json['user']?['avatar'],
      rating: _parseDouble(json['rating']) ?? 0.0,
      reviewText: json['review'] ?? json['comment'],
      reviewImages: reviewImages,
      reviewDate: json['created_at'] ?? json['date'],
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
    return {
      'id': id,
      'name': userName,
      'avatar': userAvatar,
      'rating': rating,
      'review': reviewText,
      'review_files': reviewImages,
      'created_at': reviewDate,
    };
  }
}