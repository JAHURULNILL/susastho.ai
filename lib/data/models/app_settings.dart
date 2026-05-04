class AppSettings {
  const AppSettings({
    this.notificationsEnabled = true,
    this.language = 'বাংলা',
    this.units = 'মেট্রিক',
    this.customCalorieGoal,
    this.morningEnergy = 0,
    this.eveningEnergy = 0,
  });

  final bool notificationsEnabled;
  final String language;
  final String units;
  final int? customCalorieGoal;
  final int morningEnergy;
  final int eveningEnergy;

  AppSettings copyWith({
    bool? notificationsEnabled,
    String? language,
    String? units,
    int? customCalorieGoal,
    int? morningEnergy,
    int? eveningEnergy,
    bool clearCustomGoal = false,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      units: units ?? this.units,
      customCalorieGoal: clearCustomGoal ? null : customCalorieGoal ?? this.customCalorieGoal,
      morningEnergy: morningEnergy ?? this.morningEnergy,
      eveningEnergy: eveningEnergy ?? this.eveningEnergy,
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
    );
  }
}
