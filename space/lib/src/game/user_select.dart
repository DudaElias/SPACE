import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:space/src/game/game.dart';
import 'package:space/src/game/shared/atoms/button.dart';
import 'package:space/src/game/shared/molecules/database.dart';
import 'package:space/src/game/shared/molecules/game_modal.dart';
import 'package:space/src/game/shared/settings.dart';

class UserSelectScreen extends Component with HasGameReference<SpaceGame> {
  List<({int id, String name})> _users = [];
  int _nextId = 1;
  bool _dbFailed = false;
  bool _laidOut = false;
  GameModal? _activeModal;

  @override
  Future<void> onLoad() async {
    await _loadUsers();
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
    if (!isMounted) return;
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
    final savedModal = _activeModal;
    removeAll(children);
    _activeModal = null;
    final size = game.size;
    final cx = size.x / 2;

    add(
      TextComponent(
        text: 'Quem está jogando?',
        textRenderer: TextPaint(
          style: TextStyle(
            fontFamily: GoogleFonts.silkscreen().fontFamily,
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        anchor: Anchor.center,
        position: Vector2(cx, size.y * 0.15),
      ),
    );

    double y = size.y * 0.42;

    if (_users.isEmpty && !_dbFailed) {
      add(
        TextComponent(
          text: 'Nenhum jogador ainda.\nCrie o primeiro!',
          textRenderer: TextPaint(
            style: TextStyle(
              fontFamily: GoogleFonts.silkscreen().fontFamily,
              color: Colors.white54,
              fontSize: 16,
              height: 1.6,
            ),
          ),
          anchor: Anchor.center,
          position: Vector2(cx, y - 20),
        ),
      );
    }

    for (int i = 0; i < _users.length; i++) {
      final user = _users[i];
      final btnPosition = Vector2(cx, y);
      final playerBtn = RoundedButton(
        text: user.name.toUpperCase(),
        action: () { _selectUser(user.id); },
        color: const Color(0xFF1F3A5F),
        position: btnPosition,
      );
      add(playerBtn);

      final deleteBtn = _DeleteButton(
        position: Vector2(cx + 160, y),
        onTap: () => Future.microtask(() => _confirmDelete(user.id, user.name)),
      );
      add(deleteBtn);

      y += 68;
    }

    add(RoundedButton(
      text: 'Novo Jogador',
      action: _newUser,
      color: const Color(0xffFF986A),
      position: Vector2(cx, _users.isEmpty ? size.y * 0.48 : y),
    ));

    if (_dbFailed) {
      add(TextComponent(
        text: '(jogadores não serão salvos)',
        textRenderer: TextPaint(
          style: TextStyle(
            fontFamily: GoogleFonts.silkscreen().fontFamily,
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
        anchor: Anchor.center,
        position: Vector2(cx, size.y * 0.90),
      ));
    }

    if (savedModal != null) {
      _activeModal = savedModal;
      savedModal.layoutForSize(game.size);
      add(savedModal);
    }
  }

  void _selectUser(int id) {
    _activeModal?.removeFromParent();
    _activeModal = null;
    GameSettings.instance.currentUserId = id;
    game.loadUserUnlocks(id);
    game.loadUserTutorials(id);
    _loadStoryProgress(id).whenComplete(() {
      game.router.pushNamed('home');
    });
  }

  Future<void> _loadStoryProgress(int userId) async {
    try {
      final helper = await DatabaseHelper.getInstance();
      game.storyChapter = await helper.getUserStoryProgress(userId);
    } catch (_) {
      game.storyChapter = 0;
    }
  }

  Future<void> _newUser() async {
    final name = await game.requestPlayerName();
    if (name == null || name.trim().isEmpty) return;

    final trimmed = name.trim();
    if (_users.any((u) => u.name.toUpperCase() == trimmed.toUpperCase())) return;

    int id = _nextId++;
    try {
      final helper = await DatabaseHelper.getInstance();
      id = await helper.insertUser(trimmed);
    } catch (_) {}
    _users.add((id: id, name: trimmed));
    _rebuild();
  }

  void _confirmDelete(int userId, String userName) {
    _activeModal?.removeFromParent();
    _activeModal = GameModal(
      title: 'Remover Jogador',
      message: 'Tem certeza que deseja\nremover "$userName"?',
      buttonText: 'Sim, remover',
      onPressed: () {
        _activeModal?.removeFromParent();
        _activeModal = null;
        _deleteUser(userId);
      },
      secondaryButtonText: 'Cancelar',
      onSecondaryPressed: () {
        _activeModal?.removeFromParent();
        _activeModal = null;
      },
      onBackdropTap: () {
        _activeModal?.removeFromParent();
        _activeModal = null;
      },
      style: GameModalStyle.danger,
      panelSize: Vector2(440, 240),
    );
    _activeModal!.layoutForSize(game.size);
    add(_activeModal!);
  }

  Future<void> _deleteUser(int userId) async {
    try {
      final helper = await DatabaseHelper.getInstance();
      await helper.deleteUser(userId);
    } catch (_) {}
    _users.removeWhere((u) => u.id == userId);
    _rebuild();
  }
}

class _DeleteButton extends PositionComponent with TapCallbacks {
  _DeleteButton({required super.position, required this.onTap})
    : super(size: Vector2.all(28), anchor: Anchor.center, priority: 50);

  final VoidCallback onTap;

  @override
  void render(Canvas canvas) {
    final circlePaint = Paint()..color = Colors.white.withValues(alpha: 0.18);
    canvas.drawCircle(const Offset(14, 14), 12, circlePaint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(8, 8), const Offset(20, 20), linePaint);
    canvas.drawLine(const Offset(20, 8), const Offset(8, 20), linePaint);
  }

  @override
  void onTapUp(TapUpEvent event) => onTap();
}
