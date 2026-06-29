import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:space/src/game/game.dart';
import 'package:space/src/game/shared/molecules/database.dart';
import 'package:space/src/game/shared/atoms/back_button.dart';

class RankingScreen extends Component with HasGameReference<SpaceGame>, TapCallbacks {
  String _selectedTab = 'minigame-1';
  static const _tabs = [
    ('minigame-1', 'Painel'),
    ('minigame-2', 'Asteroides'),
    ('minigame-3', 'Conserto'),
  ];
  List<Map<String, dynamic>> _entries = [];

  @override
  Future<void> onLoad() async {
    await _loadRanking();
  }

  Future<void> _loadRanking() async {
    final helper = await DatabaseHelper.getInstance();
    _entries = await helper.getRanking(_selectedTab);
    _rebuild();
  }

  void _rebuild() {
    if (!isLoaded) return;
    removeAll(children);
    final s = game.size;

    add(TextComponent(
      text: 'Ranking',
      textRenderer: TextPaint(style: TextStyle(fontFamily: GoogleFonts.silkscreen().fontFamily, color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      anchor: Anchor.topCenter,
      position: Vector2(s.x / 2, 40),
    ));

    double tx = s.x / 2 - 140;
    for (final tab in _tabs) {
      final active = tab.$1 == _selectedTab;
      final tb = _TabButton(tab.$1, tab.$2, Vector2(tx, 80), active, () {
        _selectedTab = tab.$1;
        _loadRanking();
      });
      add(tb);
      tx += 95;
    }

    double y = 140;
    final header = 'Jogador'.padRight(12) + 'Resultado'.padRight(10) + 'Pts'.padRight(6) + 'Dificuldade';
    add(TextComponent(
      text: header,
      textRenderer: TextPaint(style: TextStyle(fontFamily: GoogleFonts.silkscreen().fontFamily, color: const Color(0xFFFFD94D), fontSize: 12, fontWeight: FontWeight.w600)),
      anchor: Anchor.topLeft,
      position: Vector2(40, y),
    ));
    y += 28;

    for (final e in _entries) {
      final nm = ((e['user_name'] as String?) ?? '?').padRight(12).substring(0, 12);
      final rs = e['result'] == 'win' ? 'Venceu' : 'Perdeu';
      final sc = e['score'].toString().padRight(6);
      final df = e['difficulty'] == 'easy' ? 'Facil' : e['difficulty'] == 'medium' ? 'Medio' : 'Dificil';
      add(TextComponent(
        text: '$nm $rs $sc $df',
        textRenderer: TextPaint(style: TextStyle(fontFamily: GoogleFonts.silkscreen().fontFamily, color: Colors.white70, fontSize: 12)),
        anchor: Anchor.topLeft,
        position: Vector2(40, y),
      ));
      y += 24;
    }

    game.camera.viewport.add(SimpleBackButton());
  }
}

class _TabButton extends PositionComponent with TapCallbacks {
  _TabButton(this.tabId, this.label, Vector2 position, bool active, this.onTap)
      : _active = active,
        super(position: position, size: Vector2(90, 36), anchor: Anchor.topLeft);

  final String tabId;
  final String label;
  final VoidCallback onTap;
  bool _active;

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = _active ? const Color(0xffFF986A) : const Color(0xFF1F3A5F),
    );
    final tp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(fontFamily: GoogleFonts.silkscreen().fontFamily, color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2));
  }

  @override
  void onTapUp(TapUpEvent event) => onTap();
}
