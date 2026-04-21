import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:space/src/game/control_panel/control_panel_world.dart';

void main() {
  runApp(
    GameWidget(
      game: MyGame(),
      backgroundBuilder: (context) => Container(color: Colors.black),
    ),
  );
}

class MyGame extends FlameGame {
  World? _activeWorld;

  @override
  Color backgroundColor() => const Color(0xFF060A1A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();
    await openRoute('control_panel');
  }

  Future<void> openRoute(String routeId) async {
    final World nextWorld = switch (routeId) {
      'control_panel' => ControlPanelWorld(),
      _ => ControlPanelWorld(),
    };

    final World? previousWorld = _activeWorld;
    if (previousWorld != null) {
      previousWorld.removeFromParent();
    }

    _activeWorld = nextWorld;
    camera.world = nextWorld;
    await add(nextWorld);
  }
}