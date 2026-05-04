import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../models/weekly_plan.dart';
import '../services/ai_backend_service.dart';
import '../services/local_storage_service.dart';
import 'daily_summary_repository.dart';
import 'health_metrics_repository.dart';

class PlannerRepository {
  PlannerRepository({
    required FirebaseAuth? auth,
    required FirebaseFirestore? firestore,
    required AiBackendService aiBackendService,
    required LocalStorageService storage,
    required DailySummaryRepository dailySummaryRepository,
    required HealthMetricsRepository healthMetricsRepository,
  })  : _auth = auth,
        _firestore = firestore,
        _aiBackendService = aiBackendService,
        _storage = storage,
        _dailySummaryRepository = dailySummaryRepository,
        _healthMetricsRepository = healthMetricsRepository;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final AiBackendService _aiBackendService;
  final LocalStorageService _storage;
  final DailySummaryRepository _dailySummaryRepository;
  final HealthMetricsRepository _healthMetricsRepository;

  DocumentReference<Map<String, dynamic>>? get _userRef {
    final uid = _auth?.currentUser?.uid;
    final firestore = _firestore;
    if (uid == null || firestore == null) {
      return null;
    }
    return firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>>? get _exerciseRef => _userRef?.collection('exercise_logs');
  CollectionReference<Map<String, dynamic>>? get _mealPlanRef => _userRef?.collection('meal_plans');

  String get todayKey => _formatDate(DateTime.now());
  String get weekKey => _formatDate(_startOfWeek(DateTime.now()));
  String? get _uid => _auth?.currentUser?.uid;
  String? get _exerciseCacheKey => _uid == null ? null : 'exercise_${_uid!}_$todayKey';
  String? get _mealPlanCacheKey => _uid == null ? null : 'meal_plan_${_uid!}_$weekKey';

  Stream<List<WeeklyExerciseItem>> watchTodayExercises() async* {
    final cacheKey = _exerciseCacheKey;
    if (cacheKey != null) {
      final cached = await _storage.readJsonList(cacheKey);
      if (cached.isNotEmpty) {
        yield cached
            .map((item) => WeeklyExerciseItem.fromJson(item['id'] as String? ?? '', item))
            .toList();
      }
    }

    final ref = _exerciseRef;
    if (ref == null) {
      yield const [];
      return;
    }

    yield* ref
        .where('dateKey', isEqualTo: todayKey)
        .orderBy('loggedAt', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final items = snapshot.docs.map((doc) => WeeklyExerciseItem.fromJson(doc.id, doc.data())).toList();
      if (cacheKey != null) {
        await _storage.saveJsonList(
          cacheKey,
          items.map((item) => {'id': item.id, ...item.toJson()}).toList(),
        );
      }
      return items;
    });
  }

  Stream<WeeklyMealPlan?> watchCurrentWeekMealPlan() async* {
    final cacheKey = _mealPlanCacheKey;
    if (cacheKey != null) {
      final cached = await _storage.readJson(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        yield WeeklyMealPlan.fromJson(cached);
      }
    }

    final ref = _mealPlanRef?.doc(weekKey);
    if (ref == null) {
      yield null;
      return;
    }

    yield* ref.snapshots().asyncMap((snapshot) async {
      final data = snapshot.data();
      if (data == null || data['plan'] is! Map) {
        return null;
      }
      final plan = WeeklyMealPlan.fromJson(
        Map<String, dynamic>.from(data['plan'] as Map),
      );
      if (cacheKey != null) {
        await _storage.saveJson(cacheKey, plan.toJson());
      }
      return plan;
    });
  }

