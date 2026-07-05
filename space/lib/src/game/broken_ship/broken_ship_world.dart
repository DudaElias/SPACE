import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../shared/molecules/game_modal.dart';
import '../shared/settings.dart';
import '../shared/sound_manager.dart';
import 'broken_ship_controller.dart';
import 'broken_ship_route.dart';
import 'components/broken_ship_backdrop.dart';
import 'components/collection_bin.dart';
import 'components/combo_display.dart';
import 'components/repair_meter.dart';
import 'components/rule_indicator.dart';
import 'components/sorting_object.dart';

class BrokenShipWorld extends World with DragCallbacks {
  BrokenShipWorld({
    this.mode = BrokenShipMode.standalone,
    this.onMiniGameFinishExit,
  });

  final BrokenShipMode mode;
  final VoidCallback? onMiniGameFinishExit;

  late final BrokenShipController _controller;
  late final BrokenShipBackdrop _backdrop;
  late final RuleIndicator _ruleIndicator;
  late final RepairMeter _repairMeter;
  late final ComboDisplay _comboDisplay;
  late final CollectionBin _leftBin;
  late final CollectionBin _rightBin;

  SortingObject? _currentObject;
  bool _objectAnimating = false;

  bool _isDraggingObject = false;
  Vector2 _dragInitialPiecePos = Vector2.zero();
  Vector2 _dragStartPoint = Vector2.zero();

  double _phaseTimer = 0;
  double _flashRemaining = 0;
  bool _midRevealDone = false;
  bool _gameStarted = false;

  bool _phase3RulePending = false;
  double _phase3TransitionTimer = 0;
  bool _phase3RuleRevealed = false;

  GameModal? _activeModal;

  double get _fallSpeed {
    switch (GameSettings.instance.difficulty) {
      case GameSettings.easy:
        return 65.0;
      case GameSettings.medium:
        return 85.0;
      case GameSettings.hard:
        return 110.0;
      default:
        return 85.0;
    }
  }

  static const String _introTitle = 'Conserte a Nave';
  static const String _introMessage =
      'Classifique as pe\u00e7as para consertar a nave!\n'
      'Arraste para esquerda ou direita conforme a regra.\n'
      'Aten\u00e7\u00e3o: as regras v\u00e3o mudar!';
  static const String _introButton = 'Iniciar';

  static const String _victoryTitle = 'Nave Consertada!';
  static const String _victoryMessage =
      'Voc\u00ea consertou a nave! O astronauta est\u00e1 salvo.\n'
      'Seu melhor amigo humano agradece!';
  static const String _victoryButton = 'Continuar';

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _controller = BrokenShipController();

    _controller.onCorrect = () => SoundManager.instance.playSfx('correct');
    _controller.onIncorrect = () => SoundManager.instance.playSfx('incorrect');
    _controller.onMiss = () => SoundManager.instance.playSfx('whoosh');
    _controller.onVictory = () => SoundManager.instance.playSfx('success');

    _backdrop = BrokenShipBackdrop();
    await add(_backdrop);

    _ruleIndicator = RuleIndicator()
      ..position = Vector2.zero()
      ..size = Vector2.zero();
    await add(_ruleIndicator);

    _repairMeter = RepairMeter()
      ..position = Vector2.zero();
    await add(_repairMeter);

    _comboDisplay = ComboDisplay()
      ..position = Vector2.zero();
    await add(_comboDisplay);

    _leftBin = CollectionBin(
      side: BinSide.left,
      colorSwatch: const Color(0xFF3B82F6),
    )..position = Vector2.zero();
    await add(_leftBin);

    _rightBin = CollectionBin(
      side: BinSide.right,
      colorSwatch: const Color(0xFFF97316),
    )..position = Vector2.zero();
    await add(_rightBin);

    _layoutForSize(findGame()!.size);

