import 'difficulty.dart';

class RecordItem {
  final String id;
  final String title;
  final String imagePath;
  final Difficulty difficulty;
  final bool isCustom;

  const RecordItem({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.difficulty,
    required this.isCustom,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imagePath': imagePath,
      'difficulty': difficulty.name,
      'isCustom': isCustom,
    };
  }

  factory RecordItem.fromJson(Map<String, dynamic> json) {
    return RecordItem(
      id: json['id'],
      title: json['title'],
      imagePath: json['imagePath'],
      difficulty: Difficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
      ),
      isCustom: json['isCustom'] ?? false,
    );
  }
}
