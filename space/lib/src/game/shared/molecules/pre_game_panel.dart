import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../settings.dart';

class PreGameResult {
  const PreGameResult({required this.proceed, this.skipTutorial = false});
  final bool proceed;
  final bool skipTutorial;
}

class PreGamePanel extends PositionComponent with TapCallbacks {
  PreGamePanel._({
    required this.title,
    required this.gameSize,
    required this.showTutorialDefault,
    required this.completer,
  }) : _panelSize = Vector2(480, 360),
       super(size: gameSize, priority: 200);

  final String title;
  final Vector2 gameSize;
  final bool showTutorialDefault;
  final Completer<PreGameResult> completer;
  final Vector2 _panelSize;

  bool _tutorialEnabled = false;

  static Future<PreGameResult> show(
    Component parent, {
    required String title,
    required bool showTutorialDefault,
  }) {
    final game = parent.findGame()!;
    final completer = Completer<PreGameResult>();
    final panel = PreGamePanel._(
      title: title,
      gameSize: game.size,
      showTutorialDefault: showTutorialDefault,
      completer: completer,
    );
    panel._tutorialEnabled = showTutorialDefault;
    parent.add(panel);
    return completer.future;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final cx = gameSize.x / 2;
    final cy = gameSize.y / 2;
    final panelCenter = Vector2(cx, cy);
    final textStyle = TextStyle(
      fontFamily: GoogleFonts.silkscreen().fontFamily,
      color: const Color(0xFFE2E8F0),
    );

    final backdrop = RectangleComponent(
      size: gameSize,
      paint: Paint()..color = const Color(0xCC020617),
      position: Vector2.zero(),
      priority: 0,
    );
    backdrop.addToParent(this);

    final shell = _PreGameShell(size: _panelSize)
      ..position = panelCenter
      ..anchor = Anchor.center
      ..priority = 1;
    add(shell);

    final titleText = TextComponent(
      text: title,
      anchor: Anchor.topCenter,
      priority: 2,
      textRenderer: TextPaint(
        style: textStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
      ),
    )..position = panelCenter + Vector2(0, -_panelSize.y / 2 + 28);
    add(titleText);

    final closeBtn = _PreGameCloseButton(
      position: panelCenter + Vector2(_panelSize.x / 2 - 28, -_panelSize.y / 2 + 28),
      onTap: () {
        removeFromParent();
        completer.complete(const PreGameResult(proceed: false));
      },
    )..priority = 2;
    add(closeBtn);

    final sectionY = panelCenter.y - _panelSize.y / 2 + 80;

    final diffLabel = TextComponent(
      text: 'Dificuldade',
      anchor: Anchor.topCenter,
      priority: 2,
      textRenderer: TextPaint(
        style: textStyle.copyWith(fontSize: 16, color: const Color(0xFF9EEAFF)),
      ),
    )..position = Vector2(cx, sectionY);
    add(diffLabel);

    final diff = GameSettings.instance;
    final btnY = sectionY + 48;
    const btnSpacing = 135.0;

    final btnEasy = _PreGameDiffButton(
      label: 'Fácil',
      selected: diff.difficulty == GameSettings.easy,
      position: Vector2(cx - btnSpacing, btnY),
      onTap: () {
        diff.difficulty = GameSettings.easy;
        _refreshDiffButtons();
      },
    )..priority = 2;
    final btnMedium = _PreGameDiffButton(
      label: 'Médio',
      selected: diff.difficulty == GameSettings.medium,
      position: Vector2(cx, btnY),
      onTap: () {
        diff.difficulty = GameSettings.medium;
        _refreshDiffButtons();
      },
    )..priority = 2;
    final btnHard = _PreGameDiffButton(
      label: 'Difícil',
      selected: diff.difficulty == GameSettings.hard,
      position: Vector2(cx + btnSpacing, btnY),
      onTap: () {
        diff.difficulty = GameSettings.hard;
        _refreshDiffButtons();
      },
    )..priority = 2;

    _diffButtons = [btnEasy, btnMedium, btnHard];
    addAll(_diffButtons);

    final toggleY = btnY + 80;
    _tutorialToggle = _PreGameTutorialToggle(
      position: Vector2(cx, toggleY),
      enabled: _tutorialEnabled,
      onToggled: (v) => _tutorialEnabled = v,
    )..priority = 2;
    add(_tutorialToggle);

    final startBtn = _PreGameStartButton(
      position: Vector2(cx, toggleY + 70),
      onTap: () {
        removeFromParent();
        completer.complete(PreGameResult(
          proceed: true,
          skipTutorial: !_tutorialEnabled,
        ));
      },
    )..priority = 2;
    add(startBtn);
  }

  late List<_PreGameDiffButton> _diffButtons;
  late _PreGameTutorialToggle _tutorialToggle;

