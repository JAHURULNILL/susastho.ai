// ignore_for_file: unnecessary_null_comparison

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design.dart';
import '../../../../core/utils/bengali_formatters.dart';
import '../../../../core/widgets/fade_up_item.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../data/models/health_metrics.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../data/models/wellness_snapshot.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../home/providers/home_provider.dart';
import '../../providers/planner_provider.dart';

class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);
    final exercises = ref.watch(todayExercisesProvider).asData?.value ?? const [];
    final weeklyCalories = ref.watch(weeklyCaloriesProvider).asData?.value ?? const <String, double>{};
    final profile = ref.watch(userProfileProvider).asData?.value;
    final weightHistory = ref.watch(weightHistoryProvider).asData?.value ?? const <WeightHistoryEntry>[];
    final wellness = ref.watch(wellnessSnapshotProvider).asData?.value;
    final summary = dashboard?.summary;
    final dailyGoal = profile?.dailyCalorieTarget ?? 0;
    final avgCalories = _averageWeeklyCalories(weeklyCalories);
    final goalPercent = _goalMetPercent(weeklyCalories, dailyGoal);

    if (profile == null) {
      return const _JourneyLoadingView();
    }

    final widgets = <Widget>[
      InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('এই সপ্তাহের জার্নি', style: AppTextStyles.screenTitle),
            const SizedBox(height: 8),
            Text(
              profile == null
                  ? 'জার্নির তথ্য এখানে দেখা যাবে।'
                  : 'আপনার খাওয়া, পানি, ব্যায়াম, ঘুম আর ওজনের বাস্তব অগ্রগতি এখানে একসাথে দেখানো হচ্ছে।',
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
              value: avgCalories == null ? '—' : BengaliFormatters.toBengaliNumber(avgCalories.round()),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _JourneyStat(
              title: 'লক্ষ্য পূরণ',
              value: goalPercent == null ? '—' : '${BengaliFormatters.toBengaliNumber(goalPercent)}%',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _JourneyStat(
              title: 'রুটিন দিন',
              value: exercises.isEmpty
                  ? '—'
                  : BengaliFormatters.toBengaliNumber(exercises.where((e) => e.completed).length),
            ),
          ),
        ],
      ),
      _WeeklyCaloriesChart(
        weekData: _buildWeekBars(weeklyCalories),
        dailyGoal: dailyGoal.toDouble(),
      ),
      _WeightTrendCard(entries: weightHistory),
      _HealthGoalProgress(
        profile: profile,
        summaryWater: summary?.waterGlasses ?? 0,
        workouts: exercises.where((item) => item.completed).length,
      ),
      if (wellness != null) _JourneyAchievementsCard(snapshot: wellness),
      InfoCard(
        backgroundColor: AppColors.primaryFaint,
        borderColor: AppColors.primaryLight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('🤖 এই সপ্তাহের পর্যালোচনা', style: AppTextStyles.cardTitle),
                ),
                if (wellness != null)
                  TextButton.icon(
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(text: wellness.shareText),
                    ),
                    icon: const Icon(Icons.ios_share_rounded, size: 16),
                    label: const Text('শেয়ার'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              weeklyCalories.values.where((value) => value > 0).isEmpty
                  ? 'প্রথম সপ্তাহের শেষে আপনার বিশ্লেষণ এখানে দেখাবে।'
                  : _weeklyReviewText(
                      avgCalories: avgCalories,
                      goalPercent: goalPercent,
                      workoutCount: exercises.where((item) => item.completed).length,
                      profile: profile,
                      wellness: wellness,
                    ),
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

  String _weeklyReviewText({
    required double? avgCalories,
    required int? goalPercent,
    required int workoutCount,
    required UserProfile? profile,
    required WellnessSnapshot? wellness,
  }) {
    final goalLabel = profile?.goal.labelBn ?? 'স্বাস্থ্য লক্ষ্য';
    final caloriesPart = avgCalories == null
        ? 'এখনো যথেষ্ট ক্যালরি ডেটা নেই।'
        : 'এই সপ্তাহে প্রতিদিন গড়ে ${BengaliFormatters.toBengaliNumber(avgCalories.round())} kcal হয়েছে।';
    final goalPart = goalPercent == null
        ? 'লক্ষ্য পূরণের হার এখনো তৈরি হয়নি।'
        : 'লক্ষ্য পূরণের হার ${BengaliFormatters.toBengaliNumber(goalPercent)}%।';
    final workoutPart = workoutCount == 0
        ? 'ব্যায়াম routine এখনো শুরু হয়নি।'
        : '${BengaliFormatters.toBengaliNumber(workoutCount)}টি exercise entry completed হয়েছে।';
    final streakPart = wellness == null || wellness.calorieStreakDays == 0
        ? 'এখনো streak তৈরি হয়নি।'
        : '${BengaliFormatters.toBengaliNumber(wellness.calorieStreakDays)} দিনের ক্যালরি স্ট্রিক চলছে।';
    return '$caloriesPart $goalPart $workoutPart $streakPart আপনার $goalLabel যাত্রায় ধারাবাহিকতা এখন সবচেয়ে গুরুত্বপূর্ণ।';
  }
}

