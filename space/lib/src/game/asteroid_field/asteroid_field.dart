import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:space/src/game/shared/atoms/back_button.dart';
import 'package:space/src/game/shared/molecules/game_modal.dart';
import 'components/asteroid_field_components.dart';

enum AsteroidFieldPhase { waiting, playing, gameOver }
enum AsteroidFieldMode { standalone, miniGame }

class AsteroidField extends FlameGame
    with HasGameReference, HasCollisionDetection, DragCallbacks, TapCallbacks {
  final AsteroidFieldMode mode;
  final VoidCallback? onMiniGameFinishExit;

  late RocketPlayer player;
  late TextComponent statusText;
  late TextComponent coinText;
  late GameModal introModal;
  late GameModal finishModal;
  late GameModal lossModal;
  late GameBackButton backButton;

  final Random random = Random();

  double asteroidSpawnTimer = 0;
  double explosionSpawnTimer = 0;
  double coinSpawnTimer = 0;

  double asteroidSpawnRate = 1.0;
  double explosionSpawnRate = 2.2;
  double coinSpawnRate = 1.6;

  int coinsCollected = 0;

  double gameSpeed = 260;
  AsteroidFieldPhase phase = AsteroidFieldPhase.waiting;
  double distanceTravelled = 0.0;
  double finishDistance = 5000.0;
  late RectangleComponent progressBg;
  late RectangleComponent progressFill;
  late SpriteComponent progressShip;

  AsteroidField({
    this.mode = AsteroidFieldMode.standalone,
    this.onMiniGameFinishExit,
  });

  @override
  Future<void> onLoad() async {
    player = RocketPlayer(
      onAsteroidHit: triggerGameOver,
      onCoinCollected: collectCoin,
      onExplosionHit: triggerGameOver,
    );

    add(SpaceBackground());
    add(player);

    statusText = TextComponent(
      text: 'Tap to start',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
      anchor: Anchor.center,
    );

    add(statusText);

    coinText = TextComponent(
      text: 'Coins: 0',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFE59A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      anchor: Anchor.topRight,
    );
    add(coinText);

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
      title: 'Mission Briefing',
      message:
          'Guide the rocket through the asteroid belt. Drag to steer, avoid asteroids and explosions, collect coins, and reach the finish line.',
      buttonText: 'Start Mission',
      onPressed: _startFromIntroModal,
    );
    introModal.priority = 100;
    add(introModal);

    finishModal = GameModal(
      onPressed: onFinishContinue,
      style: GameModalStyle.success,
      title: 'Mission Complete',
      message: 'Great flight!',
      buttonText: 'Continue',
      titleColor: const Color(0xFFE8F4FF),
      messageColor: const Color(0xFFB8CEE8),
      panelSize: Vector2(480, 260),
    );
    finishModal.priority = 100;

    lossModal = GameModal(
      onPressed: resetToStart,
      style: GameModalStyle.danger,
      title: 'Mission Failed',
      message: 'Your ship was damaged.\nTry again from the start.',
      buttonText: 'Try Again',
      titleColor: const Color(0xFFFFD8D2),
      messageColor: const Color(0xFFF0BFB7),
      panelSize: Vector2(480, 260),
    );
    lossModal.priority = 100;

    backButton = GameBackButton(
      onPressed: onFinishContinue,
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
      coinText.position = Vector2(canvasSize.x - 20, 16);
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
    finishModal.configure(
      message: mode == AsteroidFieldMode.miniGame
          ? 'Great flight!\nReturn to minigames when ready.'
          : 'Great flight!\nStart a new run when ready.',
      buttonText: mode == AsteroidFieldMode.miniGame
          ? 'Back to Minigames'
          : 'Play Again',
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
      message: 'Your ship was damaged.\nTry again from the start.',
      buttonText: 'Try Again',
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
    if (mode == AsteroidFieldMode.miniGame && onMiniGameFinishExit != null) {
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
                child is Coin,
          )
          .toList(),
    );

    asteroidSpawnTimer = 0;
    explosionSpawnTimer = 0;
    coinSpawnTimer = 0;
    phase = AsteroidFieldPhase.waiting;

    statusText.text = 'Tap to start';
    statusText.position = size / 2;

    if (!statusText.isMounted) {
      add(statusText);
    }

    player.resetPosition();
    hideFinishModal();
    hideLossModal();

    coinsCollected = 0;
    coinText.text = 'Coins: 0';

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
                child is Coin,
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
    coinSpawnTimer += dt;

    if (asteroidSpawnTimer >= asteroidSpawnRate) {
      asteroidSpawnTimer = 0;
      spawnAsteroid();
    }

    if (explosionSpawnTimer >= explosionSpawnRate) {
      explosionSpawnTimer = 0;
      spawnExplosion();
    }

    final progressForCoins = distanceTravelled / finishDistance;
    if (progressForCoins >= 0.5 && progressForCoins < 0.95 && coinSpawnTimer >= coinSpawnRate) {
      coinSpawnTimer = 0;
      spawnCoin();
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

  void spawnCoin() {
    final coin = Coin(speed: gameSpeed * 0.92);

    const safeDistance = 180.0;
    var coinPosition = Vector2(
      size.x + 90,
      120 + random.nextDouble() * (size.y - 240),
    );

    for (var attempt = 0; attempt < 12; attempt++) {
      coinPosition = Vector2(
        size.x + 90,
        120 + random.nextDouble() * (size.y - 240),
      );

      if (_isCoinSpawnSafe(coinPosition, safeDistance)) {
        break;
      }
    }

    coin.position = coinPosition;

    add(coin);
  }

  bool _isCoinSpawnSafe(Vector2 coinPosition, double minDistance) {
    for (final asteroid in children.whereType<Asteroid>()) {
      final asteroidCenter = asteroid.position + asteroid.size / 2;
      if (coinPosition.distanceTo(asteroidCenter) < minDistance) {
        return false;
      }
    }

    for (final explosion in children.whereType<FakeExplosion>()) {
      final explosionCenter = explosion.position + explosion.size / 2;
      if (coinPosition.distanceTo(explosionCenter) < minDistance) {
        return false;
      }
    }

    return true;
  }

  void collectCoin(Coin coin) {
    if (phase != AsteroidFieldPhase.playing) {
      return;
    }

    coinsCollected += 1;
    coinText.text = 'Coins: $coinsCollected';
    coin.removeFromParent();
  }
}
