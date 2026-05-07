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
    
    // Graceful fallback if today's slots are empty/unpopulated in the database/AI plan
    var todayPlan = renderPlan.days[todayKey];
    final fallbackPlan = _buildPreviewPlan(profile);
    if (todayPlan == null ||
        (todayPlan.morning.items.isEmpty &&
         todayPlan.lunch.items.isEmpty &&
         todayPlan.afternoon.items.isEmpty &&
         todayPlan.night.items.isEmpty) ||
        (todayPlan.morning.calories == 0 && todayPlan.lunch.calories == 0)) {
      todayPlan = fallbackPlan.days[todayKey];
    }

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
        // Removed the highly redundant _MacroGoalCard since targets are now beautifully integrated into the hero card itself!
        _TodayPlanSection(dayPlan: todayPlan),
      ],
      _WeeklyCalendar(plan: renderPlan, todayKey: todayKey),
      if (renderPlan.weeklyTips.isNotEmpty) _TipsCard(tips: renderPlan.weeklyTips),
      if (renderPlan.specialNotes.trim().isNotEmpty)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDCFCE7)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(22, 101, 52, 0.03),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.04),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'এই সপ্তাহের বিশেষ গাইড',
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 16, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                renderPlan.specialNotes,
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFF166534),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCECE4)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(27, 94, 59, 0.03),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'আপনার জন্য এই সপ্তাহের খাবার পরিকল্পনা',
            style: AppTextStyles.screenTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          // Clean layout of target macros styled like a premium tracker
          Row(
            children: [
              Expanded(
                child: _MacroMiniCard(
                  label: 'আজকের লক্ষ্য',
                  value: '${BengaliFormatters.toBengaliNumber(totalToday.round())}',
                  unit: 'kcal',
                  color: const Color(0xFF2D6A4F),
                  icon: Icons.local_fire_department_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroMiniCard(
                  label: 'প্রোটিন',
                  value: '${BengaliFormatters.toBengaliNumber(proteinTarget)}',
                  unit: 'g',
                  color: const Color(0xFF1E88E5),
                  icon: Icons.egg_alt_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroMiniCard(
                  label: 'কার্বস',
                  value: '${BengaliFormatters.toBengaliNumber(carbTarget)}',
                  unit: 'g',
                  color: const Color(0xFF43A047),
                  icon: Icons.grain_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroMiniCard(
                  label: 'ফ্যাট',
                  value: '${BengaliFormatters.toBengaliNumber(fatTarget)}',
                  unit: 'g',
                  color: const Color(0xFFF57C00),
                  icon: Icons.opacity_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroMiniCard extends StatelessWidget {
  const _MacroMiniCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EDE7)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: unit,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    final slots = <({String title, String emoji, PlannedMealSlot slot, _MealSlotTheme theme})>[
      (
        title: 'সকাল',
        emoji: '🌅',
        slot: dayPlan.morning,
        theme: const _MealSlotTheme(
          bg: Color(0xFFFFFBEB),
          border: Color(0xFFFDE68A),
          text: Color(0xFFB45309),
          accent: Color(0xFFD97706),
        )
      ),
      (
        title: 'দুপুর',
        emoji: '☀️',
        slot: dayPlan.lunch,
        theme: const _MealSlotTheme(
          bg: Color(0xFFF0FDF4),
          border: Color(0xFFBBF7D0),
          text: Color(0xFF15803D),
          accent: Color(0xFF16A34A),
        )
      ),
      (
        title: 'বিকাল',
        emoji: '🌤',
        slot: dayPlan.afternoon,
        theme: const _MealSlotTheme(
          bg: Color(0xFFF0FDFA),
          border: Color(0xFF99F6E4),
          text: Color(0xFF0F766E),
          accent: Color(0xFF0D9488),
        )
      ),
      (
        title: 'রাত',
        emoji: '🌙',
        slot: dayPlan.night,
        theme: const _MealSlotTheme(
          bg: Color(0xFFF5F3FF),
          border: Color(0xFFDDD6FE),
          text: Color(0xFF6D28D9),
          accent: Color(0xFF7C3AED),
        )
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryFaint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text('আজকের খাদ্যতালিকা', style: AppTextStyles.cardTitle),
            ],
          ),
          const SizedBox(height: 18),
          ...slots.asMap().entries.map((entry) {
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: entry.key == slots.length - 1 ? 0 : 12),
              child: _MealPlanRow(
                title: item.title,
                emoji: item.emoji,
                slot: item.slot,
                theme: item.theme,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MealSlotTheme {
  const _MealSlotTheme({
    required this.bg,
    required this.border,
    required this.text,
    required this.accent,
  });

  final Color bg;
  final Color border;
  final Color text;
  final Color accent;
}

class _MealPlanRow extends StatelessWidget {
  const _MealPlanRow({
    required this.title,
    required this.emoji,
    required this.slot,
    required this.theme,
  });

  final String title;
  final String emoji;
  final PlannedMealSlot slot;
  final _MealSlotTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: theme.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${BengaliFormatters.toBengaliNumber(slot.calories.round())} kcal',
                  style: AppTextStyles.caption.copyWith(
                    color: theme.accent,
                    fontWeight: FontWeight.bold,
                  ),
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
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: theme.border.withValues(alpha: 0.6)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.02),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      item,
                      style: AppTextStyles.caption.copyWith(
                        color: theme.text,
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.01),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryFaint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 12),
              Text('সাপ্তাহিক রুটিন ট্র্যাকার', style: AppTextStyles.cardTitle),
            ],
          ),
          const SizedBox(height: 18),
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
                      width: isToday ? 42 : 36,
                      height: isToday ? 42 : 36,
                      decoration: BoxDecoration(
                        gradient: isToday
                            ? const LinearGradient(
                                colors: [Color(0xFF1B5E3B), Color(0xFF2D6A4F)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: isToday
                            ? null
                            : (hasData ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isToday ? Colors.transparent : (hasData ? const Color(0xFFC8E6C9) : const Color(0xFFE0E0E0)),
                          width: 1.2,
                        ),
                        boxShadow: isToday
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        hasData ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: isToday
                            ? Colors.white
                            : (hasData ? AppColors.primary : Colors.grey.shade400),
                        size: isToday ? 18 : 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.$2,
                      style: AppTextStyles.caption.copyWith(
                        color: isToday ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.01),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF4361EE), size: 18),
              ),
              const SizedBox(width: 12),
              Text('ডাক্তারের ছোট গাইড', style: AppTextStyles.cardTitle),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEDFBF0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC6F6D5)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.01),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'এই সপ্তাহের অগ্রগতি',
                      style: AppTextStyles.cardTitle.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'কাজগুলো ধীরে ধীরে শেষ করুন',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.03),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.military_tech_rounded, color: AppColors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${BengaliFormatters.toBengaliNumber(points)} পয়েন্ট',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: const Color(0xFFE2F8E7),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badgeCount > 0
                ? 'আপনি ${BengaliFormatters.toBengaliNumber(badgeCount)}টি ব্যাজ পেয়েছেন।'
                : 'প্রতিটি কাজ আপনাকে সুস্থতার লক্ষ্যের দিকে এগিয়ে নিয়ে যাচ্ছে।',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
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
