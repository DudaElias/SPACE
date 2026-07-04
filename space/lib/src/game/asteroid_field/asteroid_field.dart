import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:space/src/game/shared/atoms/back_button.dart';
import 'package:space/src/game/shared/molecules/game_modal.dart';
import 'package:space/src/game/shared/settings.dart';
import 'components/asteroid_field_components.dart';

enum AsteroidFieldPhase { waiting, playing, gameOver }
enum AsteroidFieldMode { standalone, miniGame, story }

class AsteroidField extends FlameGame
    with HasGameReference, HasCollisionDetection, DragCallbacks, TapCallbacks {
  final AsteroidFieldMode mode;
  final VoidCallback? onMiniGameFinishExit;
  final VoidCallback? onBackPressed;

  late RocketPlayer player;
  late TextComponent statusText;
  late TextComponent petiscoText;
  late GameModal introModal;
  late GameModal finishModal;
  late GameModal lossModal;
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

  AsteroidField({
    this.mode = AsteroidFieldMode.standalone,
    this.onMiniGameFinishExit,
    this.onBackPressed,
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
          'Guie o foguete através do campo de asteróides. Arraste para pilotar, evite os asteróides e as explosões, colete os petiscos, e alcance a linha de chegada.',
      buttonText: 'Comece a missão',
      onPressed: _startFromIntroModal,
    );
    introModal.priority = 100;
    add(introModal);

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

    lossModal = GameModal(
      onPressed: resetToStart,
      style: GameModalStyle.danger,
      title: 'Missão Falhou',
      message: 'Seu foguete foi danificado.\nTente novamente a partir do início.',
      buttonText: 'Tentar Novamente',
      titleColor: const Color(0xFFFFD8D2),
      messageColor: const Color(0xFFF0BFB7),
      panelSize: Vector2(480, 260),
    );
    lossModal.priority = 100;

    backButton = GameBackButton(
      onPressed: onBackPressed ?? onFinishContinue,
      position: Vector2(24, 24),
      anchor: Anchor.topLeft,
      size: Vector2.all(40),
    );
    camera.viewport.add(backButton);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);

    if (isLoaded) {
      statusText.position = canvasSize / 2;
      petiscoText.position = Vector2(canvasSize.x - 20, 16);
      progressBg.position = Vector2(canvasSize.x / 2, 14);

      if (introModal.isMounted) {
        introModal.layoutForSize(canvasSize);
      }

      if (finishModal.isMounted) {
        finishModal.layoutForSize(canvasSize);
      }

      if (lossModal.isMounted) {
        lossModal.layoutForSize(canvasSize);
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

  void showLossModal() {
    lossModal.configure(
      message: 'Seu foguete foi danificado.\nTente novamente a partir do início.',
      buttonText: 'Tentar Novamente',
    );
    if (!lossModal.isMounted) {
      lossModal.layoutForSize(size);
      add(lossModal);
    }
  }

  void hideLossModal() {
    if (lossModal.isMounted) {
      lossModal.removeFromParent();
    }
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


    phase = AsteroidFieldPhase.playing;
    statusText.removeFromParent();
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
  }

  void triggerGameOver() {
    if (phase == AsteroidFieldPhase.gameOver) {
      return;
    }

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
    statusText.text = 'Game over';
    statusText.position = size / 2;
    hideFinishModal();
    showLossModal();
  }

  void triggerFinish() {
    if (phase != AsteroidFieldPhase.playing) {
      return;
    }

    phase = AsteroidFieldPhase.gameOver;
    removeAll(children.where((child) => child is Asteroid || child is FakeExplosion).toList());
    progressFill.size.x = progressBg.size.x;
    progressShip.position = Vector2(progressBg.size.x, progressBg.size.y / 2);
    showFinishModal();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (phase != AsteroidFieldPhase.playing) {
      return;
    }

    player.followTouch(event.canvasEndPosition);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    if (introModal.isMounted) {
      _startFromIntroModal();
      return;
    }

    startGame();
  }

  @override
  void update(double dt) {
    super.update(dt);

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

    petiscosCollected += 1;
    petiscoText.text = 'Petiscos: $petiscosCollected';
    petisco.removeFromParent();
  }
}
