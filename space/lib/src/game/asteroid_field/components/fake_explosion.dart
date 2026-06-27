import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class FakeExplosion extends PositionComponent with CollisionCallbacks {
  FakeExplosion();

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

    scale = Vector2.all(0.55 + random.nextDouble() * 0.85);

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

    canvas.drawCircle(
      center,
      outerRadius,
      Paint()..color = Colors.orangeAccent.withAlpha(50),
    );

    for (int i = 0; i < 8; i++) {
      final angleStep = (pi * 2 / 8) * i + angle;
      final x = center.dx + cos(angleStep) * outerRadius;
      final y = center.dy + sin(angleStep) * outerRadius;

      canvas.drawCircle(Offset(x, y), 12, explosionPaint);
    }

    canvas.drawCircle(center, outerRadius * 0.35, Paint()..color = Colors.white);
  }
}