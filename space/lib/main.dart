import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:space/src/game/game.dart';

void main() {
  runApp(
    GameWidget(
      game: SpaceGame(),
      backgroundBuilder: (context) => Container(color: Color.fromARGB(255, 93, 101, 152)),
    )
 );
}