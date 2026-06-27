import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'star_particle.dart';

class SpaceBackground extends PositionComponent with HasGameReference {
  final Random random = Random();

  final List<StarParticle> smallStars = [];
  final List<StarParticle> bigStars = [];
  bool _initialized = false;

  @override
  Future<void> onLoad() async {
    // Size is assigned in onGameResize once the game layout is ready.
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);

    size = canvasSize;

    if (_initialized) {
      return;
    }

    _initialized = true;

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

      if (star.position.x < -10) {
        star.position.x = size.x + 10;
        star.position.y = random.nextDouble() * size.y;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    canvas.drawRect(rect, Paint()..color = const Color(0xFF050816));

    for (final star in smallStars) {
      canvas.drawCircle(
        Offset(star.position.x, star.position.y),
        star.radius,
        Paint()..color = Colors.white.withAlpha(60),
      );
    }

    for (final star in bigStars) {
      canvas.drawCircle(
        Offset(star.position.x, star.position.y),
        star.radius,
        Paint()..color = Colors.white,
      );
    }
  }
}