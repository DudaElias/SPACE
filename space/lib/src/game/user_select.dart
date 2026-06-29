import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:space/src/game/game.dart';
import 'package:space/src/game/shared/atoms/button.dart';
import 'package:space/src/game/shared/settings.dart';

class UserSelectScreen extends Component with HasGameReference<SpaceGame> {
  List<({int id, String name})> _users = [];
  int _nextId = 1;

  @override
  Future<void> onLoad() async {
    _rebuild();
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    _rebuild();
  }

  void _rebuild() {
    removeAll(children);
    final size = game.size;
    final cx = size.x / 2;

    add(
      TextComponent(
        text: 'Quem está jogando?',
        textRenderer: TextPaint(
          style: TextStyle(fontFamily: GoogleFonts.silkscreen().fontFamily, color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        anchor: Anchor.center,
        position: Vector2(cx, size.y * 0.18),
      ),
    );

    final totalItems = _users.length + 1;
    final startY = size.y * 0.40 - (totalItems * 35);
    double y = startY;

    for (int i = 0; i < _users.length; i++) {
      add(RoundedButton(
        text: _users[i].name,
        action: () { _selectUser(_users[i].id); },
        color: const Color(0xFF1F3A5F),
        position: Vector2(cx, y),
      ));
      y += 68;
    }

    y += 8;
    add(RoundedButton(
      text: 'Novo Jogador',
      action: () { _newUser(); },
      color: const Color(0xffFF986A),
      position: Vector2(cx, y),
    ));
  }

  void _selectUser(int id) {
    GameSettings.instance.currentUserId = id;
    game.router.pushNamed('home');
  }

  void _newUser() {
    final name = 'Jogador ${_users.length + 1}';
    _users.add((id: _nextId++, name: name));
    _rebuild();
  }
}
