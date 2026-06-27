import 'package:flame/components.dart';

class StarParticle {
  StarParticle({
    required this.position,
    required this.radius,
    required this.speed,
  });

  Vector2 position;
  double radius;
  double speed;
}