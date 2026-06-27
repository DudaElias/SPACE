import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Coin extends PositionComponent with CollisionCallbacks {
  Coin({required this.speed});

  final double speed;

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

    canvas.drawCircle(center, size.x / 2, Paint()..color = const Color(0xFFFFD94D));
    canvas.drawCircle(center, size.x * 0.34, Paint()..color = const Color(0xFFFFF3B0));
    canvas.drawCircle(
      Offset(size.x * 0.38, size.y * 0.36),
      size.x * 0.1,
      Paint()..color = Colors.white.withAlpha(180),
    );
  }
}