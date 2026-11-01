import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String slug;
  final String name;
  final String? category;
  final double? displayedPrice;
  final double? originalPrice;
  final String? budgetBand;
  final String? imageKey;
  final bool justIn;
  final bool fastSelling;
  final bool? featured;
  final List<String> occasions;
  final List<String> customisationOptions;
  final String? description;
  final List<String> galleryKeys;
  final double? priceMin;
  final double? priceMax;
  final List<String> siteCategories;

  const ProductEntity({
    required this.id,
    required this.slug,
    required this.name,
    this.category,
    this.displayedPrice,
    this.originalPrice,
    this.budgetBand,
    this.imageKey,
    this.justIn = false,
    this.fastSelling = false,
    this.featured,
    this.occasions = const [],
    this.customisationOptions = const [],
    this.description,
    this.galleryKeys = const [],
    this.priceMin,
    this.priceMax,
    this.siteCategories = const [],
  });

  String? get priceLabel {
    if (priceMin != null && priceMax != null && priceMin != priceMax) {
      return '${formatRupees(priceMin)} – ${formatRupees(priceMax)}';
    }
    return formatRupees(displayedPrice);
  }

  @override
  List<Object?> get props => [id, name, displayedPrice, imageKey, category];
}

class ProductPageEntity extends Equatable {
  final List<ProductEntity> items;
  final int page;
  final int pageSize;
  final int total;

  const ProductPageEntity({required this.items, required this.page, required this.pageSize, required this.total});

  bool get hasMore => page * pageSize < total;

  @override
  List<Object?> get props => [items, page, total];
}

class CategoryEntity extends Equatable {
  final String name;
  final int productCount;
  const CategoryEntity({required this.name, required this.productCount});
  @override
  List<Object?> get props => [name, productCount];
}

class OccasionEntity extends Equatable {
  final String? name;
  final String enquiryLabel;
  final bool catalogueFilter;
  const OccasionEntity({required this.name, required this.enquiryLabel, required this.catalogueFilter});
  @override
  List<Object?> get props => [name, enquiryLabel, catalogueFilter];
}

class CatalogQuery extends Equatable {
  final String q;
  final String category;
  final String occasion;
  final String budget;
  final String sort;
  final String order;
  final int page;
  final int pageSize;
  final bool justIn;
  final bool fastSelling;

  const CatalogQuery({
    this.q = '',
    this.category = '',
    this.occasion = '',
    this.budget = '',
    this.sort = 'name',
    this.order = 'asc',
    this.page = 1,
    this.pageSize = 12,
    this.justIn = false,
    this.fastSelling = false,
  });

  CatalogQuery copyWith({
    String? q,
    String? category,
    String? occasion,
    String? budget,
    String? sort,
    String? order,
    int? page,
    int? pageSize,
    bool? justIn,
    bool? fastSelling,
  }) {
    return CatalogQuery(
      q: q ?? this.q,
      category: category ?? this.category,
      occasion: occasion ?? this.occasion,
      budget: budget ?? this.budget,
      sort: sort ?? this.sort,
      order: order ?? this.order,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      justIn: justIn ?? this.justIn,
      fastSelling: fastSelling ?? this.fastSelling,
    );
  }

  Map<String, dynamic> toParams() {
    return {
      'page': page,
      'pageSize': pageSize,
      'sort': sort,
      'order': order,
      if (q.trim().isNotEmpty) 'q': q.trim(),
      if (category.isNotEmpty) 'category': category,
      if (occasion.isNotEmpty) 'occasion': occasion,
      if (budget.isNotEmpty) 'budget': budget,
      if (justIn) 'justIn': true,
      if (fastSelling) 'fastSelling': true,
    };
  }

  @override
  List<Object?> get props => [q, category, occasion, budget, sort, order, page, justIn, fastSelling];
}

const catalogueBudgets = [
  'Under ₹500',
  '₹500 to ₹1,500',
  '₹1,500 to ₹3,000',
  'Above ₹3,000',
];

String? formatRupees(double? value) {
  if (value == null) return null;
  final digits = value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  final parts = digits.split('.');
  final grouped = _indianGroup(parts.first);
  return parts.length == 2 ? '₹$grouped.${parts[1]}' : '₹$grouped';
}

String _indianGroup(String whole) {
  if (whole.length <= 3) return whole;
  final head = whole.substring(0, whole.length - 3);
  final tail = whole.substring(whole.length - 3);
  final chunks = <String>[];
  var rest = head;
  while (rest.length > 2) {
    chunks.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) chunks.insert(0, rest);
  return '${chunks.join(',')},$tail';
}

String? assetFor(String? imageKey) {
  if (imageKey == null || imageKey.isEmpty) return null;
  var clean = imageKey.replaceFirst(RegExp(r'^/+'), '');
  if (clean.startsWith('http') || clean.contains('..')) return null;
  clean = clean.replaceFirst(RegExp(r'^assets/images/'), '').replaceFirst(RegExp(r'^assets/'), '');
  return 'assets/images/$clean';
}

const categoryArt = {
  'Drinkware': 'assets/images/categories/drinkware.webp',
  'Apparel': 'assets/images/categories/apparel.webp',
  'Work Essentials': 'assets/images/categories/work-essentials.webp',
  'Wellness': 'assets/images/categories/wellness.webp',
};
