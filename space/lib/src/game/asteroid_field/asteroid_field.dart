import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

enum AsteroidFieldPhase { waiting, playing, gameOver }
enum AsteroidFieldMode { standalone, miniGame }

class AsteroidField extends FlameGame
    with HasGameReference, HasCollisionDetection, DragCallbacks, TapCallbacks {
  final AsteroidFieldMode mode;
  final VoidCallback? onMiniGameFinishExit;

  late RocketPlayer player;
  late TextComponent statusText;
  late TextComponent coinText;

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
  // Progress tracking
  double distanceTravelled = 0.0;
  double finishDistance = 5000.0;
  late RectangleComponent progressBg;
  late RectangleComponent progressFill;
  late SpriteComponent progressShip;
  late FinishModalComponent finishModal;
  late LossModalComponent lossModal;
  late AsteroidBackButton backButton;

  AsteroidField({
    this.mode = AsteroidFieldMode.standalone,
    this.onMiniGameFinishExit,
  });

  @override
  Future<void> onLoad() async {
    player = RocketPlayer();

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

    // Progress UI (positions set in onGameResize)
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

    // small ship icon on the progress bar
    final shipSprite = await Sprite.load('icon.png');
    progressShip = SpriteComponent(
      sprite: shipSprite,
      size: Vector2(20, 20),
      anchor: Anchor.center,
      position: Vector2(0, progressBg.size.y / 2),
    );
    progressBg.add(progressShip);

    finishModal = FinishModalComponent(
      onContinue: onFinishContinue,
    );
    finishModal.priority = 100;

    lossModal = LossModalComponent(
      onContinue: resetToStart,
    );
    lossModal.priority = 100;

    backButton = AsteroidBackButton(
      onPressed: onFinishContinue,
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

      if (finishModal.isMounted) {
        finishModal.position = canvasSize / 2;
      }

      if (lossModal.isMounted) {
        lossModal.position = canvasSize / 2;
      }
    }
  }

  void showFinishModal() {
    finishModal.configure(
      subtitle: mode == AsteroidFieldMode.miniGame
          ? 'Great flight!\nReturn to minigames when ready.'
          : 'Great flight!\nStart a new run when ready.',
      buttonLabel: mode == AsteroidFieldMode.miniGame
          ? 'Back to Minigames'
          : 'Play Again',
    );
    finishModal.position = size / 2;
    if (!finishModal.isMounted) {
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
      subtitle: 'Your ship was damaged.\nTry again from the start.',
      buttonLabel: 'Try Again',
    );
    lossModal.position = size / 2;
    if (!lossModal.isMounted) {
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
    if (phase != AsteroidFieldPhase.waiting) {
      return;
    }

    phase = AsteroidFieldPhase.playing;
    statusText.removeFromParent();
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

    player.collided = false;
    player.resetPosition();
    hideFinishModal();
    hideLossModal();

    coinsCollected = 0;
    coinText.text = 'Coins: 0';

    // Reset progress
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

  /// DRAG TO MOVE
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

    startGame();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (phase != AsteroidFieldPhase.playing) {
      return;
    }

    // Update progress by how far the world has moved
    distanceTravelled += gameSpeed * dt;

    final progress = (distanceTravelled / finishDistance).clamp(0.0, 1.0);
    progressFill.size.x = progressBg.size.x * progress;

    if (progress >= 1.0) {
      // Reached finish
      triggerFinish();
    }
    // move progress ship to fill edge (clamped within bar)
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

    coin.position = Vector2(
      size.x + 90,
      120 + random.nextDouble() * (size.y - 240),
    );

    add(coin);
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

/// ======================================
/// TABLET PLAYER
/// ======================================

class RocketPlayer extends PositionComponent
    with HasGameReference<AsteroidField>, CollisionCallbacks {
  Vector2 targetPosition = Vector2.zero();
  late Vector2 startPosition;

  bool collided = false;
  late SpriteComponent spriteComponent;
  /// When true, Flame will render hitboxes for this component.
  /// Use `flashHitbox()` to briefly show the hitbox for debugging.
  bool showHitboxDebug = false;

  RocketPlayer();

  @override
  Future<void> onLoad() async {
    size = Vector2(200, 150);

    // Make this component's position refer to its center so dragging targets the visible sprite center
    anchor = Anchor.center;

    /// IMPORTANT
    // Add a hitbox exactly centered on the component (matches the sprite)
    add(
      RectangleHitbox.relative(
        Vector2.all(0.75),
        parentSize: size,
        anchor: Anchor.center,
      ),
    );
    // Load the rocket sprite from assets
    final sprite = await Sprite.load('icon.png');
    spriteComponent = SpriteComponent(
      sprite: sprite,
      size: size,
      anchor: Anchor.center,
    );
    add(spriteComponent);

    // Flash the hitbox briefly on load so placement can be verified
    flashHitbox(Duration(milliseconds: 1500));
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);

    if (!isLoaded) {
      return;
    }

    startPosition = Vector2(180, canvasSize.y / 2);
    position = startPosition.clone();
    targetPosition = position.clone();
    spriteComponent.position = size / 2;
  }

  void resetPosition() {
    position = startPosition.clone();
    targetPosition = startPosition.clone();
  }

  /// Briefly enable `debugMode` so hitboxes are drawn (useful for verifying placement)
  void flashHitbox(Duration duration) {
    debugMode = true;
    Future.delayed(duration, () {
      debugMode = false;
    });
  }

  /// =======================================================
  /// FOLLOW TOUCH
  /// =======================================================

  void followTouch(Vector2 touchPosition) {
    targetPosition = touchPosition;
  }

  @override
  void update(double dt) {
    super.update(dt);

    /// Smooth interpolation
    position += (targetPosition - position) * 7 * dt;

    /// Clamp screen
    position.x = position.x.clamp(size.x / 2, game.size.x - size.x / 2);

    position.y = position.y.clamp(size.y / 2, game.size.y - size.y / 2);
  }

  /// =======================================================
  /// COLLISION
  /// =======================================================

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Asteroid) {
      collided = true;
      game.triggerGameOver();
    } else if (other is Coin) {
      game.collectCoin(other);
    } else if (other is FakeExplosion) {
      collided = true;
      game.triggerGameOver();
    }

    Future.delayed(const Duration(milliseconds: 200), () {
      collided = false;
    });
  }

}

