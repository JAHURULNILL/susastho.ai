class AppSettings {
  const AppSettings({
    this.notificationsEnabled = true,
    this.language = 'বাংলা',
    this.units = 'মেট্রিক',
    this.customCalorieGoal,
  });

  final bool notificationsEnabled;
  final String language;
  final String units;
  final int? customCalorieGoal;

  AppSettings copyWith({
    bool? notificationsEnabled,
    String? language,
    String? units,
    int? customCalorieGoal,
    bool clearCustomGoal = false,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      units: units ?? this.units,
      customCalorieGoal: clearCustomGoal ? null : customCalorieGoal ?? this.customCalorieGoal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'language': language,
      'units': units,
      'customCalorieGoal': customCalorieGoal,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      language: json['language'] as String? ?? 'বাংলা',
      units: json['units'] as String? ?? 'মেট্রিক',
      customCalorieGoal: (json['customCalorieGoal'] as num?)?.toInt(),
    );
  }
}
