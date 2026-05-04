import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_design.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackground = backgroundColor ?? theme.cardTheme.color ?? AppColors.white;
    final effectiveBorder = borderColor ??
        ((theme.cardTheme.shape is RoundedRectangleBorder)
            ? (((theme.cardTheme.shape as RoundedRectangleBorder).side.color))
            : AppColors.border);
    return Container(
      decoration: AppCardStyles.base(
        backgroundColor: effectiveBackground,
        borderColor: effectiveBorder,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
