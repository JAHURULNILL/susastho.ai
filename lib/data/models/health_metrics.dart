class SleepLogRecord {
  const SleepLogRecord({
    required this.hours,
    required this.quality,
    required this.dateKey,
  });

  final double hours;
  final String quality;
  final String dateKey;

  factory SleepLogRecord.fromJson(Map<String, dynamic> json) {
    return SleepLogRecord(
      hours: (json['hours'] as num?)?.toDouble() ?? 0,
      quality: json['quality'] as String? ?? '',
      dateKey: json['dateKey'] as String? ?? json['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hours': hours,
      'quality': quality,
      'dateKey': dateKey,
    };
  }
}

class StepLogRecord {
  const StepLogRecord({
    required this.steps,
    required this.dateKey,
  });

  final int steps;
  final String dateKey;

  factory StepLogRecord.fromJson(Map<String, dynamic> json) {
    return StepLogRecord(
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      dateKey: json['dateKey'] as String? ?? json['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'steps': steps,
      'dateKey': dateKey,
    };
  }
}

class WeightHistoryEntry {
  const WeightHistoryEntry({
    required this.id,
    required this.weightKg,
    required this.dateKey,
    required this.recordedAt,
  });

  final String id;
  final double weightKg;
  final String dateKey;
  final DateTime recordedAt;

  factory WeightHistoryEntry.fromJson(String id, Map<String, dynamic> json) {
    return WeightHistoryEntry(
      id: id,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? (json['weight'] as num?)?.toDouble() ?? 0,
      dateKey: json['dateKey'] as String? ?? json['date'] as String? ?? '',
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weightKg': weightKg,
      'dateKey': dateKey,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }
}
