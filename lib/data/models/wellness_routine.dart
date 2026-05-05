// ignore_for_file: unnecessary_brace_in_string_interps

enum WellnessRoutineType {
  breathing,
  kegel,
  meditation,
  nofap,
  sleep,
  coldshower,
}

extension WellnessRoutineTypeX on WellnessRoutineType {
  String get key => switch (this) {
        WellnessRoutineType.breathing => 'breathing',
        WellnessRoutineType.kegel => 'kegel',
        WellnessRoutineType.meditation => 'meditation',
        WellnessRoutineType.nofap => 'nofap',
        WellnessRoutineType.sleep => 'sleep',
        WellnessRoutineType.coldshower => 'coldshower',
      };

  String get labelBn => switch (this) {
        WellnessRoutineType.breathing => 'শ্বাস-প্রশ্বাস',
        WellnessRoutineType.kegel => 'কেগেল ব্যায়াম',
        WellnessRoutineType.meditation => 'মেডিটেশন',
        WellnessRoutineType.nofap => 'No Fap',
        WellnessRoutineType.sleep => 'ঘুমের রুটিন',
        WellnessRoutineType.coldshower => 'ঠান্ডা গোসল',
      };

  String get subtitleBn => switch (this) {
        WellnessRoutineType.breathing => 'সকালের শ্বাসে ফোকাস আনুন',
        WellnessRoutineType.kegel => 'Pelvic floor শক্তিশালী রাখুন',
        WellnessRoutineType.meditation => 'মনের চাপ নামিয়ে আনুন',
        WellnessRoutineType.nofap => 'Self-control ধারাবাহিক রাখুন',
        WellnessRoutineType.sleep => 'রাতের recovery ঠিক রাখুন',
        WellnessRoutineType.coldshower => 'শরীরকে fresh reset দিন',
      };

  String get iconEmoji => switch (this) {
        WellnessRoutineType.breathing => '🌬️',
        WellnessRoutineType.kegel => '💪',
        WellnessRoutineType.meditation => '🧘',
        WellnessRoutineType.nofap => '🔒',
        WellnessRoutineType.sleep => '🌙',
        WellnessRoutineType.coldshower => '🚿',
      };

  static WellnessRoutineType fromKey(String key) => switch (key) {
        'kegel' => WellnessRoutineType.kegel,
        'meditation' => WellnessRoutineType.meditation,
        'nofap' => WellnessRoutineType.nofap,
        'sleep' => WellnessRoutineType.sleep,
        'coldshower' => WellnessRoutineType.coldshower,
        _ => WellnessRoutineType.breathing,
      };
}

class WellnessCompletionLog {
  const WellnessCompletionLog({
    required this.userId,
    required this.moduleId,
    required this.date,
    required this.completedAt,
    required this.duration,
    required this.details,
  });

  final String userId;
  final WellnessRoutineType moduleId;
  final String date;
  final DateTime completedAt;
  final int duration;
  final Map<String, dynamic> details;

