import 'food_analysis_result.dart';

enum MealSlot {
  morning,
  lunch,
  snack,
  dinner,
}

extension MealSlotX on MealSlot {
  String get labelBn => switch (this) {
        MealSlot.morning => 'সকাল',
        MealSlot.lunch => 'দুপুর',
        MealSlot.snack => 'বিকাল',
        MealSlot.dinner => 'রাত',
      };

  String get icon => switch (this) {
        MealSlot.morning => '🌅',
        MealSlot.lunch => '☀️',
        MealSlot.snack => '🌤',
        MealSlot.dinner => '🌙',
      };

  static MealSlot fromHour(int hour) {
    if (hour < 11) {
      return MealSlot.morning;
    }
    if (hour < 15) {
      return MealSlot.lunch;
    }
    if (hour < 18) {
      return MealSlot.snack;
    }
    return MealSlot.dinner;
  }

  static MealSlot fromKey(String value) => MealSlot.values.firstWhere(
        (slot) => slot.name == value,
        orElse: () => MealSlot.morning,
      );
}

class MealLogEntry {
  const MealLogEntry({
    required this.id,
    required this.foodName,
    required this.loggedAt,
    required this.slot,
    required this.macros,
    required this.summary,
    required this.healthScore,
    this.imagePath,
  });

  final String id;
  final String foodName;
  final DateTime loggedAt;
  final MealSlot slot;
  final NutritionMacro macros;
  final String summary;
  final int healthScore;
  final String? imagePath;

  factory MealLogEntry.fromAnalysis(
    FoodAnalysisResult result, {
    String? imagePath,
    DateTime? loggedAt,
  }) {
    final time = loggedAt ?? DateTime.now();
    return MealLogEntry(
      id: time.microsecondsSinceEpoch.toString(),
      foodName: result.foodName,
      loggedAt: time,
      slot: MealSlotX.fromHour(time.hour),
      macros: result.macros,
      summary: result.summary,
      healthScore: result.healthScore,
      imagePath: imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodName': foodName,
      'loggedAt': loggedAt.toIso8601String(),
      'slot': slot.name,
      'macros': macros.toJson(),
      'summary': summary,
      'healthScore': healthScore,
      'imagePath': imagePath,
    };
  }

  factory MealLogEntry.fromJson(Map<String, dynamic> json) {
    return MealLogEntry(
      id: json['id'] as String? ?? '',
      foodName: json['foodName'] as String? ?? '',
      loggedAt: DateTime.tryParse(json['loggedAt'] as String? ?? '') ?? DateTime.now(),
      slot: MealSlotX.fromKey(json['slot'] as String? ?? MealSlot.morning.name),
      macros: NutritionMacro.fromJson(Map<String, dynamic>.from(json['macros'] as Map? ?? {})),
      summary: json['summary'] as String? ?? '',
      healthScore: (json['healthScore'] as num?)?.toInt() ?? 0,
      imagePath: json['imagePath'] as String?,
    );
  }
}

class DailySummary {
  const DailySummary({
    required this.dateKey,
    this.meals = const [],
    this.waterGlasses = 0,
  });

  final String dateKey;
  final List<MealLogEntry> meals;
  final int waterGlasses;

  NutritionMacro get consumedMacros {
    return meals.fold(
      const NutritionMacro(calories: 0, protein: 0, carbs: 0, fat: 0),
      (sum, meal) => NutritionMacro(
        calories: sum.calories + meal.macros.calories,
        protein: sum.protein + meal.macros.protein,
        carbs: sum.carbs + meal.macros.carbs,
        fat: sum.fat + meal.macros.fat,
      ),
    );
  }

  DailySummary copyWith({
    String? dateKey,
    List<MealLogEntry>? meals,
    int? waterGlasses,
  }) {
    return DailySummary(
      dateKey: dateKey ?? this.dateKey,
      meals: meals ?? this.meals,
      waterGlasses: waterGlasses ?? this.waterGlasses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'waterGlasses': waterGlasses,
      'meals': meals.map((meal) => meal.toJson()).toList(),
    };
  }

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      dateKey: json['dateKey'] as String? ?? '',
      waterGlasses: (json['waterGlasses'] as num?)?.toInt() ?? 0,
      meals: ((json['meals'] as List<dynamic>?) ?? [])
          .map((item) => MealLogEntry.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}
