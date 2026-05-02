import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../providers/home_provider.dart';
import '../widgets/daily_advice_card.dart';
import '../widgets/greeting_header.dart';
import '../widgets/macro_ring_chart.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).asData?.value;
    final dashboard = ref.watch(homeDashboardProvider);

    if (profile == null || dashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      children: [
        GreetingHeader(profile: profile),
        const SizedBox(height: 20),
        DailyAdviceCard(advice: dashboard.advice),
        const SizedBox(height: 16),
        MacroRingChart(
          target: dashboard.targetMacros,
          consumed: dashboard.consumedMacros,
        ),
        const SizedBox(height: 16),
        _InsightPanel(
          title: 'আজকের লক্ষ্য',
          icon: Icons.track_changes_rounded,
          rows: [
            'স্টেপ টার্গেট: ${profile.dailyStepTarget}',
            'ক্যালরি লক্ষ্য: ${profile.dailyCalorieTarget} kcal',
            'মূল ফোকাস: ${profile.goal.labelBn}',
          ],
        ),
        const SizedBox(height: 16),
        _InsightPanel(
          title: 'আপনার জন্য বিশেষ নজর',
          icon: Icons.health_and_safety_outlined,
          rows: _buildFocusLines(profile),
          toneColor: AppColors.info,
        ),
      ],
    );
  }

  List<String> _buildFocusLines(UserProfile profile) {
    if (profile.conditions.isEmpty) {
      return const [
        'আপনার জন্য এখনো নির্দিষ্ট রোগ নির্বাচন করা হয়নি।',
        'প্রতিদিন অন্তত একবার খাবার স্ক্যান করলে পরামর্শ আরও ভালো হবে।',
        'ঘরে থাকা সহজ দেশীয় খাবার দিয়েই নিয়মিত প্ল্যান ধরে রাখা যাবে।',
      ];
    }

    return profile.conditions.take(3).map((condition) {
      return switch (condition) {
        HealthCondition.diabetes => 'ডায়াবেটিসের জন্য ভাত, রুটি ও মিষ্টির পরিমাণে সতর্ক থাকুন।',
        HealthCondition.heartDisease => 'হৃদরোগের জন্য ভাজাপোড়া, ঘি ও লাল মাংস নিয়ন্ত্রণে রাখুন।',
        HealthCondition.bellyFat => 'পেটের চর্বি কমাতে রাতের খাবার হালকা রাখুন এবং কোর মুভমেন্ট করুন।',
        HealthCondition.obesity => 'স্থূলতার ক্ষেত্রে portion control আর নিয়মিত হাঁটা সবচেয়ে জরুরি।',
        HealthCondition.ed => 'ইডির জন্য নিয়মিত ঘুম, পানি এবং হালকা pelvic exercise কাজে দেয়।',
        HealthCondition.urinaryIssues => 'মূত্রজনিত সমস্যায় পানি কমাবেন না, তবে irritant খাবারে লক্ষ্য রাখুন।',
        HealthCondition.underweight => 'আন্ডারওয়েট হলে ক্যালরি-ঘন কিন্তু পুষ্টিকর খাবার বেশি নিন।',
      };
    }).toList();
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({
    required this.title,
    required this.icon,
    required this.rows,
    this.toneColor = AppColors.primaryDark,
  });

  final String title;
  final IconData icon;
  final List<String> rows;
  final Color toneColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: toneColor.withValues(alpha: 0.12),
                  child: Icon(icon, color: toneColor),
                ),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 14),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 8, color: toneColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        row,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
