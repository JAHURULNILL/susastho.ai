import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../providers/planner_provider.dart';

class WeeklyPlannerScreen extends ConsumerWidget {
  const WeeklyPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(weeklyPlannerProvider);
    final profile = ref.watch(userProfileProvider).asData?.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      children: [
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('AI তৈরি পরিকল্পনা', style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPale,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'এই সপ্তাহে ${items.length}/৭ দিন ফোকাস',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                profile == null
                    ? 'আজকের দেশীয় সহজ খাবার পরিকল্পনা এখানে দেখানো হবে।'
                    : 'লক্ষ্য: ${profile.goal.labelBn} — চার বেলার খাবার, ক্যালরি আর অভ্যাস একসাথে সাজানো হয়েছে।',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _MealPlanCard(
          title: 'সকালের পরিকল্পনা',
          kcal: '৩২০ kcal',
          foods: ['ওটস বা চিড়া', 'সেদ্ধ ডিম', 'শসা বা কলা'],
        ),
        const SizedBox(height: 12),
        const _MealPlanCard(
          title: 'দুপুরের পরিকল্পনা',
          kcal: '৪৬০ kcal',
          foods: ['নিয়ন্ত্রিত ভাত', 'মাছ বা ডাল', 'শাক-সবজি'],
        ),
        const SizedBox(height: 12),
        const _MealPlanCard(
          title: 'বিকালের পরিকল্পনা',
          kcal: '১৮০ kcal',
          foods: ['টক দই', 'বাদাম', 'লেবু পানি'],
        ),
        const SizedBox(height: 12),
        const _MealPlanCard(
          title: 'রাতের পরিকল্পনা',
          kcal: '৩৮০ kcal',
          foods: ['হালকা ভাত/রুটি', 'মুরগি বা ডাল', 'সবজি'],
        ),
        const SizedBox(height: 12),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('সাপ্তাহিক ক্যালেন্ডার', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              Row(
                children: const [
                  _DayDot(day: 'শনি', active: true),
                  _DayDot(day: 'রবি', active: true),
                  _DayDot(day: 'সোম', active: false),
                  _DayDot(day: 'মঙ্গল', active: false),
                  _DayDot(day: 'বুধ', active: false),
                  _DayDot(day: 'বৃহ', active: false),
                  _DayDot(day: 'শুক্র', active: false),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('আগামীকালের পরামর্শ', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                items.isEmpty ? 'প্রোফাইল সম্পূর্ণ করলে আগামীকালের জন্য AI পরামর্শ দেখানো হবে।' : items.first.note,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MealPlanCard extends StatelessWidget {
  const _MealPlanCard({
    required this.title,
    required this.kcal,
    required this.foods,
  });

  final String title;
  final String kcal;
  final List<String> foods;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
              Checkbox(value: false, onChanged: (_) {}),
            ],
          ),
          Text(kcal, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          ...foods.map((food) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $food', style: Theme.of(context).textTheme.bodyLarge),
              )),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.day,
    required this.active,
  });

  final String day;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: active ? AppColors.primaryDark : AppColors.primaryPale,
            child: Text(
              day,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: active ? Colors.white : AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
