import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/info_card.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../home/providers/home_provider.dart';
import '../../providers/planner_provider.dart';

class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);
    final exercises = ref.watch(weeklyPlannerProvider);
    final profile = ref.watch(userProfileProvider).asData?.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      children: [
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('এই সপ্তাহের জার্নি', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                profile == null
                    ? 'জার্নির তথ্য এখানে দেখা যাবে।'
                    : 'গড় ক্যালরি, লক্ষ্য পূরণ আর ব্যায়ামের অগ্রগতি এখানে সাজানো আছে।',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _JourneyStat(title: 'গড় ক্যালরি', value: '${dashboard?.consumedMacros.calories.round() ?? 0}')),
            const SizedBox(width: 10),
            Expanded(child: _JourneyStat(title: 'লক্ষ্য পূরণ', value: dashboard == null ? '০%' : '${((dashboard.consumedMacros.calories / dashboard.targetMacros.calories) * 100).round()}%')),
            const SizedBox(width: 10),
            Expanded(child: _JourneyStat(title: 'রুটিন', value: '${exercises.length} দিন')),
          ],
        ),
        const SizedBox(height: 12),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('সপ্তাহের ব্যায়াম লগ', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...exercises.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('${item.dayTitle}: ${item.exerciseTitle} • ${item.durationText}'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JourneyStat extends StatelessWidget {
  const _JourneyStat({
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
