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

class WeeklyPlannerScreen extends ConsumerWidget {
  const WeeklyPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).asData?.value;
    final planAsync = ref.watch(weeklyMealPlanProvider);
    final exerciseItems = ref.watch(todayExercisesProvider).asData?.value ?? const <WeeklyExerciseItem>[];

    if (profile == null) {
      return const SizedBox.shrink();
    }

    final plan = planAsync.asData?.value;
    final renderPlan = plan ?? _buildPreviewPlan(profile);
    final renderExercises = exerciseItems.isNotEmpty ? exerciseItems : _buildPreviewExercises(profile);
    final completedCount = renderExercises.where((item) => item.completed).length;
    final points = completedCount * 10;
    final badgeCount = points ~/ 100;
    final todayKey = _todayWeekKey();
    final todayPlan = renderPlan.days[todayKey];

    final widgets = <Widget>[
      _WeeklyProgressHeader(
        completedItems: completedCount,
        totalItems: renderExercises.length,
        points: points,
        badgeCount: badgeCount,
      ),
      _PlanHeroCard(
        profile: profile,
        plan: renderPlan,
        todayPlan: todayPlan,
      ),
      if (todayPlan != null) ...[
        _MacroGoalCard(profile: profile),
        _TodayPlanSection(dayPlan: todayPlan),
      ],
      _WeeklyCalendar(plan: renderPlan, todayKey: todayKey),
      if (renderPlan.weeklyTips.isNotEmpty) _TipsCard(tips: renderPlan.weeklyTips),
      if (renderPlan.specialNotes.trim().isNotEmpty)
        InfoCard(
          backgroundColor: AppColors.primaryFaint,
          borderColor: AppColors.primaryLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('এই সপ্তাহের বিশেষ গাইড', style: AppTextStyles.cardTitle),
              const SizedBox(height: 10),
              Text(renderPlan.specialNotes, style: AppTextStyles.body),
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

class _PlanHeroCard extends StatelessWidget {
  const _PlanHeroCard({
    required this.profile,
    required this.plan,
    required this.todayPlan,
  });

  final UserProfile profile;
  final WeeklyMealPlan plan;
  final WeeklyMealPlanDay? todayPlan;

  @override
  Widget build(BuildContext context) {
    final totalToday = todayPlan == null
        ? 0.0
        : todayPlan!.morning.calories + todayPlan!.lunch.calories + todayPlan!.afternoon.calories + todayPlan!.night.calories;
    final proteinTarget = (profile.weightKg * 1.5).round();
    final carbTarget = (profile.dailyCalorieTarget * 0.5 / 4).round();
    final fatTarget = (profile.dailyCalorieTarget * 0.25 / 9).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF184C30), Color(0xFF256A42), Color(0xFF3E8B5D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(27, 94, 59, 0.22),
            blurRadius: 26,
            spreadRadius: -8,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('আপনার জন্য এই সপ্তাহের খাবার পরিকল্পনা', style: AppTextStyles.screenTitle.copyWith(color: AppColors.white)),
          const SizedBox(height: 10),
          Text(
            'এই সপ্তাহে আপনার শরীর, লক্ষ্য আর সমস্যার ভিত্তিতে ডিম, দুধ, কলা, মাছ, মাংস, ছোলা, কাঠবাদাম, ভাত আর সবজির ভারসাম্য রাখা হয়েছে।',
            style: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.90)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(label: 'আজ', value: '${BengaliFormatters.toBengaliNumber(totalToday.round())} kcal'),
              _HeroPill(label: 'প্রোটিন', value: '${BengaliFormatters.toBengaliNumber(proteinTarget)}g'),
              _HeroPill(label: 'কার্ব', value: '${BengaliFormatters.toBengaliNumber(carbTarget)}g'),
              _HeroPill(label: 'ফ্যাট', value: '${BengaliFormatters.toBengaliNumber(fatTarget)}g'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.caption.copyWith(color: Colors.white70),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroGoalCard extends StatelessWidget {
  const _MacroGoalCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final proteinTarget = (profile.weightKg * 1.5).round();
    final carbTarget = (profile.dailyCalorieTarget * 0.5 / 4).round();
    final fatTarget = (profile.dailyCalorieTarget * 0.25 / 9).round();

    return InfoCard(
      child: Row(
        children: [
          Expanded(child: _MacroGoalMini(label: 'প্রোটিন', value: '${BengaliFormatters.toBengaliNumber(proteinTarget)}g')),
          const SizedBox(width: 10),
          Expanded(child: _MacroGoalMini(label: 'কার্ব', value: '${BengaliFormatters.toBengaliNumber(carbTarget)}g')),
          const SizedBox(width: 10),
          Expanded(child: _MacroGoalMini(label: 'ফ্যাট', value: '${BengaliFormatters.toBengaliNumber(fatTarget)}g')),
        ],
      ),
    );
  }
}

class _MacroGoalMini extends StatelessWidget {
  const _MacroGoalMini({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.metricSmall.copyWith(fontSize: 20)),
        ],
      ),
    );
  }
}

class _TodayPlanSection extends StatelessWidget {
  const _TodayPlanSection({required this.dayPlan});

  final WeeklyMealPlanDay dayPlan;

  @override
  Widget build(BuildContext context) {
    final slots = <({String title, String emoji, PlannedMealSlot slot})>[
      (title: 'সকাল', emoji: '🌅', slot: dayPlan.morning),
      (title: 'দুপুর', emoji: '☀️', slot: dayPlan.lunch),
      (title: 'বিকাল', emoji: '🌤', slot: dayPlan.afternoon),
      (title: 'রাত', emoji: '🌙', slot: dayPlan.night),
    ];

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('আজ কী কী খাওয়া উচিত', style: AppTextStyles.cardTitle),
          const SizedBox(height: 12),
          ...slots.asMap().entries.map((entry) {
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: entry.key == slots.length - 1 ? 0 : 12),
              child: _MealPlanRow(title: item.title, emoji: item.emoji, slot: item.slot),
            );
          }),
        ],
      ),
    );
  }
}

