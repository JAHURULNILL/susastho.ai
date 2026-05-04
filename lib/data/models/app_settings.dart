enum AppThemeModePreference {
  system,
  light,
  dark,
}

class AppSettings {
  const AppSettings({
    this.notificationsEnabled = true,
    this.language = 'বাংলা',
    this.units = 'মেট্রিক',
    this.customCalorieGoal,
    this.morningEnergy = 0,
    this.eveningEnergy = 0,
    this.themeMode = AppThemeModePreference.system,
    this.wearableSyncEnabled = true,
    this.fastingEnabled = false,
    this.fastingStartHour = 20,
    this.fastingWindowHours = 16,
    this.fastingStartedAtIso,
  });

  final bool notificationsEnabled;
  final String language;
  final String units;
  final int? customCalorieGoal;
  final int morningEnergy;
  final int eveningEnergy;
  final AppThemeModePreference themeMode;
  final bool wearableSyncEnabled;
  final bool fastingEnabled;
  final int fastingStartHour;
  final int fastingWindowHours;
  final String? fastingStartedAtIso;

  AppSettings copyWith({
    bool? notificationsEnabled,
    String? language,
    String? units,
    int? customCalorieGoal,
    int? morningEnergy,
    int? eveningEnergy,
    AppThemeModePreference? themeMode,
    bool? wearableSyncEnabled,
    bool? fastingEnabled,
    int? fastingStartHour,
    int? fastingWindowHours,
    String? fastingStartedAtIso,
    bool clearFastingStartedAt = false,
    bool clearCustomGoal = false,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      units: units ?? this.units,
      customCalorieGoal: clearCustomGoal ? null : customCalorieGoal ?? this.customCalorieGoal,
      morningEnergy: morningEnergy ?? this.morningEnergy,
      eveningEnergy: eveningEnergy ?? this.eveningEnergy,
      themeMode: themeMode ?? this.themeMode,
      wearableSyncEnabled: wearableSyncEnabled ?? this.wearableSyncEnabled,
      fastingEnabled: fastingEnabled ?? this.fastingEnabled,
      fastingStartHour: fastingStartHour ?? this.fastingStartHour,
      fastingWindowHours: fastingWindowHours ?? this.fastingWindowHours,
      fastingStartedAtIso: clearFastingStartedAt ? null : fastingStartedAtIso ?? this.fastingStartedAtIso,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'language': language,
      'units': units,
      'customCalorieGoal': customCalorieGoal,
      'morningEnergy': morningEnergy,
      'eveningEnergy': eveningEnergy,
      'themeMode': themeMode.name,
      'wearableSyncEnabled': wearableSyncEnabled,
      'fastingEnabled': fastingEnabled,
      'fastingStartHour': fastingStartHour,
      'fastingWindowHours': fastingWindowHours,
      'fastingStartedAtIso': fastingStartedAtIso,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      language: json['language'] as String? ?? 'বাংলা',
      units: json['units'] as String? ?? 'মেট্রিক',
      customCalorieGoal: (json['customCalorieGoal'] as num?)?.toInt(),
      morningEnergy: (json['morningEnergy'] as num?)?.toInt() ?? 0,
      eveningEnergy: (json['eveningEnergy'] as num?)?.toInt() ?? 0,
      themeMode: AppThemeModePreference.values.byName(
        json['themeMode'] as String? ?? AppThemeModePreference.system.name,
      ),
      wearableSyncEnabled: json['wearableSyncEnabled'] as bool? ?? true,
      fastingEnabled: json['fastingEnabled'] as bool? ?? false,
      fastingStartHour: (json['fastingStartHour'] as num?)?.toInt() ?? 20,
      fastingWindowHours: (json['fastingWindowHours'] as num?)?.toInt() ?? 16,
      fastingStartedAtIso: json['fastingStartedAtIso'] as String?,
    );
  }
}
