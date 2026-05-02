class NutritionMacro {
  const NutritionMacro({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  factory NutritionMacro.fromJson(Map<String, dynamic> json) {
    return NutritionMacro(
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

class FoodAnalysisResult {
  const FoodAnalysisResult({
    required this.foodName,
    required this.macros,
    required this.pros,
    required this.warnings,
    required this.summary,
    required this.healthScore,
    this.modelId,
    this.modelName,
    this.modelVersion,
  });

  final String foodName;
  final NutritionMacro macros;
  final List<String> pros;
  final List<String> warnings;
  final String summary;
  final int healthScore;
  final String? modelId;
  final String? modelName;
  final String? modelVersion;

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    final model = json['model'] as Map<String, dynamic>?;

    return FoodAnalysisResult(
      foodName: json['foodName'] as String? ?? 'অজানা খাবার',
      macros: NutritionMacro.fromJson(json['macros'] as Map<String, dynamic>? ?? {}),
      pros: ((json['pros'] as List<dynamic>?) ?? []).map((e) => e.toString()).toList(),
      warnings: ((json['warnings'] as List<dynamic>?) ?? []).map((e) => e.toString()).toList(),
      summary: json['summary'] as String? ?? '',
      healthScore: (json['healthScore'] as num?)?.toInt() ?? 50,
      modelId: model?['id'] as String?,
      modelName: model?['name'] as String?,
      modelVersion: model?['version'] as String?,
    );
  }
}
