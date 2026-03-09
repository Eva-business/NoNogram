import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

import '../models/difficulty.dart';
import '../models/puzzle_data.dart';

class PuzzleRepository {
  static List<PuzzleData> _allPuzzles = [];

  static Future<void> loadPuzzles() async {
    final jsonString = await rootBundle.loadString(
      'assets/puzzles/puzzles.json',
    );

    final List data = jsonDecode(jsonString);

    _allPuzzles = data.map((item) {
      return PuzzleData(
        id: item['id'],
        title: item['title'],
        imagePath: item['imagePath'],
        difficulty: Difficulty.values.firstWhere(
          (d) => d.name == item['difficulty'],
        ),
      );
    }).toList();
  }

  static List<PuzzleData> puzzlesByDifficulty(Difficulty difficulty) {
    return _allPuzzles.where((p) => p.difficulty == difficulty).toList();
  }

  static PuzzleData? pickRandomUnfinished({
    required Difficulty difficulty,
    required Set<String> finishedIds,
  }) {
    final candidates = puzzlesByDifficulty(
      difficulty,
    ).where((p) => !finishedIds.contains(p.id)).toList();

    if (candidates.isEmpty) return null;

    candidates.shuffle(Random());
    return candidates.first;
  }
}
