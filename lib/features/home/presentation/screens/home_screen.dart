import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design.dart';
import '../../../../core/utils/bengali_formatters.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../data/models/app_settings.dart';
import '../../../../data/models/daily_summary.dart';
import '../../../../data/models/doctor_note.dart';
import '../../../../data/models/food_analysis_result.dart';
import '../../../../data/models/health_metrics.dart';
import '../../../../data/models/wellness_snapshot.dart';
import '../../../../data/models/weekly_plan.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../planner/providers/planner_provider.dart';
import '../widgets/greeting_header.dart';
import '../widgets/macro_ring_chart.dart';
import '../../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.onOpenScan,
  });

  final VoidCallback onOpenScan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.asData?.value;
    final settings = ref.watch(appSettingsProvider).asData?.value ?? const AppSettings();
    final summary = ref.watch(dailySummaryProvider).asData?.value ??
        const DailySummary(dateKey: '', meals: [], waterGlasses: 0);
    final exercises = ref.watch(todayExercisesProvider).asData?.value ?? const <WeeklyExerciseItem>[];
    final note = ref.watch(activeDoctorNoteProvider).asData?.value;
    final todaySteps = ref.watch(todayStepsProvider).asData?.value;
    final todaySleep = ref.watch(todaySleepProvider).asData?.value;
    final weeklyCalories = ref.watch(weeklyCaloriesProvider).asData?.value ?? const <String, double>{};
    final wellness = ref.watch(wellnessSnapshotProvider).asData?.value;
    final queuedItems = ref.watch(offlineQueueCountProvider).asData?.value ?? 0;

    if (profileAsync.isLoading && profile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (profile == null) {
      return const SizedBox.shrink();
    }

    final targetCalories = (settings.customCalorieGoal ?? profile.dailyCalorieTarget).toDouble();
    final targetMacros = NutritionMacro(
      calories: targetCalories,
      protein: profile.weightKg * 1.5,
      carbs: targetCalories * 0.5 / 4,
      fat: targetCalories * 0.25 / 9,
    );

    final burned = exercises
        .where((item) => item.completed)
        .fold<double>(0, (sum, item) => sum + item.caloriesBurned);
    final netCalories = summary.consumedMacros.calories - burned;
    final streak = wellness?.calorieStreakDays ?? _calculateStreak(weeklyCalories, targetCalories);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
        children: [
          GreetingHeader(profile: profile),
          const SizedBox(height: 18),
          _DoctorNoteCard(note: note),
          const SizedBox(height: 14),
          MacroRingChart(
            target: targetMacros,
            consumed: NutritionMacro(
              calories: netCalories < 0 ? 0 : netCalories,
              protein: summary.consumedMacros.protein,
              carbs: summary.consumedMacros.carbs,
              fat: summary.consumedMacros.fat,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _QuickStatCard(
                  label: 'স্টেপ',
                  value: todaySteps?.steps == null || todaySteps!.steps == 0
                      ? '—'
                      : BengaliFormatters.toBengaliNumber(todaySteps.steps),
                  sublabel: profile.dailyStepTarget > 0
                      ? '/${BengaliFormatters.toBengaliNumber(profile.dailyStepTarget)}'
                      : 'আজ',
                  background: AppColors.bluePale,
                  icon: Icons.directions_walk_rounded,
                  accent: AppColors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickStatCard(
                  label: 'ঘুম',
                  value: todaySleep == null || todaySleep.hours == 0
                      ? '—'
                      : BengaliFormatters.toBengaliNumber(todaySleep.hours, fractionDigits: 1),
                  sublabel: 'ঘণ্টা',
                  background: const Color(0xFFF2EEFF),
                  icon: Icons.bedtime_rounded,
                  accent: const Color(0xFF6C5CE7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickStatCard(
                  label: 'স্ট্রিক',
                  value: streak == 0 ? '—' : BengaliFormatters.toBengaliNumber(streak),
                  sublabel: streak == 0 ? 'শুরু হয়নি' : 'দিন',
                  background: AppColors.amberPale,
                  icon: Icons.local_fire_department_rounded,
                  accent: AppColors.amber,
                ),
              ),
            ],
          ),
          if (wellness != null) ...[
            const SizedBox(height: 14),
            _AchievementCard(snapshot: wellness),
          ],
          if (queuedItems > 0) ...[
            const SizedBox(height: 14),
            _OfflineQueueCard(count: queuedItems),
          ],
          const SizedBox(height: 14),
          _FastingCard(settings: settings),
          const SizedBox(height: 14),
          _ActivitySnapshotCard(
            steps: todaySteps,
            sleep: todaySleep,
            completedExercises: exercises.where((item) => item.completed).length,
            targetSteps: profile.dailyStepTarget,
            water: summary.waterGlasses,
            wearableEnabled: settings.wearableSyncEnabled,
          ),
          const SizedBox(height: 14),
          _DiaryCard(
            meals: summary.meals,
            onOpenScan: onOpenScan,
          ),
        ],
      ),
    );
  }

  int _calculateStreak(Map<String, double> weeklyCalories, double goal) {
    if (goal <= 0 || weeklyCalories.isEmpty) {
      return 0;
    }
    final days = weeklyCalories.keys.toList()..sort();
    var streak = 0;
    for (final day in days.reversed) {
      final value = weeklyCalories[day] ?? 0;
      if (value > 0 && value <= goal) {
        streak += 1;
      } else if (value > 0) {
        break;
      }
    }
    return streak;
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.snapshot});

  final WellnessSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 38, 27, 0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color.fromRGBO(45, 106, 79, 0.09),
            blurRadius: 20,
            spreadRadius: -8,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('এই সপ্তাহের অগ্রগতি', style: AppTextStyles.cardTitle),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryFaint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${BengaliFormatters.toBengaliNumber(snapshot.activeDays)} দিন active',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (snapshot.achievements.isEmpty)
            Text(
              'বাস্তব data জমলেই এখানে streak আর milestone দেখা যাবে।',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: snapshot.achievements
                  .map(
                    (item) => Container(
                      constraints: const BoxConstraints(minWidth: 140, maxWidth: 240),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFaint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.emoji} ${item.title}', style: AppTextStyles.bodyLarge),
                          const SizedBox(height: 4),
                          Text(item.subtitle, style: AppTextStyles.caption),
                        ],
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

class _OfflineQueueCard extends StatelessWidget {
  const _OfflineQueueCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amberPale,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_rounded, color: AppColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$countটি offline log sync-এর অপেক্ষায় আছে। ইন্টারনেট এলে এগুলো নিজে থেকেই আপডেট হবে।',
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorNoteCard extends StatelessWidget {
  const _DoctorNoteCard({required this.note});

  final DoctorNoteRecord? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF163B2A), Color(0xFF236144), Color(0xFF2F7C57)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(20, 67, 46, 0.20),
            blurRadius: 28,
            spreadRadius: -10,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  note == null ? 'ডাক্তারের নোট তৈরি হচ্ছে...' : (doctorNoteCategoryLabels[note!.category] ?? 'ডাক্তারের নোট'),
                  style: AppTextStyles.cardTitle.copyWith(color: AppColors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            note?.content ?? 'AI আপনার বাস্তব ডেটা, খাবার, পানি, ঘুম আর শরীরের লক্ষ্য মিলিয়ে ব্যক্তিগত নোট তৈরি করছে।',
            style: AppTextStyles.body.copyWith(color: AppColors.white, height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.background,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String sublabel;
  final Color background;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 38, 27, 0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color.fromRGBO(45, 106, 79, 0.08),
            blurRadius: 20,
            spreadRadius: -8,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.metricSmall.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(sublabel, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _FastingCard extends StatelessWidget {
  const _FastingCard({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final start = settings.fastingStartHour;
    final end = (start + settings.fastingWindowHours) % 24;
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = start * 60;
    final durationMinutes = settings.fastingWindowHours * 60;
    final elapsed = ((currentMinutes - startMinutes) % (24 * 60)).clamp(0, 24 * 60);
    final progress = settings.fastingEnabled ? (elapsed / durationMinutes).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 38, 27, 0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color.fromRGBO(45, 106, 79, 0.09),
            blurRadius: 20,
            spreadRadius: -8,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryFaint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.timer_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('ইন্টারমিটেন্ট ফাস্টিং', style: AppTextStyles.cardTitle),
              ),
              Text(
                settings.fastingEnabled ? '${BengaliFormatters.toBengaliNumber(settings.fastingWindowHours)}/৮' : 'বন্ধ',
                style: AppTextStyles.caption.copyWith(
                  color: settings.fastingEnabled ? AppColors.primary : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            settings.fastingEnabled
                ? 'আজকের fasting window: ${_hourLabel(start)} - ${_hourLabel(end)}'
                : 'ফাস্টিং timer চালু করলে এখানে আপনার eating window আর progress দেখাবে।',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: settings.fastingEnabled ? progress : 0,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: AppColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }

  String _hourLabel(int hour) {
    final normalized = hour % 24;
    final suffix = normalized >= 12 ? 'PM' : 'AM';
    final twelve = normalized == 0 ? 12 : normalized > 12 ? normalized - 12 : normalized;
    return '$twelve $suffix';
  }
}

class _DiaryCard extends StatelessWidget {
  const _DiaryCard({
    required this.meals,
    required this.onOpenScan,
  });

  final List<MealLogEntry> meals;
  final VoidCallback onOpenScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 38, 27, 0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color.fromRGBO(45, 106, 79, 0.09),
            blurRadius: 20,
            spreadRadius: -8,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('আজকের ডায়েরি', style: AppTextStyles.cardTitle),
          const SizedBox(height: 12),
          if (meals.isEmpty)
            Text(
              'এখনো কোনো খাবার লগ করা হয়নি।',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            )
          else
            ...meals.take(4).map(
              (meal) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(meal.slot.icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meal.foodName,
                        style: AppTextStyles.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${meal.macros.calories.round()} kcal',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'খাবার স্ক্যান করুন',
            onPressed: onOpenScan,
            icon: Icons.add_a_photo_rounded,
          ),
        ],
      ),
    );
  }
}

class _ActivitySnapshotCard extends StatelessWidget {
  const _ActivitySnapshotCard({
    required this.steps,
    required this.sleep,
    required this.completedExercises,
    required this.targetSteps,
    required this.water,
    required this.wearableEnabled,
  });

  final StepLogRecord? steps;
  final SleepLogRecord? sleep;
  final int completedExercises;
  final int targetSteps;
  final int water;
  final bool wearableEnabled;

  @override
  Widget build(BuildContext context) {
    final stepValue = steps?.steps ?? 0;
    final sleepValue = sleep?.hours ?? 0;
    final activeCalories = steps?.activeCalories ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 38, 27, 0.04),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color.fromRGBO(45, 106, 79, 0.09),
            blurRadius: 20,
            spreadRadius: -8,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('আজকের অ্যাক্টিভিটি', style: AppTextStyles.cardTitle),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniActivity(label: 'হাঁটা', value: stepValue == 0 ? '—' : BengaliFormatters.toBengaliNumber(stepValue))),
              const SizedBox(width: 10),
              Expanded(child: _MiniActivity(label: 'পানি', value: water == 0 ? '—' : '${BengaliFormatters.toBengaliNumber(water)}/8')),
              const SizedBox(width: 10),
              Expanded(child: _MiniActivity(label: 'ঘুম', value: sleepValue == 0 ? '—' : BengaliFormatters.toBengaliNumber(sleepValue, fractionDigits: 1))),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            wearableEnabled
                ? (stepValue == 0
                    ? 'Health Connect / Apple Health sync থাকলে স্টেপ, ঘুম আর activity এখানে স্বয়ংক্রিয়ভাবে আসবে।'
                    : 'আজ ${BengaliFormatters.toBengaliNumber(stepValue)} স্টেপ হয়েছে • লক্ষ্য ${BengaliFormatters.toBengaliNumber(targetSteps)} • active ${BengaliFormatters.toBengaliNumber(activeCalories.round())} kcal • ব্যায়াম ${BengaliFormatters.toBengaliNumber(completedExercises)}টি সম্পন্ন')
                : 'Wearable sync বন্ধ আছে। profile থেকে চালু করলে device data এখানে আসবে।',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MiniActivity extends StatelessWidget {
  const _MiniActivity({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.metricSmall.copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }
}
