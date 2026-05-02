import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_profile.dart';
import '../../../data/models/weekly_plan.dart';
import '../../../shared/providers/app_state_provider.dart';

final weeklyPlannerProvider = Provider<List<WeeklyExerciseItem>>((ref) {
  final profile = ref.watch(userProfileProvider).asData?.value;
  if (profile == null) {
    return const [];
  }

  if (profile.conditions.contains(HealthCondition.urinaryIssues) ||
      profile.conditions.contains(HealthCondition.ed)) {
    return const [
      WeeklyExerciseItem(
        dayTitle: 'শনিবার',
        exerciseTitle: 'কেগেল এক্সারসাইজ',
        durationText: '১০ মিনিট',
        note: 'পেলভিক ফ্লোর শক্তিশালী করতে ধীরে ধীরে রিপিট করুন।',
      ),
      WeeklyExerciseItem(
        dayTitle: 'রবিবার',
        exerciseTitle: 'হালকা হাঁটা',
        durationText: '২০ মিনিট',
        note: 'রক্ত সঞ্চালন উন্নত করতে আরামদায়ক গতিতে হাঁটুন।',
      ),
      WeeklyExerciseItem(
        dayTitle: 'সোমবার',
        exerciseTitle: 'শ্বাস-প্রশ্বাস ব্যায়াম',
        durationText: '৮ মিনিট',
        note: 'স্ট্রেস কমলে সামগ্রিক ও ইউরিনারি স্বাস্থ্যে ভালো প্রভাব পড়ে।',
      ),
    ];
  }

  if (profile.conditions.contains(HealthCondition.bellyFat) ||
      profile.conditions.contains(HealthCondition.obesity)) {
    return const [
      WeeklyExerciseItem(
        dayTitle: 'শনিবার',
        exerciseTitle: 'দ্রুত হাঁটা',
        durationText: '৩০ মিনিট',
        note: 'ফ্যাট বার্ন শুরু করতে steady pace বজায় রাখুন।',
      ),
      WeeklyExerciseItem(
        dayTitle: 'রবিবার',
        exerciseTitle: 'কোর এক্সারসাইজ',
        durationText: '১৫ মিনিট',
        note: 'প্ল্যাঙ্ক, নি-টাক, বার্ড-ডগের মতো সহজ মুভমেন্ট বেছে নিন।',
      ),
      WeeklyExerciseItem(
        dayTitle: 'মঙ্গলবার',
        exerciseTitle: 'স্কোয়াট ও স্টেপ-আপ',
        durationText: '২০ মিনিট',
        note: 'লো-ইমপ্যাক্ট রুটিন দিয়ে নিয়মিততা ধরে রাখুন।',
      ),
    ];
  }

  if (profile.conditions.contains(HealthCondition.diabetes)) {
    return const [
      WeeklyExerciseItem(
        dayTitle: 'শনিবার',
        exerciseTitle: 'দ্রুত হাঁটা',
        durationText: '২৫ মিনিট',
        note: 'খাবারের পরে হাঁটা ব্লাড সুগার নিয়ন্ত্রণে সহায়ক।',
      ),
      WeeklyExerciseItem(
        dayTitle: 'সোমবার',
        exerciseTitle: 'হালকা স্ট্রেচিং',
        durationText: '১০ মিনিট',
        note: 'দীর্ঘক্ষণ বসে থাকা কমিয়ে শরীর সচল রাখুন।',
      ),
      WeeklyExerciseItem(
        dayTitle: 'বুধবার',
        exerciseTitle: 'সিঁড়ি ওঠানামা',
        durationText: '১২ মিনিট',
        note: 'ক্লান্ত লাগলে বিরতি নিন, তবে নিয়মিত থাকুন।',
      ),
    ];
  }

  return const [
    WeeklyExerciseItem(
      dayTitle: 'শনিবার',
      exerciseTitle: 'সকালের হাঁটা',
      durationText: '২০ মিনিট',
      note: 'দিনের শুরুতে শরীর গরম করতে আর এনার্জি বাড়াতে সাহায্য করে।',
    ),
    WeeklyExerciseItem(
      dayTitle: 'সোমবার',
      exerciseTitle: 'পূর্ণ শরীর স্ট্রেচ',
      durationText: '১২ মিনিট',
      note: 'ঘাড়, পিঠ, কোমর আর হ্যামস্ট্রিংয়ে ফোকাস দিন।',
    ),
    WeeklyExerciseItem(
      dayTitle: 'বুধবার',
      exerciseTitle: 'হালকা বডিওয়েট',
      durationText: '১৫ মিনিট',
      note: 'স্কোয়াট, ওয়াল পুশ-আপ, গ্লুট ব্রিজের মতো সহজ রুটিন করুন।',
    ),
  ];
});
