import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/bengali_formatters.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../data/models/food_analysis_result.dart';
import '../../../home/providers/home_provider.dart';

class FoodResultBottomSheet extends ConsumerWidget {
  const FoodResultBottomSheet({
    super.key,
    required this.result,
    required this.imagePath,
  });

  final FoodAnalysisResult result;
  final String? imagePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = imagePath == null ? null : File(imagePath!);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null && image.existsSync()) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  image,
                  width: double.infinity,
                  height: 190,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 18),
            ],
            Text(result.foodName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _scoreColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'স্বাস্থ্য স্কোর: ${BengaliFormatters.toBengaliNumber(result.healthScore)}/১০০',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _scoreColor,
                    ),
              ),
            ),
            const SizedBox(height: 18),
            _SectionTitle(title: 'পুষ্টিমান'),
            const SizedBox(height: 10),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _MacroCard(label: 'ক্যালরি', value: '${result.macros.calories.round()}kcal', color: AppColors.primaryPale),
                _MacroCard(label: 'প্রোটিন', value: '${result.macros.protein.toStringAsFixed(1)}g', color: const Color(0xFFEAF0FF)),
                _MacroCard(label: 'কার্বস', value: '${result.macros.carbs.toStringAsFixed(1)}g', color: AppColors.primaryFaint),
                _MacroCard(label: 'ফ্যাট', value: '${result.macros.fat.toStringAsFixed(1)}g', color: AppColors.warningPale),
              ],
            ),
            if (result.fiber != null || result.vitamins.isNotEmpty || result.minerals.isNotEmpty) ...[
              const SizedBox(height: 18),
              _SectionTitle(title: 'অতিরিক্ত পুষ্টি'),
              const SizedBox(height: 8),
              if (result.fiber != null) Text('ফাইবার: ${result.fiber!.toStringAsFixed(1)}g'),
              if (result.vitamins.isNotEmpty) Text('ভিটামিন: ${result.vitamins.join(', ')}'),
              if (result.minerals.isNotEmpty) Text('মিনারেল: ${result.minerals.join(', ')}'),
            ],
            const SizedBox(height: 18),
            _SectionTitle(title: 'আপনার জন্য ভালো দিক', color: AppColors.success),
            const SizedBox(height: 8),
            ...result.pros.map((item) => _InsightTile(text: item, color: AppColors.success)),
            const SizedBox(height: 14),
            _SectionTitle(title: 'সতর্কতা', color: AppColors.warning),
            const SizedBox(height: 8),
            ...result.warnings.map((item) => _InsightTile(text: item, color: AppColors.warning)),
            if ((result.conditionAdvice ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionTitle(title: 'আপনার সমস্যা অনুযায়ী পরামর্শ'),
              const SizedBox(height: 8),
              _AdviceCard(text: result.conditionAdvice!),
            ],
            if ((result.timingAdvice ?? '').isNotEmpty || (result.portionAdvice ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionTitle(title: 'কখন ও কতটুকু'),
              const SizedBox(height: 8),
              if ((result.timingAdvice ?? '').isNotEmpty) _AdviceCard(text: result.timingAdvice!),
              if ((result.portionAdvice ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                _AdviceCard(text: result.portionAdvice!),
              ],
            ],
            if ((result.alternative ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionTitle(title: 'স্বাস্থ্যকর বিকল্প'),
              const SizedBox(height: 8),
              _AdviceCard(text: result.alternative!),
            ],
            const SizedBox(height: 18),
            PrimaryButton(
              label: '+ আজকের খাবারে যোগ করুন',
              icon: Icons.add_circle_outline_rounded,
              onPressed: () async {
                await ref.read(dailySummaryProvider.notifier).addMeal(
                      result,
                      imagePath: imagePath,
                    );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('আজকের খাবারের তালিকায় যোগ করা হয়েছে।')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Color get _scoreColor {
    if (result.healthScore >= 80) {
      return AppColors.success;
    }
    if (result.healthScore >= 50) {
      return AppColors.warning;
    }
    return AppColors.danger;
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.color = AppColors.textPrimary,
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

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
