class GameSettings {
  static const String easy = 'easy';
  static const String medium = 'medium';
  static const String hard = 'hard';

  String difficulty = easy;
  double soundVolume = 1.0;
  int currentUserId = 0;

  GameSettings._();
  static final GameSettings instance = GameSettings._();

  double get speedMultiplier {
    switch (difficulty) {
      case easy:
        return 1.0;
      case medium:
        return 1.3;
      case hard:
        return 1.7;
      default:
        return 1.0;
    }
  }

  double get spawnRateMultiplier {
    switch (difficulty) {
      case easy:
        return 1.0;
      case medium:
        return 0.8;
      case hard:
        return 0.6;
      default:
        return 1.0;
    }
  }

  String get difficultyLabel {
    switch (difficulty) {
      case easy:
        return 'Fácil';
      case medium:
        return 'Médio';
      case hard:
        return 'Difícil';
      default:
        return 'Fácil';
    }
  }
}
