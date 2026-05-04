class WeeklyExerciseItem {
  const WeeklyExerciseItem({
    required this.id,
    required this.exerciseTitle,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.note,
    required this.conditionBenefit,
    required this.completed,
    required this.dateKey,
    required this.loggedAt,
  });

  final String id;
  final String exerciseTitle;
  final int durationMinutes;
  final double caloriesBurned;
  final String note;
  final String conditionBenefit;
  final bool completed;
  final String dateKey;
  final DateTime loggedAt;

  String get durationText => '$durationMinutes মিনিট';

  WeeklyExerciseItem copyWith({
    String? id,
    String? exerciseTitle,
    int? durationMinutes,
    double? caloriesBurned,
    String? note,
    String? conditionBenefit,
    bool? completed,
    String? dateKey,
    DateTime? loggedAt,
  }) {
    return WeeklyExerciseItem(
      id: id ?? this.id,
      exerciseTitle: exerciseTitle ?? this.exerciseTitle,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      note: note ?? this.note,
      conditionBenefit: conditionBenefit ?? this.conditionBenefit,
      completed: completed ?? this.completed,
      dateKey: dateKey ?? this.dateKey,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  factory WeeklyExerciseItem.fromJson(String id, Map<String, dynamic> json) {
    return WeeklyExerciseItem(
      id: id,
      exerciseTitle: json['exerciseTitle'] as String? ?? json['name'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ??
          (json['duration_minutes'] as num?)?.toInt() ??
          0,
      caloriesBurned: (json['caloriesBurned'] as num?)?.toDouble() ??
          (json['calories_burned'] as num?)?.toDouble() ??
          0,
      note: json['note'] as String? ?? json['instructions'] as String? ?? '',
      conditionBenefit: json['conditionBenefit'] as String? ?? json['condition_benefit'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      dateKey: json['dateKey'] as String? ?? json['date'] as String? ?? '',
      loggedAt: DateTime.tryParse(json['loggedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseTitle': exerciseTitle,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'note': note,
      'conditionBenefit': conditionBenefit,
      'completed': completed,
      'dateKey': dateKey,
      'loggedAt': loggedAt.toIso8601String(),
    };
  }
}

class PlannedMealSlot {
  const PlannedMealSlot({
    required this.items,
    required this.calories,
  });

  final List<String> items;
  final double calories;

  factory PlannedMealSlot.fromJson(Map<String, dynamic> json) {
    return PlannedMealSlot(
      items: ((json['items'] as List<dynamic>?) ?? const []).map((item) => item.toString()).toList(),
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items,
      'calories': calories,
    };
  }
}

class WeeklyMealPlanDay {
  const WeeklyMealPlanDay({
    required this.morning,
    required this.lunch,
    required this.afternoon,
    required this.night,
  });

  final PlannedMealSlot morning;
  final PlannedMealSlot lunch;
  final PlannedMealSlot afternoon;
  final PlannedMealSlot night;

  factory WeeklyMealPlanDay.fromJson(Map<String, dynamic> json) {
    return WeeklyMealPlanDay(
      morning: PlannedMealSlot.fromJson(Map<String, dynamic>.from(json['morning'] as Map? ?? const {})),
      lunch: PlannedMealSlot.fromJson(Map<String, dynamic>.from(json['lunch'] as Map? ?? const {})),
      afternoon: PlannedMealSlot.fromJson(Map<String, dynamic>.from(json['afternoon'] as Map? ?? const {})),
      night: PlannedMealSlot.fromJson(Map<String, dynamic>.from(json['night'] as Map? ?? const {})),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'morning': morning.toJson(),
      'lunch': lunch.toJson(),
      'afternoon': afternoon.toJson(),
      'night': night.toJson(),
    };
  }
}

class WeeklyMealPlan {
  const WeeklyMealPlan({
    required this.weekOf,
    required this.days,
    required this.weeklyTips,
    required this.specialNotes,
  });

  final String weekOf;
  final Map<String, WeeklyMealPlanDay> days;
  final List<String> weeklyTips;
  final String specialNotes;

  factory WeeklyMealPlan.fromJson(Map<String, dynamic> json) {
    final rawDays = Map<String, dynamic>.from(json['days'] as Map? ?? const {});
    return WeeklyMealPlan(
      weekOf: json['weekOf'] as String? ?? json['week_of'] as String? ?? '',
      days: rawDays.map(
        (key, value) => MapEntry(
          key,
          WeeklyMealPlanDay.fromJson(Map<String, dynamic>.from(value as Map? ?? const {})),
        ),
      ),
      weeklyTips: ((json['weeklyTips'] as List<dynamic>?) ?? json['weekly_tips'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      specialNotes: json['specialNotes'] as String? ?? json['special_notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekOf': weekOf,
      'days': days.map((key, value) => MapEntry(key, value.toJson())),
      'weeklyTips': weeklyTips,
      'specialNotes': specialNotes,
    };
  }
}
