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

  final List<Component> _hudComponents = [];

  @override
  Future<void> onLoad() async {
    final helper = await DatabaseHelper.getInstance();
    _entries = await helper.getRanking(_selectedTab);
  }

  @override
  void onMount() {
    super.onMount();
    _hudComponents.add(SimpleBackButton());
    game.camera.viewport.addAll(_hudComponents);
    _rebuild();
  }

  @override
  void onRemove() {
    game.camera.viewport.removeAll(_hudComponents);
    super.onRemove();
  }

  Future<void> _loadRanking() async {
    final helper = await DatabaseHelper.getInstance();
    _entries = await helper.getRanking(_selectedTab);
    _rebuild();
  }

  void _rebuild() {
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

    final colJ = s.x * 0.14;
    final colR = s.x * 0.34;
    final colP = s.x * 0.50;
    final colD = s.x * 0.66;
    final colDT = s.x * 0.84;

    final headerStyle = TextStyle(fontFamily: GoogleFonts.silkscreen().fontFamily, color: const Color(0xFFFFD94D), fontSize: 12, fontWeight: FontWeight.w600);
    final rowStyle = TextStyle(fontFamily: GoogleFonts.silkscreen().fontFamily, color: Colors.white70, fontSize: 12);

    double y = 140;
    _addHeaderCell('Jogador', Vector2(colJ, y), headerStyle);
    _addHeaderCell('Resultado', Vector2(colR, y), headerStyle);
    _addHeaderCell('Pts', Vector2(colP, y), headerStyle);
    _addHeaderCell('Dificuldade', Vector2(colD, y), headerStyle);
    _addHeaderCell('Data', Vector2(colDT, y), headerStyle);
    y += 28;

    for (final e in _entries) {
      final nm = ((e['user_name'] as String?) ?? '?');
      final rs = e['result'] == 'win' ? 'Venceu' : 'Perdeu';
      final sc = e['score'].toString();
      final df = _difficultyLabel(e['difficulty'] as String?);
      final dt = _formatDate(e['played_at'] as String?);
      _addRowCell(nm, Vector2(colJ, y), rowStyle);
      _addRowCell(rs, Vector2(colR, y), rowStyle);
      _addRowCell(sc, Vector2(colP, y), rowStyle);
      _addRowCell(df, Vector2(colD, y), rowStyle);
      _addRowCell(dt, Vector2(colDT, y), rowStyle);
      y += 24;
    }
  }
  void _addHeaderCell(String text, Vector2 pos, TextStyle style) {
    add(TextComponent(
      text: text,
      textRenderer: TextPaint(style: style),
      anchor: Anchor.topCenter,
      position: pos,
    ));
  }

  void _addRowCell(String text, Vector2 pos, TextStyle style) {
    add(TextComponent(
      text: text,
      textRenderer: TextPaint(style: style),
      anchor: Anchor.topCenter,
      position: pos,
    ));
  }

  String _difficultyLabel(String? d) {
    if (d == 'easy') return 'Facil';
    if (d == 'medium') return 'Medio';
    return 'Dificil';
  }

  String _formatDate(String? iso) {
    if (iso == null) return '?';
    try {
      final dt = DateTime.parse(iso);
      final dd = dt.day.toString().padLeft(2, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      final yy = (dt.year % 100).toString().padLeft(2, '0');
      return '$dd/$mm/$yy';
    } catch (_) {
      return '?';
    }
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
