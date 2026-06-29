import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Petisco extends PositionComponent with CollisionCallbacks {
  Petisco({required this.speed});

  final double speed;
  late final Sprite _sprite;

  @override
  Future<void> onLoad() async {
    size = Vector2.all(30);
    anchor = Anchor.center;

    final image = await Sprite.load('bone.png');
    _sprite = image;

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
    _sprite.render(canvas, size: size);
  }
}
