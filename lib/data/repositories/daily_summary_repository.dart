import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/daily_summary.dart';
import '../models/food_analysis_result.dart';
import '../services/local_storage_service.dart';

class DailySummaryRepository {
  DailySummaryRepository({
    required FirebaseAuth? auth,
    required FirebaseFirestore? firestore,
    required LocalStorageService storage,
  })  : _auth = auth,
        _firestore = firestore,
        _storage = storage;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final LocalStorageService _storage;

  String get todayKey => _formatDate(DateTime.now());

  DocumentReference<Map<String, dynamic>>? get _userRef {
    final uid = _auth?.currentUser?.uid;
    final firestore = _firestore;
    if (uid == null || firestore == null) {
      return null;
    }
    return firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>>? get _foodLogsRef => _userRef?.collection('food_logs');
  CollectionReference<Map<String, dynamic>>? get _waterLogsRef => _userRef?.collection('water_logs');

  String? get _uid => _auth?.currentUser?.uid;
  String? get _mealsCacheKey => _uid == null ? null : 'today_meals_${_uid!}_$todayKey';
  String? get _waterCacheKey => _uid == null ? null : 'today_water_${_uid!}_$todayKey';

  Stream<List<MealLogEntry>> watchTodayMeals() async* {
    final cacheKey = _mealsCacheKey;
    if (cacheKey != null) {
      final cached = await _storage.readJsonList(cacheKey);
      if (cached.isNotEmpty) {
        yield cached.map((item) => MealLogEntry.fromJson(item)).toList();
      }
    }

    final ref = _foodLogsRef;
    if (ref == null) {
      yield const [];
      return;
    }

    yield* ref
        .where('date', isEqualTo: todayKey)
        .orderBy('loggedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final items = snapshot.docs
          .map((doc) => MealLogEntry.fromFirestore(doc.id, doc.data()))
          .toList();
      if (cacheKey != null) {
        await _storage.saveJsonList(cacheKey, items.map((item) => item.toJson()).toList());
      }
      return items;
    });
  }

  Stream<int> watchTodayWater() async* {
    final cacheKey = _waterCacheKey;
    if (cacheKey != null) {
      final cached = await _storage.readJson(cacheKey);
      if (cached != null) {
        yield (cached['glasses'] as num?)?.toInt() ?? 0;
      }
    }

    final ref = _waterLogsRef?.doc(todayKey);
    if (ref == null) {
      yield 0;
      return;
    }

    yield* ref.snapshots().asyncMap((snapshot) async {
      final data = snapshot.data();
      final glasses = (data?['glasses'] as num?)?.toInt() ?? 0;
      if (cacheKey != null) {
        await _storage.saveJson(cacheKey, {'glasses': glasses});
      }
      return glasses;
    });
  }

  Future<void> addMeal(
    FoodAnalysisResult result, {
    String? imagePath,
    MealSlot? slot,
  }) async {
    final ref = _foodLogsRef;
    if (ref == null) {
      return;
    }

    final loggedAt = DateTime.now();
    final meal = MealLogEntry.fromAnalysis(
      result,
      imagePath: imagePath,
      loggedAt: loggedAt,
      slot: slot,
    );

    await ref.add(
      {
        ...meal.toJson(),
        'loggedAt': Timestamp.fromDate(loggedAt),
        'date': todayKey,
        'scanResult': result.toJson(),
      },
    );
  }

