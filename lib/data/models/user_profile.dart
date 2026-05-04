import '../../core/utils/health_calculators.dart';

enum UserGoal {
  weightLoss,
  weightGain,
  maintenance,
}

enum HealthCondition {
  diabetes,
  heartDisease,
  hypertension,
  underweight,
  obesity,
  bellyFat,
  ed,
  prematureEjaculation,
  urinaryIssues,
  fattyLiver,
  kidneyIssues,
  digestiveIssues,
  insomnia,
}

extension UserGoalX on UserGoal {
  String get labelBn => switch (this) {
        UserGoal.weightLoss => 'ওজন কমানো',
        UserGoal.weightGain => 'ওজন বাড়ানো',
        UserGoal.maintenance => 'ওজন ঠিক রাখা',
      };

  String get key => switch (this) {
        UserGoal.weightLoss => 'weightLoss',
        UserGoal.weightGain => 'weightGain',
        UserGoal.maintenance => 'maintenance',
      };

  static UserGoal fromKey(String value) => switch (value) {
        'weightLoss' => UserGoal.weightLoss,
        'weightGain' => UserGoal.weightGain,
        'maintenance' => UserGoal.maintenance,
        _ => UserGoal.maintenance,
      };
}

extension HealthConditionX on HealthCondition {
  String get labelBn => switch (this) {
        HealthCondition.diabetes => 'ডায়াবেটিস',
        HealthCondition.heartDisease => 'হৃদরোগ',
        HealthCondition.hypertension => 'উচ্চ রক্তচাপ',
        HealthCondition.underweight => 'আন্ডারওয়েট',
        HealthCondition.obesity => 'স্থূলতা',
        HealthCondition.bellyFat => 'পেটের চর্বি',
        HealthCondition.ed => 'ইরেকটাইল ডিসফাংশন',
        HealthCondition.prematureEjaculation => 'প্রিম্যাচিউর ইজাকুলেশন',
        HealthCondition.urinaryIssues => 'মূত্রজনিত সমস্যা',
        HealthCondition.fattyLiver => 'ফ্যাটি লিভার',
        HealthCondition.kidneyIssues => 'কিডনি সমস্যা',
        HealthCondition.digestiveIssues => 'হজমজনিত সমস্যা',
        HealthCondition.insomnia => 'ঘুমের সমস্যা',
      };

  String get key => switch (this) {
        HealthCondition.diabetes => 'diabetes',
        HealthCondition.heartDisease => 'heartDisease',
        HealthCondition.hypertension => 'hypertension',
        HealthCondition.underweight => 'underweight',
        HealthCondition.obesity => 'obesity',
        HealthCondition.bellyFat => 'bellyFat',
        HealthCondition.ed => 'ed',
        HealthCondition.prematureEjaculation => 'prematureEjaculation',
        HealthCondition.urinaryIssues => 'urinaryIssues',
        HealthCondition.fattyLiver => 'fattyLiver',
        HealthCondition.kidneyIssues => 'kidneyIssues',
        HealthCondition.digestiveIssues => 'digestiveIssues',
        HealthCondition.insomnia => 'insomnia',
      };

  static HealthCondition fromKey(String value) => switch (value) {
        'diabetes' => HealthCondition.diabetes,
        'heartDisease' => HealthCondition.heartDisease,
        'hypertension' => HealthCondition.hypertension,
        'underweight' => HealthCondition.underweight,
        'obesity' => HealthCondition.obesity,
        'bellyFat' => HealthCondition.bellyFat,
        'ed' => HealthCondition.ed,
        'prematureEjaculation' => HealthCondition.prematureEjaculation,
        'urinaryIssues' => HealthCondition.urinaryIssues,
        'fattyLiver' => HealthCondition.fattyLiver,
        'kidneyIssues' => HealthCondition.kidneyIssues,
        'digestiveIssues' => HealthCondition.digestiveIssues,
        'insomnia' => HealthCondition.insomnia,
        _ => HealthCondition.diabetes,
      };
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
    required this.conditions,
  });

  final String name;
  final int age;
  final double weightKg;
  final double heightCm;
  final UserGoal goal;
  final List<HealthCondition> conditions;

  double get bmi => HealthCalculators.bmi(this);
  int get dailyCalorieTarget => HealthCalculators.dailyCalorieTarget(this);
  int get dailyStepTarget => HealthCalculators.dailyStepTarget(this);

  UserProfile copyWith({
    String? name,
    int? age,
    double? weightKg,
    double? heightCm,
    UserGoal? goal,
    List<HealthCondition>? conditions,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      goal: goal ?? this.goal,
      conditions: conditions ?? this.conditions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'goal': goal.key,
      'conditions': conditions.map((item) => item.key).toList(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
      goal: UserGoalX.fromKey(json['goal'] as String? ?? UserGoal.maintenance.key),
      conditions: ((json['conditions'] as List<dynamic>?) ?? [])
          .map((item) => HealthConditionX.fromKey(item as String))
          .toList(),
    );
  }
}
