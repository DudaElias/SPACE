import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:space/src/game/components/back_button.dart'
    show SimpleBackButton;
import 'package:space/src/game/game.dart';

class AsteroidField extends Component with HasGameReference<SpaceGame> {
  @override
  Future<void> onLoad() async {
    addAll([
      TextComponent(
          text: 'Campo de asteróides',
          textRenderer: TextPaint(
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
        ..anchor = Anchor.center
        ..position = Vector2(game.size.x / 2, game.size.y / 2),
    ]);
  }

  final hudComponents = <Component>[];

  @override
  void onMount() {
    hudComponents.addAll([SimpleBackButton()]);
    game.camera.viewport.addAll(hudComponents);
  }

  @override
  void onRemove() {
    game.camera.viewport.removeAll(hudComponents);
    super.onRemove();
  }
}
