import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'components/control_button.dart';
import 'components/control_panel_backdrop.dart';
import 'control_panel_controller.dart';
import '../shared/molecules/game_modal.dart';
import '../shared/settings.dart';
import '../shared/sound_manager.dart';
import '../shared/tutorial.dart';
import 'control_panel_route.dart';
import '../game.dart';

class ControlPanelWorld extends World {
  ControlPanelWorld({
    ControlPanelController? controller,
    this.mode = ControlPanelMode.standalone,
    this.onMiniGameFinishExit,
    this.skipTutorial = false,
  })
    : _controller = controller ?? ControlPanelController(maxRounds: _difficultyMaxRounds());

  static int _difficultyMaxRounds() {
    switch (GameSettings.instance.difficulty) {
      case GameSettings.easy:
        return 5;
      case GameSettings.medium:
        return 6;
      case GameSettings.hard:
        return 8;
      default:
        return 6;
    }
  }

  static const String _statusIntro =
    'Toque para começar';
  static const String _statusStart =
    'Cachorro astronauta, memorize para ligar o foguete!';
  static const String _statusPlayback =
    'Computador de bordo mostrando a sequência...';
  static const String _statusYourTurn =
    'Sua vez! Acione os comandos na ordem certa.';
  static const String _statusGood = 'Boa! Continue, piloto canino.';
  static const String _statusNext =
    'Ignição parcial pronta! Próxima sequência...';
  static const String _statusWin =
    'Painel ativado! Decolagem autorizada, herói canino!';
  static const String _statusWinClosed =
    'Painel ativado! Aguardando próxima missão.';
  static const String _statusFail =
    'Falha no painel! Toque em qualquer comando para reiniciar.';

  final ControlPanelController _controller;
  final ControlPanelMode mode;
  final void Function(int score)? onMiniGameFinishExit;
  final bool skipTutorial;
  int _consecutiveLosses = 0;

  TutorialOverlay? _tutorialOverlay;
  bool _tutorialActive = false;
  int _tutorialDemoStep = 0;
  double _tutorialDemoTimer = 0;
  bool _tutorialDemoLit = false;

  static const _padKeys = ['pad_a', 'pad_b', 'pad_c', 'pad_d'];

  late final TextComponent _titleText;
  late final TextComponent _levelText;
  late final TextComponent _statusText;
  late final CircleComponent _emoji;
  late final ControlPanelBackdrop _backdrop;

  final List<ControlButton> _buttons = <ControlButton>[];
  final List<CircleComponent> _progressDots = <CircleComponent>[];

  int? _playbackButtonIndex;
  int _playbackStep = 0;
  double _playbackTimer = 0;
  bool _playbackIsLit = false;

  double _nextRoundDelay = 0;
  bool _awaitingNextRound = false;
  bool _awaitingStart = true;
  double _introDelay = 0;
  bool _awaitingIntroDelay = false;
  bool _victoryDialogOpen = false;
  GameModal? _activeDialog;
  final List<double> _inputFlashRemaining = List<double>.filled(4, 0);
  final List<double> _buttonScale = List<double>.filled(4, 1.0);

  double get _lightDurationSeconds {
    switch (GameSettings.instance.difficulty) {
      case GameSettings.easy:
        return 0.6;
      case GameSettings.medium:
        return 0.5;
      case GameSettings.hard:
        return 0.4;
      default:
        return 0.5;
    }
  }

  double get _gapDurationSeconds {
    switch (GameSettings.instance.difficulty) {
      case GameSettings.easy:
        return 0.4;
      case GameSettings.medium:
        return 0.3;
      case GameSettings.hard:
        return 0.2;
      default:
        return 0.3;
    }
  }

  double get _difficultyNextRoundDelay {
    switch (GameSettings.instance.difficulty) {
      case GameSettings.easy:
        return 1.2;
      case GameSettings.medium:
        return 0.9;
      case GameSettings.hard:
        return 0.7;
      default:
        return 0.9;
    }
  }

  static const double _inputFlashSeconds = 0.2;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _backdrop = ControlPanelBackdrop();
    await add(_backdrop);

