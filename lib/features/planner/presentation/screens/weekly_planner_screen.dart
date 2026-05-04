import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design.dart';
import '../../../../core/utils/bengali_formatters.dart';
import '../../../../core/widgets/fade_up_item.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../data/models/weekly_plan.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../home/providers/home_provider.dart';
import '../../providers/planner_provider.dart';

class WeeklyPlannerScreen extends ConsumerWidget {
  const WeeklyPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlan = ref.watch(weeklyMealPlanProvider);
    final exercises = ref.watch(todayExercisesProvider).asData?.value ?? const <WeeklyExerciseItem>[];
    final completionCount = exercises.where((item) => item.completed).length.clamp(0, 7);

    final widgets = <Widget>[
      _WeeklyProgressHeader(completedDays: completionCount),
      mealPlan.when(
        data: (plan) {
          if (plan == null) {
            return const _EmptyDataCard(
              title: 'এই সপ্তাহের খাবার পরিকল্পনা এখনো তৈরি হয়নি',
              message: 'প্রোফাইল সম্পূর্ণ থাকলে এই সপ্তাহের ব্যক্তিগত meal plan এখানে দেখা যাবে।',
            );
          }

          final todayKey = _todayWeekKey();
          final todayPlan = plan.days[todayKey];

          return Column(
            children: [
              _PlanHeroCard(plan: plan, todayPlan: todayPlan),
              const SizedBox(height: AppSpacing.cardGap),
              if (todayPlan == null)
                const _EmptyDataCard(
                  title: 'আজকের প্ল্যান পাওয়া যায়নি',
                  message: 'এই সপ্তাহের প্ল্যানে আজকের entry নেই।',
                )
              else
                _TodayPlanSection(dayPlan: todayPlan),
              const SizedBox(height: AppSpacing.cardGap),
              _WeeklyCalendar(plan: plan, todayKey: todayKey),
              if (plan.weeklyTips.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.cardGap),
                _TipsCard(tips: plan.weeklyTips),
              ],
              if (plan.specialNotes.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.cardGap),
                InfoCard(
                  backgroundColor: AppColors.primaryFaint,
                  borderColor: AppColors.primaryLight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('বিশেষ নোট', style: AppTextStyles.cardTitle),
                      const SizedBox(height: 10),
                      Text(plan.specialNotes, style: AppTextStyles.body),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const _LoadingCard(title: 'AI meal plan তৈরি হচ্ছে...'),
        error: (error, stackTrace) => _EmptyDataCard(
          title: 'প্ল্যান আনা যায়নি',
          message: _friendlyError(error),
        ),
      ),
      exercises.isEmpty
          ? const _EmptyDataCard(
              title: 'আজকের ব্যায়াম এখনো তৈরি হয়নি',
              message: 'AI আপনার প্রোফাইল অনুযায়ী আজকের ব্যায়াম তৈরি করলে এখানে দেখাবে।',
            )
          : _ExerciseCard(exercises: exercises),
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
    required this.plan,
    required this.todayPlan,
  });

  final WeeklyMealPlan plan;
  final WeeklyMealPlanDay? todayPlan;

  @override
  Widget build(BuildContext context) {
    final totalToday = todayPlan == null
        ? 0.0
        : todayPlan!.morning.calories + todayPlan!.lunch.calories + todayPlan!.afternoon.calories + todayPlan!.night.calories;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).brightness == Brightness.dark ? const Color(0xFF143122) : const Color(0xFF1B5E3B),
            Theme.of(context).brightness == Brightness.dark ? const Color(0xFF204B35) : const Color(0xFF2D6A4F),
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(27, 94, 59, 0.24),
            blurRadius: 26,
            spreadRadius: -8,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'AI meal plan',
                  style: AppTextStyles.screenTitle.copyWith(color: AppColors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'এই সপ্তাহের বাস্তব ডেটা',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            todayPlan == null
                ? 'এই সপ্তাহের পরিকল্পনা তৈরি হয়েছে, কিন্তু আজকের slot এখনো পাওয়া যায়নি।'
                : 'আজকের জন্য মোট প্রায় ${BengaliFormatters.toBengaliNumber(totalToday.round())} kcal-এর balanced দেশীয় meal plan প্রস্তুত আছে।',
            style: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.92)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroMiniStat(
                label: 'সপ্তাহ',
                value: plan.weekOf.isEmpty ? '—' : plan.weekOf.substring(5),
              ),
              const SizedBox(width: 10),
              _HeroMiniStat(
                label: 'আজ',
                value: todayPlan == null ? '—' : '${BengaliFormatters.toBengaliNumber(totalToday.round())} kcal',
              ),
              const SizedBox(width: 10),
              _HeroMiniStat(
                label: 'টিপস',
                value: BengaliFormatters.toBengaliNumber(plan.weeklyTips.length),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  const _HeroMiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.metricSmall.copyWith(
                color: AppColors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
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
          Text('আজকের পরিকল্পনা', style: AppTextStyles.cardTitle),
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
    final hasItems = slot.items.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF122119) : AppColors.primaryFaint,
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
                  color: Colors.white.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.06 : 0.92),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppTextStyles.bodyLarge)),
              Text(
                hasItems ? '${BengaliFormatters.toBengaliNumber(slot.calories.round())} kcal' : '—',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasItems)
            Text('এখনো কোনো item নেই', style: AppTextStyles.body.copyWith(color: AppColors.textMuted))
          else
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: slot.items.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.06 : 0.95),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    slot.items[index],
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryMid,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
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
          Text('সাপ্তাহিক ক্যালেন্ডার', style: AppTextStyles.cardTitle),
          const SizedBox(height: 14),
          Row(
            children: labels.map((entry) {
              final dayPlan = plan.days[entry.$1];
              final hasData = dayPlan != null &&
                  (dayPlan.morning.items.isNotEmpty ||
                      dayPlan.lunch.items.isNotEmpty ||
                      dayPlan.afternoon.items.isNotEmpty ||
                      dayPlan.night.items.isNotEmpty);
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
          Text('এই সপ্তাহের টিপস', style: AppTextStyles.cardTitle),
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

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({required this.exercises});

  final List<WeeklyExerciseItem> exercises;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('আজকের ব্যায়াম', style: AppTextStyles.cardTitle),
          const SizedBox(height: 12),
          ...exercises.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: item.completed
                      ? AppColors.primaryFaint
                      : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF13231B) : AppColors.white),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: item.completed ? AppColors.primaryLight : AppColors.border),
                ),
                child: Row(
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
                    Checkbox(
                      value: item.completed,
                      onChanged: (value) async {
                        await ref.read(plannerRepositoryProvider).toggleExercise(item.id, value ?? false);
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

class _EmptyDataCard extends StatelessWidget {
  const _EmptyDataCard({
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
          Text(message, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _WeeklyProgressHeader extends StatelessWidget {
  const _WeeklyProgressHeader({required this.completedDays});

  final int completedDays;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      backgroundColor: AppColors.primaryFaint,
      borderColor: AppColors.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('এই সপ্তাহের অগ্রগতি', style: AppTextStyles.cardTitle),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final active = index < completedDays;
              final isToday = index == DateTime.now().weekday - 1;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isToday ? 18 : 14,
                height: isToday ? 18 : 14,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.border,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            '${BengaliFormatters.toBengaliNumber(completedDays)}/৭ দিন লক্ষ্য পূরণ হয়েছে',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
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

String _friendlyError(Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('permission-denied')) {
    return 'ডেটা পড়ার অনুমতি পাওয়া যায়নি। Firebase rules sync হওয়ার পর আবার চেষ্টা করুন।';
  }
  if (text.contains('socketexception') || text.contains('failed host lookup')) {
    return 'ইন্টারনেট সংযোগ পাওয়া যাচ্ছে না।';
  }
  return 'এই মুহূর্তে প্ল্যান আনা যাচ্ছে না। একটু পরে আবার চেষ্টা করুন।';
}
