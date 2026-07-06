import 'dart:math';

enum ControlPanelPhase { showingSequence, playerInput, gameOver, gameWon }

enum ControlPanelInputResult { correct, roundComplete, gameWon, incorrect }

class ControlPanelController {
  ControlPanelController({Random? random, int maxRounds = 6})
    : _random = random ?? Random(),
      _maxRounds = maxRounds;

  final Random _random;
  final int _maxRounds;
  final List<int> _sequence = <int>[];

  ControlPanelPhase _phase = ControlPanelPhase.showingSequence;
  int _playerIndex = 0;
  int _score = 0;
  int _restartCount = 0;
  int _missPosition = 0;

  ControlPanelPhase get phase => _phase;
  int get score => _score;
  int get maxRounds => _maxRounds;
  int get playerProgress => _playerIndex;
  int get restartCount => _restartCount;
  int get missPosition => _missPosition;
  List<int> get sequence => List<int>.unmodifiable(_sequence);

  void Function()? onCorrect;
  void Function()? onRoundComplete;
  void Function()? onIncorrect;
  void Function()? onVictory;

  void startNewGame() {
    _sequence
      ..clear()
      ..add(_nextPad());
    _playerIndex = 0;
    _score = 0;
    _restartCount = 0;
    _missPosition = 0;
    _phase = ControlPanelPhase.showingSequence;
  }

  void onRestart() {
    _restartCount += 1;
  }

  void beginPlayerTurn() {
    _playerIndex = 0;
    _phase = ControlPanelPhase.playerInput;
  }

  void startNextRound() {
    if (_phase == ControlPanelPhase.gameWon) {
      return;
    }

    _sequence.add(_nextPad());
    _playerIndex = 0;
    _phase = ControlPanelPhase.showingSequence;
  }

  ControlPanelInputResult submitInput(int padIndex) {
    if (_phase != ControlPanelPhase.playerInput) {
      return ControlPanelInputResult.incorrect;
    }

    final int expected = _sequence[_playerIndex];
    if (padIndex != expected) {
      _phase = ControlPanelPhase.gameOver;
      _missPosition = _playerIndex + 1;
      return ControlPanelInputResult.incorrect;
    }

    _playerIndex += 1;
    if (_playerIndex == _sequence.length) {
      _score += 1;

      if (_score >= _maxRounds) {
        _phase = ControlPanelPhase.gameWon;
        return ControlPanelInputResult.gameWon;
      }

      return ControlPanelInputResult.roundComplete;
    }

    return ControlPanelInputResult.correct;
  }

  int calculateScore() {
    if (_restartCount == 0 && _phase == ControlPanelPhase.gameWon) {
      return 100 * _maxRounds;
    }

    int points = 100 * _score;

    if (_phase == ControlPanelPhase.gameOver && _sequence.isNotEmpty) {
      points += ((_missPosition / _sequence.length) * 100).floor();
    }

    points -= _restartCount * 30;
    return points.clamp(0, 10000);
  }

  int _nextPad() => _random.nextInt(4);
}
