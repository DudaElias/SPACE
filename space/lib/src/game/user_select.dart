import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:space/src/game/game.dart';
import 'package:space/src/game/shared/atoms/button.dart';
import 'package:space/src/game/shared/molecules/database.dart';
import 'package:space/src/game/shared/settings.dart';

class UserSelectScreen extends Component with HasGameReference<SpaceGame> {
  List<({int id, String name})> _users = [];
  int _nextId = 1;
  bool _dbFailed = false;
  bool _laidOut = false;

  @override
  Future<void> onLoad() async {
    _loadUsers();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_laidOut && game.size.x > 0) {
      _laidOut = true;
      _rebuild();
    }
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    _rebuild();
    _laidOut = true;
  }

  Future<void> _loadUsers() async {
    try {
      final helper = await DatabaseHelper.getInstance();
      final rows = await helper.getUsers();
      _users = rows.map((r) => (id: r['id'] as int, name: r['name'] as String)).toList();
      if (_users.isNotEmpty) _nextId = _users.last.id + 1;
    } catch (_) {
      _dbFailed = true;
    }
    _rebuild();
  }

  void _rebuild() {
    if (!isMounted) return;
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

    double y = size.y * 0.42;
    for (int i = 0; i < _users.length; i++) {
      add(RoundedButton(
        text: _users[i].name,
        action: () { _selectUser(_users[i].id); },
        color: const Color(0xFF1F3A5F),
        position: Vector2(cx, y),
      ));
      y += 68;
    }

    add(RoundedButton(
      text: 'Novo Jogador',
      action: () { _newUser(); },
      color: const Color(0xffFF986A),
      position: Vector2(cx, _users.isEmpty ? size.y * 0.42 : y),
    ));

    if (_dbFailed) {
      add(TextComponent(
        text: '(jogadores não serão salvos)',
        textRenderer: TextPaint(
          style: TextStyle(fontFamily: GoogleFonts.silkscreen().fontFamily, color: Colors.white38, fontSize: 12),
        ),
        anchor: Anchor.center,
        position: Vector2(cx, size.y * 0.90),
      ));
    }
  }

  void _selectUser(int id) {
    GameSettings.instance.currentUserId = id;
    game.loadUserUnlocks(id).whenComplete(() {
      game.router.pushNamed('home');
    });
  }

  void _newUser() async {
    final name = 'Jogador ${_users.length + 1}';
    int id = _nextId++;
    try {
      final helper = await DatabaseHelper.getInstance();
      id = await helper.insertUser(name);
    } catch (_) {}
    _users.add((id: id, name: name));
    _rebuild();
  }
}
