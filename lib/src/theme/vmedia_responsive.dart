import 'package:flutter/material.dart';

class VmediaResponsive {
  VmediaResponsive._();

  static late MediaQueryData _mediaQuery;
  static late double width;
  static late double height;
  static late Orientation orientation;

  static void init(BuildContext context) {
    _mediaQuery = MediaQuery.of(context);
    width = _mediaQuery.size.width;
    height = _mediaQuery.size.height;
    orientation = _mediaQuery.orientation;
  }

  static bool get isSmallPhone => width < 360;
  static bool get isPhone => width >= 360 && width < 600;
  static bool get isTablet => width >= 600 && width < 1024;
  static bool get isDesktop => width >= 1024;
}
