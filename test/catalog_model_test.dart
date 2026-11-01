import 'package:flutter_test/flutter_test.dart';
import 'package:vmedia/src/features/catalog/domain/entities/product_entity.dart';
import 'package:vmedia/src/features/catalog/models/product_model.dart';

void main() {
  test('product model maps list and detail fields', () {
    final model = ProductModel.fromJson({
      'id': 'tg-12',
      'slug': 'bottle',
      'name': 'Smart Bottle',
      'category': 'Drinkware',
      'displayedPrice': 1499,
      'originalPrice': 1800,
      'budgetBand': '₹500 to ₹1,500',
      'imageKey': 'products/bottle.webp',
      'justIn': true,
      'fastSelling': false,
      'occasions': ['Employee Onboarding'],
      'customisationOptions': ['Logo printing'],
    });
    expect(model.toEntity().id, 'tg-12');
    expect(model.toEntity().justIn, isTrue);
    expect(model.toEntity().priceLabel, '₹1,499');
    expect(assetFor(model.toEntity().imageKey), 'assets/images/products/bottle.webp');
  });

  test('page model reads data and meta', () {
    final page = ProductPageModel.fromEnvelope({
      'success': true,
      'data': [
        {'id': 'tg-1', 'slug': 'a', 'name': 'A'},
        {'id': '', 'slug': 'skip', 'name': 'Skip'},
      ],
      'meta': {'page': 2, 'pageSize': 12, 'total': 30},
    });
    expect(page.page.items, hasLength(1));
    expect(page.page.hasMore, isTrue);
  });

  test('asset paths reject remote and parent traversal', () {
    expect(assetFor('https://example.com/a.webp'), isNull);
    expect(assetFor('../secret.webp'), isNull);
    expect(assetFor('/products/a.webp'), 'assets/images/products/a.webp');
  });

  test('catalogue query omits empty filters', () {
    const query = CatalogQuery(q: '  bottle ', category: 'Drinkware', justIn: true);
    expect(query.toParams()['q'], 'bottle');
    expect(query.toParams()['category'], 'Drinkware');
    expect(query.toParams().containsKey('budget'), isFalse);
    expect(query.toParams()['justIn'], isTrue);
  });
}