  Future<void> setWaterCount(int glasses) async {
    final ref = _waterLogsRef?.doc(todayKey);
    if (ref == null) {
      return;
    }

    await ref.set(
      {
        'glasses': glasses.clamp(0, 8),
        'date': todayKey,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<Map<String, double>> loadCurrentWeekCalories() async {
    return loadWeekCalories();
  }

  Future<Map<String, double>> loadWeekCalories({DateTime? weekStart}) async {
    final targetWeek = _startOfWeek(weekStart ?? DateTime.now());
    final cacheKey = _weeklyCaloriesCacheKeyFor(targetWeek);
    if (cacheKey != null) {
      final cached = await _storage.readJson(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
    }

    final ref = _foodLogsRef;
    if (ref == null) {
      return const {};
    }

    final start = targetWeek;
    final end = start.add(const Duration(days: 6));
    final snapshot = await ref
        .where('date', isGreaterThanOrEqualTo: _formatDate(start))
        .where('date', isLessThanOrEqualTo: _formatDate(end))
        .get();

    final byDate = <String, double>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final date = data['date'] as String? ?? '';
      final calories = (data['macros'] is Map
              ? ((data['macros'] as Map)['calories'] as num?)
              : data['calories'] as num?)
          ?.toDouble() ??
          0;
      byDate.update(date, (value) => value + calories, ifAbsent: () => calories);
    }
    if (cacheKey != null) {
      await _storage.saveJson(cacheKey, byDate);
    }
    return byDate;
  }

  Future<Map<String, int>> loadCurrentWeekWater() async {
    return loadWeekWater();
  }

  Future<Map<String, int>> loadWeekWater({DateTime? weekStart}) async {
    final targetWeek = _startOfWeek(weekStart ?? DateTime.now());
    final cacheKey = _weeklyWaterCacheKeyFor(targetWeek);
    if (cacheKey != null) {
      final cached = await _storage.readJson(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached.map((key, value) => MapEntry(key, (value as num).toInt()));
      }
    }

    final ref = _waterLogsRef;
    if (ref == null) {
      return const {};
    }

    final start = targetWeek;
    final end = start.add(const Duration(days: 6));
    final snapshot = await ref
        .where('date', isGreaterThanOrEqualTo: _formatDate(start))
        .where('date', isLessThanOrEqualTo: _formatDate(end))
        .get();

    final byDate = <String, int>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final date = data['date'] as String? ?? '';
      final glasses = (data['glasses'] as num?)?.toInt() ?? 0;
      byDate[date] = glasses;
    }
    if (cacheKey != null) {
      await _storage.saveJson(cacheKey, byDate);
    }
    return byDate;
  }

  Future<List<Map<String, dynamic>>> loadRecentMeals({int days = 3, int limit = 8}) async {
    final ref = _foodLogsRef;
    if (ref == null) {
      return const [];
    }

    final start = DateTime.now().subtract(Duration(days: days - 1));
    final snapshot = await ref
        .where('date', isGreaterThanOrEqualTo: _formatDate(start))
        .orderBy('date', descending: true)
        .orderBy('loggedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => {
              'foodName': doc.data()['foodName'],
              'date': doc.data()['date'],
              'slot': doc.data()['slot'],
              'calories': ((doc.data()['macros'] as Map?)?['calories'] as num?)?.toDouble() ?? 0,
              'protein': ((doc.data()['macros'] as Map?)?['protein'] as num?)?.toDouble() ?? 0,
              'carbs': ((doc.data()['macros'] as Map?)?['carbs'] as num?)?.toDouble() ?? 0,
              'fat': ((doc.data()['macros'] as Map?)?['fat'] as num?)?.toDouble() ?? 0,
            })
        .toList();
  }

  Future<Map<String, dynamic>> loadHistoricalContext() async {
    final weeklyCalories = await loadCurrentWeekCalories();
    final weeklyWater = await loadCurrentWeekWater();
    final recentMeals = await loadRecentMeals();
    final calorieValues = weeklyCalories.values.where((value) => value > 0).toList();
    final avgCalories = calorieValues.isEmpty
        ? 0
        : calorieValues.reduce((a, b) => a + b) / calorieValues.length;
    final topFoods = _topFoods(recentMeals);
    final slotMix = _slotMix(recentMeals);
    final macroSummary = _macroSummary(recentMeals);
    final waterValues = weeklyWater.values.where((value) => value > 0).toList();
    final averageWater = waterValues.isEmpty
        ? 0
        : (waterValues.reduce((a, b) => a + b) / waterValues.length);
    final calorieTrend = _trendLabel(calorieValues);
    final hydrationTrend = _trendLabel(waterValues.map((value) => value.toDouble()).toList());
    final mealCount = recentMeals.length;

    return {
      'recentMeals': recentMeals,
      'weeklyCalories': weeklyCalories,
      'weeklyWater': weeklyWater,
      'averageCalories': avgCalories.round(),
      'mealCountLastDays': mealCount,
      'topFoods': topFoods,
      'slotMix': slotMix,
      'macroSummary': macroSummary,
      'averageWater': averageWater.round(),
      'calorieTrend': calorieTrend,
      'hydrationTrend': hydrationTrend,
      'daysWithFoodLogs': calorieValues.length,
      'daysWithWaterLogs': waterValues.length,
    };
  }

  List<String> _topFoods(List<Map<String, dynamic>> recentMeals) {
    final counts = <String, int>{};
    for (final meal in recentMeals) {
      final name = (meal['foodName'] as String? ?? '').trim();
      if (name.isEmpty) {
        continue;
      }
      counts.update(name, (value) => value + 1, ifAbsent: () => 1);
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((entry) => entry.key).toList();
  }

  Map<String, int> _slotMix(List<Map<String, dynamic>> recentMeals) {
    final slots = <String, int>{};
    for (final meal in recentMeals) {
      final slot = (meal['slot'] as String? ?? '').trim();
      if (slot.isEmpty) {
        continue;
      }
      slots.update(slot, (value) => value + 1, ifAbsent: () => 1);
    }
    return slots;
  }

  Map<String, double> _macroSummary(List<Map<String, dynamic>> recentMeals) {
    if (recentMeals.isEmpty) {
      return const {
        'averageProtein': 0,
        'averageCarbs': 0,
        'averageFat': 0,
      };
    }

    final protein = recentMeals.fold<double>(
      0,
      (total, meal) => total + ((meal['protein'] as num?)?.toDouble() ?? 0),
    );
    final carbs = recentMeals.fold<double>(
      0,
      (total, meal) => total + ((meal['carbs'] as num?)?.toDouble() ?? 0),
    );
    final fat = recentMeals.fold<double>(
      0,
      (total, meal) => total + ((meal['fat'] as num?)?.toDouble() ?? 0),
    );
    final divisor = recentMeals.length;
    return {
      'averageProtein': protein / divisor,
      'averageCarbs': carbs / divisor,
      'averageFat': fat / divisor,
    };
  }

  String _trendLabel(List<double> values) {
    if (values.length < 2) {
      return 'stable';
    }
    final firstHalf = values.take(values.length ~/ 2).fold<double>(0, (a, b) => a + b);
    final secondHalf = values.skip(values.length ~/ 2).fold<double>(0, (a, b) => a + b);
    if ((secondHalf - firstHalf).abs() < 1) {
      return 'stable';
    }
    return secondHalf > firstHalf ? 'up' : 'down';
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

  String? _weeklyCaloriesCacheKeyFor(DateTime weekStart) =>
      _uid == null ? null : 'weekly_calories_${_uid!}_${_formatDate(weekStart)}';

  String? _weeklyWaterCacheKeyFor(DateTime weekStart) =>
      _uid == null ? null : 'weekly_water_${_uid!}_${_formatDate(weekStart)}';
}
