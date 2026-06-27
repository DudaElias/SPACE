import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:space/src/game/shared/atoms/button.dart';
import 'package:space/src/game/game.dart';

class Menu extends Component with HasGameReference<SpaceGame> {
  Menu();

  late final SpriteComponent _logo;
  late final RoundedButton _button1;
  late final RoundedButton _button2;

  @override
  Future<void> onMount() async {
    super.onMount();
    try {
      // Check if image is loaded
      final logoImage = game.images.fromCache('logo.png');

      // Add components to scene
      addAll( [
              _logo = SpriteComponent(
        sprite: Sprite(logoImage),
        size: Vector2(450, 450),
        anchor: Anchor.center
      ),
      _button1 = RoundedButton(
        text: 'Iniciar Missão',
        action: () => game.router.pushNamed('story-mode'),
        color: const Color(0xffFF986A),
      ),
      _button2 = RoundedButton(
        text: 'Mini Jogos',
        action: () => game.router.pushNamed('minigame-selector'),
        color: const Color(0xffFF986A),
      )
      ]);
    } catch (e, st) {
      debugPrint('ERROR in Menu onMount: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isMounted) {
      _logo.position = Vector2(size.x / 2, size.y / 3);
      _button1.position = Vector2(size.x / 2, _logo.y + 200);
      _button2.position = Vector2(size.x / 2, _logo.y + 280);
    }
  }
}