import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/bengali_formatters.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../data/services/daily_advice_service.dart';

class DailyAdviceCard extends StatelessWidget {
  const DailyAdviceCard({
    super.key,
    required this.advice,
  });

  final HourlyAdvice advice;

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
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.schedule_rounded, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('আজকের স্মার্ট পরামর্শ', style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      advice.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(advice.message, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryFaint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Text(
                  'পরবর্তী আপডেট: ${BengaliFormatters.toBengaliNumber(advice.nextUpdateInMinutes)} মিনিট পর',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
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
