import 'package:flutter_test/flutter_test.dart';
import 'package:vmedia/src/features/enquiry/domain/enquiry_rules.dart';

void main() {
  const occasions = ['Corporate Diwali Gifting'];
  const options = ['Logo printing'];

  EnquiryDraft valid({List<SelectedGift> gifts = const [], String units = '12'}) {
    return EnquiryDraft(
      name: 'Asha Rao',
      email: 'asha@example.com',
      phone: '9876543210',
      city: 'Hyderabad',
      occasion: 'Corporate Diwali Gifting',
      budget: enquiryBudgets[1],
      message: 'Please share a branded quote.',
      units: units,
      gifts: gifts,
    );
  }

  test('normalizes Indian mobiles and rejects others', () {
    expect(normalizeIndianMobile('+91 98765 43210'), '+919876543210');
    expect(normalizeIndianMobile('09876543210'), '+919876543210');
    expect(normalizeIndianMobile('12345'), isNull);
  });

  test('selected quantities are the submitted total', () {
    final gifts = [
      const SelectedGift(id: 'tg-1', name: 'Bottle', quantity: 2),
      const SelectedGift(id: 'tg-2', name: 'Speaker', quantity: 3),
    ];
    final result = validateEnquiry(valid(gifts: gifts, units: '999'), occasions: occasions, customisations: options);
    expect(result.ok, isTrue);
    expect(result.body!['units'], 5);
    expect(result.body!['source'], 'MOBILE');
    expect(result.body!['items'], [
      {'productId': 'tg-1', 'quantity': 2},
      {'productId': 'tg-2', 'quantity': 3},
    ]);
  });

  test('rejects a non positive quantity and an unknown occasion', () {
    final result = validateEnquiry(
      EnquiryDraft(
        name: 'A',
        email: 'not-an-email',
        phone: '111',
        city: '',
        occasion: 'Party',
        budget: 'nope',
        message: 'short',
        units: '0',
        gifts: const [SelectedGift(id: 'tg-1', name: 'Bottle', quantity: 0)],
      ),
      occasions: occasions,
      customisations: options,
    );
    expect(result.ok, isFalse);
    expect(result.errors.containsKey('email'), isTrue);
    expect(result.errors.containsKey('occasion'), isTrue);
    expect(result.errors.containsKey('quantity'), isTrue);
  });

  test('reuses the idempotency key only for the same body', () {
    final body = validateEnquiry(valid(), occasions: occasions, customisations: options).body!;
    final fingerprint = enquiryFingerprint(body);
    final stored = PendingSubmission(key: 'abcd1234', fingerprint: fingerprint);
    expect(resolveIdempotencyKey(stored, fingerprint).key, 'abcd1234');
    expect(resolveIdempotencyKey(stored, '$fingerprint-changed').key, isNot('abcd1234'));
  });
}
