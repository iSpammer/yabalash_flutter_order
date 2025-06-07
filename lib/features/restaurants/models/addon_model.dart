class AddonModel {
  final int id;
  final String name;
  final double price;
  final String? description;
  final bool isMultipleSelection;
  final int minSelection;
  final int maxSelection;
  final List<AddonOption>? options;

  AddonModel({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.isMultipleSelection = false,
    this.minSelection = 0,
    this.maxSelection = 1,
    this.options,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  factory AddonModel.fromJson(Map<String, dynamic> json) {
    return AddonModel(
      id: _parseInt(json['id']),
      name: json['name'] ?? json['title'] ?? '',
      price: _parseDouble(json['price']),
      description: json['description'],
      isMultipleSelection: json['is_multiple_selection'] == 1,
      minSelection: _parseInt(json['min_selection']),
      maxSelection: _parseInt(json['max_selection']),
      options: json['options'] != null
          ? (json['options'] as List).map((o) => AddonOption.fromJson(o)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'is_multiple_selection': isMultipleSelection,
      'min_selection': minSelection,
      'max_selection': maxSelection,
      'options': options?.map((o) => o.toJson()).toList(),
    };
  }
}

class AddonOption {
  final int id;
  final String name;
  final double price;
  final bool isDefault;

  AddonOption({
    required this.id,
    required this.name,
    required this.price,
    this.isDefault = false,
  });

  factory AddonOption.fromJson(Map<String, dynamic> json) {
    return AddonOption(
      id: AddonModel._parseInt(json['id']),
      name: json['name'] ?? '',
      price: AddonModel._parseDouble(json['price']),
      isDefault: json['is_default'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'is_default': isDefault,
    };
  }
}