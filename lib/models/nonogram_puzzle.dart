import 'difficulty.dart';
import 'puzzle_data.dart';

class NonogramPuzzle {
  final PuzzleData source;
  final Difficulty difficulty;
  final int size;
  final List<List<int>> solutionGrid;
  final List<List<int>> rowHints;
  final List<List<int>> colHints;

  NonogramPuzzle({
    required this.source,
    required this.difficulty,
    required this.size,
    required this.solutionGrid,
    required this.rowHints,
    required this.colHints,
  });
}
