import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/bengali_formatters.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../data/models/food_analysis_result.dart';

class MacroRingChart extends StatelessWidget {
  const MacroRingChart({
    super.key,
    required this.target,
    required this.consumed,
  });

  final NutritionMacro target;
  final NutritionMacro consumed;

  @override
  Widget build(BuildContext context) {
    final progress = target.calories == 0 ? 0.0 : (consumed.calories / target.calories).clamp(0.0, 1.0);

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'আজকের ম্যাক্রো অবস্থা',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'এখনো কোনো মিল স্ক্যান না করলে মান শূন্য থাকবে। প্রথম স্ক্যানের পর ধীরে ধীরে এগুলো পূরণ হবে।',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: progress * 100,
                            color: AppColors.chartCalories,
                            radius: 18,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: (1 - progress) * 100,
                            color: AppColors.primaryLight,
                            radius: 18,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          BengaliFormatters.toBengaliNumber(consumed.calories.round()),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'খাওয়া ক্যালরি',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _MacroRow(
                      label: 'প্রোটিন',
                      color: AppColors.chartProtein,
                      current: consumed.protein,
                      target: target.protein,
                    ),
                    const SizedBox(height: 12),
                    _MacroRow(
                      label: 'কার্বস',
                      color: AppColors.chartCarbs,
                      current: consumed.carbs,
                      target: target.carbs,
                    ),
                    const SizedBox(height: 12),
                    _MacroRow(
                      label: 'ফ্যাট',
                      color: AppColors.chartFat,
                      current: consumed.fat,
                      target: target.fat,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'দৈনিক লক্ষ্য: ${BengaliFormatters.toBengaliNumber(target.calories.round())} kcal',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.color,
    required this.current,
    required this.target,
  });

  final String label;
  final Color color;
  final double current;
  final double target;

  @override
  Widget build(BuildContext context) {
    final percent = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 5, backgroundColor: color),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
            Text(
              '${BengaliFormatters.toBengaliNumber(current, fractionDigits: 0)}/${BengaliFormatters.toBengaliNumber(target, fractionDigits: 0)}g',
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.18),
          ),
        ),
      ],
    );
  }
}
