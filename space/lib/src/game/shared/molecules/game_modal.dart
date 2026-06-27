import 'package:flame/components.dart';
import 'package:flutter/material.dart';
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
    this.messageColor = const Color(0xFFCBD5E1),
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
  late TextBoxComponent _messageText;
  late GameModalActionButton _button;
  Vector2? _pendingLayoutSize;
  bool _uiReady = false;
  String _pendingTitle = '';
  String _pendingMessage = '';
  String _pendingButtonText = '';

  @override
  Future<void> onLoad() async {
    _backdrop = GameModalBackdrop();
    _panel = GameModalShell(size: panelSize, style: style)..priority = 101;

    _titleText = TextComponent(
      text: title,
      anchor: Anchor.topCenter,
      priority: 102,
      textRenderer: TextPaint(
        style: TextStyle(
          color: titleColor,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final messageBoxHeight = panelSize.y - 130;
    _messageText = TextBoxComponent(
      text: message,
      size: Vector2(panelSize.x - 80, messageBoxHeight < 50 ? 50 : messageBoxHeight),
      anchor: Anchor.topCenter,
      priority: 102,
      textRenderer: TextPaint(
        style: TextStyle(
          color: messageColor,
          fontSize: 18,
          height: 1.3,
        ),
      ),
    );

    _button = GameModalActionButton(
      label: buttonText,
      onPressed: onPressed,
      style: style,
    )..priority = 102;

    addAll([_backdrop, _panel, _titleText, _messageText, _button]);
    _uiReady = true;

    if (_pendingTitle.isNotEmpty) _titleText.text = _pendingTitle;
    if (_pendingMessage.isNotEmpty) _messageText.text = _pendingMessage;
    if (_pendingButtonText.isNotEmpty) _button.setLabel(_pendingButtonText);

    final targetSize = _pendingLayoutSize ?? findGame()!.size;
    _applyLayout(targetSize);
  }

  void _applyLayout(Vector2 gameSize) {
    _backdrop
      ..position = Vector2.zero()
      ..size = gameSize
      ..anchor = Anchor.topLeft;

    _panel.position = gameSize / 2;
    _titleText.position = _panel.position + Vector2(0, -96);
    _messageText.position = _panel.position + Vector2(0, -36);
    _button.position = _panel.position + Vector2(0, 84);
  }

  void layoutForSize(Vector2 gameSize) {
    if (!isLoaded) {
      _pendingLayoutSize = gameSize.clone();
      return;
    }

    _applyLayout(gameSize);
    _pendingLayoutSize = null;
  }

  void configure({
    String? title,
    String? message,
    String? buttonText,
  }) {
    if (!_uiReady) {
      if (title != null) _pendingTitle = title;
      if (message != null) _pendingMessage = message;
      if (buttonText != null) _pendingButtonText = buttonText;
      return;
    }

    if (title != null) _titleText.text = title;
    if (message != null) _messageText.text = message;
    if (buttonText != null) _button.setLabel(buttonText);
  }
}
