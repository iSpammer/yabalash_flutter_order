class DashboardSection {
  final int id;
  final String slug;
  final String title;
  final List<dynamic> data;
  final List<Translation>? translations;
  final List<dynamic>? bannerImage; // For banner sections
  final String? sectionType;
  final Map<String, dynamic>? extraData;

  DashboardSection({
    required this.id,
    required this.slug,
    required this.title,
    required this.data,
    this.translations,
    this.bannerImage,
    this.sectionType,
    this.extraData,
  });

  factory DashboardSection.fromJson(Map<String, dynamic> json) {
    // Parse translations first to determine the actual title
    final translations = json['translations'] != null
        ? List<Translation>.from(
            json['translations'].map((x) => Translation.fromJson(x)))
        : null;
    
    // Get translated title if available
    String title = json['title'] ?? '';
    if (translations != null && translations.isNotEmpty) {
      final translatedTitle = translations.first.title;
      if (translatedTitle.isNotEmpty) {
        title = translatedTitle;
      }
    }
    
    return DashboardSection(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      title: title,
      data: json['data'] != null ? List<dynamic>.from(json['data']) : [],
      translations: translations,
      bannerImage: json['banner_image'] != null
          ? List<dynamic>.from(json['banner_image'])
          : null,
      sectionType: json['section_type'],
      extraData: json,
    );
  }

  // Get localized title
  String getLocalizedTitle([String language = 'en']) {
    if (translations != null && translations!.isNotEmpty) {
      final translation = translations!.firstWhere(
        (t) => t.language == language,
        orElse: () => translations!.first,
      );
      return translation.title.isNotEmpty ? translation.title : title;
    }
    return title;
  }

  // Check if section should be displayed
  bool get shouldDisplay {
    // Always display sections that might have dynamic content
    if (slug == 'dynamic_page' || slug == 'dynamic_html') {
      return true;
    }
    
    // Check banner sections for banner images
    if (slug == 'banner') {
      return bannerImage != null && bannerImage!.isNotEmpty;
    }
    
    // For sections that might have null data (like recent_orders), check if data is actually null
    if (slug == 'recent_orders' || slug == 'ordered_products') {
      return true; // Let the widget handle empty state
    }
    
    // For all other sections, check if data is not empty
    return data.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'title': title,
      'data': data,
      'translations': translations?.map((x) => x.toJson()).toList(),
      'banner_image': bannerImage,
      'section_type': sectionType,
    };
  }
}

class Translation {
  final String title;
  final String language;

  Translation({
    required this.title,
    required this.language,
  });

  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      title: json['title'] ?? '',
      language: json['language'] ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'language': language,
    };
  }
}

// Supported section types as enum for better type safety
enum DashboardSectionType {
  banner('banner'),
  navCategories('nav_categories'),
  newProducts('new_products'),
  featuredProducts('featured_products'),
  vendors('vendors'),
  trendingVendors('trending_vendors'),
  bestSellers('best_sellers'),
  onSale('on_sale'),
  brands('brands'),
  spotlightDeals('spotlight_deals'),
  selectedProducts('selected_products'),
  singleCategoryProducts('single_category_products'),
  mostPopularProducts('most_popular_products'),
  recentlyViewed('recently_viewed'),
  orderedProducts('ordered_products'),
  cities('cities'),
  longTermService('long_term_service'),
  recentOrders('recent_orders'),
  topRated('top_rated'),
  dynamicHtml('dynamic_html'),
  yabalashBags('yabalash_bags'),
  surpriseBags('surprise_bags');

  const DashboardSectionType(this.slug);
  final String slug;

  static DashboardSectionType? fromSlug(String slug) {
    for (var type in DashboardSectionType.values) {
      if (type.slug == slug) return type;
    }
    return null;
  }
}