    _titleText = TextComponent(
      text: 'Ativar Painel de Controle',
      priority: 12,
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: const Color(0xFFFFFFFF),
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    _levelText = TextComponent(
      text: 'Memorize e repita a sequência! Nível 1/${_controller.maxRounds}',
      priority: 12,
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: const Color(0xFFCCCCCC),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    _statusText = TextComponent(
      priority: 12,
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: const Color(0xFFFFFFFF),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
    );

    _emoji = CircleComponent(
      radius: 30,
      paint: Paint()..color = const Color(0x00000000),
      priority: 12,
    );

    addAll(<Component>[_titleText, _levelText, _statusText, _emoji]);

    // Create buttons: top 2 are circular, bottom 2 are levers
    _buttons.add(
      ControlButton(
        index: 0,
        isLever: false,
        gradientColors: [
          const Color(0xFFFF8C00), // orange-500
          const Color(0xFF00BFFF), // cyan-500
        ],
        leverColor: const Color(0xFF000000),
        onPressed: _handleButtonPressed,
      ),
    );

    _buttons.add(
      ControlButton(
        index: 1,
        isLever: false,
        gradientColors: [
          const Color(0xFFFF1493), // pink-500
          const Color(0xFF9932CC), // purple-500
        ],
        leverColor: const Color(0xFF000000),
        onPressed: _handleButtonPressed,
      ),
    );

    _buttons.add(
      ControlButton(
        index: 2,
        isLever: true,
        gradientColors: const <Color>[],
        leverColor: const Color(0xFF22C55E), // green-500
        onPressed: _handleButtonPressed,
      ),
    );

    _buttons.add(
      ControlButton(
        index: 3,
        isLever: true,
        gradientColors: const <Color>[],
        leverColor: const Color(0xFFEAB308), // yellow-500
        onPressed: _handleButtonPressed,
      ),
    );

    for (final button in _buttons) {
      add(button);
    }

    _layoutForSize(findGame()!.size);
    _setStatus(_statusIntro);
    _updateLevelText();

    if (skipTutorial) {
      _showIntroDialog();
    } else {
      _startTutorial();
    }

    _controller.onIncorrect = () {
      SoundManager.instance.playSfx('incorrect');
      _consecutiveLosses++;
    };
    _controller.onVictory = () {
      SoundManager.instance.playSfx('success');
      _consecutiveLosses = 0;
    };
  }

  void _startFromIntroDialog() {
    _awaitingStart = false;
    _victoryDialogOpen = false;
    _activeDialog?.removeFromParent();
    _activeDialog = null;
    _lastLayoutSize = null;
    _awaitingIntroDelay = true;
    _introDelay = 0.75;
  }

  void _closeVictoryDialog() {
    if (onMiniGameFinishExit != null) {
      onMiniGameFinishExit!(_controller.calculateScore());
      return;
    }

    _victoryDialogOpen = false;
    _activeDialog?.removeFromParent();
    _activeDialog = null;
    _lastLayoutSize = null;
    _setStatus(_statusWinClosed);
  }

  Vector2? _lastLayoutSize;

  @override
  void update(double dt) {
    super.update(dt);
    if (_activeDialog != null) {
      final size = findGame()!.size;
      if (_lastLayoutSize != size) {
        _lastLayoutSize = size;
        _activeDialog!.layoutForSize(size);
      }
    }
    if (_tutorialOverlay != null) {
      _updateTutorial(dt);
    }
    if (_tutorialActive) return;
    _updatePlayback(dt);
    _updateRoundTimer(dt);
    _updateIntroDelay(dt);
    _updateInputFlash(dt);
    _updateButtonScale(dt);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    if (!isLoaded) {
      return;
    }

    _layoutForSize(size);
    _activeDialog?.layoutForSize(size);
  }

  void _layoutForSize(Vector2 size) {
    _backdrop.layoutForSize(size);

    // Title at top
    _titleText.position = Vector2(size.x * 0.5, 40);
    _titleText.anchor = Anchor.topCenter;

    // Level text below title
    _levelText.position = Vector2(size.x * 0.5, 80);
    _levelText.anchor = Anchor.topCenter;

    // Emoji
    _emoji.position = Vector2(size.x * 0.5, 130);
    _emoji.anchor = Anchor.center;

    // Button layout: top 2 buttons, then bottom 2 buttons/levers
    final double centerX = size.x * 0.5;
    final double topButtonY = size.y * 0.35;
    final double bottomButtonY = size.y * 0.65;
    const double horizontalGap = 100;

    // Top left button (red/orange-cyan)
    _buttons[0].position = Vector2(centerX - horizontalGap / 2 - 50, topButtonY);
    // Top right button (pink-purple)
    _buttons[1].position = Vector2(centerX + horizontalGap / 2 + 50, topButtonY);

    // Bottom left lever (green)
    _buttons[2].position = Vector2(centerX - horizontalGap / 2 - 30, bottomButtonY);
    // Bottom right lever (yellow)
    _buttons[3].position = Vector2(centerX + horizontalGap / 2 + 30, bottomButtonY);

    // Progress dots at the bottom edge of the control panel surface
    final double dotsY =
      _backdrop.panelSurface.position.y + (_backdrop.panelSurface.size.y / 2) - 18;
    final double dotsStartX = (size.x - (_progressDots.length * 12.0)) / 2;
    for (int i = 0; i < _progressDots.length; i++) {
      _progressDots[i].position = Vector2(dotsStartX + i * 14, dotsY);
      _progressDots[i].anchor = Anchor.center;
    }

    // Status text in bottom console
    _statusText.position = Vector2(size.x * 0.5, size.y - 42);
    _statusText.anchor = Anchor.bottomCenter;
  }

  void _startGame() {
    _controller.startNewGame();
    _setStatus(_statusStart);
    _updateLevelText();
    _startSequencePlayback();
  }

  void _startSequencePlayback() {
    _clearButtonHighlights();
    _updateProgressDots();
    _playbackButtonIndex = null;
    _playbackStep = 0;
    _playbackTimer = 0;
    _playbackIsLit = false;
    _setStatus(_statusPlayback);
  }

  void _updatePlayback(double dt) {
    if (_controller.phase != ControlPanelPhase.showingSequence) {
      return;
    }

    if (_playbackTimer > 0) {
      _playbackTimer -= dt;
      return;
    }

    if (!_playbackIsLit) {
      if (_playbackStep >= _controller.sequence.length) {
        _controller.beginPlayerTurn();
        _setStatus(_statusYourTurn);
        return;
      }

      _playbackButtonIndex = _controller.sequence[_playbackStep];
      _setButtonHighlight(_playbackButtonIndex!, true);
      _playPadSound(_playbackButtonIndex!);
      _playbackIsLit = true;
      _playbackTimer = _lightDurationSeconds;
      return;
    }

    if (_playbackButtonIndex != null) {
      _setButtonHighlight(_playbackButtonIndex!, false);
    }
    _playbackButtonIndex = null;
    _playbackStep += 1;
    _playbackIsLit = false;
    _playbackTimer = _gapDurationSeconds;
  }

  void _updateRoundTimer(double dt) {
    if (!_awaitingNextRound) {
      return;
    }

    _nextRoundDelay -= dt;
    if (_nextRoundDelay <= 0) {
      _awaitingNextRound = false;
      _controller.startNextRound();
      _updateLevelText();
      _startSequencePlayback();
    }
  }

  void _updateIntroDelay(double dt) {
    if (!_awaitingIntroDelay) {
      return;
    }

    _introDelay -= dt;
    if (_introDelay <= 0) {
      _awaitingIntroDelay = false;
      _startGame();
    }
  }

  void _updateInputFlash(double dt) {
    for (int index = 0; index < _inputFlashRemaining.length; index += 1) {
      final double remaining = _inputFlashRemaining[index];
      if (remaining <= 0) {
        continue;
      }

      final double next = remaining - dt;
      _inputFlashRemaining[index] = next;
      if (next <= 0 && _playbackButtonIndex != index) {
        _setButtonHighlight(index, false);
      }
    }
  }

  void _updateButtonScale(double dt) {
    // Simple scale animation for button presses
    for (int i = 0; i < _buttonScale.length; i++) {
      if (_buttonScale[i] < 1.0) {
        _buttonScale[i] = math.min(1.0, _buttonScale[i] + dt * 3);
        _buttons[i].setScale(_buttonScale[i]);
      }
    }
  }

  void _handleButtonPressed(int index) {
    if (_tutorialActive) {
      _handleTutorialInput(index);
      return;
    }

    if (_awaitingStart) {
      _startFromIntroDialog();
      return;
    }

    if (_victoryDialogOpen) {
      return;
    }

    if (_controller.phase == ControlPanelPhase.gameOver) {
      _controller.onRestart();
      _startGame();
      return;
    }

    if (_controller.phase == ControlPanelPhase.gameWon) {
      return;
    }

    if (_awaitingNextRound) {
      return;
    }

    if (_controller.phase != ControlPanelPhase.playerInput) {
      return;
    }

    // Button press scale animation
    _buttonScale[index] = 0.9;

    _playPadSound(index);

    _flashButton(index);

    final ControlPanelInputResult result = _controller.submitInput(index);
    _handleInputResult(result);
  }

  void _handleInputResult(ControlPanelInputResult result) {
    switch (result) {
      case ControlPanelInputResult.correct:
        _updateProgressDots();
        _setStatus(_statusGood);
      case ControlPanelInputResult.roundComplete:
        _controller.onRoundComplete?.call();
        _updateProgressDots();
        _updateLevelText();
        _setStatus(_statusNext);
        _awaitingNextRound = true;
        _nextRoundDelay = _difficultyNextRoundDelay;
      case ControlPanelInputResult.gameWon:
        _consecutiveLosses = 0;
        _controller.onVictory?.call();
        _updateProgressDots();
        _updateLevelText();
        _setStatus(_statusWin);
        _awaitingNextRound = false;
        _victoryDialogOpen = true;
        _showVictoryDialog();
      case ControlPanelInputResult.incorrect:
        _controller.onIncorrect?.call();
        _setStatus(_statusFail);
        _clearButtonHighlights();
        if (_consecutiveLosses >= 3) {
          _showLossDialog();
          return;
        }
    }
  }

  void _updateProgressDots() {
    _syncProgressDotsCount(_controller.sequence.length);

    final int filled = _controller.phase == ControlPanelPhase.gameWon
        ? _controller.sequence.length
        : _controller.playerProgress;

    for (int i = 0; i < _progressDots.length; i++) {
      final bool isCompleted = i < filled;
      _progressDots[i].paint.color = isCompleted
          ? const Color(0xFF4ADE80) // green
          : const Color(0xFF4B5563);
    }

    _layoutForSize(findGame()!.size);
  }

  void _updateLevelText() {
    final int currentLevel = _controller.phase == ControlPanelPhase.gameWon
        ? _controller.maxRounds
        : math.min(_controller.score + 1, _controller.maxRounds);
    _levelText.text =
        'Memorize e repita a sequência! Nível $currentLevel/${_controller.maxRounds}';
  }

  void _setStatus(String text) {
    _statusText.text = text;
  }

  void _flashButton(int index) {
    _setButtonHighlight(index, true);
    _inputFlashRemaining[index] = _inputFlashSeconds;
  }

  void _setButtonHighlight(int index, bool highlighted) {
    _buttons[index].setHighlighted(highlighted);
  }

  void _clearButtonHighlights() {
    for (final button in _buttons) {
      button.setHighlighted(false);
    }
  }

  void _syncProgressDotsCount(int count) {
    while (_progressDots.length > count) {
      _progressDots.removeLast().removeFromParent();
    }

    while (_progressDots.length < count) {
      final dot = CircleComponent(
        radius: 4,
        paint: Paint()..color = const Color(0xFF4B5563),
        priority: 11,
      );
      _progressDots.add(dot);
      add(dot);
    }
  }

  void _showDialog(GameModal dialog) {
    _activeDialog?.removeFromParent();
    _activeDialog = dialog;
    _lastLayoutSize = null;
    add(dialog);
    dialog.layoutForSize(findGame()!.size);
  }

  void _showIntroDialog() {
    _showDialog(GameModal(
      title: 'Painel de Controle',
      message:
          'Observe os comandos que acendem no painel e repita na mesma ordem.\n\nToque nos botões e alavancas na sequência certa para ligar o foguete e salvar seu melhor amigo humano!',
      buttonText: 'Iniciar',
      onPressed: _startFromIntroDialog,
      panelSize: Vector2(500, 380),
    ));
  }

  void _showVictoryDialog() {
    String buttonText;
    switch (mode) {
      case ControlPanelMode.storyMode:
        buttonText = 'Continuar';
      case ControlPanelMode.miniGame:
        buttonText = 'Voltar aos Minigames';
      case ControlPanelMode.standalone:
        buttonText = 'Continuar';
    }
    _showDialog(GameModal(
      title: 'Missão Cumprida!',
      message:
          'Painel de controle ativado com sucesso. O foguete está pronto para decolar.',
      buttonText: buttonText,
      onPressed: _closeVictoryDialog,
    ));
  }

  void _playPadSound(int padIndex) {
    SoundManager.instance.playSfx(_padKeys[padIndex]);
  }

  void _showLossDialog() {
    _showDialog(GameModal(
      title: 'Falha no Painel',
      message: 'Voc\u00EA errou ${_consecutiveLosses} vezes.\nQuer ver o tutorial novamente?',
      buttonText: 'Tentar Novamente',
      onPressed: () {
        _activeDialog?.removeFromParent();
        _activeDialog = null;
        _lastLayoutSize = null;
        _startGame();
      },
      secondaryButtonText: 'Ver Tutorial',
      onSecondaryPressed: () {
        _activeDialog?.removeFromParent();
        _activeDialog = null;
        _lastLayoutSize = null;
        _consecutiveLosses = 0;
        _startTutorial();
      },
      onBackdropTap: () {},
      panelSize: Vector2(480, 260),
    ));
  }

  void _startTutorial() {
    _tutorialActive = true;
    _consecutiveLosses = 0;

    final game = findGame()! as SpaceGame;
    final handImage = game.images.fromCache('tutorial_hand.png');
    final steps = TutorialConfigs.controlPanelSteps(game.size);

    _tutorialOverlay = TutorialOverlay(
      steps: steps,
      gameSize: game.size,
      handImage: handImage,
      onTutorialComplete: () {
        _tutorialOverlay?.removeFromParent();
        _tutorialOverlay = null;
        game.markTutorialComplete('minigame-1');
        _showIntroDialog();
        _tutorialActive = false;
      },
      onTutorialSkip: () {
        _tutorialOverlay?.removeFromParent();
        _tutorialOverlay = null;
        game.markTutorialComplete('minigame-1');
        _showIntroDialog();
        _tutorialActive = false;
      },
    );
    add(_tutorialOverlay!);
  }

  void _handleTutorialInput(int index) {
    final overlay = _tutorialOverlay;
    if (overlay == null || !overlay.isShowing) return;

    final step = overlay.currentStep;

    if (step.action == TutorialAction.tapAnyButton) {
      overlay.advance();
      return;
    }

    if (step.action == TutorialAction.tapSpecificButton) {
      if (step.padIndex == index) {
        _playPadSound(index);
        overlay.advance();
      }
      return;
    }
  }

  void _updateTutorial(double dt) {
    final overlay = _tutorialOverlay;
    if (overlay == null || !overlay.isShowing) return;

    if (overlay.currentStepIndex == 1) {
      _runTutorialDemo(dt);
    }
  }

  void _runTutorialDemo(double dt) {
    _tutorialDemoTimer -= dt;
    if (_tutorialDemoTimer > 0) return;

    if (!_tutorialDemoLit) {
      if (_tutorialDemoStep >= 1) {
        _clearButtonHighlights();
        return;
      }
      final padIndex = _tutorialDemoStep;
      _setButtonHighlight(padIndex, true);
      _playPadSound(padIndex);
      _tutorialDemoLit = true;
      _tutorialDemoTimer = _lightDurationSeconds;
      return;
    }

    _clearButtonHighlights();
    _tutorialDemoStep++;
    _tutorialDemoLit = false;
    _tutorialDemoTimer = _gapDurationSeconds;
  }
}
