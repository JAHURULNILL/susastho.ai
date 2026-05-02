import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/info_card.dart';

class AnalysisLoadingSheet extends StatelessWidget {
  const AnalysisLoadingSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ShimmerBar(widthFactor: 0.8),
          SizedBox(height: 10),
          _ShimmerBar(widthFactor: 1),
          SizedBox(height: 10),
          _ShimmerBar(widthFactor: 0.72),
          SizedBox(height: 16),
          Text('খাবার শনাক্ত হচ্ছে...'),
          SizedBox(height: 4),
          Text('আপনার স্বাস্থ্য তথ্যের সাথে মিলিয়ে দেখা হচ্ছে...'),
        ],
      ),
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: AppColors.primaryPale,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