  Future<void> ensureTodayExercises(UserProfile profile) async {
    final ref = _exerciseRef;
    if (ref == null) {
      return;
    }

    final existing = await ref.where('dateKey', isEqualTo: todayKey).limit(1).get();
    if (existing.docs.isNotEmpty) {
      return;
    }

    final generated = _buildInstantExercises(profile);
    final batch = _firestore!.batch();
    final now = DateTime.now();
    for (final item in generated) {
      final doc = ref.doc();
      batch.set(
        doc,
        item.copyWith(
          id: doc.id,
          dateKey: todayKey,
          loggedAt: now,
        ).toJson(),
      );
    }
    await batch.commit();
  }

  Future<void> toggleExercise(String exerciseId, bool completed) async {
    final ref = _exerciseRef?.doc(exerciseId);
    if (ref == null) {
      return;
    }

    await ref.update({'completed': completed});
  }

  Future<WeeklyMealPlan?> getOrGenerateWeeklyMealPlan(UserProfile profile) async {
    final ref = _mealPlanRef?.doc(weekKey);
    if (ref == null) {
      return null;
    }

    final existing = await ref.get();
    final data = existing.data();
    if (data != null && data['plan'] is Map) {
      return WeeklyMealPlan.fromJson(
        Map<String, dynamic>.from(data['plan'] as Map),
      );
    }

    final generated = _buildInstantWeeklyPlan(profile);
    await ref.set(
      {
        'weekOf': weekKey,
        'generatedAt': FieldValue.serverTimestamp(),
        'plan': generated.toJson(),
      },
      SetOptions(merge: true),
    );
    final cacheKey = _mealPlanCacheKey;
    if (cacheKey != null) {
      await _storage.saveJson(cacheKey, generated.toJson());
    }
    return generated;
  }

  Future<void> ensureCurrentWeekMealPlan(UserProfile profile) async {
    final ref = _mealPlanRef?.doc(weekKey);
    if (ref == null) {
      return;
    }

    final existing = await ref.get();
    final data = existing.data();
    if (data != null && data['plan'] is Map) {
      return;
    }

    final generated = _buildInstantWeeklyPlan(profile);
    await ref.set(
      {
        'weekOf': weekKey,
        'generatedAt': FieldValue.serverTimestamp(),
        'plan': generated.toJson(),
      },
      SetOptions(merge: true),
    );
    final cacheKey = _mealPlanCacheKey;
    if (cacheKey != null) {
      await _storage.saveJson(cacheKey, generated.toJson());
    }
  }