class FinishModalComponent extends PositionComponent {
  final VoidCallback onContinue;

  late TextComponent titleText;
  late TextComponent subtitleText;
  late ModalButtonComponent continueButton;
  bool uiReady = false;
  String pendingSubtitle = 'Great flight!';
  String pendingButtonLabel = 'Continue';

  FinishModalComponent({
    required this.onContinue,
  }) {
    size = Vector2(360, 190);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    titleText = TextComponent(
      text: 'Mission Complete',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE8F4FF),
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 22),
    );

    subtitleText = TextComponent(
      text: 'Great flight!',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFB8CEE8),
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 66),
    );

    continueButton = ModalButtonComponent(
      label: pendingButtonLabel,
      onPressed: onContinue,
      size: Vector2(210, 46),
    )
      ..anchor = Anchor.center
      ..position = Vector2(size.x / 2, size.y - 36);

    add(titleText);
    add(subtitleText);
    add(continueButton);

    uiReady = true;
    subtitleText.text = pendingSubtitle;
    continueButton.setLabel(pendingButtonLabel);
  }

  void configure({required String subtitle, required String buttonLabel}) {
    pendingSubtitle = subtitle;
    pendingButtonLabel = buttonLabel;

    if (!uiReady) {
      return;
    }

    subtitleText.text = pendingSubtitle;
    continueButton.setLabel(pendingButtonLabel);
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xEE111F39),
        Color(0xEE0A1429),
      ],
    );

    final panel = RRect.fromRectAndRadius(rect, const Radius.circular(22));
    canvas.drawRRect(
      panel,
      Paint()..shader = gradient.createShader(rect),
    );

    canvas.drawRRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF62D5FF).withAlpha(170),
    );

    // Subtle ambient glow to match the space UI.
    canvas.drawRRect(
      panel.inflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF9EEAFF).withAlpha(70),
    );
  }
}

class LossModalComponent extends PositionComponent {
  final VoidCallback onContinue;

  late TextComponent titleText;
  late TextComponent subtitleText;
  late ModalButtonComponent continueButton;
  bool uiReady = false;
  String pendingSubtitle = 'Your ship was damaged.\nTry again from the start.';
  String pendingButtonLabel = 'Try Again';

