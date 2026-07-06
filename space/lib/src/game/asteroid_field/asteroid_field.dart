import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:space/src/game/shared/atoms/back_button.dart';
import 'package:space/src/game/shared/molecules/game_modal.dart';
import 'package:space/src/game/shared/settings.dart';
import 'package:space/src/game/shared/sound_manager.dart';
import 'package:space/src/game/shared/tutorial.dart';
import 'components/asteroid_field_components.dart';

enum AsteroidFieldPhase { waiting, playing, gameOver }
enum AsteroidFieldMode { standalone, miniGame, story }

class AsteroidField extends FlameGame
    with HasGameReference, HasCollisionDetection, DragCallbacks, TapCallbacks {
  final AsteroidFieldMode mode;
  final VoidCallback? onMiniGameFinishExit;
  final VoidCallback? onBackPressed;
  final bool skipTutorial;
  final VoidCallback? onTutorialComplete;
  int _consecutiveLosses = 0;

  TutorialOverlay? _tutorialOverlay;
  bool _tutorialActive = false;
  bool _pendingLayout = false;

  late RocketPlayer player;
  late TextComponent statusText;
  late TextComponent petiscoText;
  late GameModal introModal;
  late GameModal finishModal;
  GameModal? _lossModal;
  late GameBackButton backButton;

  final Random random = Random();

  double asteroidSpawnTimer = 0;
  double explosionSpawnTimer = 0;
  double petiscoSpawnTimer = 0;

  double get gameSpeed => 260 * GameSettings.instance.speedMultiplier;
  double get asteroidSpawnRate => 1.0 * GameSettings.instance.spawnRateMultiplier;
  double get explosionSpawnRate => 2.2 * GameSettings.instance.spawnRateMultiplier;
  double get petiscoSpawnRate => 1.6 * GameSettings.instance.spawnRateMultiplier;

  int petiscosCollected = 0;
  AsteroidFieldPhase phase = AsteroidFieldPhase.waiting;
  double distanceTravelled = 0.0;
  double get finishDistance {
    switch (GameSettings.instance.difficulty) {
      case GameSettings.easy:
        return 5000.0;
      case GameSettings.medium:
        return 7000.0;
      case GameSettings.hard:
        return 10000.0;
      default:
        return 5000.0;
    }
  }
  late RectangleComponent progressBg;
  late RectangleComponent progressFill;
  late SpriteComponent progressShip;

  PositionComponent? _dragHint;

  AsteroidField({
    this.mode = AsteroidFieldMode.standalone,
    this.onMiniGameFinishExit,
    this.onBackPressed,
    this.skipTutorial = false,
    this.onTutorialComplete,
  });

  @override
  Future<void> onLoad() async {
    player = RocketPlayer(
      onAsteroidHit: triggerGameOver,
      onPetiscoCollected: collectPetisco,
      onExplosionHit: triggerGameOver,
    );

    add(SpaceBackground());
    add(player);

    statusText = TextComponent(
      text: 'Toque para começar',
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
      anchor: Anchor.center,
    );

    add(statusText);

    petiscoText = TextComponent(
      text: 'Petiscos: 0',
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: const Color(0xFFFFE59A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      anchor: Anchor.topRight,
    );
    add(petiscoText);

    progressBg = RectangleComponent(
      size: Vector2(240, 18),
      anchor: Anchor.topCenter,
      paint: Paint()..color = Colors.white.withAlpha(60),
    );

    progressFill = RectangleComponent(
      size: Vector2(0, 18),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xFF6FE7FF),
    );

    progressBg.add(progressFill);
    add(progressBg);

    final shipSprite = await Sprite.load('icon.png');
    progressShip = SpriteComponent(
      sprite: shipSprite,
      size: Vector2(20, 20),
      anchor: Anchor.center,
      position: Vector2(0, progressBg.size.y / 2),
    );
    progressBg.add(progressShip);

    introModal = GameModal(
      title: 'Sua missão:',
      message:
          'Guie o foguete através do campo de asteroides. Arraste para pilotar, evite os asteroides e as explosões, e colete os petiscos.',
      buttonText: 'Comece a missão',
      onPressed: _startFromIntroModal,
    );
    introModal.priority = 100;

    finishModal = GameModal(
      onPressed: onFinishContinue,
      style: GameModalStyle.success,
      title: 'Missão Concluída',
      message: 'Ótimo voo!',
      buttonText: 'Continuar',
      titleColor: const Color(0xFFE8F4FF),
      messageColor: const Color(0xFFB8CEE8),
      panelSize: Vector2(480, 260),
    );
    finishModal.priority = 100;

    backButton = GameBackButton(
      onPressed: onBackPressed ?? onFinishContinue,
      position: Vector2(24, 24),
      anchor: Anchor.topLeft,
      size: Vector2.all(40),
    );
    camera.viewport.add(backButton);

    if (!skipTutorial) {
      await images.load('tutorial_hand.png');
    }

    if (skipTutorial) {
      _pendingLayout = true;
    } else {
      _pendingLayout = true;
    }
  }

  void _onLayoutReady() {
    if (!_pendingLayout) return;
    _pendingLayout = false;

    if (skipTutorial) {
      add(introModal);
      introModal.layoutForSize(size);
    } else {
      _startTutorial();
    }
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);

    if (isLoaded) {
      _onLayoutReady();

      statusText.position = canvasSize / 2;
      petiscoText.position = Vector2(canvasSize.x - 20, 16);
      progressBg.position = Vector2(canvasSize.x / 2, 14);

      if (introModal.isMounted) {
        introModal.layoutForSize(canvasSize);
      }

      if (finishModal.isMounted) {
        finishModal.layoutForSize(canvasSize);
      }

      if (_lossModal?.isMounted == true) {
        _lossModal!.layoutForSize(canvasSize);
      }
    }
  }

  void showFinishModal() {
    String message;
    String buttonText;
    switch (mode) {
      case AsteroidFieldMode.story:
        message = 'Ótimo voo!\nContinue a história quando estiver pronto.';
        buttonText = 'Continuar';
      case AsteroidFieldMode.miniGame:
        message = 'Ótimo voo!\nVolte para os minijogos quando estiver pronto.';
        buttonText = 'Voltar para Minijogos';
      case AsteroidFieldMode.standalone:
        message = 'Ótimo voo!\nInicie uma nova tentativa quando estiver pronto.';
        buttonText = 'Jogar Novamente';
    }
    finishModal.configure(
      message: message,
      buttonText: buttonText,
    );
    if (!finishModal.isMounted) {
      finishModal.layoutForSize(size);
      add(finishModal);
    }
  }

  void hideFinishModal() {
    if (finishModal.isMounted) {
      finishModal.removeFromParent();
    }
  }

  void hideLossModal() {
    _lossModal?.removeFromParent();
    _lossModal = null;
  }

  void onFinishContinue() {
    if (onMiniGameFinishExit != null) {
      onMiniGameFinishExit!.call();
      return;
    }

    resetToStart();
  }

  void startGame() {
    if (phase != AsteroidFieldPhase.waiting || introModal.isMounted) {
      return;
    }

    SoundManager.instance.playBgm('asteroid_field/bgm.mp3');

    phase = AsteroidFieldPhase.playing;
    statusText.removeFromParent();

    _dragHint?.removeFromParent();
    _dragHint = _AsteroidDragHint(player: player);
    add(_dragHint!);
  }

  void _startFromIntroModal() {
    if (introModal.isMounted) {
      introModal.removeFromParent();
    }
    startGame();
  }

  void resetToStart() {
    removeAll(
      children
          .where(
            (child) =>
                child is Asteroid ||
                child is FakeExplosion ||
                child is Petisco,
          )
          .toList(),
    );

    asteroidSpawnTimer = 0;
    explosionSpawnTimer = 0;
    petiscoSpawnTimer = 0;
    phase = AsteroidFieldPhase.waiting;

    statusText.text = 'Toque para começar';
    statusText.position = size / 2;

    if (!statusText.isMounted) {
      add(statusText);
    }

    player.resetPosition();
    hideFinishModal();
    hideLossModal();

    petiscosCollected = 0;
    petiscoText.text = 'Petiscos: 0';

    distanceTravelled = 0;
    progressFill.size.x = 0;
    progressShip.position = Vector2(0, progressBg.size.y / 2);

    _removeDragHint();
  }

  void triggerGameOver() {
    if (phase == AsteroidFieldPhase.gameOver) {
      return;
    }

    _consecutiveLosses++;
    SoundManager.instance.playSfx('asteroid_hit');
    SoundManager.instance.stopBgm();

    phase = AsteroidFieldPhase.gameOver;
    removeAll(
      children
          .where(
            (child) =>
                child is Asteroid ||
                child is FakeExplosion ||
                child is Petisco,
          )
          .toList(),
    );
    statusText.text = 'Fim de Jogo';
    statusText.position = size / 2;
    hideFinishModal();
    _showLossModal();
  }

  void _showLossModal() {
    hideLossModal();
    final showTutorial = _consecutiveLosses >= 3;
    _lossModal = GameModal(
      onPressed: () {
        hideLossModal();
        resetToStart();
      },
      style: GameModalStyle.danger,
      title: 'Missao Falhou',
      message: showTutorial
          ? 'Seu foguete foi danificado.\nQuer ver o tutorial novamente?'
          : 'Seu foguete foi danificado.\nTente novamente a partir do inicio.',
      buttonText: 'Tentar Novamente',
      titleColor: const Color(0xFFFFD8D2),
      messageColor: const Color(0xFFF0BFB7),
      panelSize: Vector2(480, 260),
    );
    if (showTutorial) {
      _lossModal!.configure(
        secondaryButtonText: 'Ver Tutorial',
        onSecondaryPressed: () {
          hideLossModal();
          _consecutiveLosses = 0;
          _startTutorial();
        },
      );
    }
    _lossModal!.priority = 100;
    _lossModal!.layoutForSize(size);
    add(_lossModal!);
  }

  void triggerFinish() {
    if (phase != AsteroidFieldPhase.playing) {
      return;
    }

    _consecutiveLosses = 0;
    SoundManager.instance.playSfx('success');
    SoundManager.instance.stopBgm();

    phase = AsteroidFieldPhase.gameOver;
    removeAll(children.where((child) => child is Asteroid || child is FakeExplosion).toList());
    progressFill.size.x = progressBg.size.x;
    progressShip.position = Vector2(progressBg.size.x, progressBg.size.y / 2);
    showFinishModal();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_tutorialActive && _tutorialOverlay != null) {
      final step = _tutorialOverlay!.currentStep;
      if (step.action == TutorialAction.dragAnywhere) {
        _tutorialOverlay!.advance();
      }
      return;
    }

    if (phase != AsteroidFieldPhase.playing) {
      return;
    }

    _removeDragHint();

    player.followTouch(event.canvasEndPosition);
  }

  void _removeDragHint() {
    _dragHint?.removeFromParent();
    _dragHint = null;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    if (_tutorialActive) return;

    if (introModal.isMounted) {
      _startFromIntroModal();
      return;
    }

    startGame();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_tutorialActive) return;

    if (phase != AsteroidFieldPhase.playing) {
      return;
    }

    distanceTravelled += gameSpeed * dt;

    final progress = (distanceTravelled / finishDistance).clamp(0.0, 1.0);
    progressFill.size.x = progressBg.size.x * progress;

    if (progress >= 1.0) {
      triggerFinish();
    }
    final shipX = progressFill.size.x.clamp(0.0, progressBg.size.x);
    progressShip.position = Vector2(shipX, progressBg.size.y / 2);

    asteroidSpawnTimer += dt;
    explosionSpawnTimer += dt;
    petiscoSpawnTimer += dt;

    if (asteroidSpawnTimer >= asteroidSpawnRate) {
      asteroidSpawnTimer = 0;
      spawnAsteroid();
    }

    if (explosionSpawnTimer >= explosionSpawnRate) {
      explosionSpawnTimer = 0;
      spawnExplosion();
    }

    final progressForPetiscos = distanceTravelled / finishDistance;
    if (progressForPetiscos >= 0.5 && progressForPetiscos < 0.95 && petiscoSpawnTimer >= petiscoSpawnRate) {
      petiscoSpawnTimer = 0;
      spawnPetisco();
    }
  }

  void spawnAsteroid() {
    final asteroid = Asteroid(speed: gameSpeed);

    asteroid.position = Vector2(
      size.x + 100,
      random.nextDouble() * (size.y - 120),
    );

    add(asteroid);
  }

  void spawnExplosion() {
    final explosion = FakeExplosion();

    const safeDistance = 280.0;
    var explosionPosition = Vector2.zero();

    for (var attempt = 0; attempt < 12; attempt++) {
      explosionPosition = Vector2(
        random.nextDouble() * game.size.x,
        random.nextDouble() * size.y,
      );

      if (explosionPosition.distanceTo(player.position) >= safeDistance) {
        break;
      }
    }

    explosion.position = explosionPosition;

    add(explosion);
  }

  void spawnPetisco() {
    final petisco = Petisco(speed: gameSpeed * 0.92);

    const safeDistance = 180.0;
    var petiscoPosition = Vector2(
      size.x + 90,
      120 + random.nextDouble() * (size.y - 240),
    );

    for (var attempt = 0; attempt < 12; attempt++) {
      petiscoPosition = Vector2(
        size.x + 90,
        120 + random.nextDouble() * (size.y - 240),
      );

      if (_isPetiscoSpawnSafe(petiscoPosition, safeDistance)) {
        break;
      }
    }

    petisco.position = petiscoPosition;

    add(petisco);
  }

  bool _isPetiscoSpawnSafe(Vector2 petiscoPosition, double minDistance) {
    for (final asteroid in children.whereType<Asteroid>()) {
      final asteroidCenter = asteroid.position + asteroid.size / 2;
      if (petiscoPosition.distanceTo(asteroidCenter) < minDistance) {
        return false;
      }
    }

    for (final explosion in children.whereType<FakeExplosion>()) {
      final explosionCenter = explosion.position + explosion.size / 2;
      if (petiscoPosition.distanceTo(explosionCenter) < minDistance) {
        return false;
      }
    }

    return true;
  }

  void collectPetisco(Petisco petisco) {
    if (phase != AsteroidFieldPhase.playing) {
      return;
    }

    SoundManager.instance.playSfx('correct');
    petiscosCollected += 1;
    petiscoText.text = 'Petiscos: $petiscosCollected';
    petisco.removeFromParent();
  }

  void _startTutorial() {
    _tutorialActive = true;

    final handImage = images.fromCache('tutorial_hand.png');
    final steps = TutorialConfigs.asteroidFieldSteps(size);

    _tutorialOverlay = TutorialOverlay(
      steps: steps,
      gameSize: size,
      handImage: handImage,
      onTutorialComplete: () {
        _tutorialOverlay?.removeFromParent();
        _tutorialOverlay = null;
        _tutorialActive = false;
        onTutorialComplete?.call();
        add(introModal);
        introModal.layoutForSize(size);
      },
      onTutorialSkip: () {
        _tutorialOverlay?.removeFromParent();
        _tutorialOverlay = null;
        _tutorialActive = false;
        onTutorialComplete?.call();
        add(introModal);
        introModal.layoutForSize(size);
      },
    );
    add(_tutorialOverlay!);
  }
}

