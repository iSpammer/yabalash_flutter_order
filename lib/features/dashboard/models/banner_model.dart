import '../../../core/utils/image_utils.dart';

class BannerModel {
  final int? id;
  final String? title;
  final String? image;
  final String? redirectionUrl;
  final String? actionType; // vendor, category, external
  final int? actionId;
  final bool? isActive;
  final String? description;

  BannerModel({
    this.id,
    this.title,
    this.image,
    this.redirectionUrl,
    this.actionType,
    this.actionId,
    this.isActive,
    this.description,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    // Handle both direct image URL and nested image object from V2 API
    String? imageUrl = ImageUtils.buildImageUrl(json['image']);
    
    // Safe parsing for integer fields
    int? bannerId;
    if (json['id'] is int) {
      bannerId = json['id'];
    } else if (json['id'] is String) {
      bannerId = int.tryParse(json['id']);
    }
    
    int? actionIdValue;
    if (json['action_id'] != null) {
      if (json['action_id'] is int) {
        actionIdValue = json['action_id'];
      } else if (json['action_id'] is String) {
        actionIdValue = int.tryParse(json['action_id']);
      }
    } else if (json['vendor_id'] != null) {
      if (json['vendor_id'] is int) {
        actionIdValue = json['vendor_id'];
      } else if (json['vendor_id'] is String) {
        actionIdValue = int.tryParse(json['vendor_id']);
      }
    }
    
    return BannerModel(
      id: bannerId,
      title: json['title']?.toString() ?? json['name']?.toString(),
      image: imageUrl,
      redirectionUrl: json['redirection_url']?.toString() ?? json['redirect_url']?.toString(),
      actionType: json['action_type']?.toString(),
      actionId: actionIdValue,
      isActive: json['is_active'] == 1 || json['status'] == 1,
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'redirection_url': redirectionUrl,
      'action_type': actionType,
      'action_id': actionId,
      'is_active': isActive == true ? 1 : 0,
      'description': description,
    };
  }
}