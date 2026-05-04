import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design.dart';
import '../../../../core/widgets/fade_up_item.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../data/models/app_settings.dart';
import '../../../../data/models/health_metrics.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../shared/providers/app_state_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).asData?.value;
    final settings = ref.watch(appSettingsProvider).asData?.value ?? const AppSettings();
    final sleep = ref.watch(todaySleepProvider).asData?.value;
    final steps = ref.watch(todayStepsProvider).asData?.value;
    final weightHistory = ref.watch(weightHistoryProvider).asData?.value ?? const <WeightHistoryEntry>[];
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_goalController.text != (settings.customCalorieGoal?.toString() ?? '')) {
      _goalController.text = settings.customCalorieGoal?.toString() ?? '';
    }

    final initial = profile.name.trim().isEmpty ? 'S' : profile.name.trim().characters.first.toUpperCase();
    final bmiMeta = _bmiMeta(profile.bmi);

    final widgets = [
      InfoCard(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(27, 94, 59, 0.18),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: AppTextStyles.metric.copyWith(
                  color: AppColors.white,
                  fontSize: 28,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(profile.name, style: AppTextStyles.screenTitle),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: bmiMeta.$2.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'BMI ${profile.bmi.toStringAsFixed(1)} • ${bmiMeta.$1}',
                style: AppTextStyles.caption.copyWith(
                  color: bmiMeta.$2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      Row(
        children: [
          Expanded(
            child: _MetricCard(
              title: 'ওজন',
              value: '${profile.weightKg.toStringAsFixed(0)} kg',
              onEdit: () => _editProfileValue(context, profile, field: _EditableField.weight),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _MetricCard(
              title: 'উচ্চতা',
              value: '${profile.heightCm.toStringAsFixed(0)} cm',
              onEdit: () => _editProfileValue(context, profile, field: _EditableField.height),
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: _MetricCard(
              title: 'বয়স',
              value: '${profile.age}',
              onEdit: () => _editProfileValue(context, profile, field: _EditableField.age),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _MetricCard(
              title: 'লক্ষ্য',
              value: profile.goal.labelBn,
              onEdit: () => _editGoal(context, profile),
            ),
          ),
        ],
      ),
      InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('আজকের ট্র্যাকিং', style: AppTextStyles.cardTitle),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'ঘুম',
                    value: sleep == null || sleep.hours == 0 ? '—' : '${sleep.hours.toStringAsFixed(1)} ঘন্টা',
                    onEdit: () => _editSleep(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MetricCard(
                    title: 'স্টেপ',
                    value: steps == null || steps.steps == 0 ? '—' : '${steps.steps}',
                    onEdit: () => _editSteps(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('ওজন ইতিহাস', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            if (weightHistory.isEmpty)
              Text('—', style: AppTextStyles.body.copyWith(color: AppColors.textMuted))
            else
              ...weightHistory.take(5).map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${entry.weightKg.toStringAsFixed(1)} kg • ${entry.dateKey}',
                    style: AppTextStyles.body,
                  ),
                ),
              ),
          ],
        ),
      ),
      _EditableConditionsCard(profile: profile),
      InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('দৈনিক লক্ষ্য সেটিংস', style: AppTextStyles.cardTitle),
            const SizedBox(height: 12),
            TextField(
              controller: _goalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'কাস্টম ক্যালরি লক্ষ্য (ঐচ্ছিক)',
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'ক্যালরি লক্ষ্য সংরক্ষণ করুন',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final goal = int.tryParse(_goalController.text.trim());
                final updated = settings.copyWith(customCalorieGoal: goal, clearCustomGoal: goal == null);
                await ref.read(appSettingsProvider.notifier).save(updated);
                if (mounted) messenger.showSnackBar(const SnackBar(content: Text('পরিবর্তন সংরক্ষিত হয়েছে ✓')));
              },
              icon: Icons.flag_rounded,
            ),
          ],
        ),
      ),
      InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('নোটিফিকেশন সেটিংস', style: AppTextStyles.cardTitle),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('দৈনিক রিমাইন্ডার চালু', style: AppTextStyles.bodyLarge),
              value: settings.notificationsEnabled,
              onChanged: (value) async {
                await ref.read(appSettingsProvider.notifier).save(settings.copyWith(notificationsEnabled: value));
              },
            ),
          ],
        ),
      ),
      InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('অ্যাপ সেটিংস', style: AppTextStyles.cardTitle),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: settings.language,
              items: const [
                DropdownMenuItem(value: 'বাংলা', child: Text('বাংলা')),
                DropdownMenuItem(value: 'English', child: Text('English')),
              ],
              onChanged: (value) async {
                if (value == null) return;
                await ref.read(appSettingsProvider.notifier).save(settings.copyWith(language: value));
              },
              decoration: const InputDecoration(labelText: 'Language'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: settings.units,
              items: const [
                DropdownMenuItem(value: 'মেট্রিক', child: Text('মেট্রিক')),
                DropdownMenuItem(value: 'ইম্পেরিয়াল', child: Text('ইম্পেরিয়াল')),
              ],
              onChanged: (value) async {
                if (value == null) return;
                await ref.read(appSettingsProvider.notifier).save(settings.copyWith(units: value));
              },
              decoration: const InputDecoration(labelText: 'Units'),
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

  (String, Color) _bmiMeta(double bmi) {
    if (bmi < 18.5) {
      return ('আন্ডারওয়েট', AppColors.blue);
    }
    if (bmi < 25) {
      return ('স্বাভাবিক ✓', AppColors.primary);
    }
    if (bmi < 30) {
      return ('ওভারওয়েট', AppColors.amber);
    }
    return ('স্থূলতা', AppColors.red);
  }

  Future<void> _editProfileValue(
    BuildContext context,
    UserProfile profile, {
    required _EditableField field,
  }) async {
    final controller = TextEditingController(
      text: switch (field) {
        _EditableField.weight => profile.weightKg.toStringAsFixed(0),
        _EditableField.height => profile.heightCm.toStringAsFixed(0),
        _EditableField.age => profile.age.toString(),
      },
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label, style: AppTextStyles.cardTitle),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'সংরক্ষণ করুন',
              onPressed: () async {
                final raw = controller.text.trim();
                if (raw.isEmpty) return;
                final notifier = ref.read(userProfileProvider.notifier);
                final updated = switch (field) {
                  _EditableField.weight => profile.copyWith(weightKg: double.tryParse(raw) ?? profile.weightKg),
                  _EditableField.height => profile.copyWith(heightCm: double.tryParse(raw) ?? profile.heightCm),
                  _EditableField.age => profile.copyWith(age: int.tryParse(raw) ?? profile.age),
                };
                await notifier.save(updated);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editGoal(BuildContext context, UserProfile profile) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('লক্ষ্য পরিবর্তন', style: AppTextStyles.cardTitle),
            const SizedBox(height: 12),
            ...UserGoal.values.map(
              (goal) => ListTile(
                title: Text(goal.labelBn),
                onTap: () async {
                  await ref.read(userProfileProvider.notifier).save(profile.copyWith(goal: goal));
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSleep(BuildContext context) async {
    final hoursController = TextEditingController();
    String selectedQuality = 'good';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('আজকের ঘুম', style: AppTextStyles.cardTitle),
              const SizedBox(height: 12),
              TextField(
                controller: hoursController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'যেমন ৭.৫'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedQuality,
                items: const [
                  DropdownMenuItem(value: 'poor', child: Text('Poor')),
                  DropdownMenuItem(value: 'fair', child: Text('Fair')),
                  DropdownMenuItem(value: 'good', child: Text('Good')),
                  DropdownMenuItem(value: 'excellent', child: Text('Excellent')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setModalState(() => selectedQuality = value);
                },
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'সংরক্ষণ করুন',
                onPressed: () async {
                  final hours = double.tryParse(hoursController.text.trim());
                  if (hours == null) return;
                  await ref.read(healthMetricsRepositoryProvider).saveSleep(
                        hours: hours,
                        quality: selectedQuality,
                      );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editSteps(BuildContext context) async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('আজকের স্টেপ', style: AppTextStyles.cardTitle),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'যেমন ৫০০০'),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'সংরক্ষণ করুন',
              onPressed: () async {
                final steps = int.tryParse(controller.text.trim());
                if (steps == null) return;
                await ref.read(healthMetricsRepositoryProvider).saveSteps(steps);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum _EditableField {
  weight('ওজন'),
  height('উচ্চতা'),
  age('বয়স');

  const _EditableField(this.label);

  final String label;
}

class _EditableConditionsCard extends ConsumerWidget {
  const _EditableConditionsCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('স্বাস্থ্য সমস্যা', style: AppTextStyles.cardTitle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HealthCondition.values.map((condition) {
              final selected = profile.conditions.contains(condition);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: FilterChip(
                  label: Text(
                    condition.labelBn,
                    style: AppTextStyles.caption.copyWith(
                      color: selected ? AppColors.primary : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  avatar: selected ? const Icon(Icons.check_rounded, size: 16, color: AppColors.primary) : null,
                  selected: selected,
                  side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                  backgroundColor: AppColors.white,
                  selectedColor: AppColors.primaryPale,
                  showCheckmark: false,
                  onSelected: (isSelected) async {
                    final updated = [...profile.conditions];
                    if (isSelected) {
                      if (!updated.contains(condition)) updated.add(condition);
                    } else {
                      updated.remove(condition);
                    }
                    await ref.read(userProfileProvider.notifier).save(profile.copyWith(conditions: updated));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('পরিবর্তন সংরক্ষিত হয়েছে ✓')),
                      );
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.onEdit,
  });

  final String title;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.caption)),
              InkWell(
                onTap: onEdit,
                child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.metricSmall),
        ],
      ),
    );
  }
}
