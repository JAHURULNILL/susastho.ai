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
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (image != null && image.existsSync()) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    image,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 18),
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
                        Text(_subtitle, style: AppTextStyles.caption),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _modeAccent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _modeAccent.withValues(alpha: 0.20)),
                          ),
                          child: Text(
                            _modeLabel,
                            style: AppTextStyles.caption.copyWith(
                              color: _modeAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (result.summary.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            result.summary,
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: scoreBackground,
                          shape: BoxShape.circle,
                          border: Border.all(color: scoreColor, width: 2.2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${BengaliFormatters.toBengaliNumber(result.healthScore)}/১০০',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: scoreColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('স্বাস্থ্য স্কোর', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                childAspectRatio: 1.65,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _MacroCell(
                    label: 'ক্যালরি',
                    value: '${result.macros.calories.round()}',
                    unit: 'kcal',
                    background: AppColors.primaryPale,
                    accent: AppColors.primary,
                    icon: Icons.local_fire_department_rounded,
                  ),
                  _MacroCell(
                    label: 'প্রোটিন',
                    value: result.macros.protein.toStringAsFixed(1),
                    unit: 'g',
                    background: AppColors.bluePale,
                    accent: AppColors.blue,
                    icon: Icons.fitness_center_rounded,
                  ),
                  _MacroCell(
                    label: 'কার্বস',
                    value: result.macros.carbs.toStringAsFixed(1),
                    unit: 'g',
                    background: AppColors.primaryFaint,
                    accent: AppColors.primaryLight,
                    icon: Icons.grain_rounded,
                  ),
                  _MacroCell(
                    label: 'ফ্যাট',
                    value: result.macros.fat.toStringAsFixed(1),
                    unit: 'g',
                    background: AppColors.amberPale,
                    accent: AppColors.amber,
                    icon: Icons.opacity_rounded,
                  ),
                ],
              ),
              if (result.pros.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('উপকারিতা', style: AppTextStyles.cardTitle),
                const SizedBox(height: 10),
                ...result.pros.map((item) => _LineItem(text: item, color: AppColors.primary)),
              ],
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('সতর্কতা', style: AppTextStyles.cardTitle),
                const SizedBox(height: 10),
                ...result.warnings.map((item) => _LineItem(text: item, color: AppColors.red)),
              ],
              if (result.redFlags.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InsightCard(
                  title: 'রিয়েল-টাইম সতর্কতা',
                  body: result.redFlags.join('\n'),
                  backgroundColor: AppColors.redPale,
                  borderColor: AppColors.red,
                  icon: Icons.warning_amber_rounded,
                ),
              ],
              if (result.plateBreakdown.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InsightCard(
                  title: 'মিক্সড প্লেট বিশ্লেষণ',
                  body: result.plateBreakdown.join('\n'),
                  backgroundColor: AppColors.primaryFaint,
                  borderColor: AppColors.primaryLight,
                  icon: Icons.dinner_dining_rounded,
                ),
              ],
              if (result.menuSuggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InsightCard(
                  title: 'মেনু থেকে ভালো পছন্দ',
                  body: result.menuSuggestions.join('\n'),
                  backgroundColor: AppColors.primaryFaint,
                  borderColor: AppColors.primaryLight,
                  icon: Icons.menu_book_rounded,
                ),
              ],
              if (result.receiptInsights.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InsightCard(
                  title: 'রসিদ বিশ্লেষণ',
                  body: result.receiptInsights.join('\n'),
                  backgroundColor: AppColors.bluePale,
                  borderColor: AppColors.blue,
                  icon: Icons.receipt_long_rounded,
                ),
              ],
              if (result.grocerySuggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InsightCard(
                  title: 'স্মার্ট বাজার তালিকা',
                  body: result.grocerySuggestions.join('\n'),
                  backgroundColor: AppColors.primaryFaint,
                  borderColor: AppColors.primaryLight,
                  icon: Icons.shopping_basket_rounded,
                ),
              ],
              if ((result.memoryInsight ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                _InsightCard(
                  title: 'সাম্প্রতিক প্যাটার্ন',
                  body: result.memoryInsight!,
                  backgroundColor: AppColors.bluePale,
                  borderColor: AppColors.blue,
                  icon: Icons.psychology_alt_rounded,
                ),
              ],
              if ((result.conditionAdvice ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                _InsightCard(
                  title: 'আপনার শরীর অনুযায়ী পরামর্শ',
                  body: result.conditionAdvice!,
                  backgroundColor: AppColors.amberPale,
                  borderColor: AppColors.amber,
                  icon: Icons.health_and_safety_rounded,
                ),
              ],
              if ((result.alternative ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                _InsightCard(
                  title: 'স্বাস্থ্যকর বিকল্প',
                  body: result.alternative!,
                  backgroundColor: AppColors.primaryFaint,
                  borderColor: AppColors.primaryLight,
                  icon: Icons.eco_rounded,
                ),
              ],
              if ((result.doctorTip ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                _InsightCard(
                  title: 'ডাক্তারের ছোট টিপ',
                  body: result.doctorTip!,
                  backgroundColor: AppColors.primaryFaint,
                  borderColor: AppColors.primaryLight,
                  icon: Icons.medical_services_rounded,
                ),
              ],
              if ((result.bestChoice ?? '').isNotEmpty || (result.budgetImpact ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                _InsightCard(
                  title: 'স্মার্ট সিদ্ধান্ত',
                  body: [
                    if ((result.bestChoice ?? '').isNotEmpty) result.bestChoice!,
                    if ((result.budgetImpact ?? '').isNotEmpty) result.budgetImpact!,
                  ].join('\n'),
                  backgroundColor: AppColors.primaryFaint,
                  borderColor: AppColors.primaryLight,
                  icon: Icons.auto_awesome_rounded,
                ),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: result.analysisMode == 'meal' ? '+ আজকের খাবারে যোগ করুন' : 'বিশ্লেষণ সম্পন্ন',
                icon: result.analysisMode == 'meal' ? Icons.add_circle_outline_rounded : Icons.check_circle_outline_rounded,
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
                    : () => Navigator.of(context).pop(),
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

  String get _modeLabel {
    switch (result.analysisMode) {
      case 'menu':
        return 'রেস্টুরেন্ট মেনু গাইড';
      case 'receipt':
        return 'বাজার ও রসিদ ইনসাইট';
      default:
        return 'খাবার স্ক্যান ফলাফল';
    }
  }

  Color get _modeAccent {
    switch (result.analysisMode) {
      case 'receipt':
        return AppColors.blue;
      case 'menu':
        return AppColors.amber;
      default:
        return AppColors.primary;
    }
  }

  Color get _scoreColor {
    if (result.healthScore >= 80) return AppColors.primary;
    if (result.healthScore >= 50) return AppColors.amber;
    return AppColors.red;
  }

  Color get _scoreBackground {
    if (result.healthScore >= 80) return AppColors.primaryPale;
    if (result.healthScore >= 50) return AppColors.amberPale;
    return AppColors.redPale;
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.body,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
  });

  final String title;
  final String body;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: borderColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 8),
                Text(body, style: AppTextStyles.body),
              ],
            ),
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
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final Color background;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
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
          color: color == AppColors.red ? AppColors.red : Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
        ),
      ),
    );
  }
}
