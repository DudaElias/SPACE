import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:space/src/game/entities/player.dart';

void main() {
  runApp(
    GameWidget(
      game: MyGame(),
      backgroundBuilder: (context) => Container(color: Colors.black),
    ),
  );
}

class MyGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    // Add player at center of screen
    add(Player());
  }
}