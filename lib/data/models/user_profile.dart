import '../../core/utils/health_calculators.dart';

enum UserGender {
  male,
  female,
}

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
  pcos,
  irregularPeriods,
  hormonalImbalance,
}

extension UserGenderX on UserGender {
  String get labelBn => switch (this) {
        UserGender.male => 'ছেলে',
        UserGender.female => 'মেয়ে',
      };

  String get key => switch (this) {
        UserGender.male => 'male',
        UserGender.female => 'female',
      };

  static UserGender fromKey(String value) => switch (value) {
        'female' => UserGender.female,
        _ => UserGender.male,
      };
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
        HealthCondition.pcos => 'পিসিওএস',
        HealthCondition.irregularPeriods => 'অনিয়মিত পিরিয়ড',
        HealthCondition.hormonalImbalance => 'হরমোনাল সমস্যা',
      };

  String get emoji => switch (this) {
        HealthCondition.diabetes => '🩸',
        HealthCondition.heartDisease => '🫀',
        HealthCondition.hypertension => '🩺',
        HealthCondition.underweight => '⚖️',
        HealthCondition.obesity => '🏃‍♂️',
        HealthCondition.bellyFat => '🔥',
        HealthCondition.ed => '⚡',
        HealthCondition.prematureEjaculation => '⏱️',
        HealthCondition.urinaryIssues => '💧',
        HealthCondition.fattyLiver => '🍏',
        HealthCondition.kidneyIssues => '🛡️',
        HealthCondition.digestiveIssues => '🔋',
        HealthCondition.insomnia => '🌙',
        HealthCondition.pcos => '🎀',
        HealthCondition.irregularPeriods => '📅',
        HealthCondition.hormonalImbalance => '🧪',
      };

  String get descriptionBn => switch (this) {
        HealthCondition.diabetes => 'রক্তে গ্লুকোজ লেভেল ও সুগার কন্ট্রোল',
        HealthCondition.heartDisease => 'কার্ডিওভাসকুলার ও হার্টের সুস্বাস্থ্য যত্ন',
        HealthCondition.hypertension => 'উচ্চ রক্তচাপ নিয়ন্ত্রণ ও লবণমুক্ত খাবার',
        HealthCondition.underweight => 'স্বাস্থ্যকর উপায়ে মাসল ও ওজন বৃদ্ধি',
        HealthCondition.obesity => 'ওজন হ্রাস, চর্বি বার্ন ও অ্যাক্টিভ লাইফস্টাইল',
        HealthCondition.bellyFat => 'পেটের জেদি মেদ কমানো ও মেটাবলিজম বুস্ট',
        HealthCondition.ed => 'রক্ত সঞ্চালন বৃদ্ধি ও স্ট্যামিনা রুটিন',
        HealthCondition.prematureEjaculation => 'ধৈর্য, স্ট্যামিনা ও মানসিক প্রশান্তি',
        HealthCondition.urinaryIssues => 'মূত্রনালীর ইনফেকশন ও প্রস্টেট কেয়ার',
        HealthCondition.fattyLiver => 'লিভারের ফ্যাট দূর ও বডি ডিটক্স ডায়েট',
        HealthCondition.kidneyIssues => 'সোডিয়াম, পটাশিয়াম ও ফসফরাস কন্ট্রোল',
        HealthCondition.digestiveIssues => 'গ্যাস, অ্যাসিডিটি কমানো ও অন্ত্রের যত্ন',
        HealthCondition.insomnia => 'গভীর ঘুম ও স্লিপ রুটিন ম্যানেজমেন্ট',
        HealthCondition.pcos => 'ওভারিয়ান সিন্ড্রোম ও হরমোন ব্যালেন্স',
        HealthCondition.irregularPeriods => 'পিরিয়ড চক্র স্বাভাবিক করা ও পুষ্টির যত্ন',
        HealthCondition.hormonalImbalance => 'মেটাবলিক ব্যালেন্স ও স্ট্রেস রিলিজ',
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
        HealthCondition.pcos => 'pcos',
        HealthCondition.irregularPeriods => 'irregularPeriods',
        HealthCondition.hormonalImbalance => 'hormonalImbalance',
      };

  bool isVisibleFor(UserGender gender) {
    return switch (this) {
      HealthCondition.ed || HealthCondition.prematureEjaculation => gender == UserGender.male,
      HealthCondition.pcos || HealthCondition.irregularPeriods || HealthCondition.hormonalImbalance => gender == UserGender.female,
      _ => true,
    };
  }

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
        'pcos' => HealthCondition.pcos,
        'irregularPeriods' => HealthCondition.irregularPeriods,
        'hormonalImbalance' => HealthCondition.hormonalImbalance,
        _ => HealthCondition.diabetes,
      };
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.gender,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
    required this.conditions,
  });

  final String name;
  final UserGender gender;
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
    UserGender? gender,
    int? age,
    double? weightKg,
    double? heightCm,
    UserGoal? goal,
    List<HealthCondition>? conditions,
  }) {
    return UserProfile(
      name: name ?? this.name,
      gender: gender ?? this.gender,
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
      'gender': gender.key,
      'age': age,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'goal': goal.key,
      'conditions': conditions.map((item) => item.key).toList(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final gender = UserGenderX.fromKey(json['gender'] as String? ?? UserGender.male.key);
    final conditions = ((json['conditions'] as List<dynamic>?) ?? [])
        .map((item) => HealthConditionX.fromKey(item as String))
        .where((item) => item.isVisibleFor(gender))
        .toList();

    return UserProfile(
      name: json['name'] as String? ?? '',
      gender: gender,
      age: (json['age'] as num?)?.toInt() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
      goal: UserGoalX.fromKey(json['goal'] as String? ?? UserGoal.maintenance.key),
      conditions: conditions,
    );
  }
}
