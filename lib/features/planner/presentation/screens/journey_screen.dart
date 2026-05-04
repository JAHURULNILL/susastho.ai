import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design.dart';
import '../../../../core/utils/bengali_formatters.dart';
import '../../../../core/widgets/fade_up_item.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../data/models/weekly_plan.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../home/providers/home_provider.dart';
import '../../providers/planner_provider.dart';

class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);
    final exercises = ref.watch(todayExercisesProvider).asData?.value ?? const <WeeklyExerciseItem>[];
    final weeklyCalories = ref.watch(weeklyCaloriesProvider);
    final profile = ref.watch(userProfileProvider).asData?.value;
    final summary = dashboard?.summary;
    final dailyGoal = profile?.dailyCalorieTarget ?? 0;

    final widgets = [
      InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('এই সপ্তাহের জার্নি', style: AppTextStyles.screenTitle),
            const SizedBox(height: 8),
            Text(
              profile == null
                  ? 'জার্নির তথ্য এখানে দেখা যাবে।'
                  : 'আপনার লগ করা খাবার, পানি আর ব্যায়ামের বাস্তব ডেটা এখানে দেখানো হচ্ছে।',
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
      Row(
        children: [
          Expanded(
            child: _JourneyStat(
              title: 'গড় ক্যালরি',
              value: _averageWeeklyCalories(weeklyCalories.asData?.value) == null
                  ? '—'
                  : BengaliFormatters.toBengaliNumber(_averageWeeklyCalories(weeklyCalories.asData?.value)!.round()),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _JourneyStat(
              title: 'লক্ষ্য পূরণ',
              value: _goalMetPercent(weeklyCalories.asData?.value, dailyGoal) == null
                  ? '—'
                  : '${BengaliFormatters.toBengaliNumber(_goalMetPercent(weeklyCalories.asData?.value, dailyGoal)!)}%',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _JourneyStat(
              title: 'রুটিন',
              value: exercises.isEmpty ? '—' : '${BengaliFormatters.toBengaliNumber(exercises.where((e) => e.completed).length)} দিন',
            ),
          ),
        ],
      ),
      weeklyCalories.when(
        data: (data) => _WeeklyCaloriesChart(
          weekData: _buildWeekBars(data),
          dailyGoal: dailyGoal.toDouble(),
        ),
        loading: () => const _LoadingCard(title: 'সাপ্তাহিক ক্যালরি চার্ট লোড হচ্ছে...'),
        error: (error, stackTrace) => _EmptyCard(
          title: 'চার্ট আনা যায়নি',
          message: error.toString(),
        ),
      ),
      _HealthGoalProgress(
        profile: profile,
        summaryWater: summary?.waterGlasses ?? 0,
        workouts: exercises.where((item) => item.completed).length,
      ),
      InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('এই সপ্তাহের ব্যায়াম লগ', style: AppTextStyles.cardTitle),
            const SizedBox(height: 12),
            if (exercises.isEmpty)
              Text('এই সপ্তাহে এখনো কোনো ব্যায়াম লগ নেই।', style: AppTextStyles.body.copyWith(color: AppColors.textMuted))
            else
              ...exercises.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${item.exerciseTitle} • ${item.durationText}${item.completed ? ' • সম্পন্ন' : ''}',
                    style: AppTextStyles.body,
                  ),
                ),
              ),
          ],
        ),
      ),
      InfoCard(
        backgroundColor: AppColors.primaryFaint,
        borderColor: AppColors.primaryLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('এই সপ্তাহের পর্যালোচনা', style: AppTextStyles.cardTitle),
            const SizedBox(height: 8),
            Text(
              weeklyCalories.asData?.value.isEmpty ?? true
                  ? 'এই সপ্তাহে এখনো কোনো লগ নেই।'
                  : 'আপনার বাস্তব ক্যালরি লগ অনুযায়ী এই সপ্তাহের ধারাবাহিকতা এখানে দেখা যাচ্ছে। আরও লগ করলে বিশ্লেষণ আরও নির্ভুল হবে।',
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        20,
        AppSpacing.screenPadding,
        120,
      ),
      itemCount: widgets.length,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: index == widgets.length - 1 ? 0 : AppSpacing.cardGap),
        child: FadeUpItem(index: index, child: widgets[index]),
      ),
    );
  }
}

double? _averageWeeklyCalories(Map<String, double>? data) {
  if (data == null || data.isEmpty) {
    return null;
  }
  final nonZero = data.values.where((value) => value > 0).toList();
  if (nonZero.isEmpty) {
    return null;
  }
  return nonZero.reduce((a, b) => a + b) / nonZero.length;
}

