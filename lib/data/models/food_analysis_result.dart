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
    this.conditionAdvice,
    this.timingAdvice,
    this.portionAdvice,
    this.alternative,
    this.fiber,
    this.vitamins = const [],
    this.minerals = const [],
    this.plateBreakdown = const [],
    this.redFlags = const [],
    this.doctorTip,
    this.analysisMode = 'meal',
    this.menuSuggestions = const [],
    this.receiptInsights = const [],
    this.grocerySuggestions = const [],
    this.memoryInsight,
    this.bestChoice,
    this.budgetImpact,
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
  final String? conditionAdvice;
  final String? timingAdvice;
  final String? portionAdvice;
  final String? alternative;
  final double? fiber;
  final List<String> vitamins;
  final List<String> minerals;
  final List<String> plateBreakdown;
  final List<String> redFlags;
  final String? doctorTip;
  final String analysisMode;
  final List<String> menuSuggestions;
  final List<String> receiptInsights;
  final List<String> grocerySuggestions;
  final String? memoryInsight;
  final String? bestChoice;
  final String? budgetImpact;
  final String? modelId;
  final String? modelName;
  final String? modelVersion;

  static List<String> _parseList(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    // Handle single string or other types gracefully
    final str = value.toString().trim();
    if (str.isEmpty || str == '[]' || str == 'null') return const [];
    return [str];
  }

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    final model = json['model'] as Map<String, dynamic>?;
    return FoodAnalysisResult(
      foodName: json['foodName'] as String? ?? json['name'] as String? ?? 'অজানা খাবার',
      macros: NutritionMacro.fromJson(json['macros'] as Map<String, dynamic>? ?? json),
      pros: _parseList(json['pros'] ?? json['benefits']),
      warnings: _parseList(json['warnings'] ?? json['harms']),
      summary: json['summary'] as String? ?? json['score_reason'] as String? ?? '',
      healthScore: (json['healthScore'] as num?)?.toInt() ?? (json['score'] as num?)?.toInt() ?? 50,
      conditionAdvice: json['conditionAdvice'] as String? ?? json['condition_advice'] as String?,
      timingAdvice: json['timingAdvice'] as String? ?? json['timing_advice'] as String?,
      portionAdvice: json['portionAdvice'] as String? ?? json['portion_advice'] as String?,
      alternative: json['alternative'] as String?,
      fiber: (json['fiber'] as num?)?.toDouble(),
      vitamins: _parseList(json['vitamins']),
      minerals: _parseList(json['minerals']),
      plateBreakdown: _parseList(json['plateBreakdown'] ?? json['plate_breakdown']),
      redFlags: _parseList(json['redFlags'] ?? json['red_flags']),
      doctorTip: json['doctorTip'] as String? ?? json['doctor_tip'] as String?,
      analysisMode: json['analysisMode'] as String? ?? json['analysis_mode'] as String? ?? 'meal',
      menuSuggestions: _parseList(json['menuSuggestions'] ?? json['menu_suggestions']),
      receiptInsights: _parseList(json['receiptInsights'] ?? json['receipt_insights']),
      grocerySuggestions: _parseList(json['grocerySuggestions'] ?? json['grocery_suggestions']),
      memoryInsight: json['memoryInsight'] as String? ?? json['memory_insight'] as String?,
      bestChoice: json['bestChoice'] as String? ?? json['best_choice'] as String?,
      budgetImpact: json['budgetImpact'] as String? ?? json['budget_impact'] as String?,
      modelId: model?['id'] as String?,
      modelName: model?['name'] as String?,
      modelVersion: model?['version'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodName': foodName,
      'macros': macros.toJson(),
      'pros': pros,
      'warnings': warnings,
      'summary': summary,
      'healthScore': healthScore,
      'conditionAdvice': conditionAdvice,
      'timingAdvice': timingAdvice,
      'portionAdvice': portionAdvice,
      'alternative': alternative,
      'fiber': fiber,
      'vitamins': vitamins,
      'minerals': minerals,
      'plateBreakdown': plateBreakdown,
      'redFlags': redFlags,
      'doctorTip': doctorTip,
      'analysisMode': analysisMode,
      'menuSuggestions': menuSuggestions,
      'receiptInsights': receiptInsights,
      'grocerySuggestions': grocerySuggestions,
      'memoryInsight': memoryInsight,
      'bestChoice': bestChoice,
      'budgetImpact': budgetImpact,
      if (modelId != null || modelName != null || modelVersion != null)
        'model': {
          'id': modelId,
          'name': modelName,
          'version': modelVersion,
        },
    };
  }
}