double? _averageWeeklyCalories(Map<String, double> data) {
  final nonZero = data.values.where((value) => value > 0).toList();
  if (nonZero.isEmpty) {
    return null;
  }
  return nonZero.reduce((a, b) => a + b) / nonZero.length;
}

int? _goalMetPercent(Map<String, double> data, int goal) {
  if (goal <= 0) {
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
    final maxY = dailyGoal > 0 ? (dailyGoal * 1.2).clamp(800, 4000).toDouble() : 2200.0;

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('সাপ্তাহিক ক্যালরি চার্ট', style: AppTextStyles.cardTitle),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: dailyGoal > 0
                    ? ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: dailyGoal,
                            color: AppColors.red.withValues(alpha: 0.35),
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
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(days[value.toInt()], style: AppTextStyles.caption),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    spots: List.generate(
                      weekData.length,
                      (index) => FlSpot(index.toDouble(), weekData[index]),
                    ),
                    color: AppColors.primary,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryLight.withValues(alpha: 0.35),
                          AppColors.primaryLight.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primary,
                        strokeWidth: 2,
                        strokeColor: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!hasAnyData) ...[
            const SizedBox(height: 12),
            Text(
              'এখনো কোনো ডেটা নেই। খাবার লগ শুরু করুন।',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeightTrendCard extends StatelessWidget {
  const _WeightTrendCard({required this.entries});

  final List<WeightHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final reversed = entries.toList().reversed.toList();
    final hasData = reversed.length >= 2;
    final minWeight = hasData
        ? reversed.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b) - 1
        : 0.0;
    final maxWeight = hasData
        ? reversed.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b) + 1
        : 1.0;

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ওজনের ধারা', style: AppTextStyles.cardTitle),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            child: hasData
                ? LineChart(
                    LineChartData(
                      minY: minWeight,
                      maxY: maxWeight,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) =>
                            FlLine(color: AppColors.border, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= reversed.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(reversed[index].dateKey.substring(5), style: AppTextStyles.caption),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          spots: List.generate(
                            reversed.length,
                            (index) => FlSpot(index.toDouble(), reversed[index].weightKg),
                          ),
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 4,
                              color: AppColors.primary,
                              strokeWidth: 2,
                              strokeColor: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'ওজন ট্র্যাকিং শুরু হলে এখানে চার্ট দেখাবে।',
                      style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                    ),
                  ),
          ),
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
              ratio: items[i].ratio.clamp(0.0, 1.0).toDouble(),
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
              style: AppTextStyles.caption.copyWith(
                color: hasData ? AppColors.primary : AppColors.textMuted,
              ),
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

class _JourneyAchievementsCard extends StatelessWidget {
  const _JourneyAchievementsCard({required this.snapshot});

  final WellnessSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('স্ট্রিক ও মাইলস্টোন', style: AppTextStyles.cardTitle),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _JourneyMilestone(
                  label: 'ক্যালরি স্ট্রিক',
                  value: snapshot.calorieStreakDays == 0 ? '—' : '${snapshot.calorieStreakDays}',
                  accent: AppColors.amber,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _JourneyMilestone(
                  label: 'পানি স্ট্রিক',
                  value: snapshot.waterStreakDays == 0 ? '—' : '${snapshot.waterStreakDays}',
                  accent: AppColors.blue,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _JourneyMilestone(
                  label: 'অ্যাক্টিভ দিন',
                  value: snapshot.activeDays == 0 ? '—' : '${snapshot.activeDays}',
                  accent: AppColors.primary,
                ),
              ),
            ],
          ),
          if (snapshot.achievements.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: snapshot.achievements.map((achievement) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFaint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${achievement.emoji} ${achievement.title}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _JourneyMilestone extends StatelessWidget {
  const _JourneyMilestone({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.metricSmall.copyWith(color: accent)),
        ],
      ),
    );
  }
}

class _JourneyLoadingView extends StatelessWidget {
  const _JourneyLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        20,
        AppSpacing.screenPadding,
        120,
      ),
      children: const [
        _JourneySkeleton(height: 126),
        SizedBox(height: AppSpacing.cardGap),
        Row(
          children: [
            Expanded(child: _JourneySkeleton(height: 96)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: _JourneySkeleton(height: 96)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: _JourneySkeleton(height: 96)),
          ],
        ),
        SizedBox(height: AppSpacing.cardGap),
        _JourneySkeleton(height: 264),
        SizedBox(height: AppSpacing.cardGap),
        _JourneySkeleton(height: 220),
        SizedBox(height: AppSpacing.cardGap),
        _JourneySkeleton(height: 220),
      ],
    );
  }
}

class _JourneySkeleton extends StatelessWidget {
  const _JourneySkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: SizedBox(height: height),
    );
  }
}
