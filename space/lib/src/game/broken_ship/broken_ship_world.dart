import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../shared/molecules/game_modal.dart';
import 'broken_ship_controller.dart';
import 'broken_ship_route.dart';
import 'components/broken_ship_backdrop.dart';
import 'components/collection_bin.dart';
import 'components/combo_display.dart';
import 'components/repair_meter.dart';
import 'components/rule_indicator.dart';
import 'components/sorting_object.dart';

class BrokenShipWorld extends World {
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

  double _phaseTimer = 0;
  double _ruleElapsedTime = 0;
  bool _gameStarted = false;

  GameModal? _activeModal;

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

    _backdrop = BrokenShipBackdrop();
    await add(_backdrop);

    _ruleIndicator = RuleIndicator()
      ..position = Vector2.zero()
      ..size = Vector2(420, 80);
    add(_ruleIndicator);

    _repairMeter = RepairMeter()
      ..position = Vector2.zero();
    add(_repairMeter);

    _comboDisplay = ComboDisplay()
      ..position = Vector2.zero();
    add(_comboDisplay);

    _leftBin = CollectionBin(
      side: BinSide.left,
      colorSwatch: const Color(0xFF3B82F6),
    )..position = Vector2.zero();
    add(_leftBin);

    _rightBin = CollectionBin(
      side: BinSide.right,
      colorSwatch: const Color(0xFFF97316),
    )..position = Vector2.zero();
    add(_rightBin);

    _layoutForSize(findGame()!.size);

    _showIntroModal();
  }

  void _layoutForSize(Vector2 size) {
    _backdrop.layoutForSize(size);

    _ruleIndicator
      ..position = Vector2(size.x * 0.5, 60)
      ..size = Vector2(420, 100);

    _repairMeter
      ..position = Vector2(size.x * 0.5, 125)
      ..size = Vector2(320, 30);

    _comboDisplay.position = Vector2(size.x * 0.5 + 170, 125);

    final binY = size.y * 0.84;
    _leftBin.position = Vector2(size.x * 0.18, binY);
    _rightBin.position = Vector2(size.x * 0.82, binY);
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
        _updateTransition(dt);
        break;
    }
  }

  void _updateGameplay(double dt) {
    _ruleElapsedTime += dt;

    if (_controller.phase == BrokenShipPhase.phase3) {
      final shouldFade = _controller.shouldFadeLabels(_ruleElapsedTime);
      if (shouldFade) {
        _leftBin.labelOpacity += (0.0 - _leftBin.labelOpacity) * dt * 1.5;
        _rightBin.labelOpacity += (0.0 - _rightBin.labelOpacity) * dt * 1.5;
      }
    }

    if (_currentObject == null && !_objectAnimating) {
      _spawnNextObject();
    }
  }

  void _updatePause(double dt) {
    _phaseTimer -= dt;
    if (_phaseTimer <= 0) {
      _controller.advanceFromPause();
      _ruleIndicator.setFlashing(true);
      _phaseTimer = BrokenShipController.transitionFlashSecs;
    }
  }

  void _updateTransition(double dt) {
    _phaseTimer -= dt;
    if (_phaseTimer <= 0) {
      _controller.advanceFromTransition();
      _ruleIndicator.setFlashing(false);
      _refreshRuleUI();
      _ruleElapsedTime = 0;
      _leftBin.labelOpacity = 1.0;
      _rightBin.labelOpacity = 1.0;
    }
  }

  void _startGame() {
    _controller.startGame();
    _gameStarted = true;
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
    final restX = size.x * 0.5;
    final restY = size.y * 0.48;

    _currentObject = SortingObject(piece: piece)
      ..position = Vector2(spawnX, spawnY)
      ..restPosition = Vector2(restX, restY)
      ..onSorted = _handleSorted
      ..onMissed = _handleMissed
      ..onUnjammed = _handleUnjammed;

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
        _controller.onJam?.call();
        _comboDisplay.setCombo(_controller.comboCount);

        if (side == BinSide.left) {
          _leftBin.flashIncorrect();
        } else {
          _rightBin.flashIncorrect();
        }

        _currentObject!.jam();
        _objectAnimating = false;
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

  void _handleUnjammed() {
    _controller.onUnjam?.call();
    _currentObject?.restPosition = Vector2(
      findGame()!.size.x * 0.5,
      findGame()!.size.y * 0.48,
    );
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
        _controller.advancePhase3Rule();
        _ruleIndicator.flashBrief();
        _refreshRuleUI();
        _ruleElapsedTime = 0;
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
}
