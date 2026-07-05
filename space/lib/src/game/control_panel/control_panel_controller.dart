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

  ControlPanelPhase get phase => _phase;
  int get score => _score;
  int get maxRounds => _maxRounds;
  int get playerProgress => _playerIndex;
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
    _phase = ControlPanelPhase.showingSequence;
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

  int _nextPad() => _random.nextInt(4);
}
