import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/info_card.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../shared/providers/app_state_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).asData?.value;
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
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
        InfoCard(
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
                        onSelected: (_) {},
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
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
