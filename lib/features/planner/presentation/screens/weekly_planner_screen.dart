import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../providers/planner_provider.dart';
import '../widgets/weekly_timeline.dart';

class WeeklyPlannerScreen extends ConsumerWidget {
  const WeeklyPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(weeklyPlannerProvider);
    final profile = ref.watch(userProfileProvider).asData?.value;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFDF7EA), Color(0xFFF8F2E4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'সাপ্তাহিক জার্নি',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'আপনার লক্ষ্য আর স্বাস্থ্য অবস্থার ভিত্তিতে এই সপ্তাহের জন্য সহজ ব্যায়াম রুটিন সাজানো হয়েছে।',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _JourneyPill(label: 'সপ্তাহে ${items.length} দিন ফোকাস'),
                  if (profile != null) _JourneyPill(label: 'লক্ষ্য: ${profile.goal.labelBn}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        WeeklyTimeline(items: items),
      ],
    );
  }
}

class _JourneyPill extends StatelessWidget {
  const _JourneyPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
