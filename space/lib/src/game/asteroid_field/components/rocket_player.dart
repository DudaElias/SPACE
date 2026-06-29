import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../asteroid_field.dart';
import 'asteroid.dart';
import 'petisco.dart';
import 'fake_explosion.dart';

class RocketPlayer extends PositionComponent
  with HasGameReference<AsteroidField>, CollisionCallbacks {
  RocketPlayer({
    required this.onAsteroidHit,
    required this.onPetiscoCollected,
    required this.onExplosionHit,
  });

  final VoidCallback onAsteroidHit;
  final ValueChanged<Petisco> onPetiscoCollected;
  final VoidCallback onExplosionHit;

  Vector2 targetPosition = Vector2.zero();
  late Vector2 startPosition;
  late SpriteComponent spriteComponent;

  @override
  Future<void> onLoad() async {
    size = Vector2(200, 150);
    anchor = Anchor.center;

    add(
      RectangleHitbox.relative(
        Vector2.all(0.75),
        parentSize: size,
        anchor: Anchor.center,
      ),
    );

    final sprite = await Sprite.load('icon.png');
    spriteComponent = SpriteComponent(
      sprite: sprite,
      size: size,
      anchor: Anchor.center,
    );
    add(spriteComponent);
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

  void followTouch(Vector2 touchPosition) {
    targetPosition = touchPosition;
  }

  @override
  void update(double dt) {
    super.update(dt);

    position += (targetPosition - position) * 7 * dt;
    position.x = position.x.clamp(size.x / 2, game.size.x - size.x / 2);
    position.y = position.y.clamp(size.y / 2, game.size.y - size.y / 2);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Asteroid) {
      onAsteroidHit();
    } else if (other is Petisco) {
      onPetiscoCollected(other);
    } else if (other is FakeExplosion) {
      onExplosionHit();
    }
  }
}