int? _goalMetPercent(Map<String, double>? data, int goal) {
  if (data == null || data.isEmpty || goal <= 0) {
    return null;
  }
  final logged = data.values.where((value) => value > 0).toList();
  if (logged.isEmpty) {
    return null;
  }
  final met = logged.where((value) => value <= goal).length;
  return ((met / logged.length) * 100).round();
}

List<double> _buildWeekBars(Map<String, double> weekly) {
  final start = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  return List.generate(7, (index) {
    final date = start.add(Duration(days: index));
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return weekly[key] ?? 0;
  });
}

class _JourneyStat extends StatelessWidget {
  const _JourneyStat({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.metricSmall),
        ],
      ),
    );
  }
}

class _WeeklyCaloriesChart extends StatelessWidget {
  const _WeeklyCaloriesChart({
    required this.weekData,
    required this.dailyGoal,
  });

  final List<double> weekData;
  final double dailyGoal;

  @override
  Widget build(BuildContext context) {
    final hasAnyData = weekData.any((value) => value > 0);
    final maxValue = dailyGoal > 0 ? (dailyGoal * 1.2).clamp(1000, 4000) : 2000;
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('সাপ্তাহিক ক্যালরি চার্ট', style: AppTextStyles.cardTitle),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxValue.toDouble(),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                alignment: BarChartAlignment.spaceAround,
                extraLinesData: dailyGoal > 0
                    ? ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: dailyGoal,
                            color: AppColors.red.withValues(alpha: 0.5),
                            dashArray: [5, 4],
                            strokeWidth: 1.4,
                          ),
                        ],
                      )
                    : const ExtraLinesData(),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['সো', 'মঙ্গ', 'বুধ', 'বৃহ', 'শু', 'শনি', 'রবি'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(days[value.toInt()], style: AppTextStyles.caption),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(weekData.length, (index) {
                  final value = weekData[index];
                  final isToday = index == DateTime.now().weekday - 1;
                  final isFuture = index > DateTime.now().weekday - 1;
                  final color = isFuture
                      ? AppColors.border
                      : value == 0
                          ? AppColors.border
                          : value > dailyGoal && dailyGoal > 0
                              ? AppColors.amber
                              : isToday
                                  ? AppColors.primary
                                  : AppColors.primaryLight;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        color: color,
                        width: 20,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          if (!hasAnyData) ...[
            const SizedBox(height: 12),
            Text('এখনো কোনো ডেটা নেই। খাবার লগ শুরু করুন।', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}

class _HealthGoalProgress extends StatelessWidget {
  const _HealthGoalProgress({
    required this.profile,
    required this.summaryWater,
    required this.workouts,
  });

  final UserProfile? profile;
  final int summaryWater;
  final int workouts;

  @override
  Widget build(BuildContext context) {
    final conditions = profile?.conditions ?? const <HealthCondition>[];
    final items = <({String title, IconData icon, double ratio})>[];

    if (conditions.contains(HealthCondition.bellyFat)) {
      items.add((title: 'পেটের চর্বি', icon: Icons.accessibility_new_rounded, ratio: workouts / 7));
    }
    if (conditions.contains(HealthCondition.ed) || conditions.contains(HealthCondition.prematureEjaculation)) {
      items.add((title: 'পুরুষ স্বাস্থ্য', icon: Icons.male_rounded, ratio: 0));
    }
    if (conditions.contains(HealthCondition.urinaryIssues)) {
      items.add((title: 'মূত্রজনিত', icon: Icons.water_drop_rounded, ratio: summaryWater / 8));
    }
    if (conditions.contains(HealthCondition.digestiveIssues)) {
      items.add((title: 'হজমজনিত', icon: Icons.spa_rounded, ratio: 0));
    }
    if (items.isEmpty) {
      items.add((title: 'সামগ্রিক স্বাস্থ্য', icon: Icons.favorite_rounded, ratio: 0));
    }

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('স্বাস্থ্য লক্ষ্যমাত্রা', style: AppTextStyles.cardTitle),
          const SizedBox(height: 14),
          for (var i = 0; i < items.length; i++) ...[
            _GoalProgressRow(
              title: items[i].title,
              icon: items[i].icon,
              ratio: items[i].ratio.clamp(0.0, 1.0),
            ),
            if (i != items.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _GoalProgressRow extends StatelessWidget {
  const _GoalProgressRow({
    required this.title,
    required this.icon,
    required this.ratio,
  });

  final String title;
  final IconData icon;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final hasData = ratio > 0;
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: AppTextStyles.bodyLarge)),
            Text(
              hasData ? '${(ratio * 100).round()}%' : 'ট্র্যাকিং শুরু হয়নি',
              style: AppTextStyles.caption.copyWith(color: hasData ? AppColors.primary : AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: hasData ? ratio : 0,
            minHeight: 8,
            backgroundColor: AppColors.border,
            color: AppColors.primaryLight,
          ),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 8),
          Text(message, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
