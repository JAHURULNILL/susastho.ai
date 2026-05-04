import 'package:flutter/material.dart';

class AnimatedCountText extends StatelessWidget {
  const AnimatedCountText({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 800),
  });

  final double value;
  final Duration duration;
  final Widget Function(double value) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, animatedValue, _) => builder(animatedValue),
    );
  }
}
