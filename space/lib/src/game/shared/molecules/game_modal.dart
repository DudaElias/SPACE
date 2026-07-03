import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:space/src/game/shared/atoms/modal_components.dart';
export 'package:space/src/game/shared/atoms/modal_components.dart';

class GameModal extends PositionComponent {
  GameModal({
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
    this.style = GameModalStyle.shared,
    this.titleColor = const Color(0xFFE2E8F0),
    this.messageColor = const Color(0xFFE2E8F0),
    Vector2? panelSize,
  }) : panelSize = panelSize ?? Vector2(480, 260),
       super(priority: 100);

  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;
  final GameModalStyle style;
  final Color titleColor;
  final Color messageColor;
  final Vector2 panelSize;

  late GameModalBackdrop _backdrop;
  late GameModalShell _panel;
  late TextComponent _titleText;
  late GameModalActionButton _button;
  ScrollTextBoxComponent<TextPaint>? _msgComponent;
  Vector2? _pendingLayoutSize;
  bool _uiReady = false;
  String _pendingMessage = '';

  @override
  Future<void> onLoad() async {
    _backdrop = GameModalBackdrop();
    _panel = GameModalShell(size: panelSize, style: style)..priority = 101;

    _titleText = TextComponent(
      text: title,
      anchor: Anchor.topCenter,
      priority: 102,
      textRenderer: TextPaint(
        style: TextStyle(fontFamily: GoogleFonts.silkscreen().fontFamily, color: titleColor, fontSize: 28, fontWeight: FontWeight.w700),
      ),
    );

    _button = GameModalActionButton(
      label: buttonText,
      onPressed: onPressed,
      style: style,
    )..priority = 102;

    addAll([_backdrop, _panel, _titleText, _button]);
    _uiReady = true;

    final targetSize = _pendingLayoutSize ?? findGame()!.size;
    _applyLayout(targetSize);
  }

  void _applyLayout(Vector2 gameSize) {
    size = gameSize;
    _backdrop..position = Vector2.zero()..size = gameSize..anchor = Anchor.topLeft;
    _panel.position = gameSize / 2;
    _titleText.position = _panel.position + Vector2(0, -panelSize.y / 2 + 36);
    _button.position = _panel.position + Vector2(0, panelSize.y / 2 - 36);

    final text = _pendingMessage.isNotEmpty ? _pendingMessage : message;
    final renderer = TextPaint(
      style: TextStyle(fontFamily: GoogleFonts.silkscreen().fontFamily, color: messageColor, fontSize: 18, height: 1.3),
    );

    _msgComponent?.removeFromParent();
    final msg = ScrollTextBoxComponent<TextPaint>(
      size: Vector2(panelSize.x - 80, panelSize.y - 150),
      text: text,
      textRenderer: renderer,
      boxConfig: const TextBoxConfig(timePerChar: 0),
      anchor: Anchor.topCenter,
      position: Vector2(gameSize.x / 2, gameSize.y / 2 - panelSize.y / 2 + 80),
      priority: 102,
      onComplete: () {
        final clip = _msgComponent?.children.firstOrNull;
        if (clip != null && clip.children.isNotEmpty) {
          (clip.children.first as PositionComponent).position.y = 0;
        }
      },
    );
    _msgComponent = msg;
    add(msg);
    _pendingLayoutSize = null;
  }

  void layoutForSize(Vector2 gameSize) {
    if (!isLoaded) { _pendingLayoutSize = gameSize.clone(); return; }
    _applyLayout(gameSize);
    _pendingLayoutSize = null;
  }

  void configure({String? title, String? message, String? buttonText}) {
    if (!_uiReady) return;
    if (title != null) _titleText.text = title;
    if (message != null) { _pendingMessage = message; _applyLayout(findGame()!.size); }
    if (buttonText != null) _button.setLabel(buttonText);
  }
}
