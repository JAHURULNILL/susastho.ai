import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_design.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    this.backgroundColor = AppColors.white,
    this.borderColor = AppColors.border,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppCardStyles.base(
        backgroundColor: backgroundColor,
        borderColor: borderColor,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
