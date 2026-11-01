import 'package:flutter/material.dart';

class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => _ShimmerScope(slide: _controller.value * 2 - 1, child: child!),
      child: widget.child,
    );
  }
}

class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required this.slide, required super.child});

  final double slide;

  static double of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ShimmerScope>();
    return scope?.slide ?? 0;
  }

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) => slide != oldWidget.slide;
}

class ShimmerBlock extends StatelessWidget {
  const ShimmerBlock({super.key, this.height = 16, this.width, this.radius = 12});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final slide = _ShimmerScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(slide - 1, 0),
          end: Alignment(slide + 1, 0),
          colors: [scheme.surfaceContainerHighest, scheme.surface, scheme.surfaceContainerHighest],
        ),
      ),
    );
  }
}
