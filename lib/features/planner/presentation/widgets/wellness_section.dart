import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design.dart';
import '../../../../core/utils/bengali_formatters.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../data/models/wellness_routine.dart';
import '../../providers/planner_provider.dart';

class JourneyWellnessSection extends ConsumerWidget {
  const JourneyWellnessSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(wellnessRoutineProvider);
    final plan = planAsync.asData?.value;

    if (plan == null) {
      return const _WellnessLoadingView();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        20,
        AppSpacing.screenPadding,
        120,
      ),
      children: [
        _OverallProgressCard(plan: plan),
        const SizedBox(height: AppSpacing.cardGap),
        _ModuleGrid(
          plan: plan,
          onOpen: (type) => _openModuleSheet(
            context: context,
            ref: ref,
            type: type,
            plan: plan,
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),
        _WeeklyStreakCalendar(plan: plan),
        const SizedBox(height: AppSpacing.cardGap),
        _DailyBenefitCard(
          text: plan.dailyBenefit,
          loading: plan.isLoadingBenefit,
          onRefresh: () => ref.read(wellnessRoutineProvider.notifier).refreshDailyBenefit(),
        ),
      ],
    );
  }

  Future<void> _openModuleSheet({
    required BuildContext context,
    required WidgetRef ref,
    required WellnessRoutineType type,
    required WellnessRoutinePlan plan,
  }) async {
    final meta = _metaFor(type);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (sheetContext) {
        switch (type) {
          case WellnessRoutineType.breathing:
            return _BreathingSessionSheet(
              meta: meta,
              onComplete: (duration, details) => _completeModule(
                context: sheetContext,
                ref: ref,
                type: type,
                duration: duration,
                details: details,
              ),
            );
          case WellnessRoutineType.kegel:
            return _KegelSessionSheet(
              meta: meta,
              onComplete: (duration, details) => _completeModule(
                context: sheetContext,
                ref: ref,
                type: type,
                duration: duration,
                details: details,
              ),
            );
          case WellnessRoutineType.meditation:
            return _MeditationSessionSheet(
              meta: meta,
              onComplete: (duration, details) => _completeModule(
                context: sheetContext,
                ref: ref,
                type: type,
                duration: duration,
                details: details,
              ),
            );
          case WellnessRoutineType.nofap:
            return _NoFapSheet(
              meta: meta,
              plan: plan,
              onCheckIn: () => _completeModule(
                context: sheetContext,
                ref: ref,
                type: type,
                duration: 0,
                details: const {},
              ),
              onReset: () => _resetNofap(sheetContext, ref),
              onUpdateStreak: (val) => _updateNofapStreak(sheetContext, ref, val),
            );
          case WellnessRoutineType.sleep:
            return _SimpleCompletionSheet(
              meta: meta,
              title: 'রাতের wind-down routine',
              summary: 'স্ক্রিন বন্ধ, আলো কম, আর মন শান্ত রেখে আজকের sleep routine শেষ করুন।',
              bullets: const [
                'ঘুমানোর ১৫ মিনিট আগে স্ক্রিন বন্ধ করুন',
                'হালকা আলো রাখুন',
                'আজকের দিনের চাপ ছেড়ে দিন',
              ],
              actionLabel: 'Sleep routine সম্পন্ন',
              onComplete: () => _completeModule(
                context: sheetContext,
                ref: ref,
                type: type,
                duration: 600,
                details: const {'type': 'night_routine'},
              ),
            );
          case WellnessRoutineType.coldshower:
            return _SimpleCompletionSheet(
              meta: meta,
              title: 'ডিজিটাল ডিটক্স চ্যালেঞ্জ',
              summary: 'পরবর্তী ৩ ঘণ্টা সব ধরনের স্ক্রিন থেকে দূরে থাকুন এবং অফলাইন কাজে সময় দিন।',
              bullets: const [
                'ফোন অন্য ঘরে রাখুন',
                'বই পড়ুন বা পরিবারের সাথে সময় কাটান',
                'প্রকৃতির সাথে বা নিজের সাথে সময় কাটান',
              ],
              actionLabel: 'ডিটক্স শুরু করলাম',
              onComplete: () => _completeModule(
                context: sheetContext,
                ref: ref,
                type: type,
                duration: 10800,
                details: const {'type': 'digital_detox'},
              ),
            );
        }
      },
    );
  }

  Future<void> _completeModule({
    required BuildContext context,
    required WidgetRef ref,
    required WellnessRoutineType type,
    required int duration,
    required Map<String, dynamic> details,
  }) async {
    try {
      await ref.read(wellnessRoutineProvider.notifier).completeModule(
            type,
            duration: duration,
            details: details,
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wellness update রাখা যায়নি: $error')),
        );
      }
      rethrow;
    }
  }

  Future<void> _resetNofap(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(wellnessRoutineProvider.notifier).resetNofap();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset রাখা যায়নি: $error')),
        );
      }
      rethrow;
    }
  }

  Future<void> _updateNofapStreak(BuildContext context, WidgetRef ref, int newStreak) async {
    try {
      await ref.read(wellnessRoutineProvider.notifier).updateNofapStreak(newStreak);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Streak update করা যায়নি: $error')),
        );
      }
      rethrow;
    }
  }
}

