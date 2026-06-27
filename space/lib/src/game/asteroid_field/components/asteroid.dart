import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Asteroid extends PositionComponent with CollisionCallbacks {
  Asteroid({required this.speed});

  final double speed;
  final Random random = Random();
  late final double asteroidSize;

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