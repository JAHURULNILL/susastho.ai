import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/info_card.dart';

class DailyAdviceCard extends StatelessWidget {
  const DailyAdviceCard({
    super.key,
    required this.advice,
  });

  final String advice;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 12),
              Text(
                'আজকের স্মার্ট পরামর্শ',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            advice,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryDark, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'প্রথম মিল স্ক্যান করলে আজকের পরিকল্পনা আরও ব্যক্তিগতভাবে বদলে যাবে।',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
