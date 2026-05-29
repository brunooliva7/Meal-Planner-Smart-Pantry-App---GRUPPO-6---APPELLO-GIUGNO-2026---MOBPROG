// recipe_model.dart
class RecipeModel {
  final int id;
  final String title;
  final String image;

  const RecipeModel({required this.id, required this.title, required this.image});

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Nessun Titolo',
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'image': image};
  }
}