class _MealPlanRow extends StatelessWidget {
  const _MealPlanRow({
    required this.title,
    required this.emoji,
    required this.slot,
  });

  final String title;
  final String emoji;
  final PlannedMealSlot slot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppTextStyles.bodyLarge)),
              Text(
                '${BengaliFormatters.toBengaliNumber(slot.calories.round())} kcal',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: slot.items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      item,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryMid,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _WeeklyCalendar extends StatelessWidget {
  const _WeeklyCalendar({
    required this.plan,
    required this.todayKey,
  });

  final WeeklyMealPlan plan;
  final String todayKey;

  @override
  Widget build(BuildContext context) {
    const labels = <(String key, String label)>[
      ('monday', 'সো'),
      ('tuesday', 'মঙ্গ'),
      ('wednesday', 'বুধ'),
      ('thursday', 'বৃহ'),
      ('friday', 'শু'),
      ('saturday', 'শনি'),
      ('sunday', 'রবি'),
    ];

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('এই সপ্তাহের দিনভিত্তিক গাইড', style: AppTextStyles.cardTitle),
          const SizedBox(height: 14),
          Row(
            children: labels.map((entry) {
              final dayPlan = plan.days[entry.$1];
              final hasData = dayPlan != null;
              final isToday = entry.$1 == todayKey;
              return Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: isToday ? 40 : 34,
                      height: isToday ? 40 : 34,
                      decoration: BoxDecoration(
                        color: hasData ? AppColors.primaryPale : AppColors.border.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isToday ? AppColors.primary : Colors.transparent,
                          width: 1.4,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        hasData ? Icons.check_rounded : Icons.remove_rounded,
                        color: hasData ? AppColors.primary : AppColors.textMuted,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(entry.$2, style: AppTextStyles.caption),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.tips});

  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ডাক্তারের ছোট গাইড', style: AppTextStyles.cardTitle),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(tip, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRoadmapCard extends ConsumerWidget {
  const _ExerciseRoadmapCard({
    required this.exercises,
    required this.onToggle,
  });

  final List<WeeklyExerciseItem> exercises;
  final Future<void> Function(WeeklyExerciseItem item, bool completed) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = exercises.where((item) => item.completed).length;
    final points = completed * 10;
    final nextBadgeAt = points >= 100 ? (((points ~/ 100) + 1) * 100) : 100;
    final progress = exercises.isEmpty ? 0.0 : completed / exercises.length;

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('আজকের ব্যায়াম রোডম্যাপ', style: AppTextStyles.cardTitle),
          const SizedBox(height: 8),
          Text(
            'আজকের কাজগুলোর প্রতিটা সম্পন্ন করলে ${BengaliFormatters.toBengaliNumber(10)} পয়েন্ট করে পাবেন।',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryFaint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'আপনি সুস্থ হতে ${BengaliFormatters.toBengaliNumber(points)} পয়েন্ট এগিয়েছেন',
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  points >= 100
                      ? 'আপনি ${BengaliFormatters.toBengaliNumber(points ~/ 100)}টি ব্যাজ অর্জন করেছেন।'
                      : 'পরের ব্যাজ পেতে আরও ${BengaliFormatters.toBengaliNumber(nextBadgeAt - points)} পয়েন্ট বাকি।',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...exercises.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: item.completed ? AppColors.primaryFaint : AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: item.completed ? AppColors.primaryLight : AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.exerciseTitle, style: AppTextStyles.bodyLarge),
                          const SizedBox(height: 4),
                          Text(
                            '${item.durationText} • ${BengaliFormatters.toBengaliNumber(item.caloriesBurned.round())} kcal',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 8),
                          Text(item.conditionBenefit, style: AppTextStyles.body),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Checkbox(
                      value: item.completed,
                      onChanged: item.id.isEmpty
                          ? null
                          : (value) async {
                              await onToggle(item, value ?? false);
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyProgressHeader extends StatelessWidget {
  const _WeeklyProgressHeader({
    required this.completedItems,
    required this.totalItems,
    required this.points,
    required this.badgeCount,
  });

  final int completedItems;
  final int totalItems;
  final int points;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final progress = totalItems == 0 ? 0.0 : completedItems / totalItems;

    return InfoCard(
      backgroundColor: AppColors.primaryFaint,
      borderColor: AppColors.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('এই সপ্তাহের অগ্রগতি', style: AppTextStyles.cardTitle),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${BengaliFormatters.toBengaliNumber(points)} পয়েন্ট',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          Text(
            badgeCount > 0
                ? 'আপনি ${BengaliFormatters.toBengaliNumber(badgeCount)}টি ব্যাজ পেয়েছেন।'
                : 'প্রতিটি চেকমার্ক আপনাকে ধীরে ধীরে লক্ষ্য পূরণের দিকে এগিয়ে নিচ্ছে।',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

WeeklyMealPlan _buildPreviewPlan(UserProfile profile) {
  final dailyTarget = profile.dailyCalorieTarget.toDouble();
  final breakfastCalories = dailyTarget * 0.22;
  final lunchCalories = dailyTarget * 0.36;
  final snackCalories = dailyTarget * 0.14;
  final dinnerCalories = dailyTarget * 0.28;

  WeeklyMealPlanDay day(List<String> breakfast, List<String> lunch, List<String> snack, List<String> dinner) {
    return WeeklyMealPlanDay(
      morning: PlannedMealSlot(items: breakfast, calories: breakfastCalories),
      lunch: PlannedMealSlot(items: lunch, calories: lunchCalories),
      afternoon: PlannedMealSlot(items: snack, calories: snackCalories),
      night: PlannedMealSlot(items: dinner, calories: dinnerCalories),
    );
  }

  final proteinHint = (profile.weightKg * 1.5).round();
  final carbHint = (profile.dailyCalorieTarget * 0.5 / 4).round();
  final fatHint = (profile.dailyCalorieTarget * 0.25 / 9).round();

  return WeeklyMealPlan(
    weekOf: '',
    days: {
      'monday': day(['২টি ডিম', 'দুধ', 'কলা'], ['২ প্লেট ভাত', 'মাছ', 'ডাল', 'শাক'], ['ছোলা', 'কাঠবাদাম'], ['১ প্লেট ভাত', 'মুরগি', 'সবজি']),
      'tuesday': day(['চিড়া', 'দই', 'ডিম'], ['ভাত', 'মুরগি', 'সবজি', 'ডাল'], ['আপেল', 'বাদাম'], ['রুটি', 'মাছ', 'শাক']),
      'wednesday': day(['ডিম', 'ওটস', 'কলা'], ['ভাত', 'ডাল', 'মাছ', 'সালাদ'], ['দই', 'ছোলা'], ['রুটি', 'ডিম', 'সবজি']),
      'thursday': day(['দুধ', 'ছোলার ঘুগনি', 'ডিম'], ['ভাত', 'মুরগি', 'শাক', 'ডাল'], ['মুড়ি', 'বাদাম'], ['রুটি', 'ডাল', 'লাউ']),
      'friday': day(['২টি ডিম', 'চিড়া', 'দই'], ['ভাত', 'মাছ', 'সবজি', 'ডাল'], ['চিনাবাদাম', 'ফল'], ['রুটি', 'মুরগি', 'সবজি']),
      'saturday': day(['ডিম', 'দুধ', 'কলা'], ['ভাত', 'গরুর মাংস', 'সালাদ', 'ডাল'], ['দই', 'কাঠবাদাম'], ['রুটি', 'মাছ', 'শাক']),
      'sunday': day(['চিড়া', 'ডিম', 'কলা'], ['ভাত', 'মাছ', 'সবজি', 'ডাল'], ['ছোলা', 'আপেল'], ['রুটি', 'ডিম', 'সবজি']),
    },
    weeklyTips: [
      'এই সপ্তাহে প্রায় ${BengaliFormatters.toBengaliNumber(proteinHint)}g প্রোটিন, ${BengaliFormatters.toBengaliNumber(carbHint)}g কার্ব আর ${BengaliFormatters.toBengaliNumber(fatHint)}g ফ্যাটের দিকে লক্ষ্য রাখুন।',
      'ডিম, দুধ, মাছ, মাংস, ছোলা, কাঠবাদাম আর ভাত ভারসাম্য রেখে সাজানো হয়েছে।',
    ],
    specialNotes: 'আপনার প্রোফাইল অনুযায়ী এমনভাবে খাবার সাজানো হয়েছে যেন শক্তি, পুনরুদ্ধার আর স্বাভাবিক সুস্থ জীবনযাপন স্থির থাকে।',
  );
}

List<WeeklyExerciseItem> _buildPreviewExercises(UserProfile profile) {
  return [
    WeeklyExerciseItem(
      id: '',
      exerciseTitle: 'সকাল • ৫ মিনিট শ্বাস-প্রশ্বাস অনুশীলন',
      durationMinutes: 5,
      caloriesBurned: 20,
      note: '',
      conditionBenefit: 'দিনটা স্থিরভাবে শুরু করতে আর মানসিক চাপ কমাতে সাহায্য করবে।',
      completed: false,
      dateKey: '',
      loggedAt: DateTime.now(),
    ),
    WeeklyExerciseItem(
      id: '',
      exerciseTitle: 'দুপুর • ১০ মিনিট দ্রুত হাঁটা',
      durationMinutes: 10,
      caloriesBurned: 45,
      note: '',
      conditionBenefit: profile.conditions.contains(HealthCondition.diabetes)
          ? 'রক্তে শর্করা নিয়ন্ত্রণে রাখতে সাহায্য করবে।'
          : 'দৈনিক চলাফেরা আর বিপাকক্রিয়া বাড়াবে।',
      completed: false,
      dateKey: '',
      loggedAt: DateTime.now(),
    ),
    WeeklyExerciseItem(
      id: '',
      exerciseTitle: profile.conditions.contains(HealthCondition.ed) || profile.conditions.contains(HealthCondition.prematureEjaculation)
          ? 'বিকাল • ১০ মিনিট কেগেল অনুশীলন'
          : 'বিকাল • ১০ মিনিট স্কোয়াট',
      durationMinutes: 10,
      caloriesBurned: 40,
      note: '',
      conditionBenefit: profile.conditions.contains(HealthCondition.ed) || profile.conditions.contains(HealthCondition.prematureEjaculation)
          ? 'পেলভিক ফ্লোর শক্তিশালী করতে সাহায্য করবে।'
          : 'শরীরের নিচের অংশের সক্রিয়তা আর সহনশীলতা বাড়াবে।',
      completed: false,
      dateKey: '',
      loggedAt: DateTime.now(),
    ),
    WeeklyExerciseItem(
      id: '',
      exerciseTitle: 'রাত • ১০ মিনিট মেডিটেশন',
      durationMinutes: 10,
      caloriesBurned: 20,
      note: '',
      conditionBenefit: 'পুনরুদ্ধার আর ঘুমের মান ভালো করতে সাহায্য করবে।',
      completed: false,
      dateKey: '',
      loggedAt: DateTime.now(),
    ),
  ];
}

String _todayWeekKey() {
  switch (DateTime.now().weekday) {
    case DateTime.monday:
      return 'monday';
    case DateTime.tuesday:
      return 'tuesday';
    case DateTime.wednesday:
      return 'wednesday';
    case DateTime.thursday:
      return 'thursday';
    case DateTime.friday:
      return 'friday';
    case DateTime.saturday:
      return 'saturday';
    case DateTime.sunday:
      return 'sunday';
  }
  return 'monday';
}
