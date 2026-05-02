import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/bengali_formatters.dart';
import '../../../../data/models/food_analysis_result.dart';

class FoodResultBottomSheet extends StatelessWidget {
  const FoodResultBottomSheet({
    super.key,
    required this.result,
  });

  final FoodAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              result.foodName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _scoreColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                'স্বাস্থ্য স্কোর ${BengaliFormatters.toBengaliNumber(result.healthScore)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _scoreColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            if (result.modelName != null || result.modelId != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryDark, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _modelLabel(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              result.summary,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _MacroStat(label: 'ক্যালরি', value: result.macros.calories, unit: 'kcal'),
                _MacroStat(label: 'প্রোটিন', value: result.macros.protein, unit: 'g'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MacroStat(label: 'কার্বস', value: result.macros.carbs, unit: 'g'),
                _MacroStat(label: 'ফ্যাট', value: result.macros.fat, unit: 'g'),
              ],
            ),
            const SizedBox(height: 20),
            _SectionTitle(
              title: 'আপনার জন্য ভালো দিক',
              color: AppColors.success,
            ),
            const SizedBox(height: 8),
            ...result.pros.map((item) => _InsightTile(text: item, color: AppColors.success)),
            const SizedBox(height: 12),
            _SectionTitle(
              title: 'সতর্কতা',
              color: AppColors.warning,
            ),
            const SizedBox(height: 8),
            ...result.warnings.map((item) => _InsightTile(text: item, color: AppColors.warning)),
          ],
        ),
      ),
    );
  }

  Color get _scoreColor {
    if (result.healthScore >= 75) {
      return AppColors.success;
    }
    if (result.healthScore >= 50) {
      return const Color(0xFFE09B1F);
    }
    return AppColors.warning;
  }

  String _modelLabel() {
    final version = result.modelVersion == null || result.modelVersion!.isEmpty
        ? ''
        : ' • ${result.modelVersion}';
    return 'বিশ্লেষণে ব্যবহৃত মডেল: ${result.modelName ?? result.modelId ?? 'অজানা'}$version';
  }
}

class _MacroStat extends StatelessWidget {
  const _MacroStat({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final double value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Text(
                BengaliFormatters.toBengaliNumber(value, fractionDigits: 0),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text('$label $unit'),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.color,
  });

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: color),
      ),
    );
  }
}
