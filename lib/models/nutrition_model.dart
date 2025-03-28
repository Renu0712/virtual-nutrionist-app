class NutritionModel {
  final String nutritionId;
  final String title;
  final String nutritionEntry;
  final String createdAt;

  NutritionModel({
    required this.nutritionId,
    required this.title,
    required this.nutritionEntry,
    required this.createdAt,
  });

  factory NutritionModel.fromJson(Map<String, dynamic> json) {
    return NutritionModel(
      nutritionId: json['_id'],
      title: json['title'],
      nutritionEntry: json['nutrition_entry'],
      createdAt: json['datetime'],
    );
  }
}