  WeeklyMealPlan _buildInstantWeeklyPlan(UserProfile profile) {
    final dailyTarget = profile.dailyCalorieTarget.toDouble();
    final breakfastCalories = dailyTarget * 0.22;
    final lunchCalories = dailyTarget * 0.36;
    final snackCalories = dailyTarget * 0.14;
    final dinnerCalories = dailyTarget * 0.28;

    final breakfastBases = _breakfastOptions(profile);
    final lunchProteins = _lunchProteins(profile);
    final lunchSides = _lunchSides(profile);
    final snackOptions = _snackOptions(profile);
    final dinnerProteins = _dinnerProteins(profile);
    final dinnerSides = _dinnerSides(profile);

    final dayKeys = <String>[
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    final days = <String, WeeklyMealPlanDay>{};
    for (var index = 0; index < dayKeys.length; index++) {
      final breakfast = breakfastBases[index % breakfastBases.length];
      final lunchProtein = lunchProteins[index % lunchProteins.length];
      final lunchSide = lunchSides[index % lunchSides.length];
      final snack = snackOptions[index % snackOptions.length];
      final dinnerProtein = dinnerProteins[index % dinnerProteins.length];
      final dinnerSide = dinnerSides[index % dinnerSides.length];

      days[dayKeys[index]] = WeeklyMealPlanDay(
        morning: PlannedMealSlot(
          items: breakfast,
          calories: breakfastCalories,
        ),
        lunch: PlannedMealSlot(
          items: [
            _mainRiceOrRoti(profile, lunch: true),
            lunchProtein,
            lunchSide,
            'ডাল',
          ],
          calories: lunchCalories,
        ),
        afternoon: PlannedMealSlot(
          items: snack,
          calories: snackCalories,
        ),
        night: PlannedMealSlot(
          items: [
            _mainRiceOrRoti(profile, lunch: false),
            dinnerProtein,
            dinnerSide,
          ],
          calories: dinnerCalories,
        ),
      );
    }

    final proteinTarget = (profile.weightKg * 1.5).round();
    final carbTarget = (dailyTarget * 0.5 / 4).round();
    final fatTarget = (dailyTarget * 0.25 / 9).round();

    return WeeklyMealPlan(
      weekOf: weekKey,
      days: days,
      weeklyTips: [
        'এই সপ্তাহে প্রতিদিন প্রায় ${_bn(proteinTarget)}g প্রোটিন, ${_bn(carbTarget)}g কার্ব আর ${_bn(fatTarget)}g ফ্যাটের দিকে লক্ষ্য রাখুন।',
        _hydrationTip(profile),
        _conditionMealTip(profile),
      ],
      specialNotes: _specialMealNote(profile),
    );
  }

  List<WeeklyExerciseItem> _buildInstantExercises(UserProfile profile) {
    final sessions = <_InstantExerciseSeed>[
      _InstantExerciseSeed(
        title: 'সকাল • ৫ মিনিট শ্বাস-প্রশ্বাস',
        duration: 5,
        calories: 20,
        note: 'ধীরে ধীরে গভীর শ্বাস নিন আর ছাড়ুন।',
        benefit: 'সকালের ফোকাস আর মানসিক চাপ নিয়ন্ত্রণে সাহায্য করবে।',
      ),
      _InstantExerciseSeed(
        title: 'দুপুর • ১০ মিনিট brisk walk',
        duration: 10,
        calories: 50,
        note: 'খাবারের পর হালকা দ্রুত হাঁটুন।',
        benefit: profile.conditions.contains(HealthCondition.diabetes)
            ? 'রক্তে শর্করার ওঠানামা নিয়ন্ত্রণে সহায়তা করবে।'
            : 'মেটাবলিজম চালু রাখতে সাহায্য করবে।',
      ),
      _InstantExerciseSeed(
        title: _middayStrengthTitle(profile),
        duration: 10,
        calories: 45,
        note: _middayStrengthNote(profile),
        benefit: _middayStrengthBenefit(profile),
      ),
      _InstantExerciseSeed(
        title: _nightRecoveryTitle(profile),
        duration: 10,
        calories: 25,
        note: _nightRecoveryNote(profile),
        benefit: _nightRecoveryBenefit(profile),
      ),
    ];

    return sessions
        .map(
          (item) => WeeklyExerciseItem(
            id: '',
            exerciseTitle: item.title,
            durationMinutes: item.duration,
            caloriesBurned: item.calories,
            note: item.note,
            conditionBenefit: item.benefit,
            completed: false,
            dateKey: todayKey,
            loggedAt: DateTime.now(),
          ),
        )
        .toList();
  }

  List<List<String>> _breakfastOptions(UserProfile profile) {
    final isGain = profile.goal == UserGoal.weightGain;
    final hasDiabetes = profile.conditions.contains(HealthCondition.diabetes);
    return [
      ['২টি ডিম', hasDiabetes ? 'সবজি ভাজি' : 'দুধ', hasDiabetes ? 'ছোলা' : 'কলা'],
      ['চিড়া', 'দই', 'কাঠবাদাম'],
      ['ডিম ভাজি', 'ওটস', 'শসা'],
      ['সিদ্ধ ডিম', isGain ? 'দুধ' : 'ডাল স্যুপ', hasDiabetes ? 'আপেল' : 'কলা'],
      ['ছোলার ঘুগনি', '১টি ডিম', 'টমেটো'],
      ['দুধ', 'চিনাবাদাম', hasDiabetes ? 'শসা' : 'কলা'],
      ['ডিম', 'লাল আটা রুটি', 'শাক'],
    ];
  }

  List<String> _lunchProteins(UserProfile profile) {
    final proteins = <String>['মাছ', 'মুরগি', 'ডাল', 'ডিম'];
    if (profile.goal == UserGoal.weightGain || profile.conditions.contains(HealthCondition.underweight)) {
      proteins.add('গরুর মাংস');
    }
    return proteins;
  }

  List<String> _lunchSides(UserProfile profile) {
    if (profile.conditions.contains(HealthCondition.digestiveIssues)) {
      return ['পেঁপে ভাজি', 'শাক', 'লাউ'];
    }
    if (profile.conditions.contains(HealthCondition.kidneyIssues)) {
      return ['লাউ', 'করলা', 'শসা'];
    }
    return ['শাক', 'সবজি', 'ডালনা', 'সালাদ'];
  }

  List<List<String>> _snackOptions(UserProfile profile) {
    return [
      ['ভাজা ছোলা', 'লেবু পানি'],
      ['কাঠবাদাম', 'শসা'],
      ['দই', 'চিনাবাদাম'],
      ['মুড়ি', 'ছোলা'],
      ['আপেল', 'বাদাম'],
      ['ডাবের পানি', 'ছোট কলা'],
      ['চিড়া-দই', 'তিল'],
    ];
  }

  List<String> _dinnerProteins(UserProfile profile) {
    if (profile.conditions.contains(HealthCondition.bellyFat) || profile.goal == UserGoal.weightLoss) {
      return ['মাছ', 'ডাল', 'মুরগি'];
    }
    return ['মাছ', 'মুরগি', 'ডিম', 'ডাল'];
  }

  List<String> _dinnerSides(UserProfile profile) {
    if (profile.conditions.contains(HealthCondition.insomnia)) {
      return ['সবজি স্যুপ', 'শাক', 'লাউ'];
    }
    return ['সবজি', 'শাক', 'ডাল', 'সালাদ'];
  }

  String _mainRiceOrRoti(UserProfile profile, {required bool lunch}) {
    final lowCarb = profile.goal == UserGoal.weightLoss || profile.conditions.contains(HealthCondition.diabetes);
    if (lowCarb) {
      return lunch ? '১ প্লেট ভাত' : '২টি রুটি';
    }
    return lunch ? '২ প্লেট ভাত' : '১ প্লেট ভাত';
  }

  String _hydrationTip(UserProfile profile) {
    if (profile.conditions.contains(HealthCondition.urinaryIssues) || profile.conditions.contains(HealthCondition.kidneyIssues)) {
      return 'পানি ৭–৮ গ্লাসে রাখুন, তবে একসাথে বেশি নয়—সারাদিনে ভাগ করে পান করুন।';
    }
    return 'প্রতিদিন অন্তত ৭–৮ গ্লাস পানি, বিশেষ করে দুপুর আর বিকালে, লক্ষ্য রাখুন।';
  }

  String _conditionMealTip(UserProfile profile) {
    if (profile.conditions.contains(HealthCondition.ed) || profile.conditions.contains(HealthCondition.prematureEjaculation)) {
      return 'ডিম, মাছ, বাদাম, দুধ আর ছোলা নিয়মিত রাখলে শক্তি আর পুরুষস্বাস্থ্যে সাহায্য করবে।';
    }
    if (profile.conditions.contains(HealthCondition.bellyFat)) {
      return 'রাতে হালকা রাখুন, আর ভাতের সাথে সবজি ও প্রোটিনের অনুপাত বাড়ান।';
    }
    if (profile.conditions.contains(HealthCondition.diabetes)) {
      return 'সাদা ভাতের পরিমাণ নিয়ন্ত্রণে রাখুন, আর প্রতিটি মিলে প্রোটিন যোগ করুন।';
    }
    return 'প্রতিটি মিলে প্রোটিন, কার্ব আর সবজির balance রাখলে শরীর steady থাকবে।';
  }

  String _specialMealNote(UserProfile profile) {
    final proteinTarget = (profile.weightKg * 1.5).round();
    final carbTarget = (profile.dailyCalorieTarget * 0.5 / 4).round();
    final fatTarget = (profile.dailyCalorieTarget * 0.25 / 9).round();
    return 'এই সপ্তাহে আপনার শরীরের জন্য প্রায় ${_bn(proteinTarget)}g প্রোটিন, ${_bn(carbTarget)}g কার্ব আর ${_bn(fatTarget)}g ফ্যাট রাখা হয়েছে। আপনার লক্ষ্য আর সমস্যার ভিত্তিতে ডিম, দুধ, কলা, মাছ, মাংস, কাঠবাদাম, ছোলা, ভাত, শাকসবজি ঘুরিয়ে রাখা হয়েছে।';
  }

  String _middayStrengthTitle(UserProfile profile) {
    if (profile.conditions.contains(HealthCondition.bellyFat)) {
      return 'বিকাল • ১০ মিনিট squat';
    }
    if (profile.conditions.contains(HealthCondition.ed) || profile.conditions.contains(HealthCondition.prematureEjaculation)) {
      return 'বিকাল • ১০ মিনিট kegel exercise';
    }
    return 'বিকাল • ১০ মিনিট bodyweight squat';
  }

  String _middayStrengthNote(UserProfile profile) {
    if (profile.conditions.contains(HealthCondition.ed) || profile.conditions.contains(HealthCondition.prematureEjaculation)) {
      return 'Pelvic floor টাইট করে ৫ সেকেন্ড ধরে রেখে ছাড়ুন।';
    }
    return 'ধীরে ধীরে form ঠিক রেখে ১০ মিনিট করুন।';
  }

  String _middayStrengthBenefit(UserProfile profile) {
    if (profile.conditions.contains(HealthCondition.ed) || profile.conditions.contains(HealthCondition.prematureEjaculation)) {
      return 'Pelvic control, রক্তসঞ্চালন আর পুরুষস্বাস্থ্যে ধীরে ধীরে উন্নতি আনতে সাহায্য করবে।';
    }
    if (profile.conditions.contains(HealthCondition.bellyFat)) {
      return 'Lower body activation আর fat loss progress-এ সাহায্য করবে।';
    }
    return 'শরীরের শক্তি আর daily activity level বাড়াতে সাহায্য করবে।';
  }

  String _nightRecoveryTitle(UserProfile profile) {
    if (profile.conditions.contains(HealthCondition.insomnia)) {
      return 'রাত • ১০ মিনিট meditation';
    }
    return 'রাত • ১০ মিনিট meditation';
  }

  String _nightRecoveryNote(UserProfile profile) {
    return 'শোবার আগে শান্ত পরিবেশে ধীরে ধীরে করুন।';
  }

  String _nightRecoveryBenefit(UserProfile profile) {
    if (profile.conditions.contains(HealthCondition.insomnia)) {
      return 'ঘুমের মান ভালো করতে আর মানসিক চাপ কমাতে সাহায্য করবে।';
    }
    return 'দিনের চাপ কমিয়ে recovery আর ঘুমের জন্য শরীরকে প্রস্তুত করবে।';
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime _startOfWeek(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.subtract(Duration(days: local.weekday - 1));
  }

  String _bn(num value) {
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var text = value.round().toString();
    for (var i = 0; i < western.length; i++) {
      text = text.replaceAll(western[i], bengali[i]);
    }
    return text;
  }
}

class _InstantExerciseSeed {
  const _InstantExerciseSeed({
    required this.title,
    required this.duration,
    required this.calories,
    required this.note,
    required this.benefit,
  });

  final String title;
  final int duration;
  final double calories;
  final String note;
  final String benefit;
}
