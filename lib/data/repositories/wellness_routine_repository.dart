import '../models/user_profile.dart';
import '../models/wellness_routine.dart';
import '../services/local_storage_service.dart';

class WellnessRoutineRepository {
  WellnessRoutineRepository(this._storage);

  final LocalStorageService _storage;
  static const _planKey = 'wellness_routine_plan_v1';
  static const _statsKey = 'wellness_routine_stats_v1';

  Future<WellnessRoutinePlan> loadToday(UserProfile profile) async {
    final today = _todayKey();
    await _loadStats();
    final stored = await _storage.readJson(_planKey);
    if (stored != null) {
      final plan = WellnessRoutinePlan.fromJson(stored);
      if (plan.dateKey == today) {
        return plan;
      }
    }

    final plan = _buildDefaultPlan(profile, today);
    await _storage.saveJson(_planKey, plan.toJson());
    return plan;
  }

  Future<WellnessRoutinePlan> toggleTask({
    required UserProfile profile,
    required WellnessRoutineType type,
  }) async {
    final plan = await loadToday(profile);
    final stats = await _loadStats();
    final previousEntry = plan.entries.firstWhere((entry) => entry.type == type);
    final entries = plan.entries.map((entry) {
      if (entry.type != type) {
        return entry;
      }
      final nextCompleted = !entry.completed;
      final currentStatStreak = (stats['streaks']?[entry.type.key] as num?)?.toInt() ?? entry.streakDays;
      final nextStreak = nextCompleted
          ? (currentStatStreak == 0 ? 1 : currentStatStreak + 1)
          : (currentStatStreak > 0 ? currentStatStreak - 1 : 0);
      return entry.copyWith(
        completed: nextCompleted,
        streakDays: nextStreak,
      );
    }).toList();

    final earnedPoints = entries
        .where((entry) => entry.completed)
        .fold<int>(0, (sum, entry) => sum + entry.points);
    final scoreDelta = previousEntry.completed ? -previousEntry.points : previousEntry.points;
    final totalScore = ((stats['totalScore'] as num?)?.toInt() ?? 0) + scoreDelta;
    final badgesEarned = totalScore <= 0 ? 0 : totalScore ~/ 100;

    final updatedStats = <String, dynamic>{
      'totalScore': totalScore < 0 ? 0 : totalScore,
      'streaks': {
        ...(stats['streaks'] as Map<String, dynamic>? ?? const {}),
        for (final entry in entries) entry.type.key: entry.streakDays,
      },
    };
    await _storage.saveJson(_statsKey, updatedStats);

    final updated = plan.copyWith(
      entries: entries,
      earnedPoints: earnedPoints,
      totalScore: totalScore < 0 ? 0 : totalScore,
      badgesEarned: badgesEarned,
      progressMessage: _buildProgressMessage(earnedPoints, plan.totalPoints),
    );

    await _storage.saveJson(_planKey, updated.toJson());
    return updated;
  }

  WellnessRoutinePlan _buildDefaultPlan(UserProfile profile, String today) {
    final needsPelvicFocus = profile.conditions.contains(HealthCondition.urinaryIssues) ||
        profile.conditions.contains(HealthCondition.ed) ||
        profile.conditions.contains(HealthCondition.prematureEjaculation) ||
        profile.conditions.contains(HealthCondition.irregularPeriods);
    final stats = _cachedStats;

    final entries = <WellnessRoutineEntry>[
      WellnessRoutineEntry(
        type: WellnessRoutineType.breathing,
        timeLabel: 'সকাল',
        title: '৫ মিনিট Breathing',
        instructions: '৪ সেকেন্ড শ্বাস নিন, ৪ সেকেন্ড ধরে রাখুন, ৬ সেকেন্ডে ছাড়ুন।',
        benefit: 'দিনের শুরুতে মন ও নার্ভ শান্ত রাখতে সাহায্য করবে।',
        minutes: 5,
        points: 10,
        completed: false,
        streakDays: (stats['streaks']?['breathing'] as num?)?.toInt() ?? 0,
      ),
      WellnessRoutineEntry(
        type: WellnessRoutineType.pelvicFloor,
        timeLabel: 'দুপুর',
        title: needsPelvicFocus ? '১০ মিনিট Pelvic Floor' : '৮ মিনিট Pelvic Floor',
        instructions: needsPelvicFocus
            ? 'Pelvic muscle টাইট করে ৫ সেকেন্ড ধরে রাখুন, ছাড়ুন, এভাবে ১০–১২ বার করুন।'
            : 'Pelvic muscle টাইট করে ৩–৫ সেকেন্ড ধরে রেখে ধীরে ছাড়ুন, ৮–১০ বার করুন।',
        benefit: 'Pelvic control, bladder support আর core stability-তে সাহায্য করবে।',
        minutes: needsPelvicFocus ? 10 : 8,
        points: 15,
        completed: false,
        streakDays: (stats['streaks']?['pelvicFloor'] as num?)?.toInt() ?? 0,
      ),
      WellnessRoutineEntry(
        type: WellnessRoutineType.meditation,
        timeLabel: 'বিকাল',
        title: '১০ মিনিট Meditation',
        instructions: 'শান্ত হয়ে বসে শ্বাসের উপর মন দিন, ১০ মিনিট শুধু present থাকুন।',
        benefit: 'বিকালের stress কমিয়ে সন্ধ্যার focus ফিরিয়ে আনবে।',
        minutes: 10,
        points: 10,
        completed: false,
        streakDays: (stats['streaks']?['meditation'] as num?)?.toInt() ?? 0,
      ),
      WellnessRoutineEntry(
        type: WellnessRoutineType.habitControl,
        timeLabel: 'রাত',
        title: 'Habit Control Check-in',
        instructions: 'আজ নিজের উপর নিয়ন্ত্রণ কেমন ছিল, সেটা note করে দিন আর streak বজায় রাখুন।',
        benefit: 'Self-control, discipline আর long-term motivation ধরে রাখতে সাহায্য করবে।',
        minutes: 3,
        points: 10,
        completed: false,
        streakDays: (stats['streaks']?['habitControl'] as num?)?.toInt() ?? 0,
      ),
    ];

    final totalPoints = entries.fold<int>(0, (sum, entry) => sum + entry.points);
    final totalScore = (stats['totalScore'] as num?)?.toInt() ?? 0;

    return WellnessRoutinePlan(
      dateKey: today,
      entries: entries,
      totalPoints: totalPoints,
      earnedPoints: 0,
      totalScore: totalScore,
      badgesEarned: totalScore <= 0 ? 0 : totalScore ~/ 100,
      progressMessage: _buildProgressMessage(0, totalPoints),
    );
  }

  String _buildProgressMessage(int earnedPoints, int totalPoints) {
    if (earnedPoints == 0) {
      return 'আজ শুরু করুন। প্রতিটি অনুশীলন আপনাকে আরও সুস্থ জীবনের দিকে এগিয়ে নেবে।';
    }
    if (earnedPoints >= totalPoints) {
      return 'দারুণ। আজকের সব wellness target পূরণ হয়েছে। আপনি সত্যিই অনেকটা এগিয়েছেন।';
    }
    return 'আপনি সুস্থ হতে ${earnedPoints} পয়েন্ট এগিয়েছেন। আরেকটি অনুশীলন শেষ করলে অগ্রগতি আরও বাড়বে।';
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _cachedStats = const {};

  Future<Map<String, dynamic>> _loadStats() async {
    final stats = await _storage.readJson(_statsKey) ?? const {};
    _cachedStats = stats;
    return stats;
  }
}
