class HelloValidator {
  HelloValidator._();

  static bool isValidTitle(String title) {
    return title.trim().length >= 3;
  }
}
