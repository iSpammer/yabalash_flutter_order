class TranslationModel {
  final int id;
  final String? title;
  final String? bodyHtml;
  final String? metaTitle;
  final String? metaKeyword;
  final String? metaDescription;
  final int productId;
  final int languageId;

  TranslationModel({
    required this.id,
    this.title,
    this.bodyHtml,
    this.metaTitle,
    this.metaKeyword,
    this.metaDescription,
    required this.productId,
    required this.languageId,
  });

  factory TranslationModel.fromJson(Map<String, dynamic> json) {
    return TranslationModel(
      id: json['id'] ?? 0,
      title: json['title'],
      bodyHtml: json['body_html'],
      metaTitle: json['meta_title'],
      metaKeyword: json['meta_keyword'],
      metaDescription: json['meta_description'],
      productId: json['product_id'] ?? 0,
      languageId: json['language_id'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body_html': bodyHtml,
      'meta_title': metaTitle,
      'meta_keyword': metaKeyword,
      'meta_description': metaDescription,
      'product_id': productId,
      'language_id': languageId,
    };
  }
}