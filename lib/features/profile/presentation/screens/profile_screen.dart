import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../data/models/app_settings.dart';
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
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_goalController.text != (settings.customCalorieGoal?.toString() ?? '')) {
      _goalController.text = settings.customCalorieGoal?.toString() ?? '';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      children: [
        InfoCard(
          child: Column(
            children: [
              const CircleAvatar(radius: 32, child: Icon(Icons.person_rounded, size: 30)),
              const SizedBox(height: 10),
              Text(profile.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('BMI ${profile.bmi.toStringAsFixed(1)}', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MetricCard(title: 'ওজন', value: '${profile.weightKg.toStringAsFixed(0)} kg')),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(title: 'উচ্চতা', value: '${profile.heightCm.toStringAsFixed(0)} cm')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _MetricCard(title: 'বয়স', value: '${profile.age}')),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(title: 'লক্ষ্য', value: profile.goal.labelBn)),
          ],
        ),
        const SizedBox(height: 12),
        _EditableConditionsCard(profile: profile),
        const SizedBox(height: 12),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('দৈনিক লক্ষ্য সেটিংস', style: Theme.of(context).textTheme.titleLarge),
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
                  final goal = int.tryParse(_goalController.text.trim());
                  final updated = settings.copyWith(customCalorieGoal: goal, clearCustomGoal: goal == null);
                  await ref.read(appSettingsProvider.notifier).save(updated);
                },
                icon: Icons.flag_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('নোটিফিকেশন সেটিংস', style: Theme.of(context).textTheme.titleLarge),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('দৈনিক রিমাইন্ডার চালু'),
                value: settings.notificationsEnabled,
                onChanged: (value) async {
                  await ref.read(appSettingsProvider.notifier).save(
                        settings.copyWith(notificationsEnabled: value),
                      );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('অ্যাপ সেটিংস', style: Theme.of(context).textTheme.titleLarge),
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
                  DropdownMenuItem(value: 'ইম্পেরিয়াল', child: Text('ইম্পেরিয়াল')),
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
      ],
    );
  }
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
          Text('স্বাস্থ্য সমস্যা', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HealthCondition.values
                .map(
                  (condition) => FilterChip(
                    label: Text(condition.labelBn),
                    selected: profile.conditions.contains(condition),
                    onSelected: (selected) async {
                      final updated = [...profile.conditions];
                      if (selected) {
                        if (!updated.contains(condition)) updated.add(condition);
                      } else {
                        updated.remove(condition);
                      }
                      await ref.read(userProfileProvider.notifier).save(
                            profile.copyWith(conditions: updated),
                          );
                    },
                  ),
                )
                .toList(),
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
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
