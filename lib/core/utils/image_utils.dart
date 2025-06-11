class ImageUtils {
  static const String baseUrl =
      'https://yabalash-assets.s3.me-central-1.amazonaws.com/';
  static const String proxyUrl = 'https://images.yabalash.com/insecure/fill/';
  static const String proxyPath = '/ce/0/plain/';

  /// Build complete image URL from API response
  static String? buildImageUrl(dynamic imageData) {
    if (imageData == null) return null;

    // If it's already a complete URL
    if (imageData is String) {
      // First, clean up the URL
      String cleanUrl = imageData.trim();
      
      // Handle proxy URLs with @webp suffix - these are problematic
      if (cleanUrl.contains('/ce/0/plain/') || cleanUrl.contains('images.yabalash.com')) {
        // Extract the actual URL from the proxy format
        final urlMatch = RegExp(r'/ce/0/plain/(https?://[^@\s]+)').firstMatch(cleanUrl);
        if (urlMatch != null && urlMatch.group(1) != null) {
          String extractedUrl = urlMatch.group(1)!;
          // Remove any @webp suffix
          return extractedUrl.split('@webp').first.trim();
        }
        
        // If it's a malformed proxy URL, try to extract the S3 part
        if (cleanUrl.contains('yabalash-assets.s3')) {
          final s3Match = RegExp(r'(https?://yabalash-assets\.s3[^@\s]+)').firstMatch(cleanUrl);
          if (s3Match != null && s3Match.group(1) != null) {
            return s3Match.group(1)!.split('@webp').first.trim();
          }
        }
      }
      
      if (cleanUrl.startsWith('http')) {
        return cleanUrl.split('@webp').first.trim(); // Remove @webp suffix if present
      }
      // If it's a path, build the full URL
      return '$baseUrl$cleanUrl';
    }

    // If it's a nested object with proxy_url and image_path
    if (imageData is Map<String, dynamic>) {
      final proxyUrlFromData = imageData['proxy_url'] as String?;
      final imagePath = imageData['image_path'] as String?;
      final imageField = imageData['image'] as String?;

      // For the new format, extract the actual S3 URL from image_path
      if (imagePath != null && imagePath.contains('/ce/0/plain/')) {
        // Extract the actual URL from the proxy format
        final urlMatch = RegExp(r'/ce/0/plain/(https?://[^@\s]+)').firstMatch(imagePath);
        if (urlMatch != null && urlMatch.group(1) != null) {
          String extractedUrl = urlMatch.group(1)!;
          // Remove any @webp suffix
          return extractedUrl.split('@webp').first.trim();
        }
      }

      // If we have an image field with the path, build the full S3 URL
      if (imageField != null && imageField.contains('category/image/')) {
        return '$baseUrl$imageField';
      }

      if (proxyUrlFromData != null && imagePath != null) {
        String proxy = proxyUrlFromData;
        String path = imagePath;
        
        // Remove trailing slash from proxy_url and leading slash from image_path to avoid double slashes
        if (proxy.endsWith('/')) {
          proxy = proxy.substring(0, proxy.length - 1);
        }
        if (path.startsWith('/')) {
          path = path.substring(1);
        }
        
        return '$proxy/$path';
      }

      // Fallback to just the image path
      if (imagePath != null) {
        return buildImageUrl(imagePath); // Recursively handle string format
      }
    }

    return null;
  }

  /// Build vendor logo URL specifically
  static String? buildVendorLogoUrl(String? logoPath) {
    if (logoPath == null || logoPath.isEmpty) return null;

    if (logoPath.startsWith('http')) {
      return logoPath;
    }

    return '$baseUrl$logoPath';
  }

  /// Build vendor banner URL specifically
  static String? buildVendorBannerUrl(String? bannerPath) {
    if (bannerPath == null || bannerPath.isEmpty) return null;

    if (bannerPath.startsWith('http')) {
      return bannerPath;
    }

    return '$baseUrl$bannerPath';
  }

  /// Build category icon URL correctly
  static String? buildCategoryIconUrl(dynamic iconData) {
    if (iconData == null) return null;

    if (iconData is String) {
      // First, clean up the URL
      String cleanUrl = iconData.trim();
      
      // Handle proxy URLs with @webp suffix - these are problematic
      if (cleanUrl.contains('/ce/0/plain/') || cleanUrl.contains('images.yabalash.com')) {
        // Extract the actual URL from the proxy format
        final urlMatch = RegExp(r'/ce/0/plain/(https?://[^@\s]+)').firstMatch(cleanUrl);
        if (urlMatch != null && urlMatch.group(1) != null) {
          String extractedUrl = urlMatch.group(1)!;
          // Remove any @webp suffix
          return extractedUrl.split('@webp').first.trim();
        }
        
        // If it's a malformed proxy URL, try to extract the S3 part
        if (cleanUrl.contains('yabalash-assets.s3')) {
          final s3Match = RegExp(r'(https?://yabalash-assets\.s3[^@\s]+)').firstMatch(cleanUrl);
          if (s3Match != null && s3Match.group(1) != null) {
            return s3Match.group(1)!.split('@webp').first.trim();
          }
        }
      }
      
      if (cleanUrl.startsWith('http')) {
        return cleanUrl.split('@webp').first.trim(); // Remove @webp suffix if present
      }
      
      // Handle paths without protocol
      if (cleanUrl.contains('category/image/')) {
        return '$baseUrl$cleanUrl';
      }
      
      return '$baseUrl$cleanUrl';
    }

    if (iconData is Map<String, dynamic>) {
      final imagePath = iconData['image_path'] as String?;
      final imageField = iconData['image'] as String?;
      
      // For the new format, extract the actual S3 URL from image_path
      if (imagePath != null && imagePath.contains('/ce/0/plain/')) {
        // Extract the actual URL from the proxy format
        final urlMatch = RegExp(r'/ce/0/plain/(https?://[^@\s]+)').firstMatch(imagePath);
        if (urlMatch != null && urlMatch.group(1) != null) {
          String extractedUrl = urlMatch.group(1)!;
          // Remove any @webp suffix
          return extractedUrl.split('@webp').first.trim();
        }
      }
      
      // If we have an image field with the path, build the full S3 URL
      if (imageField != null && imageField.contains('category/image/')) {
        return '$baseUrl$imageField';
      }
      
      if (imagePath != null) {
        return buildCategoryIconUrl(imagePath); // Recursively handle string format
      }
    }

    return null;
  }
}
