import 'difficulty.dart';

class PuzzleData {
  final String id;
  final String title;
  final String imagePath;
  final Difficulty difficulty;

  const PuzzleData({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.difficulty,
  });
}