class _WellnessLoadingView extends StatelessWidget {
  const _WellnessLoadingView();

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
        InfoCard(child: SizedBox(height: 120)),
        SizedBox(height: AppSpacing.cardGap),
        InfoCard(child: SizedBox(height: 260)),
        SizedBox(height: AppSpacing.cardGap),
        InfoCard(child: SizedBox(height: 220)),
        SizedBox(height: AppSpacing.cardGap),
        InfoCard(child: SizedBox(height: 150)),
      ],
    );
  }
}

class _OverallProgressCard extends StatelessWidget {
  const _OverallProgressCard({required this.plan});

  final WellnessRoutinePlan plan;

  @override
  Widget build(BuildContext context) {
    final ratio = plan.totalModules == 0 ? 0.0 : plan.doneTodayCount / plan.totalModules;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF173926), Color(0xFF21593A), Color(0xFF2C7A4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(23, 57, 38, 0.18),
            blurRadius: 28,
            spreadRadius: -10,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'আজকের Wellness Progress',
            style: AppTextStyles.cardTitle.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '${BengaliFormatters.toBengaliNumber(plan.doneTodayCount)} / ${BengaliFormatters.toBengaliNumber(plan.totalModules)} module আজ সম্পন্ন হয়েছে।',
            style: AppTextStyles.body.copyWith(color: AppColors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              color: AppColors.primaryPale,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  label: 'মোট স্ট্রিক',
                  value: '${BengaliFormatters.toBengaliNumber(plan.totalStreak)} দিন',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatPill(
                  label: 'No Fap',
                  value: '${BengaliFormatters.toBengaliNumber(plan.nofapStreak)} দিন',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({
    required this.plan,
    required this.onOpen,
  });

  final WellnessRoutinePlan plan;
  final ValueChanged<WellnessRoutineType> onOpen;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('আজকের সুস্থতা মডিউল', style: AppTextStyles.cardTitle),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: WellnessRoutineType.values.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              final type = WellnessRoutineType.values[index];
              final meta = _metaFor(type);
              return _ModuleCard(
                meta: meta,
                streak: plan.streakFor(type),
                doneToday: plan.isDoneToday(type),
                onTap: () => onOpen(type),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.meta,
    required this.streak,
    required this.doneToday,
    required this.onTap,
  });

  final _WellnessModuleMeta meta;
  final int streak;
  final bool doneToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: meta.pale,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: doneToday ? meta.color : meta.color.withValues(alpha: 0.18),
            width: doneToday ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(meta.icon, style: const TextStyle(fontSize: 22)),
                const Spacer(),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: doneToday ? meta.color : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    doneToday ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    color: doneToday ? AppColors.white : meta.color,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              meta.title,
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(meta.duration, style: AppTextStyles.caption.copyWith(color: meta.color)),
            const Spacer(),
            Text(
              doneToday ? 'আজ সম্পন্ন' : '${BengaliFormatters.toBengaliNumber(streak)} দিনের স্ট্রিক',
              style: AppTextStyles.caption.copyWith(
                color: doneToday ? meta.color : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyStreakCalendar extends StatelessWidget {
  const _WeeklyStreakCalendar({required this.plan});

  final WellnessRoutinePlan plan;

  @override
  Widget build(BuildContext context) {
    final dates = _lastSevenDays();
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('সাপ্তাহিক স্ট্রিক ডটস', style: AppTextStyles.cardTitle),
          const SizedBox(height: 8),
          Text(
            'প্রতিটি মডিউল গত ৭ দিনে কোন দিনে সম্পন্ন হয়েছে, সেটা এখানে live দেখা যাচ্ছে।',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox(width: 112),
              for (final date in dates)
                Expanded(
                  child: Center(
                    child: Text(
                      _weekdayLabel(date),
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final type in WellnessRoutineType.values) ...[
            _WeekRow(
              plan: plan,
              type: type,
              dates: dates,
            ),
            if (type != WellnessRoutineType.values.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  List<DateTime> _lastSevenDays() {
    final today = DateTime.now();
    return List.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - index)),
    );
  }

  String _weekdayLabel(DateTime date) {
    const labels = <int, String>{
      DateTime.monday: 'সো',
      DateTime.tuesday: 'মং',
      DateTime.wednesday: 'বুধ',
      DateTime.thursday: 'বৃহ',
      DateTime.friday: 'শু',
      DateTime.saturday: 'শনি',
      DateTime.sunday: 'রবি',
    };
    return labels[date.weekday] ?? '';
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.plan,
    required this.type,
    required this.dates,
  });

  final WellnessRoutinePlan plan;
  final WellnessRoutineType type;
  final List<DateTime> dates;

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(type);
    final todayKey = _dateKey(DateTime.now());
    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Row(
            children: [
              Text(meta.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meta.shortTitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final date in dates)
          Expanded(
            child: Center(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: plan.wasDoneOn(type, _dateKey(date)) ? meta.color : meta.pale,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _dateKey(date) == todayKey ? meta.color : meta.color.withValues(alpha: 0.22),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _DailyBenefitCard extends StatelessWidget {
  const _DailyBenefitCard({
    required this.text,
    required this.loading,
    required this.onRefresh,
  });

  final String text;
  final bool loading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      backgroundColor: AppColors.primaryFaint,
      borderColor: AppColors.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('আজকের AI wellness guide', style: AppTextStyles.cardTitle),
              ),
              IconButton(
                onPressed: loading ? null : onRefresh,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text.trim().isEmpty ? 'আজকের wellness অভ্যাসগুলো সম্পন্ন করুন।' : text,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}

class _BreathingSessionSheet extends StatefulWidget {
  const _BreathingSessionSheet({
    required this.meta,
    required this.onComplete,
  });

  final _WellnessModuleMeta meta;
  final Future<void> Function(int duration, Map<String, dynamic> details) onComplete;

  @override
  State<_BreathingSessionSheet> createState() => _BreathingSessionSheetState();
}

class _BreathingSessionSheetState extends State<_BreathingSessionSheet> {
  Timer? _timer;
  final List<_BreathingPattern> _patterns = const [
    _BreathingPattern(label: 'Calm 4-4-6', inhale: 4, hold: 4, exhale: 6, cycles: 5),
    _BreathingPattern(label: 'Focus 4-2-4', inhale: 4, hold: 2, exhale: 4, cycles: 6),
  ];

  int _selectedIndex = 0;
  int _phaseIndex = 0;
  int _remaining = 0;
  int _completedCycles = 0;
  int _elapsed = 0;
  bool _running = false;
  bool _submitting = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pattern = _patterns[_selectedIndex];
    final phase = _currentPhase(pattern);
    final phaseName = _phaseLabel(pattern, phase);

    return _BaseSessionSheet(
      meta: widget.meta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('শ্বাসের phase: $phaseName', style: AppTextStyles.bodyLarge),
          const SizedBox(height: 8),
          Text(
            'Pattern: ${pattern.label} • cycle ${BengaliFormatters.toBengaliNumber(_completedCycles + (_running ? 1 : 0))}/${BengaliFormatters.toBengaliNumber(pattern.cycles)}',
            style: AppTextStyles.caption.copyWith(color: widget.meta.color),
          ),
          const SizedBox(height: 18),
          if (!_running)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_patterns.length, (index) {
                final item = _patterns[index];
                final selected = index == _selectedIndex;
                return ChoiceChip(
                  label: Text(item.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedIndex = index),
                );
              }),
            ),
          const SizedBox(height: 18),
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: phase == _BreathingPhase.inhale ? 160 : phase == _BreathingPhase.hold ? 144 : 120,
              height: phase == _BreathingPhase.inhale ? 160 : phase == _BreathingPhase.hold ? 144 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    widget.meta.color.withValues(alpha: 0.2),
                    widget.meta.color.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _running ? BengaliFormatters.toBengaliNumber(_remaining) : 'শুরু',
                    style: AppTextStyles.metric.copyWith(fontSize: 36),
                  ),
                  const SizedBox(height: 6),
                  Text(phaseName, style: AppTextStyles.body),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SessionActions(
            running: _running,
            submitting: _submitting,
            startLabel: 'Breathing শুরু',
            onStart: _start,
            onStop: _stop,
          ),
        ],
      ),
    );
  }

  void _start() {
    final pattern = _patterns[_selectedIndex];
    setState(() {
      _running = true;
      _submitting = false;
      _phaseIndex = 0;
      _completedCycles = 0;
      _elapsed = 0;
      _remaining = pattern.inhale;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final active = _patterns[_selectedIndex];
      if (_remaining > 1) {
        setState(() {
          _remaining -= 1;
          _elapsed += 1;
        });
        return;
      }

      setState(() {
        _elapsed += 1;
      });

      final nextPhaseIndex = _phaseIndex + 1;
      if (nextPhaseIndex >= _phases(active).length) {
        if (_completedCycles + 1 >= active.cycles) {
          await _finish(active);
          return;
        }
        setState(() {
          _completedCycles += 1;
          _phaseIndex = 0;
          _remaining = active.inhale;
        });
        return;
      }

      final nextPhase = _phases(active)[nextPhaseIndex];
      setState(() {
        _phaseIndex = nextPhaseIndex;
        _remaining = _secondsForPhase(active, nextPhase);
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = 0;
      _phaseIndex = 0;
      _completedCycles = 0;
      _elapsed = 0;
    });
  }

  Future<void> _finish(_BreathingPattern pattern) async {
    _timer?.cancel();
    setState(() {
      _running = false;
      _submitting = true;
    });
    await widget.onComplete(
      _elapsed,
      {
        'type': pattern.label,
        'cycles': pattern.cycles,
      },
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  List<_BreathingPhase> _phases(_BreathingPattern pattern) {
    return [
      _BreathingPhase.inhale,
      if (pattern.hold > 0) _BreathingPhase.hold,
      _BreathingPhase.exhale,
    ];
  }

  _BreathingPhase _currentPhase(_BreathingPattern pattern) {
    final phases = _phases(pattern);
    if (_phaseIndex >= phases.length) {
      return phases.last;
    }
    return phases[_phaseIndex];
  }

  int _secondsForPhase(_BreathingPattern pattern, _BreathingPhase phase) {
    switch (phase) {
      case _BreathingPhase.inhale:
        return pattern.inhale;
      case _BreathingPhase.hold:
        return pattern.hold;
      case _BreathingPhase.exhale:
        return pattern.exhale;
    }
  }

  String _phaseLabel(_BreathingPattern pattern, _BreathingPhase phase) {
    switch (phase) {
      case _BreathingPhase.inhale:
        return 'শ্বাস নিন';
      case _BreathingPhase.hold:
        return pattern.hold > 0 ? 'ধরে রাখুন' : 'শ্বাস নিন';
      case _BreathingPhase.exhale:
        return 'শ্বাস ছাড়ুন';
    }
  }
}

class _KegelSessionSheet extends StatefulWidget {
  const _KegelSessionSheet({
    required this.meta,
    required this.onComplete,
  });

  final _WellnessModuleMeta meta;
  final Future<void> Function(int duration, Map<String, dynamic> details) onComplete;

  @override
  State<_KegelSessionSheet> createState() => _KegelSessionSheetState();
}

class _KegelSessionSheetState extends State<_KegelSessionSheet> {
  Timer? _timer;
  final List<_KegelLevel> _levels = const [
    _KegelLevel(label: 'Beginner', reps: 10, holdSeconds: 4, restSeconds: 4),
    _KegelLevel(label: 'Steady', reps: 12, holdSeconds: 5, restSeconds: 4),
  ];

  int _selectedIndex = 0;
  int _completedReps = 0;
  int _remaining = 0;
  int _elapsed = 0;
  _KegelPhase _phase = _KegelPhase.ready;
  bool _running = false;
  bool _submitting = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = _levels[_selectedIndex];
    final progress = level.reps == 0 ? 0.0 : _completedReps / level.reps;

    return _BaseSessionSheet(
      meta: widget.meta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('আজকের kegel phase: ${_phaseLabel(_phase)}', style: AppTextStyles.bodyLarge),
          const SizedBox(height: 8),
          if (!_running)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_levels.length, (index) {
                final item = _levels[index];
                return ChoiceChip(
                  label: Text('${item.label} • ${item.reps} reps'),
                  selected: index == _selectedIndex,
                  onSelected: (_) => setState(() => _selectedIndex = index),
                );
              }),
            ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: widget.meta.pale,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 8,
                  color: widget.meta.color,
                  backgroundColor: AppColors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  '${BengaliFormatters.toBengaliNumber(_completedReps)}/${BengaliFormatters.toBengaliNumber(level.reps)} reps',
                  style: AppTextStyles.metricSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _running ? 'বাকি ${BengaliFormatters.toBengaliNumber(_remaining)} সেকেন্ড' : 'Ready হলে শুরু করুন',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SessionActions(
            running: _running,
            submitting: _submitting,
            startLabel: 'Kegel শুরু',
            onStart: _start,
            onStop: _stop,
          ),
        ],
      ),
    );
  }

  void _start() {
    final level = _levels[_selectedIndex];
    setState(() {
      _running = true;
      _submitting = false;
      _completedReps = 0;
      _elapsed = 0;
      _phase = _KegelPhase.squeeze;
      _remaining = level.holdSeconds;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final active = _levels[_selectedIndex];
      if (_remaining > 1) {
        setState(() {
          _remaining -= 1;
          _elapsed += 1;
        });
        return;
      }

      setState(() {
        _elapsed += 1;
      });

      if (_phase == _KegelPhase.squeeze) {
        setState(() {
          _phase = _KegelPhase.rest;
          _remaining = active.restSeconds;
        });
        return;
      }

      if (_completedReps + 1 >= active.reps) {
        await _finish(active);
        return;
      }

      setState(() {
        _completedReps += 1;
        _phase = _KegelPhase.squeeze;
        _remaining = active.holdSeconds;
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _completedReps = 0;
      _remaining = 0;
      _elapsed = 0;
      _phase = _KegelPhase.ready;
    });
  }

  Future<void> _finish(_KegelLevel level) async {
    _timer?.cancel();
    setState(() {
      _running = false;
      _submitting = true;
      _completedReps = level.reps;
    });
    await widget.onComplete(
      _elapsed,
      {
        'reps': level.reps,
        'holdTime': level.holdSeconds,
        'setLevel': level.label,
      },
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _phaseLabel(_KegelPhase phase) {
    switch (phase) {
      case _KegelPhase.ready:
        return 'প্রস্তুত';
      case _KegelPhase.squeeze:
        return 'চেপে ধরুন';
      case _KegelPhase.rest:
        return 'রিল্যাক্স করুন';
    }
  }
}

class _MeditationSessionSheet extends StatefulWidget {
  const _MeditationSessionSheet({
    required this.meta,
    required this.onComplete,
  });

  final _WellnessModuleMeta meta;
  final Future<void> Function(int duration, Map<String, dynamic> details) onComplete;

  @override
  State<_MeditationSessionSheet> createState() => _MeditationSessionSheetState();
}

class _MeditationSessionSheetState extends State<_MeditationSessionSheet> {
  Timer? _timer;
  AudioPlayer? _audioPlayer;
  final List<int> _minutes = const [5, 10, 15];
  int _selectedMinutes = 10;
  int _remaining = 0;
  int _elapsed = 0;
  bool _running = false;
  bool _submitting = false;

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = _selectedMinutes * 60;
    final progress = totalSeconds == 0 ? 0.0 : 1 - (_remaining / totalSeconds);
    return _BaseSessionSheet(
      meta: widget.meta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_running)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _minutes.map((value) {
                return ChoiceChip(
                  label: Text('$value মিনিট'),
                  selected: value == _selectedMinutes,
                  onSelected: (_) => setState(() => _selectedMinutes = value),
                );
              }).toList(),
            ),
          const SizedBox(height: 18),
          if (!_running) ...[
            Text('মেডিটেশনের নিয়ম:', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('• শান্ত পরিবেশে মেরুদণ্ড সোজা করে বসুন।\n• চোখ বন্ধ করে স্বাভাবিক শ্বাসের দিকে মনোযোগ দিন।\n• যখনই অন্য চিন্তা আসবে, আবার শ্বাসে ফিরে আসুন।\n• শুরু করলে রিলাক্সিং সাউন্ড প্লে হবে।', style: AppTextStyles.body),
            const SizedBox(height: 18),
          ],
          AnimatedContainer(
            duration: const Duration(milliseconds: 900),
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: widget.meta.pale,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Icon(Icons.self_improvement_rounded, color: widget.meta.color, size: 34),
                const SizedBox(height: 12),
                Text(
                  _running ? _formatRemaining(_remaining) : 'ধ্যান শুরু করুন',
                  style: AppTextStyles.metric.copyWith(fontSize: 34),
                ),
                const SizedBox(height: 8),
                Text(
                  _guideText(progress),
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SessionActions(
            running: _running,
            submitting: _submitting,
            startLabel: 'Meditation শুরু',
            onStart: _start,
            onStop: _stop,
          ),
        ],
      ),
    );
  }

  void _start() {
    final totalSeconds = _selectedMinutes * 60;
    setState(() {
      _running = true;
      _submitting = false;
      _remaining = totalSeconds;
      _elapsed = 0;
    });

    _audioPlayer = AudioPlayer();
    _audioPlayer!.setReleaseMode(ReleaseMode.loop);
    // Playing a calming rain/waves sound
    _audioPlayer!.play(UrlSource('https://actions.google.com/sounds/v1/water/waves_crashing_on_rock_beach.ogg'));

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_remaining > 1) {
        setState(() {
          _remaining -= 1;
          _elapsed += 1;
        });
        return;
      }
      setState(() {
        _elapsed += 1;
      });
      await _finish();
    });
  }

  void _stop() {
    _timer?.cancel();
    _audioPlayer?.stop();
    setState(() {
      _running = false;
      _remaining = 0;
      _elapsed = 0;
    });
  }

  Future<void> _finish() async {
    _timer?.cancel();
    _audioPlayer?.stop();
    setState(() {
      _running = false;
      _submitting = true;
    });
    await widget.onComplete(
      _elapsed,
      {'sessionType': '${_selectedMinutes}_minute'},
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _guideText(double progress) {
    if (!_running) {
      return 'চোখ বন্ধ করে শ্বাসের দিকে মন দিন।';
    }
    if (progress < 0.33) {
      return 'শ্বাসের ছন্দ লক্ষ্য করুন, মনকে ধীরে আনুন।';
    }
    if (progress < 0.66) {
      return 'যে চিন্তা আসছে, শুধু দেখে যেতে থাকুন।';
    }
    return 'এখন মনটা একটু হালকা করুন, session শেষের দিকে।';
  }

  String _formatRemaining(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }
}

class _NoFapSheet extends StatelessWidget {
  const _NoFapSheet({
    required this.meta,
    required this.plan,
    required this.onCheckIn,
    required this.onReset,
    required this.onUpdateStreak,
  });

  final _WellnessModuleMeta meta;
  final WellnessRoutinePlan plan;
  final Future<void> Function() onCheckIn;
  final Future<void> Function() onReset;
  final Future<void> Function(int) onUpdateStreak;

  @override
  Widget build(BuildContext context) {
    final streak = plan.nofapStreak;
    final milestones = <int>[3, 7, 14, 30, 60, 90];
    final benefits = _benefitsFor(streak);
    final isDone = plan.isDoneToday(WellnessRoutineType.nofap);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Premium Slate Black backdrop for Iron Will look
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Indicator and header
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🛡️', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'আত্মশুদ্ধি (Iron Will)',
                            style: AppTextStyles.cardTitle.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'সংযম ও সংকল্প ট্র্যাকার',
                            style: AppTextStyles.caption.copyWith(color: Colors.indigoAccent),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showEditDialog(context, streak),
                      icon: const Icon(Icons.edit_note_rounded, color: Colors.indigoAccent, size: 28),
                      tooltip: 'দিন সেট করুন',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Giant Circular "Iron Will" Counter Section
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner glowing circle background
                      Container(
                        width: 184,
                        height: 184,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E293B),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withValues(alpha: 0.22),
                              blurRadius: 36,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // Circular indicator ring
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: (streak % 30) / 30, // Show daily progress cycle relative to monthly milestones
                          strokeWidth: 6,
                          color: Colors.indigoAccent,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      // Center Counter Texts
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            BengaliFormatters.toBengaliNumber(streak),
                            style: const TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.w900,
                              color: AppColors.white,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'দিনের স্ট্রিক',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.indigoAccent,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // Check-in status capsule
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDone 
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isDone 
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDone ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                          color: isDone ? Colors.green : Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDone 
                              ? 'আজকের দিন সফলভাবে চেক-ইন হয়েছে!' 
                              : 'আত্মসংযম আজ সফলভাবে চলছে...',
                          style: AppTextStyles.caption.copyWith(
                            color: isDone ? Colors.green : Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Milestones Track
                Text(
                  'Milestones & Achievements',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: milestones.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final item = milestones[index];
                      final unlocked = streak >= item;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: unlocked 
                              ? Colors.indigoAccent.withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: unlocked 
                                ? Colors.indigoAccent.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              unlocked ? Icons.verified_rounded : Icons.lock_outline_rounded,
                              color: unlocked ? Colors.indigoAccent : Colors.white38,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${BengaliFormatters.toBengaliNumber(item)} দিন',
                              style: AppTextStyles.caption.copyWith(
                                color: unlocked ? Colors.white : Colors.white38,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // Beautiful Unlocked benefits card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_moon_rounded, color: Colors.indigoAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Unlocked Benefits',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      for (final item in benefits)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('⚡ ', style: TextStyle(fontSize: 16)),
                              Expanded(
                                child: Text(
                                  item,
                                  style: AppTextStyles.body.copyWith(
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Interactive Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: isDone 
                              ? null 
                              : const LinearGradient(
                                  colors: [Colors.indigoAccent, Colors.indigo],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                        ),
                        child: ElevatedButton(
                          onPressed: isDone
                              ? null
                              : () async {
                                  await onCheckIn();
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDone ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isDone ? Icons.check_circle_outline : Icons.bolt_rounded,
                                color: isDone ? Colors.white38 : Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isDone ? 'আজকের জন্য পার করেছেন' : 'আজকের দিন পার করলাম',
                                style: TextStyle(
                                  color: isDone ? Colors.white38 : Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () => _confirmRelapse(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.red,
                            side: BorderSide(color: AppColors.red.withValues(alpha: 0.4), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_toggle_off_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Relapse হয়েছে (Reset)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _benefitsFor(int streak) {
    final benefits = <String>[];
    if (streak >= 1) {
      benefits.add('আজকের আত্মনিয়ন্ত্রণ পেশী আরও একটু শক্তিশালী হয়েছে।');
    }
    if (streak >= 3) {
      benefits.add('ফোকাস এবং আত্মসম্মানবোধ ধীরে ধীরে সুস্থ ও অবিচল হচ্ছে।');
    }
    if (streak >= 7) {
      benefits.add('সাময়িক প্রলোভন নিয়ন্ত্রণের ক্ষমতা আগের চেয়ে অনেক ভালো হচ্ছে।');
    }
    if (streak >= 14) {
      benefits.add('নিজের রুটিনের প্রতি গভীর আস্থা ও মনস্তাত্ত্বিক গিল্ট হ্রাস পেয়েছে।');
    }
    if (streak >= 30) {
      benefits.add('দীর্ঘমেয়াদী সংকল্প ও কঠোর আত্মশাসন গঠনের স্থায়ী ভিত্তি তৈরি হয়েছে।');
    }
    return benefits.isEmpty ? ['প্রতিদিনের সুনির্দিষ্ট চেক-ইন আপনার ভবিষ্যৎ আত্মনিয়ন্ত্রণের মজবুত ভিত্তি গড়ে তোলে।'] : benefits;
  }

  Future<void> _confirmRelapse(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B), // Sleek dialog
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 28),
            const SizedBox(width: 10),
            Text(
              'আপনি কি নিশ্চিত?',
              style: AppTextStyles.cardTitle.copyWith(color: AppColors.white),
            ),
          ],
        ),
        content: Text(
          'রিলেপস সিলেক্ট করলে আপনার কষ্টার্জিত সমস্ত স্ট্রিক ০ দিনে রিসেট হবে এবং নতুন করে সংকল্প শুরু হবে।',
          style: AppTextStyles.body.copyWith(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'ভুল করে চেপেছি',
              style: AppTextStyles.caption.copyWith(color: Colors.white38, fontWeight: FontWeight.bold),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('হ্যাঁ, রিসেট করুন'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await onReset();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _showEditDialog(BuildContext context, int currentStreak) async {
    final controller = TextEditingController(text: currentStreak.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Streak দিন সেট করুন',
          style: AppTextStyles.cardTitle.copyWith(color: AppColors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'কত দিন হয়েছে?',
            labelStyle: const TextStyle(color: Colors.white38),
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.indigoAccent),
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white12),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('বাতিল', style: TextStyle(color: Colors.white38)),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val >= 0) {
                Navigator.of(ctx).pop(val);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.indigoAccent),
            child: const Text('সেভ করুন'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      await onUpdateStreak(result);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

class _SimpleCompletionSheet extends StatelessWidget {
  const _SimpleCompletionSheet({
    required this.meta,
    required this.title,
    required this.summary,
    required this.bullets,
    required this.actionLabel,
    required this.onComplete,
  });

  final _WellnessModuleMeta meta;
  final String title;
  final String summary;
  final List<String> bullets;
  final String actionLabel;
  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context) {
    return _BaseSessionSheet(
      meta: meta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(summary, style: AppTextStyles.body),
          const SizedBox(height: 14),
          for (final item in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: meta.color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: AppTextStyles.body)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await onComplete();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: meta.color,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}



class _SessionActions extends StatelessWidget {
  const _SessionActions({
    required this.running,
    required this.submitting,
    required this.startLabel,
    required this.onStart,
    required this.onStop,
  });

  final bool running;
  final bool submitting;
  final String startLabel;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: submitting ? null : (running ? onStop : onStart),
            style: FilledButton.styleFrom(
              backgroundColor: running ? AppColors.red : AppColors.primary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                  )
                : Text(running ? 'বন্ধ করুন' : startLabel),
          ),
        ),
      ],
    );
  }
}

class _BaseSessionSheet extends StatelessWidget {
  const _BaseSessionSheet({
    required this.meta,
    required this.child,
  });

  final _WellnessModuleMeta meta;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: meta.pale,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(meta.icon, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(meta.title, style: AppTextStyles.cardTitle),
                        const SizedBox(height: 4),
                        Text(meta.subtitle, style: AppTextStyles.caption.copyWith(color: meta.color)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _WellnessModuleMeta {
  const _WellnessModuleMeta({
    required this.type,
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.icon,
    required this.duration,
    required this.color,
    required this.pale,
  });

  final WellnessRoutineType type;
  final String title;
  final String shortTitle;
  final String subtitle;
  final String icon;
  final String duration;
  final Color color;
  final Color pale;
}

_WellnessModuleMeta _metaFor(WellnessRoutineType type) {
  switch (type) {
    case WellnessRoutineType.breathing:
      return const _WellnessModuleMeta(
        type: WellnessRoutineType.breathing,
        title: 'শ্বাস-প্রশ্বাস',
        shortTitle: 'Breath',
        subtitle: 'দিনটা steady করে শুরু করুন',
        icon: '🌬️',
        duration: '৫ মিনিট',
        color: Color(0xFF0D9488),
        pale: Color(0xFFCCFBF1),
      );
    case WellnessRoutineType.kegel:
      return const _WellnessModuleMeta(
        type: WellnessRoutineType.kegel,
        title: 'কেগেল ব্যায়াম',
        shortTitle: 'Kegel',
        subtitle: 'Pelvic floor শক্তিশালী রাখুন',
        icon: '💪',
        duration: '৮ মিনিট',
        color: Color(0xFF2563EB),
        pale: Color(0xFFDBEAFE),
      );
    case WellnessRoutineType.meditation:
      return const _WellnessModuleMeta(
        type: WellnessRoutineType.meditation,
        title: 'মেডিটেশন',
        shortTitle: 'Meditate',
        subtitle: 'মনের চাপ নামান',
        icon: '🧘',
        duration: '১০ মিনিট',
        color: Color(0xFF7C3AED),
        pale: Color(0xFFEDE9FE),
      );
    case WellnessRoutineType.nofap:
      return const _WellnessModuleMeta(
        type: WellnessRoutineType.nofap,
        title: 'আত্মশুদ্ধি',
        shortTitle: 'আত্মশুদ্ধি',
        subtitle: 'Discipline ধরে রাখুন',
        icon: '🛡️',
        duration: 'সারাদিন',
        color: Color(0xFF4338CA),
        pale: Color(0xFFE0E7FF),
      );
    case WellnessRoutineType.sleep:
      return const _WellnessModuleMeta(
        type: WellnessRoutineType.sleep,
        title: 'ঘুমের রুটিন',
        shortTitle: 'Sleep',
        subtitle: 'রাত ১০টার পর calm mode',
        icon: '🌙',
        duration: 'রাত ১০টা',
        color: Color(0xFF312E81),
        pale: Color(0xFFE0E7FF),
      );
    case WellnessRoutineType.coldshower:
      return const _WellnessModuleMeta(
        type: WellnessRoutineType.coldshower,
        title: 'ডিজিটাল ডিটক্স',
        shortTitle: 'ডিটক্স',
        subtitle: 'স্ক্রিন থেকে দূরে থাকুন',
        icon: '📵',
        duration: '৩ ঘণ্টা',
        color: Color(0xFF1D4ED8),
        pale: Color(0xFFBFDBFE),
      );
  }
}

enum _BreathingPhase { inhale, hold, exhale }

class _BreathingPattern {
  const _BreathingPattern({
    required this.label,
    required this.inhale,
    required this.hold,
    required this.exhale,
    required this.cycles,
  });

  final String label;
  final int inhale;
  final int hold;
  final int exhale;
  final int cycles;
}

enum _KegelPhase { ready, squeeze, rest }

class _KegelLevel {
  const _KegelLevel({
    required this.label,
    required this.reps,
    required this.holdSeconds,
    required this.restSeconds,
  });

  final String label;
  final int reps;
  final int holdSeconds;
  final int restSeconds;
}
