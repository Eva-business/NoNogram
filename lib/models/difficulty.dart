enum Difficulty { easy, medium, hard }

extension DifficultyExtension on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.easy:
        return '簡單';
      case Difficulty.medium:
        return '普通';
      case Difficulty.hard:
        return '困難';
    }
  }

  int get size {
    switch (this) {
      case Difficulty.easy:
        return 5;
      case Difficulty.medium:
        return 10;
      case Difficulty.hard:
        return 15;
    }
  }

  String get key {
    switch (this) {
      case Difficulty.easy:
        return 'easy';
      case Difficulty.medium:
        return 'medium';
      case Difficulty.hard:
        return 'hard';
    }
  }
}
