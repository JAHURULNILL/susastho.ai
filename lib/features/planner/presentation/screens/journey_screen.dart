// ignore_for_file: unnecessary_null_comparison, unused_element

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
import '../../../../data/models/wellness_routine.dart';
import '../../../../data/models/wellness_snapshot.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../home/providers/home_provider.dart';
import '../widgets/wellness_section.dart';
import '../../providers/planner_provider.dart';

class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  _JourneyTab _selectedTab = _JourneyTab.weekly;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            20,
            AppSpacing.screenPadding,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: _JourneyTabChip(
                  label: 'সাপ্তাহিক',
                  selected: _selectedTab == _JourneyTab.weekly,
                  onTap: () => setState(() => _selectedTab = _JourneyTab.weekly),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _JourneyTabChip(
                  label: 'সুস্থতা',
                  selected: _selectedTab == _JourneyTab.wellness,
                  onTap: () => setState(() => _selectedTab = _JourneyTab.wellness),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedTab == _JourneyTab.weekly
              ? const _JourneyWeeklyTab()
              : const JourneyWellnessSection(),
        ),
      ],
    );
  }
}

enum _JourneyTab { weekly, wellness }

class _JourneyTabChip extends StatelessWidget {
  const _JourneyTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            color: selected ? AppColors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _JourneyWeeklyTab extends ConsumerWidget {
  const _JourneyWeeklyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);
    final exercises = ref.watch(todayExercisesProvider).asData?.value ?? const [];
    final weeklyCalories = ref.watch(weeklyCaloriesProvider).asData?.value ?? const <String, double>{};
    final profile = ref.watch(userProfileProvider).asData?.value;
    final weightHistory = ref.watch(weightHistoryProvider).asData?.value ?? const <WeightHistoryEntry>[];
    final wellness = ref.watch(wellnessSnapshotProvider).asData?.value;
    final previousWeeklyCalories = ref.watch(previousWeeklyCaloriesProvider).asData?.value ?? const <String, double>{};
    final previousWeeklySteps = ref.watch(previousWeeklyStepsProvider).asData?.value ?? const <String, int>{};
    final previousWeeklySleep = ref.watch(previousWeeklySleepProvider).asData?.value ?? const <String, double>{};
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
      _WeekComparisonCard(
        currentCalories: weeklyCalories,
        previousCalories: previousWeeklyCalories,
        currentSteps: ref.watch(weeklyStepsProvider).asData?.value ?? const <String, int>{},
        previousSteps: previousWeeklySteps,
        currentSleep: ref.watch(weeklySleepProvider).asData?.value ?? const <String, double>{},
        previousSleep: previousWeeklySleep,
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
        ? 'ব্যায়াম রুটিন এখনো শুরু হয়নি।'
        : '${BengaliFormatters.toBengaliNumber(workoutCount)}টি ব্যায়াম সম্পন্ন হয়েছে।';
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

class _WeekComparisonCard extends StatelessWidget {
  const _WeekComparisonCard({
    required this.currentCalories,
    required this.previousCalories,
    required this.currentSteps,
    required this.previousSteps,
    required this.currentSleep,
    required this.previousSleep,
  });

  final Map<String, double> currentCalories;
  final Map<String, double> previousCalories;
  final Map<String, int> currentSteps;
  final Map<String, int> previousSteps;
  final Map<String, double> currentSleep;
  final Map<String, double> previousSleep;

  @override
  Widget build(BuildContext context) {
    final calorieText = _comparisonText(
      _averageDouble(currentCalories.values),
      _averageDouble(previousCalories.values),
      suffix: 'kcal',
    );
    final stepText = _comparisonText(
      _averageInt(currentSteps.values),
      _averageInt(previousSteps.values),
      suffix: 'স্টেপ',
    );
    final sleepText = _comparisonText(
      _averageDouble(currentSleep.values),
      _averageDouble(previousSleep.values),
      suffix: 'ঘণ্টা',
      digits: 1,
    );

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('গত সপ্তাহ বনাম এই সপ্তাহ', style: AppTextStyles.cardTitle),
          const SizedBox(height: 12),
          _ComparisonRow(label: 'ক্যালরি', value: calorieText),
          const SizedBox(height: 10),
          _ComparisonRow(label: 'হাঁটা', value: stepText),
          const SizedBox(height: 10),
          _ComparisonRow(label: 'ঘুম', value: sleepText),
        ],
      ),
    );
  }

  String _comparisonText(
    num? current,
    num? previous, {
    required String suffix,
    int digits = 0,
  }) {
    if (current == null && previous == null) {
      return '—';
    }
    if (current != null && previous == null) {
      return '${_bn(current, digits)} $suffix • নতুন শুরু';
    }
    if (current == null && previous != null) {
      return '—';
    }
    final currentValue = current!;
    final previousValue = previous!;
    final diff = currentValue - previousValue;
    final tone = diff == 0 ? 'একই আছে' : diff > 0 ? 'বেড়েছে' : 'কমেছে';
    return '${_bn(currentValue, digits)} $suffix • ${_bn(diff.abs(), digits)} $tone';
  }

  String _bn(num value, int digits) {
    return BengaliFormatters.toBengaliNumber(
      digits == 0 ? value.round() : value,
      fractionDigits: digits,
    );
  }

  double? _averageDouble(Iterable<num> values) {
    final items = values.where((value) => value > 0).toList();
    if (items.isEmpty) {
      return null;
    }
    return items.fold<double>(0, (sum, value) => sum + value.toDouble()) / items.length;
  }

  int? _averageInt(Iterable<int> values) {
    final items = values.where((value) => value > 0).toList();
    if (items.isEmpty) {
      return null;
    }
    return (items.reduce((a, b) => a + b) / items.length).round();
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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

class _WellnessOverviewCard extends StatelessWidget {
  const _WellnessOverviewCard({required this.plan});

  final WellnessRoutinePlan plan;

  @override
  Widget build(BuildContext context) {
    final nextBadgeAt = ((plan.totalScore ~/ 100) + 1) * 100;
    final remaining = nextBadgeAt - plan.totalScore;

    return InfoCard(
      backgroundColor: AppColors.primaryFaint,
      borderColor: AppColors.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('আজকের Wellness Journey', style: AppTextStyles.cardTitle),
          const SizedBox(height: 10),
          Text(plan.progressMessage, style: AppTextStyles.body),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _JourneyMilestone(
                  label: 'আজকের পয়েন্ট',
                  value: '${plan.earnedPoints}/${plan.totalPoints}',
                  accent: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _JourneyMilestone(
                  label: 'ব্যাজ',
                  value: plan.badgesEarned == 0 ? '—' : '${plan.badgesEarned}',
                  accent: AppColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: plan.progressRatio.clamp(0, 1),
              minHeight: 10,
              backgroundColor: AppColors.border,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remaining <= 0
                ? 'নতুন ব্যাজ আনলক হয়েছে।'
                : 'আর $remaining পয়েন্ট হলে পরের ব্যাজ পাবেন।',
            style: AppTextStyles.caption.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _WellnessSystemSection extends StatelessWidget {
  const _WellnessSystemSection({
    required this.plan,
    required this.onToggle,
  });

  final WellnessRoutinePlan plan;
  final void Function(WellnessRoutineType type) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ওয়েলনেস সিস্টেম', style: AppTextStyles.cardTitle),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: plan.entries.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, index) => _WellnessModuleCard(entry: plan.entries[index]),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('আজকের অনুশীলন তালিকা', style: AppTextStyles.cardTitle),
              const SizedBox(height: 14),
              for (var i = 0; i < plan.entries.length; i++) ...[
                _WellnessTaskRow(
                  entry: plan.entries[i],
                  onToggle: () => onToggle(plan.entries[i].type),
                ),
                if (i != plan.entries.length - 1) const Divider(height: 22, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WellnessModuleCard extends StatelessWidget {
  const _WellnessModuleCard({required this.entry});

  final WellnessRoutineEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(13, 44, 28, 0.04),
            offset: Offset(0, 2),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Color.fromRGBO(45, 106, 79, 0.10),
            offset: Offset(0, 12),
            blurRadius: 24,
            spreadRadius: -12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.type.iconEmoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 10),
          Text(entry.type.labelBn, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(entry.type.subtitleBn, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Text(
            entry.benefit,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${entry.minutes} মিনিট',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: entry.completed ? AppColors.primaryPale : AppColors.primaryFaint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  entry.completed ? 'সম্পন্ন' : '+${entry.points}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WellnessTaskRow extends StatelessWidget {
  const _WellnessTaskRow({
    required this.entry,
    required this.onToggle,
  });

  final WellnessRoutineEntry entry;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: entry.completed ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: entry.completed ? AppColors.primary : AppColors.border),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 18,
              color: entry.completed ? AppColors.white : AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(entry.timeLabel, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.title,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(entry.instructions, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFaint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${entry.points} পয়েন্ট',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.amberPale,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                  '${entry.streakDays} দিন স্ট্রিক',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.amber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
