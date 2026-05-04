import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design.dart';
import '../../../../core/widgets/fade_up_item.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../data/models/weekly_plan.dart';
import '../../../home/providers/home_provider.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../providers/planner_provider.dart';

class WeeklyPlannerScreen extends ConsumerWidget {
  const WeeklyPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlan = ref.watch(weeklyMealPlanProvider);
    final exercises = ref.watch(todayExercisesProvider).asData?.value ?? const <WeeklyExerciseItem>[];

    final widgets = <Widget>[
      _WeeklyProgressHeader(
        completedDays: exercises.where((item) => item.completed).length.clamp(0, 7),
      ),
      InfoCard(
        child: Row(
          children: [
            Expanded(child: Text('AI পরিকল্পনা', style: AppTextStyles.screenTitle)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'এই সপ্তাহের বাস্তব ডেটা',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      mealPlan.when(
        data: (plan) {
          if (plan == null) {
            return const _EmptyDataCard(
              title: 'মিল প্ল্যান এখনো তৈরি হয়নি',
              message: 'প্রোফাইল সম্পূর্ণ থাকলে এই সপ্তাহের খাবার পরিকল্পনা এখানে আসবে।',
            );
          }

          final todayKey = _todayWeekKey();
          final todayPlan = plan.days[todayKey];
          if (todayPlan == null) {
            return const _EmptyDataCard(
              title: 'আজকের প্ল্যান নেই',
              message: 'এই সপ্তাহের পরিকল্পনায় আজকের জন্য কোনো এন্ট্রি পাওয়া যায়নি।',
            );
          }

          return Column(
            children: [
              _MealPlanCard(title: 'সকালের পরিকল্পনা', slot: todayPlan.morning),
              const SizedBox(height: AppSpacing.cardGap),
              _MealPlanCard(title: 'দুপুরের পরিকল্পনা', slot: todayPlan.lunch),
              const SizedBox(height: AppSpacing.cardGap),
              _MealPlanCard(title: 'বিকালের পরিকল্পনা', slot: todayPlan.afternoon),
              const SizedBox(height: AppSpacing.cardGap),
              _MealPlanCard(title: 'রাতের পরিকল্পনা', slot: todayPlan.night),
              if (plan.weeklyTips.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.cardGap),
                InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('সপ্তাহের টিপস', style: AppTextStyles.cardTitle),
                      const SizedBox(height: 12),
                      ...plan.weeklyTips.map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(tip, style: AppTextStyles.body),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const _LoadingCard(title: 'মিল প্ল্যান তৈরি হচ্ছে...'),
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
          : InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('আজকের ব্যায়াম', style: AppTextStyles.cardTitle),
                  const SizedBox(height: 12),
                  ...exercises.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ExerciseRow(item: item),
                    ),
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

class _ExerciseRow extends ConsumerWidget {
  const _ExerciseRow({required this.item});

  final WeeklyExerciseItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.completed ? AppColors.primaryFaint : AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
                Text('${item.durationText} • ${item.caloriesBurned.round()} kcal', style: AppTextStyles.caption),
                const SizedBox(height: 6),
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
    );
  }
}

class _MealPlanCard extends StatelessWidget {
  const _MealPlanCard({
    required this.title,
    required this.slot,
  });

  final String title;
  final PlannedMealSlot slot;

  @override
  Widget build(BuildContext context) {
    final hasItems = slot.items.isNotEmpty;
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.cardTitle)),
              Text(
                hasItems ? '${slot.calories.round()} kcal' : '—',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasItems)
            Text('—', style: AppTextStyles.body.copyWith(color: AppColors.textMuted))
          else
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFaint,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    slot.items[index],
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryMid,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemCount: slot.items.length,
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
            '$completedDays/৭ দিন লক্ষ্য পূরণ হয়েছে',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
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
