class DoctorNoteRecord {
  const DoctorNoteRecord({
    required this.id,
    required this.content,
    required this.category,
    required this.generatedAt,
    required this.expiresAt,
    required this.contextSnapshot,
  });

  final String id;
  final String content;
  final String category;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final Map<String, dynamic> contextSnapshot;

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  factory DoctorNoteRecord.fromJson(String id, Map<String, dynamic> json) {
    return DoctorNoteRecord(
      id: id,
      content: json['content'] as String? ?? '',
      category: json['category'] as String? ?? '',
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ?? DateTime.now(),
      contextSnapshot: Map<String, dynamic>.from(json['contextSnapshot'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'category': category,
      'generatedAt': generatedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'contextSnapshot': contextSnapshot,
    };
  }
}

const doctorNoteCategoryLabels = <String, String>{
  'morning_routine': '🌅 সকালের রুটিন',
  'food_suggestion': '🍽️ খাবার পরামর্শ',
  'water_reminder': '💧 পানি পান',
  'exercise_tip': '🏃 ব্যায়াম টিপস',
  'sleep_advice': '🌙 ঘুমের পরামর্শ',
  'meditation_stress': '🧘 মেডিটেশন',
  'mental_health': '🧠 মানসিক স্বাস্থ্য',
  'lifestyle_habit': '✨ জীবনযাপন',
  'condition_specific': '🩺 বিশেষ পরামর্শ',
  'nutrition_fact': '📊 পুষ্টি তথ্য',
  'motivation': '💪 অনুপ্রেরণা',
  'digestion': '🌿 হজম স্বাস্থ্য',
  'sexual_health': '❤️ যৌন স্বাস্থ্য',
  'hormonal_health': '⚗️ হরমোনাল স্বাস্থ্য',
  'posture_ergonomics': '🪑 ভঙ্গি পরামর্শ',
  'breathing_exercise': '🌬️ শ্বাস-প্রশ্বাস',
  'sunlight_vitamin_d': '☀️ সূর্যালোক',
  'intermittent_fasting': '⏰ ইন্টারমিটেন্ট ফাস্টিং',
  'gut_health': '🦠 অন্ত্রের স্বাস্থ্য',
  'immune_system': '🛡️ রোগ প্রতিরোধ',
};