  LossModalComponent({
    required this.onContinue,
  }) {
    size = Vector2(360, 190);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    titleText = TextComponent(
      text: 'Mission Failed',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFD8D2),
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 22),
    );

    subtitleText = TextComponent(
      text: 'Your ship was damaged.\nTry again from the start.',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF0BFB7),
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 66),
    );

    continueButton = ModalButtonComponent(
      label: pendingButtonLabel,
      onPressed: onContinue,
      size: Vector2(210, 46),
    )
      ..anchor = Anchor.center
      ..position = Vector2(size.x / 2, size.y - 36);

    add(titleText);
    add(subtitleText);
    add(continueButton);

    uiReady = true;
    subtitleText.text = pendingSubtitle;
    continueButton.setLabel(pendingButtonLabel);
  }

  void configure({required String subtitle, required String buttonLabel}) {
    pendingSubtitle = subtitle;
    pendingButtonLabel = buttonLabel;

    if (!uiReady) {
      return;
    }

    subtitleText.text = pendingSubtitle;
    continueButton.setLabel(pendingButtonLabel);
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xEE33161C),
        Color(0xEE170D18),
      ],
    );

    final panel = RRect.fromRectAndRadius(rect, const Radius.circular(22));
    canvas.drawRRect(
      panel,
      Paint()..shader = gradient.createShader(rect),
    );

    canvas.drawRRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFFF8F8F).withAlpha(170),
    );

    canvas.drawRRect(
      panel.inflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFFFC8C8).withAlpha(70),
    );
  }
}

class AsteroidBackButton extends PositionComponent with TapCallbacks {
  final VoidCallback onPressed;

  AsteroidBackButton({required this.onPressed})
      : _iconPath = Path()
          ..moveTo(22, 8)
          ..lineTo(10, 20)
          ..lineTo(22, 32)
          ..moveTo(12, 20)
          ..lineTo(34, 20),
        super(
          size: Vector2.all(40),
          anchor: Anchor.topLeft,
          position: Vector2(24, 24),
        );

  final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.transparent;
  final Paint _iconPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color.fromARGB(255, 207, 207, 207)
    ..strokeWidth = 7;
  final Path _iconPath;

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(8)),
      _borderPaint,
    );
    canvas.drawPath(_iconPath, _iconPaint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _iconPaint.color = const Color(0xffffffff);
  }

  @override
  void onTapUp(TapUpEvent event) {
    _iconPaint.color = const Color.fromARGB(255, 207, 207, 207);
    onPressed();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _iconPaint.color = const Color.fromARGB(255, 207, 207, 207);
  }
}

class ModalButtonComponent extends PositionComponent with TapCallbacks {
  final VoidCallback onPressed;
  late TextComponent labelText;
  bool pressed = false;

  ModalButtonComponent({
    required String label,
    required this.onPressed,
    required Vector2 size,
  }) {
    this.size = size;
    labelText = TextComponent(
      text: label,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      anchor: Anchor.center,
      position: size / 2,
    );
    add(labelText);
  }

  void setLabel(String label) {
    labelText.text = label;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    pressed = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    pressed = false;
    onPressed();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    super.onTapCancel(event);
    pressed = false;
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final button = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    final topColor = pressed ? const Color(0xFF1B88A8) : const Color(0xFF2AB7DE);
    final bottomColor = pressed ? const Color(0xFF166E88) : const Color(0xFF1A8DB2);

    canvas.drawRRect(
      button,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor],
        ).createShader(rect),
    );

    canvas.drawRRect(
      button,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFBEF3FF),
    );
  }
}

class Asteroid extends PositionComponent with CollisionCallbacks {
  final double speed;

  final Random random = Random();

  late final double asteroidSize;

  Asteroid({required this.speed});

  @override
  Future<void> onLoad() async {
    asteroidSize = 70 + random.nextDouble() * 40;

    size = Vector2.all(asteroidSize);

    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.x -= speed * dt;

    if (position.x < -size.x) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.deepOrange;

    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);

    /// Craters
    canvas.drawCircle(
      Offset(size.x * 0.35, size.y * 0.4),
      size.x * 0.08,
      Paint()..color = Colors.black26,
    );

    canvas.drawCircle(
      Offset(size.x * 0.7, size.y * 0.65),
      size.x * 0.12,
      Paint()..color = Colors.black26,
    );
  }
}

class Coin extends PositionComponent with CollisionCallbacks {
  final double speed;

  Coin({required this.speed});

