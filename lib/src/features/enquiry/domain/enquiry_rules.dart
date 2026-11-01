import 'dart:convert';
import 'dart:math';

import 'package:equatable/equatable.dart';

class SelectedGift extends Equatable {
  final String id;
  final String name;
  final String? imageKey;
  final int quantity;
  final List<String> customisationOptions;

  const SelectedGift({
    required this.id,
    required this.name,
    this.imageKey,
    this.quantity = 1,
    this.customisationOptions = const [],
  });

  SelectedGift copyWith({int? quantity}) => SelectedGift(
        id: id,
        name: name,
        imageKey: imageKey,
        quantity: quantity ?? this.quantity,
        customisationOptions: customisationOptions,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageKey': imageKey,
        'quantity': quantity,
        'customisationOptions': customisationOptions,
      };

  factory SelectedGift.fromJson(Map<String, dynamic> json) {
    return SelectedGift(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageKey: json['imageKey'] as String?,
      quantity: json['quantity'] is num ? (json['quantity'] as num).toInt() : 1,
      customisationOptions: json['customisationOptions'] is List ? (json['customisationOptions'] as List).whereType<String>().toList() : const [],
    );
  }

  @override
  List<Object?> get props => [id, quantity];
}

int totalUnits(List<SelectedGift> gifts) => gifts.fold(0, (sum, gift) => sum + gift.quantity);

class EnquiryReceipt extends Equatable {
  final String id;
  final String enquiryNumber;
  final String createdAt;
  final int units;

  const EnquiryReceipt({required this.id, required this.enquiryNumber, required this.createdAt, required this.units});

  @override
  List<Object?> get props => [enquiryNumber, createdAt];
}

class StoredEnquiry extends Equatable {
  final String enquiryNumber;
  final String createdAt;
  final String occasion;
  final String budget;
  final int units;
  final String status;
  final List<SelectedGift> products;

  const StoredEnquiry({
    required this.enquiryNumber,
    required this.createdAt,
    required this.occasion,
    required this.budget,
    required this.units,
    required this.status,
    required this.products,
  });

  Map<String, dynamic> toJson() => {
        'enquiryNumber': enquiryNumber,
        'createdAt': createdAt,
        'occasion': occasion,
        'budget': budget,
        'units': units,
        'status': status,
        'products': products.map((item) => item.toJson()).toList(),
      };

