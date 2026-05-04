enum WellnessRoutineType {
  breathing,
  pelvicFloor,
  meditation,
  habitControl,
}

extension WellnessRoutineTypeX on WellnessRoutineType {
  String get key => switch (this) {
        WellnessRoutineType.breathing => 'breathing',
        WellnessRoutineType.pelvicFloor => 'pelvicFloor',
        WellnessRoutineType.meditation => 'meditation',
        WellnessRoutineType.habitControl => 'habitControl',
      };

  String get labelBn => switch (this) {
        WellnessRoutineType.breathing => 'Breathing',
        WellnessRoutineType.pelvicFloor => 'Pelvic Floor',
        WellnessRoutineType.meditation => 'Meditation',
        WellnessRoutineType.habitControl => 'Habit Control',
      };

  String get subtitleBn => switch (this) {
        WellnessRoutineType.breathing => 'শ্বাস-প্রশ্বাস ঠিক রাখুন',
        WellnessRoutineType.pelvicFloor => 'পেলভিক কন্ট্রোল শক্তিশালী করুন',
        WellnessRoutineType.meditation => 'মনকে শান্ত রাখুন',
        WellnessRoutineType.habitControl => 'নিজের উপর নিয়ন্ত্রণ গড়ুন',
      };

  String get benefitBn => switch (this) {
        WellnessRoutineType.breathing => 'স্ট্রেস কমাতে আর মন পরিষ্কার রাখতে সাহায্য করে।',
        WellnessRoutineType.pelvicFloor => 'পেলভিক স্বাস্থ্য, bladder control আর core support-এ সাহায্য করে।',
        WellnessRoutineType.meditation => 'মানসিক চাপ কমিয়ে ঘুম ও ফোকাস উন্নত করতে সাহায্য করে।',
        WellnessRoutineType.habitControl => 'দৈনিক self-discipline বজায় রাখতে আর relapse কমাতে সহায়তা করে।',
      };

  String get iconEmoji => switch (this) {
        WellnessRoutineType.breathing => '🌬️',
        WellnessRoutineType.pelvicFloor => '🧘',
        WellnessRoutineType.meditation => '🕯️',
        WellnessRoutineType.habitControl => '🛡️',
      };

  static WellnessRoutineType fromKey(String key) => switch (key) {
        'pelvicFloor' => WellnessRoutineType.pelvicFloor,
        'meditation' => WellnessRoutineType.meditation,
        'habitControl' => WellnessRoutineType.habitControl,
        _ => WellnessRoutineType.breathing,
      };
}

class WellnessRoutineEntry {
  const WellnessRoutineEntry({
    required this.type,
    required this.timeLabel,
    required this.title,
    required this.instructions,
    required this.benefit,
    required this.minutes,
    required this.points,
    required this.completed,
    required this.streakDays,
  });

  final WellnessRoutineType type;
  final String timeLabel;
  final String title;
  final String instructions;
  final String benefit;
  final int minutes;
  final int points;
  final bool completed;
  final int streakDays;

  WellnessRoutineEntry copyWith({
    bool? completed,
    int? streakDays,
  }) {
    return WellnessRoutineEntry(
      type: type,
      timeLabel: timeLabel,
      title: title,
      instructions: instructions,
      benefit: benefit,
      minutes: minutes,
      points: points,
      completed: completed ?? this.completed,
      streakDays: streakDays ?? this.streakDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.key,
      'timeLabel': timeLabel,
      'title': title,
      'instructions': instructions,
      'benefit': benefit,
      'minutes': minutes,
      'points': points,
      'completed': completed,
      'streakDays': streakDays,
    };
  }

  factory WellnessRoutineEntry.fromJson(Map<String, dynamic> json) {
    return WellnessRoutineEntry(
      type: WellnessRoutineTypeX.fromKey(json['type'] as String? ?? 'breathing'),
      timeLabel: json['timeLabel'] as String? ?? '',
      title: json['title'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      benefit: json['benefit'] as String? ?? '',
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 10,
      completed: json['completed'] as bool? ?? false,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
    );
  }
}

class WellnessRoutinePlan {
  const WellnessRoutinePlan({
    required this.dateKey,
    required this.entries,
    required this.totalPoints,
    required this.earnedPoints,
    required this.totalScore,
    required this.badgesEarned,
    required this.progressMessage,
  });

  final String dateKey;
  final List<WellnessRoutineEntry> entries;
  final int totalPoints;
  final int earnedPoints;
  final int totalScore;
  final int badgesEarned;
  final String progressMessage;

  double get progressRatio => totalPoints == 0 ? 0 : earnedPoints / totalPoints;

  WellnessRoutinePlan copyWith({
    List<WellnessRoutineEntry>? entries,
    int? earnedPoints,
    int? totalScore,
    int? badgesEarned,
    String? progressMessage,
  }) {
    return WellnessRoutinePlan(
      dateKey: dateKey,
      entries: entries ?? this.entries,
      totalPoints: totalPoints,
      earnedPoints: earnedPoints ?? this.earnedPoints,
      totalScore: totalScore ?? this.totalScore,
      badgesEarned: badgesEarned ?? this.badgesEarned,
      progressMessage: progressMessage ?? this.progressMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'entries': entries.map((item) => item.toJson()).toList(),
      'totalPoints': totalPoints,
      'earnedPoints': earnedPoints,
      'totalScore': totalScore,
      'badgesEarned': badgesEarned,
      'progressMessage': progressMessage,
    };
  }

  factory WellnessRoutinePlan.fromJson(Map<String, dynamic> json) {
    return WellnessRoutinePlan(
      dateKey: json['dateKey'] as String? ?? '',
      entries: ((json['entries'] as List<dynamic>?) ?? const [])
          .map((item) => WellnessRoutineEntry.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 40,
      earnedPoints: (json['earnedPoints'] as num?)?.toInt() ?? 0,
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
      badgesEarned: (json['badgesEarned'] as num?)?.toInt() ?? 0,
      progressMessage: json['progressMessage'] as String? ?? '',
    );
  }
}
