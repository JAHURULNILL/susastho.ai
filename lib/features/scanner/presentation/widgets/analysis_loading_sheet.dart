import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design.dart';
import '../../../../core/widgets/info_card.dart';

class AnalysisLoadingSheet extends StatefulWidget {
  const AnalysisLoadingSheet({super.key});

  @override
  State<AnalysisLoadingSheet> createState() => _AnalysisLoadingSheetState();
}

class _AnalysisLoadingSheetState extends State<AnalysisLoadingSheet> {
  int _dotCount = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {
        _dotCount = _dotCount == 1 ? 3 : _dotCount - 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _ShimmerBlock(widthFactor: 0.6, height: 24)),
              const SizedBox(width: 12),
              const SizedBox(width: 48, height: 48, child: _ShimmerCircle()),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: const [
              _ShimmerCard(),
              _ShimmerCard(),
              _ShimmerCard(),
              _ShimmerCard(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _ShimmerBlock(widthFactor: 1, height: 16),
          const SizedBox(height: 8),
          const _ShimmerBlock(widthFactor: 0.92, height: 16),
          const SizedBox(height: 8),
          const _ShimmerBlock(widthFactor: 0.84, height: 16),
          const SizedBox(height: AppSpacing.md),
          Text(
            'AI আপনার প্রোফাইল মিলিয়ে দেখছে${'.' * _dotCount}',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _ShimmerCircle extends StatelessWidget {
  const _ShimmerCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryFaint,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({
    required this.widthFactor,
    required this.height,
  });

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.primaryFaint,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
