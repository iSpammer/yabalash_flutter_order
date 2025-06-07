import 'banner_model.dart';
import 'category_model.dart';
import '../../restaurants/models/restaurant_model.dart';

class DashboardModel {
  final List<BannerModel>? banners;
  final List<CategoryModel>? categories;
  final List<RestaurantModel>? featuredRestaurants;
  final List<RestaurantModel>? nearbyRestaurants;
  final List<RestaurantModel>? popularRestaurants;
  final Map<String, dynamic>? appConfig;
  final Map<String, dynamic>? userLocation;

  DashboardModel({
    this.banners,
    this.categories,
    this.featuredRestaurants,
    this.nearbyRestaurants,
    this.popularRestaurants,
    this.appConfig,
    this.userLocation,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      banners: json['banners'] != null
          ? (json['banners'] as List).map((e) => BannerModel.fromJson(e)).toList()
          : null,
      categories: json['categories'] != null
          ? (json['categories'] as List).map((e) => CategoryModel.fromJson(e)).toList()
          : null,
      featuredRestaurants: json['featured_restaurants'] != null
          ? (json['featured_restaurants'] as List).map((e) => RestaurantModel.fromJson(e)).toList()
          : null,
      nearbyRestaurants: json['nearby_restaurants'] != null
          ? (json['nearby_restaurants'] as List).map((e) => RestaurantModel.fromJson(e)).toList()
          : null,
      popularRestaurants: json['popular_restaurants'] != null
          ? (json['popular_restaurants'] as List).map((e) => RestaurantModel.fromJson(e)).toList()
          : null,
      appConfig: json['app_config'],
      userLocation: json['user_location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'banners': banners?.map((e) => e.toJson()).toList(),
      'categories': categories?.map((e) => e.toJson()).toList(),
      'featured_restaurants': featuredRestaurants?.map((e) => e.toJson()).toList(),
      'nearby_restaurants': nearbyRestaurants?.map((e) => e.toJson()).toList(),
      'popular_restaurants': popularRestaurants?.map((e) => e.toJson()).toList(),
      'app_config': appConfig,
      'user_location': userLocation,
    };
  }
}