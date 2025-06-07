class MediaModel {
  final int id;
  final int productId;
  final int mediaId;
  final bool isDefault;
  final ImageModel? image;

  MediaModel({
    required this.id,
    required this.productId,
    required this.mediaId,
    required this.isDefault,
    this.image,
  });

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      mediaId: json['media_id'] ?? 0,
      isDefault: json['is_default'] == 1,
      image: json['image'] != null ? ImageModel.fromJson(json['image']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'media_id': mediaId,
      'is_default': isDefault ? 1 : 0,
      'image': image?.toJson(),
    };
  }
}

class ImageModel {
  final int id;
  final int mediaType;
  final ImagePathModel? path;

  ImageModel({
    required this.id,
    required this.mediaType,
    this.path,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'] ?? 0,
      mediaType: json['media_type'] ?? 1,
      path: json['path'] != null ? ImagePathModel.fromJson(json['path']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'media_type': mediaType,
      'path': path?.toJson(),
    };
  }
}

class ImagePathModel {
  final String? proxyUrl;
  final String? imagePath;
  final String? imageFit;
  final String? originalImage;
  final String? imageS3Url;

  ImagePathModel({
    this.proxyUrl,
    this.imagePath,
    this.imageFit,
    this.originalImage,
    this.imageS3Url,
  });

  factory ImagePathModel.fromJson(Map<String, dynamic> json) {
    return ImagePathModel(
      proxyUrl: json['proxy_url'],
      imagePath: json['image_path'],
      imageFit: json['image_fit'],
      originalImage: json['original_image'],
      imageS3Url: json['image_s3_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'proxy_url': proxyUrl,
      'image_path': imagePath,
      'image_fit': imageFit,
      'original_image': originalImage,
      'image_s3_url': imageS3Url,
    };
  }

  String? get fullImageUrl {
    if (originalImage != null) return originalImage;
    if (imageS3Url != null) return imageS3Url;
    if (proxyUrl != null && imagePath != null) {
      String proxy = proxyUrl!;
      String path = imagePath!;
      
      // Remove trailing slash from proxy_url and leading slash from image_path to avoid double slashes
      if (proxy.endsWith('/')) {
        proxy = proxy.substring(0, proxy.length - 1);
      }
      if (path.startsWith('/')) {
        path = path.substring(1);
      }
      
      return '$proxy/$path';
    }
    return null;
  }
}