import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/bengali_formatters.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../data/models/daily_summary.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../planner/providers/planner_provider.dart';
import '../../providers/home_provider.dart';
import '../widgets/daily_advice_card.dart';
import '../widgets/greeting_header.dart';
import '../widgets/macro_ring_chart.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onOpenScan,
  });

  final VoidCallback onOpenScan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).asData?.value;
    final dashboard = ref.watch(homeDashboardProvider);
    final exercises = ref.watch(weeklyPlannerProvider);

    if (profile == null || dashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = dashboard.summary;
    final firstExercise = exercises.isEmpty ? null : exercises.first;
    final consumedCalories = dashboard.consumedMacros.calories.round();
    final burnedCalories = (summary.waterGlasses * 4) + (profile.dailyStepTarget * 0.04).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      children: [
        GreetingHeader(profile: profile),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: profile.conditions
              .map(
                (condition) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPale,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    condition.labelBn,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        MacroRingChart(
          target: dashboard.targetMacros,
          consumed: dashboard.consumedMacros,
        ),
        const SizedBox(height: 12),
        DailyAdviceCard(advice: dashboard.advice),
        const SizedBox(height: 12),
        _QuickStatsRow(
          burnedCalories: burnedCalories,
          stepTarget: profile.dailyStepTarget,
          waterCount: summary.waterGlasses,
        ),
        const SizedBox(height: 12),
        _WaterTracker(
          count: summary.waterGlasses,
          onTap: (index) => ref.read(dailySummaryProvider.notifier).setWaterCount(index + 1),
        ),
        const SizedBox(height: 12),
        _MealTimelineCard(
          summary: summary,
          targetCalories: profile.dailyCalorieTarget,
          onAddMeal: onOpenScan,
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'দৈনিক পুষ্টি সারসংক্ষেপ',
          child: Column(
            children: [
              _AdequacyBar(
                label: 'প্রোটিন',
                current: dashboard.consumedMacros.protein,
                target: dashboard.targetMacros.protein,
                unit: 'g',
                color: AppColors.chartProtein,
              ),
              const SizedBox(height: 12),
              _AdequacyBar(
                label: 'কার্বস',
                current: dashboard.consumedMacros.carbs,
                target: dashboard.targetMacros.carbs,
                unit: 'g',
                color: AppColors.chartCarbs,
              ),
              const SizedBox(height: 12),
              _AdequacyBar(
                label: 'ফ্যাট',
                current: dashboard.consumedMacros.fat,
                target: dashboard.targetMacros.fat,
                unit: 'g',
                color: AppColors.chartFat,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'আজকের লক্ষ্য',
          child: Row(
            children: [
              Expanded(
                child: _MiniGoalCard(
                  icon: Icons.local_fire_department_rounded,
                  title: 'ক্যালরি লক্ষ্য',
                  value: '${BengaliFormatters.toBengaliNumber(profile.dailyCalorieTarget)} kcal',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniGoalCard(
                  icon: Icons.directions_walk_rounded,
                  title: 'স্টেপ',
                  value: BengaliFormatters.toBengaliNumber(profile.dailyStepTarget),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniGoalCard(
                  icon: Icons.track_changes_rounded,
                  title: 'ফোকাস',
                  value: profile.goal.labelBn,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'আপনার জন্য বিশেষ নজর',
          child: Column(
            children: _buildFocusCards(profile)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FocusInsightCard(
                      title: item.$1,
                      text: item.$2,
                      icon: item.$3,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        if (firstExercise != null) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'আজকের ব্যায়াম',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPale,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.fitness_center_rounded, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(firstExercise.exerciseTitle, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(firstExercise.durationText, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Text(firstExercise.note, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _SectionCard(
          title: 'AI Insight',
          child: Text(
            consumedCalories == 0
                ? 'আজ এখনো কোনো খাবার লগ হয়নি। প্রথম মিল স্ক্যান করলে আপনার অবস্থা আরও নির্ভুলভাবে বুঝতে পারব।'
                : 'আজ ${BengaliFormatters.toBengaliNumber(consumedCalories)} kcal খাওয়া হয়েছে। লক্ষ্য ধরে রাখতে পরের মিলটি হালকা, সুষম এবং কম তেলে রাখুন।',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  List<(String, String, IconData)> _buildFocusCards(UserProfile profile) {
    if (profile.conditions.isEmpty) {
      return const [
        ('নিয়মিত স্ক্যান', 'প্রতিদিন অন্তত ১ বার স্ক্যান করলে পরামর্শ আরও ভালো হবে।', Icons.camera_alt_rounded),
      ];
    }

    return profile.conditions.take(3).map((condition) {
      return switch (condition) {
        HealthCondition.diabetes => ('ডায়াবেটিস নজর', 'সাদা ভাত, মিষ্টি আর বড় portion এ সতর্ক থাকুন।', Icons.bloodtype_rounded),
        HealthCondition.heartDisease => ('হার্ট কেয়ার', 'কম তেল, কম লবণ আর মাছ-শাক বেশি রাখুন।', Icons.favorite_rounded),
        HealthCondition.hypertension => ('প্রেসার কন্ট্রোল', 'অতিরিক্ত লবণ, আচার আর processed খাবার কমান।', Icons.monitor_heart_rounded),
        HealthCondition.bellyFat => ('পেটের চর্বি', 'রাতের খাবার হালকা রাখুন আর sugary drinks এড়িয়ে চলুন।', Icons.accessibility_new_rounded),
        HealthCondition.obesity => ('ওজন নিয়ন্ত্রণ', 'portion control আর daily হাঁটা এখন সবচেয়ে জরুরি।', Icons.track_changes_rounded),
        HealthCondition.ed => ('পুরুষ স্বাস্থ্য', 'ঘুম, পানি আর zinc সমৃদ্ধ খাবারে ফোকাস দিন।', Icons.male_rounded),
        HealthCondition.prematureEjaculation => ('স্ট্যামিনা ফোকাস', 'ক্যাফেইন কমিয়ে hydration ও stress control জরুরি।', Icons.bolt_rounded),
        HealthCondition.urinaryIssues => ('মূত্রজনিত যত্ন', 'পানি কমাবেন না, তবে অতিরিক্ত ঝাল খাবার কমান।', Icons.water_drop_rounded),
        HealthCondition.fattyLiver => ('লিভার কেয়ার', 'চর্বিযুক্ত ও ভাজা খাবার কমিয়ে শাকসবজি বাড়ান।', Icons.healing_rounded),
        HealthCondition.kidneyIssues => ('কিডনি যত্ন', 'অতিরিক্ত লবণ আর processed খাবার এড়িয়ে চলুন।', Icons.medical_services_rounded),
        HealthCondition.digestiveIssues => ('হজম কেয়ার', 'কম তেল, ফাইবার আর probiotic খাবার সহায়ক হবে।', Icons.spa_rounded),
        HealthCondition.insomnia => ('ঘুমের রুটিন', 'রাতে ক্যাফেইন ও ভারী খাবার কমিয়ে ঘুমের সময় ঠিক রাখুন।', Icons.nightlight_round),
        HealthCondition.underweight => ('ওজন বাড়ানো', 'প্রোটিন ও calorie-dense ভালো খাবার নিয়মিত রাখুন।', Icons.restaurant_rounded),
      };
    }).toList();
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({
    required this.burnedCalories,
    required this.stepTarget,
    required this.waterCount,
  });

  final int burnedCalories;
  final int stepTarget;
  final int waterCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'পোড়া ক্যালরি', value: '$burnedCalories', suffix: 'kcal', icon: Icons.local_fire_department_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'স্টেপ লক্ষ্য', value: '$stepTarget', suffix: '', icon: Icons.directions_walk_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'পানি', value: '$waterCount', suffix: '/8', icon: Icons.water_drop_rounded)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
  });

  final String label;
  final String value;
  final String suffix;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 18),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            '${BengaliFormatters.toBengaliNumber(num.tryParse(value) ?? 0)}$suffix',
            style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _WaterTracker extends StatelessWidget {
  const _WaterTracker({
    required this.count,
    required this.onTap,
  });

  final int count;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'পানি ট্র্যাকার',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(8, (index) {
              final active = index < count;
              return InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42,
                  height: 54,
                  decoration: BoxDecoration(
                    color: active ? AppColors.info : AppColors.primaryFaint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.water_drop_rounded,
                    color: active ? Colors.white : AppColors.textMuted,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'আজ ${BengaliFormatters.toBengaliNumber(count)} গ্লাস পানি পান করেছেন',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _MealTimelineCard extends StatelessWidget {
  const _MealTimelineCard({
    required this.summary,
    required this.targetCalories,
    required this.onAddMeal,
  });

  final DailySummary summary;
  final int targetCalories;
  final VoidCallback onAddMeal;

  @override
  Widget build(BuildContext context) {
    final total = summary.consumedMacros.calories.round();
    final remaining = (targetCalories - total).clamp(0, targetCalories);

    return _SectionCard(
      title: 'আজকের খাবার সারসংক্ষেপ',
      child: Column(
        children: [
          ...MealSlot.values.map(
            (slot) {
              MealLogEntry? meal;
              for (final item in summary.meals) {
                if (item.slot == slot) {
                  meal = item;
                  break;
                }
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MealRow(
                  slot: slot,
                  meal: meal,
                  onAdd: onAddMeal,
                ),
              );
            },
          ),
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'মোট: ${BengaliFormatters.toBengaliNumber(total)}/${BengaliFormatters.toBengaliNumber(targetCalories)} kcal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                'বাকি ${BengaliFormatters.toBengaliNumber(remaining)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.slot,
    required this.meal,
    required this.onAdd,
  });

  final MealSlot slot;
  final MealLogEntry? meal;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final mealData = meal;

    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(slot.icon, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: mealData == null
              ? Text('${slot.labelBn} — এখনো খাননি', style: Theme.of(context).textTheme.bodyLarge)
              : Text(
                  '${slot.labelBn} ${mealData.foodName} ${mealData.macros.calories.round()} kcal',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
        ),
        IconButton(
          onPressed: mealData == null ? onAdd : null,
          icon: Icon(
            mealData == null ? Icons.add_circle_rounded : Icons.check_circle_rounded,
            color: mealData == null ? AppColors.primaryDark : AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _AdequacyBar extends StatelessWidget {
  const _AdequacyBar({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.color,
  });

  final String label;
  final double current;
  final double target;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = target == 0 ? 0.0 : current / target;
    final percent = (ratio * 100).round();
    final clamped = ratio.clamp(0.0, 1.0);
    final tone = percent <= 40
        ? AppColors.danger
        : percent <= 70
            ? AppColors.warning
            : percent <= 100
                ? AppColors.success
                : Colors.deepOrange;
    final status = percent <= 40
        ? 'অনেক কম'
        : percent <= 70
            ? 'কম'
            : percent <= 100
                ? 'ঠিক আছে'
                : 'বেশি';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
            Text(
              '${BengaliFormatters.toBengaliNumber(current, fractionDigits: 0)}/${BengaliFormatters.toBengaliNumber(target, fractionDigits: 0)}$unit (${BengaliFormatters.toBengaliNumber(percent) }%) $status',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.16),
            color: tone,
          ),
        ),
      ],
    );
  }
}

class _MiniGoalCard extends StatelessWidget {
  const _MiniGoalCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryDark),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _FocusInsightCard extends StatelessWidget {
  const _FocusInsightCard({
    required this.title,
    required this.text,
    required this.icon,
  });

  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(text, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
