import 'package:flame/components.dart';

class Player extends SpriteComponent {
  Player() :
    super(size: Vector2.all(200), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('Car.png');
  }
}