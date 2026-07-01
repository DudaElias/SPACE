import 'dart:math';

enum SortCriterion { shape, color, state }

enum Shape { gear, battery }

enum PieceColor { blue, orange }

enum PieceState { broken, notBroken }

enum BinSide { left, right }

enum BrokenShipPhase {
  intro,
  phase1,
  phase1Pause,
  phase1Transition,
  phase2,
  phase2Pause,
  phase2Transition,
  phase3,
  victory,
}

enum SortingResult { correct, incorrect, missed }

class SortingPiece {
  const SortingPiece({
    required this.shape,
    required this.color,
    required this.state,
  });

  final Shape shape;
  final PieceColor color;
  final PieceState state;

  String get imagePath {
    final shapeStr = shape.name;
    final colorStr = color.name;
    final brokenSuffix = state == PieceState.broken ? '-broken' : '';
    return 'assets/images/broken_ship_pieces/$shapeStr-$colorStr$brokenSuffix.png';
  }
}

class BrokenShipController {
  BrokenShipController({Random? random}) : _random = random ?? Random();

  final Random _random;

  BrokenShipPhase _phase = BrokenShipPhase.intro;
  SortCriterion _currentCriterion = SortCriterion.shape;
  double _repairProgress = 0.0;
  int _comboCount = 0;
  int _objectsDealtWithInPhase = 0;
  int _objectsDealtWithInRule = 0;
  SortingPiece? _currentPiece;

  static const int objectsPerPhase12 = 5;
  static const int objectsPerRule = 4;
  static const double baseProgress = 0.03;
  static const int maxComboLevel = 4;
  static const double transitionPauseSecs = 0.5;
  static const double transitionFlashSecs = 1.5;

  BrokenShipPhase get phase => _phase;
  SortCriterion get currentCriterion => _currentCriterion;
  double get repairPercent => _repairProgress;
  int get comboCount => _comboCount;

  int get comboMultiplier {
    final level = 1 + (_comboCount ~/ 5);
    return level > maxComboLevel ? maxComboLevel : level;
  }

  int get phaseObjectsCompleted => _objectsDealtWithInPhase;

  int get phaseTotalObjects {
    switch (_phase) {
      case BrokenShipPhase.phase1:
      case BrokenShipPhase.phase1Pause:
      case BrokenShipPhase.phase1Transition:
        return objectsPerPhase12;
      case BrokenShipPhase.phase2:
      case BrokenShipPhase.phase2Pause:
      case BrokenShipPhase.phase2Transition:
        return objectsPerPhase12;
      default:
        return 0;
    }
  }

  int get ruleObjectsElapsed => _objectsDealtWithInRule;

  bool get isTransitionPhase {
    return _phase == BrokenShipPhase.phase1Transition ||
        _phase == BrokenShipPhase.phase2Transition;
  }

  bool get isPausePhase {
    return _phase == BrokenShipPhase.phase1Pause ||
        _phase == BrokenShipPhase.phase2Pause;
  }

  String get ruleDescription {
    switch (_currentCriterion) {
      case SortCriterion.shape:
        return 'Classifique por Tipo de Pe\u00e7a';
      case SortCriterion.color:
        return 'Classifique por Cor';
      case SortCriterion.state:
        return 'Classifique por Estado';
    }
  }

  String get leftBinLabel {
    switch (_currentCriterion) {
      case SortCriterion.shape:
        return 'Engrenagem';
      case SortCriterion.color:
        return 'Azul';
      case SortCriterion.state:
        return 'Inteiro';
    }
  }

  String get rightBinLabel {
    switch (_currentCriterion) {
      case SortCriterion.shape:
        return 'Bateria';
      case SortCriterion.color:
        return 'Laranja';
      case SortCriterion.state:
        return 'Quebrado';
    }
  }

  String get leftBinIconPath {
    switch (_currentCriterion) {
      case SortCriterion.shape:
        return 'assets/images/broken_ship_pieces/gear.png';
      case SortCriterion.color:
        return 'assets/images/broken_ship_pieces/battery-blue.png';
      case SortCriterion.state:
        return 'assets/images/broken_ship_pieces/whole.png';
    }
  }

