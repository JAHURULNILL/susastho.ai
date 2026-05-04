import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design.dart';
import '../../../../core/utils/bengali_formatters.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../data/models/food_analysis_result.dart';
import '../../../home/presentation/screens/home_shell.dart';
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
    final scoreColor = _scoreColor;
    final scoreBackground = _scoreBackground;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (image != null && image.existsSync()) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    image,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(result.foodName, style: AppTextStyles.screenTitle),
                        const SizedBox(height: 4),
                        Text(
                          _subtitle,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: scoreBackground,
                          shape: BoxShape.circle,
                          border: Border.all(color: scoreColor, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          BengaliFormatters.toBengaliNumber(result.healthScore),
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: scoreColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('স্বাস্থ্য স্কোর', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                childAspectRatio: 1.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _MacroCell(
                    label: 'ক্যালরি',
                    value: '${result.macros.calories.round()}',
                    unit: 'kcal',
                    background: AppColors.primaryPale,
                    accent: AppColors.primary,
                  ),
                  _MacroCell(
                    label: 'প্রোটিন',
                    value: result.macros.protein.toStringAsFixed(1),
                    unit: 'g',
                    background: AppColors.bluePale,
                    accent: AppColors.blue,
                  ),
                  _MacroCell(
                    label: 'কার্বস',
                    value: result.macros.carbs.toStringAsFixed(1),
                    unit: 'g',
                    background: AppColors.primaryFaint,
                    accent: AppColors.primaryLight,
                  ),
                  _MacroCell(
                    label: 'ফ্যাট',
                    value: result.macros.fat.toStringAsFixed(1),
                    unit: 'g',
                    background: AppColors.amberPale,
                    accent: AppColors.amber,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 18),
              if (result.pros.isNotEmpty) ...[
                Text('✅ উপকারিতা', style: AppTextStyles.cardTitle),
                const SizedBox(height: 10),
                ...result.pros.map((item) => _LineItem(text: item, color: AppColors.primary)),
              ],
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('⚠️ সতর্কতা', style: AppTextStyles.cardTitle),
                const SizedBox(height: 10),
                ...result.warnings.map((item) => _LineItem(text: item, color: AppColors.red)),
              ],
              if (result.redFlags.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InsightCard(
                  title: '🚨 রিয়েল-টাইম সতর্কতা',
                  body: result.redFlags.join('\n'),
                  backgroundColor: AppColors.redPale,
                  borderColor: AppColors.red,
                  bodyColor: AppColors.red,
                ),
              ],
              if (result.plateBreakdown.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('🍽️ প্লেট বিশ্লেষণ', style: AppTextStyles.cardTitle),
                const SizedBox(height: 10),
                ...result.plateBreakdown.map((item) => _LineItem(text: item, color: AppColors.primaryMid)),
              ],
              if (result.menuSuggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('📋 এই মেনু থেকে সেরা পছন্দ', style: AppTextStyles.cardTitle),
                const SizedBox(height: 10),
                ...result.menuSuggestions.map((item) => _LineItem(text: item, color: AppColors.primary)),
              ],
              if (result.receiptInsights.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('🧾 রসিদ বিশ্লেষণ', style: AppTextStyles.cardTitle),
                const SizedBox(height: 10),
                ...result.receiptInsights.map((item) => _LineItem(text: item, color: AppColors.primaryMid)),
              ],
              if (result.grocerySuggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('🛒 স্মার্ট বাজার তালিকা', style: AppTextStyles.cardTitle),
                const SizedBox(height: 10),
                ...result.grocerySuggestions.map((item) => _LineItem(text: item, color: AppColors.primary)),
              ],
              if ((result.memoryInsight ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                _InsightCard(
                  title: '🧠 সাম্প্রতিক প্যাটার্ন',
                  body: result.memoryInsight!,
                  backgroundColor: AppColors.bluePale,
                  borderColor: AppColors.blue,
                ),
              ],
              if ((result.conditionAdvice ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                _InsightCard(
                  title: '🎯 আপনার শরীর অনুযায়ী',
                  body: result.conditionAdvice!,
                  backgroundColor: AppColors.amberPale,
                  borderColor: AppColors.amber,
                ),
              ],
              if ((result.alternative ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                _InsightCard(
                  title: '🌿 স্বাস্থ্যকর বিকল্প',
                  body: result.alternative!,
                  backgroundColor: AppColors.primaryFaint,
                  borderColor: AppColors.primaryLight,
                ),
              ],
              if ((result.doctorTip ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                _InsightCard(
                  title: '🩺 ডাক্তারের ছোট টিপ',
                  body: result.doctorTip!,
                  backgroundColor: AppColors.primaryFaint,
                  borderColor: AppColors.primaryLight,
                ),
              ],
              if ((result.bestChoice ?? '').isNotEmpty || (result.budgetImpact ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                _InsightCard(
                  title: '✨ স্মার্ট সিদ্ধান্ত',
                  body: [
                    if ((result.bestChoice ?? '').isNotEmpty) result.bestChoice!,
                    if ((result.budgetImpact ?? '').isNotEmpty) result.budgetImpact!,
                  ].join('\n'),
                  backgroundColor: AppColors.primaryFaint,
                  borderColor: AppColors.primaryLight,
                ),
              ],
              const SizedBox(height: 18),
              PrimaryButton(
                label: '+ আজকের খাবারে যোগ করুন',
                icon: Icons.add_circle_outline_rounded,
                onPressed: result.analysisMode == 'meal'
                    ? () async {
                        await ref.read(dailySummaryProvider.notifier).addMeal(
                              result,
                              imagePath: imagePath,
                            );
                        ref.read(navigationTabProvider.notifier).setTab(0);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.primary,
                              duration: Duration(seconds: 2),
                              content: Text('✓ খাবার লগে যোগ হয়েছে'),
                            ),
                          );
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    switch (result.analysisMode) {
      case 'menu':
        return 'AI মেনু বিশ্লেষণ • এইমাত্র';
      case 'receipt':
        return 'AI রসিদ বিশ্লেষণ • এইমাত্র';
      default:
        return 'AI বিশ্লেষণ • এইমাত্র';
    }
  }

  Color get _scoreColor {
    if (result.healthScore >= 80) {
      return AppColors.primary;
    }
    if (result.healthScore >= 50) {
      return AppColors.amber;
    }
    return AppColors.red;
  }

  Color get _scoreBackground {
    if (result.healthScore >= 80) {
      return AppColors.primaryPale;
    }
    if (result.healthScore >= 50) {
      return AppColors.amberPale;
    }
    return AppColors.redPale;
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.body,
    required this.backgroundColor,
    required this.borderColor,
    this.bodyColor,
  });

  final String title;
  final String body;
  final Color backgroundColor;
  final Color borderColor;
  final Color? bodyColor;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTextStyles.body.copyWith(color: bodyColor ?? AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _MacroCell extends StatelessWidget {
  const _MacroCell({
    required this.label,
    required this.value,
    required this.unit,
    required this.background,
    required this.accent,
  });

  final String label;
  final String value;
  final String unit;
  final Color background;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTextStyles.metricSmall.copyWith(
                    color: accent,
                    fontSize: 24,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: AppTextStyles.body.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
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

class _LineItem extends StatelessWidget {
  const _LineItem({
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
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          color: color == AppColors.red ? AppColors.red : AppColors.textPrimary,
        ),
      ),
    );
  }
}