  factory WellnessCompletionLog.fromJson(Map<String, dynamic> json) {
    return WellnessCompletionLog(
      userId: json['userId'] as String? ?? '',
      moduleId: WellnessRoutineTypeX.fromKey(json['moduleId'] as String? ?? ''),
      date: json['date'] as String? ?? '',
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ?? DateTime.now(),
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      details: Map<String, dynamic>.from(json['details'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'moduleId': moduleId.key,
      'date': date,
      'completedAt': completedAt.toIso8601String(),
      'duration': duration,
      'details': details,
    };
  }
}

class WellnessStreakRecord {
  const WellnessStreakRecord({
    required this.userId,
    required this.moduleId,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletedDate,
    required this.totalSessions,
    required this.startedAt,
  });

  final String userId;
  final WellnessRoutineType moduleId;
  final int currentStreak;
  final int longestStreak;
  final String lastCompletedDate;
  final int totalSessions;
  final DateTime startedAt;

  factory WellnessStreakRecord.fromJson(Map<String, dynamic> json) {
    return WellnessStreakRecord(
      userId: json['userId'] as String? ?? '',
      moduleId: WellnessRoutineTypeX.fromKey(json['moduleId'] as String? ?? ''),
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      lastCompletedDate: json['lastCompletedDate'] as String? ?? '',
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'moduleId': moduleId.key,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCompletedDate': lastCompletedDate,
      'totalSessions': totalSessions,
      'startedAt': startedAt.toIso8601String(),
    };
  }
}

class NofapTrackerRecord {
  const NofapTrackerRecord({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.startDate,
    required this.lastResetDate,
    required this.totalResets,
  });

  final String userId;
  final int currentStreak;
  final int longestStreak;
  final String startDate;
  final String lastResetDate;
  final int totalResets;

  factory NofapTrackerRecord.fromJson(Map<String, dynamic> json) {
    return NofapTrackerRecord(
      userId: json['userId'] as String? ?? '',
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      startDate: json['startDate'] as String? ?? '',
      lastResetDate: json['lastResetDate'] as String? ?? '',
      totalResets: (json['totalResets'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'startDate': startDate,
      'lastResetDate': lastResetDate,
      'totalResets': totalResets,
    };
  }
}

class WellnessRoutinePlan {
  const WellnessRoutinePlan({
    required this.dateKey,
    required this.streaks,
    required this.todayLogs,
    required this.weekLogs,
    required this.nofapTracker,
    required this.dailyBenefit,
    required this.isLoadingBenefit,
  });

  final String dateKey;
  final Map<WellnessRoutineType, WellnessStreakRecord> streaks;
  final Set<String> todayLogs;
  final Map<String, Set<String>> weekLogs;
  final NofapTrackerRecord? nofapTracker;
  final String dailyBenefit;
  final bool isLoadingBenefit;

  int get nofapStreak => nofapTracker?.currentStreak ?? 0;
  int get doneTodayCount => todayLogs.length;
  int get totalModules => WellnessRoutineType.values.length;
  int get totalPoints => totalModules * 10;
  int get earnedPoints => doneTodayCount * 10;
  int get totalScore => totalStreak * 10;
  int get badgesEarned => totalScore ~/ 100;
  double get progressRatio => totalModules == 0 ? 0 : doneTodayCount / totalModules;

  String get progressMessage {
    if (doneTodayCount == 0) {
      return 'আজ একটি ছোট wellness অভ্যাস দিয়েই শুরু করুন।';
    }
    if (doneTodayCount >= totalModules) {
      return 'দারুণ। আজকের সব wellness module সম্পন্ন হয়েছে।';
    }
    return 'আজ ${doneTodayCount}/${totalModules} module শেষ হয়েছে। ধারাবাহিকতা ধরে রাখুন।';
  }

  int get totalStreak {
    var total = nofapStreak;
    for (final entry in streaks.entries) {
      if (entry.key == WellnessRoutineType.nofap) {
        continue;
      }
      total += entry.value.currentStreak;
    }
    return total;
  }

  int streakFor(WellnessRoutineType type) {
    if (type == WellnessRoutineType.nofap) {
      return nofapStreak;
    }
    return streaks[type]?.currentStreak ?? 0;
  }

  bool isDoneToday(WellnessRoutineType type) => todayLogs.contains(type.key);

  bool wasDoneOn(WellnessRoutineType type, String dateKey) {
    return weekLogs[dateKey]?.contains(type.key) ?? false;
  }

  WellnessRoutinePlan copyWith({
    Map<WellnessRoutineType, WellnessStreakRecord>? streaks,
    Set<String>? todayLogs,
    Map<String, Set<String>>? weekLogs,
    NofapTrackerRecord? nofapTracker,
    String? dailyBenefit,
    bool? isLoadingBenefit,
    bool clearNofapTracker = false,
  }) {
    return WellnessRoutinePlan(
      dateKey: dateKey,
      streaks: streaks ?? this.streaks,
      todayLogs: todayLogs ?? this.todayLogs,
      weekLogs: weekLogs ?? this.weekLogs,
      nofapTracker: clearNofapTracker ? null : nofapTracker ?? this.nofapTracker,
      dailyBenefit: dailyBenefit ?? this.dailyBenefit,
      isLoadingBenefit: isLoadingBenefit ?? this.isLoadingBenefit,
    );
  }

  List<WellnessRoutineEntry> get entries {
    return WellnessRoutineType.values.map((type) {
      final minutes = switch (type) {
        WellnessRoutineType.breathing => 5,
        WellnessRoutineType.kegel => 8,
        WellnessRoutineType.meditation => 10,
        WellnessRoutineType.nofap => 0,
        WellnessRoutineType.sleep => 10,
        WellnessRoutineType.coldshower => 3,
      };
      final title = switch (type) {
        WellnessRoutineType.breathing => 'Breathing session',
        WellnessRoutineType.kegel => 'Kegel session',
        WellnessRoutineType.meditation => 'Meditation session',
        WellnessRoutineType.nofap => 'No Fap check-in',
        WellnessRoutineType.sleep => 'Sleep routine',
        WellnessRoutineType.coldshower => 'Cold shower',
      };
      return WellnessRoutineEntry(
        type: type,
        timeLabel: type == WellnessRoutineType.sleep ? 'রাত' : 'আজ',
        title: title,
        instructions: type.subtitleBn,
        benefit: type.subtitleBn,
        minutes: minutes,
        points: 10,
        completed: isDoneToday(type),
        streakDays: streakFor(type),
      );
    }).toList();
  }

  factory WellnessRoutinePlan.empty(String dateKey) {
    return WellnessRoutinePlan(
      dateKey: dateKey,
      streaks: const {},
      todayLogs: const <String>{},
      weekLogs: const {},
      nofapTracker: null,
      dailyBenefit: '',
      isLoadingBenefit: true,
    );
  }
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
}
