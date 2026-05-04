import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      return const _HomeLoadingView();
    }
    if (profile == null) {
      return const _HomeLoadingView();
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
    final instantAdvice = _buildInstantAdvice(
      profile: profile,
      summary: summary,
      targetMacros: targetMacros,
      steps: todaySteps,
      sleep: todaySleep,
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
        children: [
          GreetingHeader(profile: profile),
          const SizedBox(height: 14),
          _DoctorNoteCard(
            note: note,
            instantAdvice: instantAdvice,
          ),
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
          _FastingCard(settings: settings),
          if (wellness != null) ...[
            const SizedBox(height: 14),
            _AchievementCard(snapshot: wellness),
          ],
          if (queuedItems > 0) ...[
            const SizedBox(height: 14),
            _OfflineQueueCard(count: queuedItems),
          ],
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

  String _buildInstantAdvice({
    required dynamic profile,
    required DailySummary summary,
    required NutritionMacro targetMacros,
    required StepLogRecord? steps,
    required SleepLogRecord? sleep,
  }) {
    final now = DateTime.now();
    final consumed = summary.consumedMacros;
    final water = summary.waterGlasses;
    final stepCount = steps?.steps ?? 0;
    final sleepHours = sleep?.hours ?? 0;
    final proteinRatio = targetMacros.protein <= 0 ? 0 : consumed.protein / targetMacros.protein;

    if (summary.meals.isEmpty) {
      if (now.hour < 11) {
        return '${profile.name.split(' ').first}, সকালটা হালকা কিন্তু পুষ্টিকর খাবার দিয়ে শুরু করুন। আজকের প্রথম খাবার লগ করলেই আমি পরের পরামর্শ আরও নির্ভুলভাবে দেব।';
      }
      return '${profile.name.split(' ').first}, আজ এখনো কোনো খাবার লগ হয়নি। এখন যা খাচ্ছেন সেটা লিখে বা ছবি তুলে দিন, আমি সঙ্গে সঙ্গে গাইড করব।';
    }

    if (water < 3 && now.hour >= 10) {
      final remaining = 8 - water;
      return '${profile.name.split(' ').first}, আজ পানি এখনো কম হয়েছে। এখন এক গ্লাস পানি খেলেই লক্ষ্যের দিকে ${BengaliFormatters.toBengaliNumber(remaining - 1 < 0 ? 0 : remaining - 1)} গ্লাস বাকি থাকবে।';
    }

    if (sleepHours > 0 && sleepHours < 6) {
      return '${profile.name.split(' ').first}, আজকের ঘুম কম হয়েছে। আজ বিকেলের পর ক্যাফেইন কমিয়ে রাতে একটু আগে ঘুমালে শরীর দ্রুত recover করবে।';
    }

    if (proteinRatio < 0.35 && now.hour >= 18) {
      return '${profile.name.split(' ').first}, আজ প্রোটিন এখনো কম আছে। রাতের খাবারে ডিম, ডাল, মাছ বা মুরগি রাখলে balance ভালো হবে।';
    }

    if (stepCount > 0 && stepCount < profile.dailyStepTarget * 0.35 && now.hour >= 17) {
      return '${profile.name.split(' ').first}, আজ হাঁটা এখনো কম হয়েছে। ১৫–২০ মিনিট brisk walk করলে step target-এর দিকে ভালো অগ্রগতি হবে।';
    }

    return '${profile.name.split(' ').first}, আজকের routine মোটামুটি ঠিক আছে। এখন শুধু পানি, হাঁটা আর পরের meal-এর balance ঠিক রাখলেই দিনটা সুন্দর যাবে।';
  }
}

class _DoctorNoteCard extends StatelessWidget {
  const _DoctorNoteCard({
    required this.note,
    required this.instantAdvice,
  });

  final DoctorNoteRecord? note;
  final String instantAdvice;

  @override
  Widget build(BuildContext context) {
    final title = note == null
        ? 'এখনকার জন্য দ্রুত পরামর্শ'
        : (doctorNoteCategoryLabels[note!.category] ?? 'ডাক্তারের নোট');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF173B2B), Color(0xFF23583F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(20, 67, 46, 0.20),
            blurRadius: 24,
            spreadRadius: -10,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  note?.content ?? instantAdvice,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.white.withValues(alpha: 0.95),
                    height: 1.45,
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

class _FastingCard extends ConsumerStatefulWidget {
  const _FastingCard({required this.settings});

  final AppSettings settings;

  @override
  ConsumerState<_FastingCard> createState() => _FastingCardState();
}

class _FastingCardState extends ConsumerState<_FastingCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final now = DateTime.now();
    final startedAt = _resolveStartTime(settings, now);
    final total = Duration(hours: settings.fastingWindowHours);
    final elapsed = settings.fastingEnabled && startedAt != null ? now.difference(startedAt) : Duration.zero;
    final safeElapsed = elapsed.isNegative ? Duration.zero : elapsed;
    final remaining = safeElapsed >= total ? Duration.zero : total - safeElapsed;
    final progress = settings.fastingEnabled && total.inMinutes > 0
        ? (safeElapsed.inMinutes / total.inMinutes).clamp(0.0, 1.0)
        : 0.0;

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
                child: const Icon(Icons.hourglass_bottom_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('ইন্টারমিটেন্ট ফাস্টিং', style: AppTextStyles.cardTitle),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: settings.fastingEnabled ? AppColors.primaryPale : AppColors.border.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  settings.fastingEnabled ? 'চালু' : 'বন্ধ',
                  style: AppTextStyles.caption.copyWith(
                    color: settings.fastingEnabled ? AppColors.primary : AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!settings.fastingEnabled || startedAt == null) ...[
            Text(
              'ফাস্টিং শুরু করলে এখানে real-time countdown দেখাবে। আপনি এখনই শুরু করতে পারেন, বা আগের কোনো সময়ও সেট করতে পারেন।',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ] else ...[
            Text(
              'শুরু: ${_formatDateTime(startedAt)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FastingMetric(
                    title: 'পেরিয়েছে',
                    value: _formatDuration(safeElapsed),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FastingMetric(
                    title: 'বাকি আছে',
                    value: _formatDuration(remaining),
                    highlighted: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: AppColors.border,
                color: remaining == Duration.zero ? AppColors.primary : AppColors.primaryLight,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _setStartedAt(DateTime.now()),
                  child: const Text('এখন শুরু'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'সময় ঠিক করুন',
                  onPressed: _pickCustomStart,
                  height: 46,
                  icon: Icons.schedule_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickWindow,
                  child: Text('${BengaliFormatters.toBengaliNumber(settings.fastingWindowHours)} ঘণ্টার উইন্ডো'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(appSettingsProvider.notifier).save(
                          settings.copyWith(
                            fastingEnabled: false,
                            clearFastingStartedAt: true,
                          ),
                        );
                  },
                  child: const Text('বন্ধ করুন'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DateTime? _resolveStartTime(AppSettings settings, DateTime now) {
    final raw = settings.fastingStartedAtIso;
    if (raw != null && raw.trim().isNotEmpty) {
      return DateTime.tryParse(raw)?.toLocal();
    }
    if (!settings.fastingEnabled) {
      return null;
    }
    var candidate = DateTime(now.year, now.month, now.day, settings.fastingStartHour);
    if (candidate.isAfter(now)) {
      candidate = candidate.subtract(const Duration(days: 1));
    }
    return candidate;
  }

  Future<void> _setStartedAt(DateTime value) async {
    final settings = widget.settings;
    await ref.read(appSettingsProvider.notifier).save(
          settings.copyWith(
            fastingEnabled: true,
            fastingStartHour: value.hour,
            fastingStartedAtIso: value.toIso8601String(),
          ),
        );
    HapticFeedback.selectionClick();
  }

  Future<void> _pickCustomStart() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now,
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) {
      return;
    }
    final startedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await _setStartedAt(startedAt);
  }

  Future<void> _pickWindow() async {
    final controller = TextEditingController(text: '${widget.settings.fastingWindowHours}');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ফাস্টিং সময় ঠিক করুন', style: AppTextStyles.cardTitle),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'যেমন ১২, ১৪, ১৬'),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'সংরক্ষণ করুন',
              onPressed: () async {
                final value = int.tryParse(controller.text.trim());
                if (value == null) {
                  return;
                }
                await ref.read(appSettingsProvider.notifier).save(
                      widget.settings.copyWith(fastingWindowHours: value.clamp(8, 24)),
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day}/${dateTime.month} $hour:$minute $suffix';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours <= 0) {
      return '${BengaliFormatters.toBengaliNumber(minutes)} মিনিট';
    }
    return '${BengaliFormatters.toBengaliNumber(hours)} ঘ ${BengaliFormatters.toBengaliNumber(minutes)} মি';
  }
}

class _FastingMetric extends StatelessWidget {
  const _FastingMetric({
    required this.title,
    required this.value,
    this.highlighted = false,
  });

  final String title;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primaryFaint : AppColors.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlighted ? AppColors.primaryLight : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.caption),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.metricSmall.copyWith(
              color: highlighted ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
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

class _ActivitySnapshotCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final stepValue = steps?.steps ?? 0;
    final sleepValue = sleep?.hours ?? 0;
    final activeCalories = steps?.activeCalories ?? 0;
    final waterRemaining = (8 - water).clamp(0, 8);

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
              Expanded(child: Text('আজকের অ্যাক্টিভিটি', style: AppTextStyles.cardTitle)),
              if (wearableEnabled)
                TextButton.icon(
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    await ref.read(healthSyncServiceProvider).syncToday();
                  },
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('সিঙ্ক'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniActivity(
                  label: 'হাঁটা',
                  value: stepValue == 0 ? '—' : BengaliFormatters.toBengaliNumber(stepValue),
                  subtitle: targetSteps > 0 ? '/${BengaliFormatters.toBengaliNumber(targetSteps)}' : 'আজ',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniActivity(
                  label: 'ঘুম',
                  value: sleepValue == 0 ? '—' : BengaliFormatters.toBengaliNumber(sleepValue, fractionDigits: 1),
                  subtitle: 'ঘণ্টা',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniActivity(
                  label: 'ব্যায়াম',
                  value: completedExercises == 0 ? '—' : BengaliFormatters.toBengaliNumber(completedExercises),
                  subtitle: activeCalories > 0 ? '${BengaliFormatters.toBengaliNumber(activeCalories.round())} kcal' : 'সমাপ্ত',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('পানি', style: AppTextStyles.bodyLarge),
              const Spacer(),
              Text(
                water == 0
                    ? 'পানি পান শুরু করুন 💧'
                    : 'আজ ${BengaliFormatters.toBengaliNumber(water)}/৮ গ্লাস • আরও ${BengaliFormatters.toBengaliNumber(waterRemaining)} বাকি',
                style: AppTextStyles.caption.copyWith(
                  color: water == 0 ? AppColors.textMuted : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(8, (index) {
              final filled = index < water;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 7 ? 0 : 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await ref.read(dailySummaryProvider.notifier).setWaterCount(index + 1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 46,
                      decoration: BoxDecoration(
                        color: filled ? AppColors.blue : AppColors.pageBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: filled ? AppColors.blue : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.water_drop_rounded,
                        color: filled ? AppColors.white : const Color(0xFFB2DFDB),
                        size: filled ? 20 : 18,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: water / 8,
            minHeight: 6,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: AppColors.border,
            color: AppColors.blue,
          ),
          const SizedBox(height: 12),
          Text(
            wearableEnabled
                ? (stepValue == 0
                    ? 'ডিভাইস sync চালু আছে। কয়েক পা হাঁটলেই বা Health data এলে এখানে automatic update হবে।'
                    : 'আজ ${BengaliFormatters.toBengaliNumber(stepValue)} স্টেপ হয়েছে • active ${BengaliFormatters.toBengaliNumber(activeCalories.round())} kcal')
                : 'Wearable sync বন্ধ আছে। profile থেকে চালু করলে device data automatic আসবে।',
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
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

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
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.caption),
        ],
      ),
    );
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
              '$countটি offline log sync-এর অপেক্ষায় আছে। ইন্টারনেট এলেই এগুলো নিজে থেকেই update হবে।',
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
        children: const [
          _SkeletonBox(height: 48, radius: 18),
          SizedBox(height: 14),
          _SkeletonBox(height: 96, radius: 22),
          SizedBox(height: 14),
          _SkeletonBox(height: 250, radius: 22),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _SkeletonBox(height: 108, radius: 20)),
              SizedBox(width: 10),
              Expanded(child: _SkeletonBox(height: 108, radius: 20)),
              SizedBox(width: 10),
              Expanded(child: _SkeletonBox(height: 108, radius: 20)),
            ],
          ),
          SizedBox(height: 14),
          _SkeletonBox(height: 230, radius: 22),
          SizedBox(height: 14),
          _SkeletonBox(height: 190, radius: 22),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.height,
    required this.radius,
  });

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          colors: [Color(0xFFF5FAF7), Color(0xFFEAF4EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
    );
  }
}