class _AsteroidDragHint extends PositionComponent {
  _AsteroidDragHint({required this.player}) : super(priority: 20, size: Vector2(80, 120));

  final RocketPlayer player;
  double _timer = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    final gameSize = findGame()!.size;
    position = Vector2(
      player.position.x + 50,
      player.position.y,
    );
    position.x = position.x.clamp(20, gameSize.x - size.x - 20);
    position.y = position.y.clamp(size.y / 2 + 20, gameSize.y - size.y / 2 - 20);
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final phase = (_timer % 1.4) / 1.4;
    final alpha = (phase < 0.5 ? phase * 2 : (1.0 - (phase - 0.5) * 2)) * 0.6;

    final arrowPaint = Paint()
      ..color = const Color(0xFF62D5FF).withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawLine(Offset(cx, size.y * 0.8), Offset(cx, size.y * 0.2), arrowPaint);

    final tipPaint = Paint()
      ..color = const Color(0xFF62D5FF).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final upPath = Path()
      ..moveTo(cx, size.y * 0.15)
      ..lineTo(cx - 8, size.y * 0.3)
      ..lineTo(cx + 8, size.y * 0.3)
      ..close();
    canvas.drawPath(upPath, tipPaint);

    final downPath = Path()
      ..moveTo(cx, size.y * 0.85)
      ..lineTo(cx - 8, size.y * 0.7)
      ..lineTo(cx + 8, size.y * 0.7)
      ..close();
    canvas.drawPath(downPath, tipPaint);

    final handPaint = Paint()..color = Colors.white.withValues(alpha: alpha * 1.2);
    canvas.drawCircle(Offset(cx, size.y / 2), 6, handPaint);
  }
}