  @override
  Future<void> onLoad() async {
    size = Vector2.all(30);
    anchor = Anchor.center;

    add(
      CircleHitbox.relative(
        1.0,
        parentSize: size,
        anchor: Anchor.center,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.x -= speed * dt;

    if (position.x < -size.x) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    canvas.drawCircle(
      center,
      size.x / 2,
      Paint()..color = const Color(0xFFFFD94D),
    );

    canvas.drawCircle(
      center,
      size.x * 0.34,
      Paint()..color = const Color(0xFFFFF3B0),
    );

    canvas.drawCircle(
      Offset(size.x * 0.38, size.y * 0.36),
      size.x * 0.1,
      Paint()..color = Colors.white.withAlpha(180),
    );
  }
}

/// ======================================
/// DISTRACTION / FAKE EXPLOSION
/// ======================================
///
/// ADHD Design Notes:
/// - Flashy visual distraction
/// - Brief lifespan
/// - High stimulation
/// - Non-dangerous visual noise
///

class FakeExplosion extends PositionComponent with CollisionCallbacks {
  final Random random = Random();

  late Paint explosionPaint;

  double radius = 6;

  double life = 0.5;

  @override
  Future<void> onLoad() async {
    size = Vector2.all(72);
    anchor = Anchor.center;

    explosionPaint = Paint()..color = Colors.yellowAccent;

    add(CircleHitbox.relative(1.0, parentSize: size, anchor: Anchor.center));

    /// Random scale
    scale = Vector2.all(0.55 + random.nextDouble() * 0.85);

    /// Pop animation
    add(
      ScaleEffect.to(
        Vector2.all(1.25),
        EffectController(duration: 0.25, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    life -= dt;

    radius += 150 * dt;

    angle += dt * 1.5;

    if (life <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final outerRadius = radius * 0.9;

    /// Outer glow
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()..color = Colors.orangeAccent.withAlpha(50),
    );

    /// Main explosion
    for (int i = 0; i < 8; i++) {
      final angleStep = (pi * 2 / 8) * i + angle;

      final x = center.dx + cos(angleStep) * outerRadius;
      final y = center.dy + sin(angleStep) * outerRadius;

      canvas.drawCircle(Offset(x, y), 12, explosionPaint);
    }

    /// Center flash
    canvas.drawCircle(center, outerRadius * 0.35, Paint()..color = Colors.white);
  }
}

class SpaceBackground extends PositionComponent with HasGameReference {
  final Random random = Random();

  final List<StarParticle> smallStars = [];
  final List<StarParticle> bigStars = [];

  @override
  Future<void> onLoad() async {
    size = game.size;

    /// Small distant stars
    for (int i = 0; i < 90; i++) {
      smallStars.add(
        StarParticle(
          position: Vector2(
            random.nextDouble() * size.x,
            random.nextDouble() * size.y,
          ),
          radius: 1.5,
          speed: 40 + random.nextDouble() * 20,
        ),
      );
    }

    /// Bigger closer stars
    for (int i = 0; i < 35; i++) {
      bigStars.add(
        StarParticle(
          position: Vector2(
            random.nextDouble() * size.x,
            random.nextDouble() * size.y,
          ),
          radius: 3,
          speed: 80 + random.nextDouble() * 40,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _updateStars(smallStars, dt);
    _updateStars(bigStars, dt);
  }

  void _updateStars(List<StarParticle> stars, double dt) {
    for (final star in stars) {
      star.position.x -= star.speed * dt;

      /// Respawn on right side
      if (star.position.x < -10) {
        star.position.x = size.x + 10;
        star.position.y = random.nextDouble() * size.y;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    final bgPaint = Paint()..color = const Color(0xFF050816);

    canvas.drawRect(rect, bgPaint);

    /// Small stars
    for (final star in smallStars) {
      canvas.drawCircle(
        Offset(star.position.x, star.position.y),
        star.radius,
        Paint()..color = Colors.white.withAlpha(60),
      );
    }

    /// Big stars
    for (final star in bigStars) {
      canvas.drawCircle(
        Offset(star.position.x, star.position.y),
        star.radius,
        Paint()..color = Colors.white,
      );
    }
  }
}

class StarParticle {
  Vector2 position;

  double radius;

  double speed;

  StarParticle({
    required this.position,
    required this.radius,
    required this.speed,
  });
}