    _showIntroModal();
  }

  void _layoutForSize(Vector2 size) {
    _backdrop.layoutForSize(size);

    final tubeLeftX = size.x * 0.28;
    final tubeRightX = size.x * 0.72;
    final tubeWidth = tubeRightX - tubeLeftX;

    _ruleIndicator
      ..position = Vector2(size.x * 0.5, size.y * 0.09)
      ..size = Vector2(tubeWidth, size.y * 0.17);

    _repairMeter
      ..position = Vector2(size.x * 0.5, size.y * 0.21)
      ..size = Vector2(tubeWidth * 0.82, size.y * 0.047);

    _comboDisplay.position = Vector2(size.x * 0.5 + tubeWidth * 0.48, size.y * 0.21);

    final binHeight = size.y * 0.15;
    final binY = size.y - binHeight * 0.5;
    final maxBinWidth = tubeLeftX;
    _leftBin.position = Vector2(tubeLeftX - maxBinWidth * 0.5, binY);
    _leftBin.size = Vector2(maxBinWidth, size.y * 0.15);

    _rightBin.position = Vector2(tubeRightX + maxBinWidth * 0.5, binY);
    _rightBin.size = Vector2(maxBinWidth, size.y * 0.15);

    _ruleIndicator.layoutInternals();
    _repairMeter.layoutInternals();
    _leftBin.layoutInternals();
    _rightBin.layoutInternals();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isLoaded) return;
    _layoutForSize(size);
    _activeModal?.layoutForSize(size);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_flashRemaining > 0) {
      _flashRemaining -= dt;
      if (!_midRevealDone &&
          _flashRemaining <= _controller.transitionFlashSecs * 0.6) {
        _midRevealDone = true;
        _controller.advanceFromTransition();
        _refreshRuleUI();
        _leftBin.labelOpacity = 1.0;
        _rightBin.labelOpacity = 1.0;
      }
      if (_flashRemaining <= 0) {
        _ruleIndicator.setFlashing(false);
      }
    }

    if (_activeModal != null) {
      _activeModal!.layoutForSize(findGame()!.size);
    }

    if (!_gameStarted) return;

    final phase = _controller.phase;

    switch (phase) {
      case BrokenShipPhase.intro:
      case BrokenShipPhase.victory:
        break;

      case BrokenShipPhase.phase1:
      case BrokenShipPhase.phase2:
      case BrokenShipPhase.phase3:
        _updateGameplay(dt);
        break;

      case BrokenShipPhase.phase1Pause:
      case BrokenShipPhase.phase2Pause:
        _updatePause(dt);
        break;

      case BrokenShipPhase.phase1Transition:
      case BrokenShipPhase.phase2Transition:
        break;
    }
  }

  void _updateGameplay(double dt) {

    if (_phase3RulePending) {
      _phase3TransitionTimer -= dt;
      if (!_phase3RuleRevealed && _phase3TransitionTimer <= 0.6) {
        _phase3RuleRevealed = true;
        _controller.advancePhase3Rule();
        _refreshRuleUI();
      }
      if (_phase3TransitionTimer <= 0) {
        _phase3RulePending = false;
        _phase3RuleRevealed = false;
        _ruleIndicator.setFlashing(false);
      }
    }

    if (_currentObject == null && !_objectAnimating && !_phase3RulePending) {
      _spawnNextObject();
    }
  }

  void _updatePause(double dt) {
    _phaseTimer -= dt;
    if (_phaseTimer <= 0) {
      _controller.advanceFromPause();
      _ruleIndicator.setFlashing(true);
      _flashRemaining = _controller.transitionFlashSecs;
      _midRevealDone = false;
    }
  }

  void _startGame() {
    _controller.startGame();
    _gameStarted = true;
    _phase3RulePending = false;
    _phase3TransitionTimer = 0;
    _phase3RuleRevealed = false;
    _flashRemaining = 0;
    _midRevealDone = false;
    _refreshRuleUI();
    _repairMeter.setProgress(0);
    _comboDisplay.reset();
  }

  void _refreshRuleUI() {
    _ruleIndicator.updateRule(
      ruleText: _controller.ruleDescription,
      iconLeftPath: _controller.leftBinIconPath,
      iconRightPath: _controller.rightBinIconPath,
      criterion: _controller.currentCriterion,
      labelLeft: _controller.leftBinLabel,
      labelRight: _controller.rightBinLabel,
      colorLeft: const Color(0xFF3B82F6),
      colorRight: const Color(0xFFF97316),
    );

    _leftBin.updateForRule(
      criterion: _controller.currentCriterion,
      iconPath: _controller.leftBinIconPath,
      label: _controller.leftBinLabel,
    );
    _leftBin.labelOpacity = 1.0;

    _rightBin.updateForRule(
      criterion: _controller.currentCriterion,
      iconPath: _controller.rightBinIconPath,
      label: _controller.rightBinLabel,
    );
    _rightBin.labelOpacity = 1.0;
  }

  void _spawnNextObject() {
    final piece = _controller.generateNextPiece();

    final size = findGame()!.size;
    final spawnX = size.x * 0.5;
    final spawnY = size.y * 0.22;

    _currentObject = SortingObject(piece: piece, fallSpeed: _fallSpeed)
      ..position = Vector2(spawnX, spawnY)
      ..onSorted = _handleSorted
      ..onMissed = _handleMissed;

    add(_currentObject!);
  }

  void _handleSorted(BinSide side) {
    if (_objectAnimating || _currentObject == null) return;
    _objectAnimating = true;

    final result = _controller.evaluateSort(side);

    switch (result) {
      case SortingResult.correct:
        _controller.handleCorrect();
        _controller.onCorrect?.call();
        _repairMeter.setProgress(_controller.repairPercent);
        _comboDisplay.setCombo(_controller.comboCount);

        (side == BinSide.left ? _leftBin : _rightBin).flashCorrect();

        final target = side == BinSide.left ? _leftBin.position : _rightBin.position;
        _currentObject!.animateToBin(target, () {
          _currentObject?.removeFromParent();
          _currentObject = null;
          _objectAnimating = false;
          _afterObjectDealtWith();
        });
        break;

      case SortingResult.incorrect:
        _controller.handleIncorrect();
        _controller.onIncorrect?.call();
        _comboDisplay.setCombo(_controller.comboCount);

        if (side == BinSide.left) {
          _leftBin.flashIncorrect();
        } else {
          _rightBin.flashIncorrect();
        }

        final binTopY = side == BinSide.left
            ? _leftBin.position.y - _leftBin.size.y * 0.5
            : _rightBin.position.y - _rightBin.size.y * 0.5;
        final driftDir = side == BinSide.left ? -1.0 : 1.0;
        _currentObject!.bounceOffBin(binTopY, driftDir, () {
          _currentObject?.removeFromParent();
          _currentObject = null;
          _objectAnimating = false;
          _afterObjectDealtWith();
        });
        break;

      case SortingResult.missed:
        _objectAnimating = false;
        break;
    }
  }

  void _handleMissed() {
    _controller.handleMissed();
    _controller.onMiss?.call();
    _comboDisplay.setCombo(_controller.comboCount);

    _currentObject?.animateFallAway(() {
      _currentObject?.removeFromParent();
      _currentObject = null;
      _objectAnimating = false;
      _afterObjectDealtWith();
    });
  }

  void _afterObjectDealtWith() {
    final phase = _controller.phase;

    if (phase == BrokenShipPhase.phase1 || phase == BrokenShipPhase.phase2) {
      if (_controller.phaseObjectsCompleted >= _controller.phaseTotalObjects) {
        _phaseTimer = BrokenShipController.transitionPauseSecs;
        _controller.enterPause();
      }
    } else if (phase == BrokenShipPhase.phase3) {
      if (_controller.ruleObjectsElapsed >= BrokenShipController.objectsPerRule) {
        _phase3RulePending = true;
        _phase3TransitionTimer = 1.0;
        _ruleIndicator.setFlashing(true);
      }

      if (_controller.checkVictory()) {
        _showVictoryModal();
        return;
      }
    }
  }

  void _showIntroModal() {
    _activeModal?.removeFromParent();
    _activeModal = GameModal(
      title: _introTitle,
      message: _introMessage,
      buttonText: _introButton,
      onPressed: () {
        _activeModal?.removeFromParent();
        _activeModal = null;
        _startGame();
      },
      style: GameModalStyle.shared,
      panelSize: Vector2(500, 300),
    );
    add(_activeModal!);
    _activeModal!.layoutForSize(findGame()!.size);
  }

  void _showVictoryModal() {
    if (_activeModal != null) return;
    _activeModal = GameModal(
      title: _victoryTitle,
      message: _victoryMessage,
      buttonText: _victoryButton,
      onPressed: () {
        _activeModal?.removeFromParent();
        _activeModal = null;
        onMiniGameFinishExit?.call();
      },
      style: GameModalStyle.success,
      panelSize: Vector2(500, 300),
    );
    add(_activeModal!);
    _activeModal!.layoutForSize(findGame()!.size);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    if (!_gameStarted ||
        _currentObject == null ||
        _currentObject!.isAnimating ||
        _objectAnimating) {
      return false;
    }
    final gameSize = findGame()!.size;
    return point.x >= 0 &&
        point.x < gameSize.x &&
        point.y >= gameSize.y * 0.1 &&
        point.y < gameSize.y * 0.9;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_currentObject == null || _currentObject!.isAnimating) return;
    _isDraggingObject = true;
    _currentObject!.isBeingDragged = true;
    _dragStartPoint = event.canvasPosition;
    _dragInitialPiecePos = _currentObject!.position.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_isDraggingObject || _currentObject == null || _currentObject!.isAnimating) return;
    final dx = event.canvasEndPosition.x - _dragStartPoint.x;
    _currentObject!.position.x = (_dragInitialPiecePos.x + dx).clamp(20, findGame()!.size.x - 20);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_isDraggingObject) return;
    _isDraggingObject = false;
    if (_currentObject == null) return;
    _currentObject!.isBeingDragged = false;

    if (_currentObject!.isAnimating || _objectAnimating) return;

    final objX = _currentObject!.position.x;
    final tubeLeftX = findGame()!.size.x * 0.28;
    final tubeRightX = findGame()!.size.x * 0.72;
    final centerX = findGame()!.size.x * 0.5;
    if (objX < tubeLeftX) {
      _handleSorted(BinSide.left);
    } else if (objX > tubeRightX) {
      _handleSorted(BinSide.right);
    } else {
      _currentObject!.snapToCenter(centerX);
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    if (!_isDraggingObject) return;
    _isDraggingObject = false;
    if (_currentObject != null) {
      _currentObject!.isBeingDragged = false;
    }
  }
}
