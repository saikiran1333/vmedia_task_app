class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  /// Catalogue API origin. Override at build time with `--dart-define=API_BASE_URL=...`.
  /// The Android emulator default reaches the host machine. Hello keeps [baseUrl].
  static const String catalogBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  static const String dummyPost = '/posts/1';
  static const String products = '/api/v1/products';
  static const String categories = '/api/v1/categories';
  static const String occasions = '/api/v1/occasions';
  static const String customisations = '/api/v1/customisation-options';
  static const String enquiries = '/api/v1/enquiries';
}
