class VendorInfoModel {
  final int id;
  final String? slug;
  final String name;
  final String? description;
  final ImageLogoModel? logo;

  VendorInfoModel({
    required this.id,
    this.slug,
    required this.name,
    this.description,
    this.logo,
  });

  factory VendorInfoModel.fromJson(Map<String, dynamic> json) {
    return VendorInfoModel(
      id: json['id'] ?? 0,
      slug: json['slug'],
      name: json['name'] ?? '',
      description: json['desc'] ?? json['description'],
      logo: json['logo'] != null ? ImageLogoModel.fromJson(json['logo']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'desc': description,
      'logo': logo?.toJson(),
    };
  }
}

class ImageLogoModel {
  final String? proxyUrl;
  final String? imagePath;
  final String? imageFit;
  final String? imageS3Url;

  ImageLogoModel({
    this.proxyUrl,
    this.imagePath,
    this.imageFit,
    this.imageS3Url,
  });

  factory ImageLogoModel.fromJson(Map<String, dynamic> json) {
    return ImageLogoModel(
      proxyUrl: json['proxy_url'],
      imagePath: json['image_path'],
      imageFit: json['image_fit'],
      imageS3Url: json['image_s3_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'proxy_url': proxyUrl,
      'image_path': imagePath,
      'image_fit': imageFit,
      'image_s3_url': imageS3Url,
    };
  }

  String? get fullImageUrl {
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