import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension GoExt on BuildContext {
  void navTo(String path) => GoRouter.of(this).push(path);
  void goTo(String path) => GoRouter.of(this).go(path);
  void replaceWith(String path) => GoRouter.of(this).replace(path);
}
