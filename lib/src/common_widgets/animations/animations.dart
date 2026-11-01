import 'package:flutter/material.dart';

class FadeSlideTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final double offsetY;
  const FadeSlideTransition({super.key, required this.child, required this.animation, this.offsetY = 18});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, childWidget) {
        final fade = Curves.easeInOut.transform(animation.value);
        final dy = (1 - fade) * offsetY;
        return Opacity(opacity: fade, child: Transform.translate(offset: Offset(0, dy), child: childWidget));
      },
      child: child,
    );
  }
}

// small pulse widget for subtle AI aura
class Pulse extends StatefulWidget {
  final Widget child;
  final Duration duration;
  const Pulse({super.key, required this.child, this.duration = const Duration(seconds: 2)});

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final s = 1 + (0.025 * _c.value);
        final o = 0.85 + (0.15 * _c.value);
        return Transform.scale(scale: s, child: Opacity(opacity: o, child: child));
      },
      child: widget.child,
    );
  }
}
