import '../models/daily_summary.dart';
import '../models/user_profile.dart';

class HourlyAdvice {
  const HourlyAdvice({
    required this.title,
    required this.message,
    required this.nextUpdateInMinutes,
  });

  final String title;
  final String message;
  final int nextUpdateInMinutes;
}

class DailyAdviceService {
  const DailyAdviceService();

  HourlyAdvice getAdvice(
    UserProfile profile, {
    required DailySummary summary,
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();
    final consumed = summary.consumedMacros.calories.round();
    final remaining = (profile.dailyCalorieTarget - consumed).clamp(0, 99999);
    final nextUpdateInMinutes = 60 - time.minute;
    final conditionText = _conditionKeyword(profile);

    if (time.hour >= 6 && time.hour < 10) {
      return HourlyAdvice(
        title: 'সকালের শুরুর পরামর্শ',
        message: '$conditionText সকাল শুরু করুন হালকা পানি আর প্রোটিনসমৃদ্ধ নাস্তায়। আজ এখনও $remaining kcal বাকি আছে।',
        nextUpdateInMinutes: nextUpdateInMinutes,
      );
    }
    if (time.hour >= 10 && time.hour < 12) {
      return HourlyAdvice(
        title: 'পানির স্মার্ট রিমাইন্ডার',
        message: 'এখন পর্যন্ত ${summary.waterGlasses} গ্লাস পানি হয়েছে। দুপুরের আগে অন্তত আরও ১ গ্লাস পানি পান করুন।',
        nextUpdateInMinutes: nextUpdateInMinutes,
      );
    }
    if (time.hour >= 12 && time.hour < 15) {
      return HourlyAdvice(
        title: 'দুপুরের খাবার গাইড',
        message: '$conditionText দুপুরে ভাতের পরিমাণ নিয়ন্ত্রিত রাখুন, সাথে শাক, ডাল বা মাছ যোগ করুন।',
        nextUpdateInMinutes: nextUpdateInMinutes,
      );
    }
    if (time.hour >= 15 && time.hour < 18) {
      return HourlyAdvice(
        title: 'হালকা নাস্তার সময়',
        message: 'বিকেলে তেলেভাজা নয়, বাদাম, দই বা ফলের মতো হালকা নাস্তা বেছে নিন।',
        nextUpdateInMinutes: nextUpdateInMinutes,
      );
    }
    if (time.hour >= 18 && time.hour < 20) {
      return HourlyAdvice(
        title: 'ব্যায়াম মনে করিয়ে দিচ্ছি',
        message: '${profile.dailyStepTarget} স্টেপ লক্ষ্য ছুঁতে এখন ১৫-২০ মিনিট হাঁটা বা হালকা ব্যায়াম করুন।',
        nextUpdateInMinutes: nextUpdateInMinutes,
      );
    }
    if (time.hour >= 20 && time.hour < 22) {
      return HourlyAdvice(
        title: 'রাতের খাবার গাইড',
        message: 'রাতের খাবার হালকা রাখুন। আজকের মোট intake $consumed kcal, তাই প্রয়োজন হলে ছোট portion নিন।',
        nextUpdateInMinutes: nextUpdateInMinutes,
      );
    }
    return HourlyAdvice(
      title: 'ঘুমের আগের পরামর্শ',
      message: 'ঘুমের অন্তত ১ ঘণ্টা আগে ভারী খাবার এড়িয়ে চলুন। আগামীকালের জন্য পানি ও সকালের নাস্তা প্রস্তুত রাখুন।',
      nextUpdateInMinutes: nextUpdateInMinutes,
    );
  }

  String _conditionKeyword(UserProfile profile) {
    if (profile.conditions.contains(HealthCondition.diabetes)) {
      return 'ডায়াবেটিস মাথায় রেখে,';
    }
    if (profile.conditions.contains(HealthCondition.heartDisease) ||
        profile.conditions.contains(HealthCondition.hypertension)) {
      return 'হার্ট ও প্রেসারের কথা ভেবে,';
    }
    if (profile.conditions.contains(HealthCondition.ed) ||
        profile.conditions.contains(HealthCondition.prematureEjaculation)) {
      return 'শরীরের শক্তি আর রক্তসঞ্চালন ভালো রাখতে,';
    }
    return 'আপনার লক্ষ্য ধরে রাখতে,';
  }
}
