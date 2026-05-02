import '../models/user_profile.dart';

class DailyAdviceService {
  const DailyAdviceService();

  String getAdvice(UserProfile profile) {
    if (profile.conditions.contains(HealthCondition.diabetes)) {
      return 'আজ সাদা ভাত, চিনি আর মিষ্টি কমিয়ে হাঁটা ও শাকসবজি বাড়ান।';
    }
    if (profile.conditions.contains(HealthCondition.heartDisease)) {
      return 'আজ অতিরিক্ত তেল, ভাজাপোড়া ও লাল মাংস কমিয়ে হালকা খাবার বেছে নিন।';
    }
    if (profile.goal == UserGoal.weightLoss) {
      return 'আজ অন্তত ${profile.dailyStepTarget} স্টেপ হাঁটা আর রাতের খাবার হালকা রাখুন।';
    }
    if (profile.goal == UserGoal.weightGain) {
      return 'আজ ডিম, মাছ, ডাল বা দুধের মতো প্রোটিনসমৃদ্ধ দেশীয় খাবার যোগ করুন।';
    }
    return 'আজ খাবারে ভারসাম্য রাখুন, পানি বেশি পান করুন এবং একবার হলেও শরীরচর্চা করুন।';
  }
}