  factory StoredEnquiry.fromJson(Map<String, dynamic> json) {
    final products = json['products'];
    return StoredEnquiry(
      enquiryNumber: json['enquiryNumber'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      occasion: json['occasion'] as String? ?? '',
      budget: json['budget'] as String? ?? '',
      units: json['units'] is num ? (json['units'] as num).toInt() : 0,
      status: json['status'] as String? ?? 'Submitted',
      products: products is List
          ? products.whereType<Map>().map((row) => SelectedGift.fromJson(Map<String, dynamic>.from(row))).where((item) => item.id.isNotEmpty).toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [enquiryNumber, createdAt];
}

class PendingSubmission extends Equatable {
  final String key;
  final String fingerprint;
  const PendingSubmission({required this.key, required this.fingerprint});
  @override
  List<Object?> get props => [key, fingerprint];
}

const enquiryBudgets = [
  'Under ₹200 per gift',
  '₹200 \u2013 ₹500 per gift',
  '₹500 \u2013 ₹1,000 per gift',
  '₹1,000 \u2013 ₹2,500 per gift',
  '₹2,500+ per gift',
  'Flexible / Not sure',
];

class EnquiryDraft {
  final String name;
  final String email;
  final String phone;
  final String city;
  final String companyName;
  final String occasion;
  final String budget;
  final String message;
  final String units;
  final String customisationRequirements;
  final String deliveryDate;
  final List<String> customisationOptions;
  final List<SelectedGift> gifts;

  const EnquiryDraft({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.city = '',
    this.companyName = '',
    this.occasion = '',
    this.budget = '',
    this.message = '',
    this.units = '1',
    this.customisationRequirements = '',
    this.deliveryDate = '',
    this.customisationOptions = const [],
    this.gifts = const [],
  });
}

class EnquiryValidation {
  final Map<String, String> errors;
  final Map<String, dynamic>? body;
  const EnquiryValidation._(this.errors, this.body);
  bool get ok => errors.isEmpty && body != null;
  factory EnquiryValidation.ok(Map<String, dynamic> body) => EnquiryValidation._(const {}, body);
  factory EnquiryValidation.fail(Map<String, String> errors) => EnquiryValidation._(errors, null);
}

String? normalizeIndianMobile(String input) {
  var national = input.replaceAll(RegExp(r'[\s()-]'), '');
  if (national.startsWith('+91')) {
    national = national.substring(3);
  } else if (national.startsWith('91') && national.length == 12) {
    national = national.substring(2);
  } else if (national.startsWith('0') && national.length == 11) {
    national = national.substring(1);
  }
  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(national)) return null;
  return '+91$national';
}

String kolkataToday() {
  final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

EnquiryValidation validateEnquiry(EnquiryDraft draft, {required List<String> occasions, required List<String> customisations}) {
  final errors = <String, String>{};
  final name = draft.name.trim();
  if (name.length < 2 || name.length > 80) errors['name'] = 'Enter a name between 2 and 80 characters.';
  final email = draft.email.trim().toLowerCase();
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email) || email.length > 254) {
    errors['email'] = 'Enter a valid email address.';
  }
  final phone = normalizeIndianMobile(draft.phone.trim());
  if (phone == null) errors['phone'] = 'Enter a valid Indian mobile number.';
  final city = draft.city.trim();
  if (city.length < 2 || city.length > 80) errors['city'] = 'Enter a city between 2 and 80 characters.';
  final company = draft.companyName.trim();
  if (company.length > 120) errors['companyName'] = 'Company name must be 120 characters or fewer.';
  if (draft.occasion.isEmpty || !occasions.contains(draft.occasion)) errors['occasion'] = 'Choose an occasion from the list.';
  if (!enquiryBudgets.contains(draft.budget)) errors['budget'] = 'Choose a budget from the list.';
  final message = draft.message.trim();
  if (message.length < 10 || message.length > 2000) errors['message'] = 'Enter a message between 10 and 2000 characters.';
  final requirements = draft.customisationRequirements.trim();
  if (requirements.length > 2000) errors['customisationRequirements'] = 'Customisation requirements must be 2000 characters or fewer.';
  if (draft.customisationOptions.any((option) => !customisations.contains(option))) {
    errors['customisationOptions'] = 'Choose a customisation option from the list.';
  }
  if (draft.deliveryDate.isNotEmpty) {
    final parsed = DateTime.tryParse(draft.deliveryDate);
    if (parsed == null || draft.deliveryDate.length != 10) {
      errors['deliveryDate'] = 'Enter a delivery date as YYYY-MM-DD.';
    } else if (draft.deliveryDate.compareTo(kolkataToday()) < 0) {
      errors['deliveryDate'] = 'Delivery date cannot be in the past.';
    }
  }
  final items = <Map<String, dynamic>>[];
  for (final gift in draft.gifts) {
    if (!RegExp(r'^tg-[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(gift.id)) {
      errors['gifts'] = 'Choose a product from the catalogue.';
      continue;
    }
    if (gift.quantity < 1 || gift.quantity > 10000) {
      errors['quantity'] = 'Quantity must be a whole number from 1 to 10000.';
      continue;
    }
    items.add({'productId': gift.id, 'quantity': gift.quantity});
  }
  if (items.map((item) => item['productId']).toSet().length != items.length) {
    errors['gifts'] = 'Each product can appear once. Add the quantities together.';
  }
  int? units;
  if (items.isEmpty) {
    final parsed = int.tryParse(draft.units.trim());
    if (parsed == null || parsed < 1 || parsed > 100000) {
      errors['units'] = 'Enter the number of gifts as a whole number.';
    } else {
      units = parsed;
    }
  } else {
    units = totalUnits(draft.gifts.where((gift) => gift.quantity > 0).toList());
    if (units > 100000) errors['units'] = 'The combined quantity is too large.';
  }
  if (errors.isNotEmpty || phone == null) return EnquiryValidation.fail(errors);
  final body = <String, dynamic>{
    'name': name,
    'email': email,
    'phone': phone,
    'city': city,
    'occasion': draft.occasion,
    'budget': draft.budget,
    'message': message,
    'source': 'MOBILE',
    'units': units,
    if (company.isNotEmpty) 'companyName': company,
    if (items.isNotEmpty) 'items': items,
    if (draft.customisationOptions.isNotEmpty) 'customisationOptions': [...draft.customisationOptions]..sort(),
    if (requirements.isNotEmpty) 'customisationRequirements': requirements,
    if (draft.deliveryDate.isNotEmpty) 'deliveryDate': draft.deliveryDate,
  };
  return EnquiryValidation.ok(body);
}

String enquiryFingerprint(Map<String, dynamic> body) => jsonEncode(_sort(body));

Object? _sort(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return {for (final key in keys) key: _sort(value[key])};
  }
  if (value is List) return value.map(_sort).toList();
  return value;
}

String newIdempotencyKey() {
  final random = Random.secure();
  return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

PendingSubmission resolveIdempotencyKey(PendingSubmission? stored, String fingerprint) {
  final pattern = RegExp(r'^[A-Za-z0-9._:-]{8,128}$');
  if (stored != null && stored.fingerprint == fingerprint && pattern.hasMatch(stored.key)) return stored;
  return PendingSubmission(key: newIdempotencyKey(), fingerprint: fingerprint);
}
