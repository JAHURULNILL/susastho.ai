import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final remaining = (target.calories - consumed.calories).clamp(0, target.calories).round();
    final ringSize = MediaQuery.sizeOf(context).width * 0.5;

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('আজকের ক্যালরি অবস্থা', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              height: ringSize,
              width: ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 0,
                      centerSpaceRadius: ringSize * 0.29,
                      sections: [
                        PieChartSectionData(
                          value: progress * 100,
                          color: AppColors.chartCalories,
                          radius: 14,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: (1 - progress) * 100,
                          color: AppColors.primaryPale,
                          radius: 14,
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
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 36,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'kcal',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              '${BengaliFormatters.toBengaliNumber(remaining)} kcal বাকি',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