  String get rightBinIconPath {
    switch (_currentCriterion) {
      case SortCriterion.shape:
        return 'assets/images/broken_ship_pieces/battery.png';
      case SortCriterion.color:
        return 'assets/images/broken_ship_pieces/battery-orange.png';
      case SortCriterion.state:
        return 'assets/images/broken_ship_pieces/broken.png';
    }
  }

  void Function()? onCorrect;
  void Function()? onIncorrect;
  void Function()? onJam;
  void Function()? onUnjam;
  void Function()? onComboUp;
  void Function()? onRuleChange;
  void Function()? onVictory;
  void Function()? onMiss;

  void startGame() {
    _phase = BrokenShipPhase.phase1;
    _currentCriterion = SortCriterion.shape;
    _repairProgress = 0.0;
    _comboCount = 0;
    _objectsDealtWithInPhase = 0;
    _objectsDealtWithInRule = 0;
    _currentPiece = null;
  }

  SortingPiece generateNextPiece() {
    final shape = Shape.values[_random.nextInt(2)];
    final color = PieceColor.values[_random.nextInt(2)];
    final state = PieceState.values[_random.nextInt(2)];

    _currentPiece = SortingPiece(shape: shape, color: color, state: state);
    return _currentPiece!;
  }

  SortingResult evaluateSort(BinSide chosen) {
    if (_currentPiece == null) return SortingResult.missed;

    final correctSide = _evaluatePiece(_currentPiece!);
    return chosen == correctSide ? SortingResult.correct : SortingResult.incorrect;
  }

  void handleCorrect() {
    final prevLevel = comboMultiplier;
    _comboCount++;
    _repairProgress = _repairProgress + baseProgress * comboMultiplier;
    if (_repairProgress > 1.0) _repairProgress = 1.0;
    _objectsDealtWithInPhase++;
    _objectsDealtWithInRule++;

    if (comboMultiplier > prevLevel) {
      onComboUp?.call();
    }
  }

  void handleIncorrect() {
    _comboCount = 0;
  }

  void handleMissed() {
    _comboCount = 0;
  }

  void enterPause() {
    if (_phase == BrokenShipPhase.phase1) {
      _phase = BrokenShipPhase.phase1Pause;
    } else if (_phase == BrokenShipPhase.phase2) {
      _phase = BrokenShipPhase.phase2Pause;
    }
  }

  void advanceFromPause() {
    if (_phase == BrokenShipPhase.phase1Pause) {
      _phase = BrokenShipPhase.phase1Transition;
    } else if (_phase == BrokenShipPhase.phase2Pause) {
      _phase = BrokenShipPhase.phase2Transition;
    }
  }

  void advanceFromTransition() {
    if (_phase == BrokenShipPhase.phase1Transition) {
      _phase = BrokenShipPhase.phase2;
      _currentCriterion = SortCriterion.color;
      _objectsDealtWithInPhase = 0;
      _objectsDealtWithInRule = 0;
      onRuleChange?.call();
    } else if (_phase == BrokenShipPhase.phase2Transition) {
      _phase = BrokenShipPhase.phase3;
      _switchRule();
      _objectsDealtWithInPhase = 0;
      _objectsDealtWithInRule = 0;
      onRuleChange?.call();
    }
  }

  void advancePhase3Rule() {
    _switchRule();
    _objectsDealtWithInRule = 0;
    onRuleChange?.call();
  }

  bool checkVictory() {
    if (_phase != BrokenShipPhase.phase3) return false;
    if (_repairProgress >= 1.0) {
      _phase = BrokenShipPhase.victory;
      onVictory?.call();
      return true;
    }
    return false;
  }

  BinSide _evaluatePiece(SortingPiece piece) {
    switch (_currentCriterion) {
      case SortCriterion.shape:
        return piece.shape == Shape.gear ? BinSide.left : BinSide.right;
      case SortCriterion.color:
        return piece.color == PieceColor.blue ? BinSide.left : BinSide.right;
      case SortCriterion.state:
        return piece.state == PieceState.notBroken ? BinSide.left : BinSide.right;
    }
  }

  void _switchRule() {
    SortCriterion next;
    do {
      next = SortCriterion.values[_random.nextInt(3)];
    } while (next == _currentCriterion);
    _currentCriterion = next;
  }
}