  void _refreshDiffButtons() {
    final diff = GameSettings.instance;
    _diffButtons[0].selected = diff.difficulty == GameSettings.easy;
    _diffButtons[1].selected = diff.difficulty == GameSettings.medium;
    _diffButtons[2].selected = diff.difficulty == GameSettings.hard;
  }
}

class _PreGameShell extends PositionComponent with TapCallbacks {
  _PreGameShell({required super.size}) : super(anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xEE111F39), Color(0xEE0A1429)],
    );
    final panel = RRect.fromRectAndRadius(rect, const Radius.circular(22));
    canvas.drawRRect(panel, Paint()..shader = gradient.createShader(rect));
    canvas.drawRRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF62D5FF).withAlpha(170),
    );
    canvas.drawRRect(
      panel.inflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF9EEAFF).withAlpha(70),
    );
  }
}

class _PreGameCloseButton extends PositionComponent with TapCallbacks {
  _PreGameCloseButton({required super.position, required this.onTap})
    : super(size: Vector2.all(32), anchor: Anchor.center);

  final VoidCallback onTap;

  @override
  void render(Canvas canvas) {
    final bgPaint = Paint()..color = Colors.white.withValues(alpha: 0.15);
    canvas.drawCircle(const Offset(16, 16), 14, bgPaint);
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(9, 9), const Offset(23, 23), linePaint);
    canvas.drawLine(const Offset(23, 9), const Offset(9, 23), linePaint);
  }

  @override
  void onTapUp(TapUpEvent event) => onTap();
}

class _PreGameDiffButton extends PositionComponent with TapCallbacks {
  _PreGameDiffButton({
    required String label,
    required this.selected,
    required super.position,
    required this.onTap,
  }) : _label = label,
       super(size: Vector2(110, 40), anchor: Anchor.center);

  final String _label;
  final VoidCallback onTap;
  bool selected;

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    final bgColor = selected ? const Color(0xffFF986A) : const Color(0xFF1F3A5F);
    canvas.drawRRect(rrect, Paint()..color = bgColor);
    final tp = TextPainter(
      text: TextSpan(
        text: _label,
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2));
  }

  @override
  void onTapUp(TapUpEvent event) => onTap();
}

class _PreGameTutorialToggle extends PositionComponent with TapCallbacks {
  _PreGameTutorialToggle({
    required super.position,
    required bool enabled,
    required this.onToggled,
  }) : _enabled = enabled,
       super(size: Vector2(380, 48), anchor: Anchor.center);

  final void Function(bool) onToggled;
  bool _enabled;

  @override
  void render(Canvas canvas) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'Mostrar tutorial',
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: const Color(0xFFCBD5E1),
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(0, (size.y - tp.height) / 2));

    final trackW = 100.0;
    final trackH = 36.0;
    final trackX = size.x - trackW;
    final trackY = (size.y - trackH) / 2;
    final trackRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(trackX, trackY, trackW, trackH),
      const Radius.circular(18),
    );
    final trackColor = _enabled
        ? const Color(0xFF62D5FF).withValues(alpha: 0.5)
        : const Color(0xFF334155).withValues(alpha: 0.4);
    canvas.drawRRect(trackRRect, Paint()..color = trackColor);

    const knobR = 14.0;
    final knobX = _enabled ? trackX + trackW - knobR - 4 : trackX + knobR + 4;
    final knobY = trackY + trackH / 2;
    canvas.drawCircle(Offset(knobX, knobY), knobR, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(knobX, knobY),
      knobR - 2,
      Paint()..color = _enabled ? const Color(0xFF62D5FF) : const Color(0xFF94A3B8),
    );

    final stateTp = TextPainter(
      text: TextSpan(
        text: _enabled ? 'LIG' : 'DESL',
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: Colors.white,
          fontSize: 11,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final stateX = _enabled ? trackX + 9 : trackX + trackW - stateTp.width - 9;
    stateTp.paint(canvas, Offset(stateX, trackY + (trackH - stateTp.height) / 2));

    final hintTp = TextPainter(
      text: TextSpan(
        text: _enabled ? '(recomendado)' : '',
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: const Color(0xFFCBD5E1).withValues(alpha: 0.5),
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    if (_enabled) {
      hintTp.paint(canvas, Offset(0, size.y / 2 + 6));
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    _enabled = !_enabled;
    onToggled(_enabled);
  }
}

class _PreGameStartButton extends PositionComponent with TapCallbacks {
  _PreGameStartButton({required super.position, required this.onTap})
    : super(size: Vector2(240, 50), anchor: Anchor.center);

  final VoidCallback onTap;

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(25),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xffFF986A));
    final tp = TextPainter(
      text: TextSpan(
        text: 'Começar!',
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2));
  }

  @override
  void onTapUp(TapUpEvent event) => onTap();
}
