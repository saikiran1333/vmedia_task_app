import '../domain/entities/product_entity.dart';

class ProductModel {
  final ProductEntity entity;
  const ProductModel(this.entity);

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      ProductEntity(
        id: json['id'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        name: json['name'] as String? ?? 'Untitled product',
        category: json['category'] as String?,
        displayedPrice: _num(json['displayedPrice']),
        originalPrice: _num(json['originalPrice']),
        budgetBand: json['budgetBand'] as String?,
        imageKey: json['imageKey'] as String?,
        justIn: json['justIn'] == true,
        fastSelling: json['fastSelling'] == true,
        featured: json['featured'] is bool ? json['featured'] as bool : null,
        occasions: _strings(json['occasions']),
        customisationOptions: _strings(json['customisationOptions']),
        description: json['description'] as String?,
        galleryKeys: _strings(json['galleryKeys']),
        priceMin: _num(json['priceMin']),
        priceMax: _num(json['priceMax']),
        siteCategories: _strings(json['siteCategories']),
      ),
    );
  }

  ProductEntity toEntity() => entity;
}

class ProductPageModel {
  final ProductPageEntity page;
  const ProductPageModel(this.page);

  factory ProductPageModel.fromEnvelope(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    final meta = envelope['meta'];
    final items = data is List
        ? data.whereType<Map>().map((row) => ProductModel.fromJson(Map<String, dynamic>.from(row)).toEntity()).where((item) => item.id.isNotEmpty).toList()
        : <ProductEntity>[];
    final metaMap = meta is Map ? Map<String, dynamic>.from(meta) : <String, dynamic>{};
    return ProductPageModel(
      ProductPageEntity(
        items: items,
        page: _int(metaMap['page']) ?? 1,
        pageSize: _int(metaMap['pageSize']) ?? items.length,
        total: _int(metaMap['total']) ?? items.length,
      ),
    );
  }
}

class CategoryModel {
  final CategoryEntity entity;
  const CategoryModel(this.entity);
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(CategoryEntity(name: json['name'] as String? ?? '', productCount: _int(json['productCount']) ?? 0));
  }
}

class OccasionModel {
  final OccasionEntity entity;
  const OccasionModel(this.entity);
  factory OccasionModel.fromJson(Map<String, dynamic> json) {
    return OccasionModel(
      OccasionEntity(
        name: json['name'] as String?,
        enquiryLabel: json['enquiryLabel'] as String? ?? '',
        catalogueFilter: json['catalogueFilter'] == true,
      ),
    );
  }
}

double? _num(dynamic value) => value is num ? value.toDouble() : null;
int? _int(dynamic value) => value is num ? value.toInt() : null;
List<String> _strings(dynamic value) => value is List ? value.whereType<String>().toList() : const [];
