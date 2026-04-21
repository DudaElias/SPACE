import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class GameDialogOverlay extends PositionComponent {
  GameDialogOverlay({
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  }) : super(priority: 100);

  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  late final RectangleComponent _backdrop;
  late final RectangleComponent _panel;
  late final TextComponent _titleText;
  late final TextBoxComponent _messageText;
  late final _DialogButton _button;
  Vector2? _pendingLayoutSize;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _backdrop = RectangleComponent(
      paint: Paint()..color = const Color(0xCC020617),
      priority: 100,
    );

    _panel = RectangleComponent(
      size: Vector2(480, 260),
      paint: Paint()..color = const Color(0xFF0F172A),
      anchor: Anchor.center,
      priority: 101,
    );

    _titleText = TextComponent(
      text: title,
      anchor: Anchor.topCenter,
      priority: 102,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    _messageText = TextBoxComponent(
      text: message,
      size: Vector2(400, 92),
      anchor: Anchor.topCenter,
      priority: 102,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 18,
          height: 1.3,
        ),
      ),
    );

    _button = _DialogButton(
      text: buttonText,
      onPressed: onPressed,
    )..priority = 102;

    addAll([_backdrop, _panel, _titleText, _messageText, _button]);

    final Vector2 targetSize = _pendingLayoutSize ?? findGame()!.size;
    layoutForSize(targetSize);
  }

  void layoutForSize(Vector2 gameSize) {
    if (!isLoaded) {
      _pendingLayoutSize = gameSize.clone();
      return;
    }

    size = gameSize;

    _backdrop
      ..position = Vector2.zero()
      ..size = gameSize
      ..anchor = Anchor.topLeft;

    _panel.position = gameSize / 2;
    _titleText.position = _panel.position + Vector2(0, -96);
    _messageText.position = _panel.position + Vector2(0, -36);
    _button.position = _panel.position + Vector2(0, 84);
    _pendingLayoutSize = null;
  }
}

class _DialogButton extends PositionComponent with TapCallbacks {
  _DialogButton({required this.text, required this.onPressed})
    : super(size: Vector2(200, 52), anchor: Anchor.center);

  final String text;
  final VoidCallback onPressed;

  late final RectangleComponent _background;
  late final TextComponent _label;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _background = RectangleComponent(
      size: size,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()..color = const Color(0xFF22C55E),
    );

    _label = TextComponent(
      text: text,
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF0B1120),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    addAll([_background, _label]);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    onPressed();
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return point.x >= 0 && point.y >= 0 && point.x <= size.x && point.y <= size.y;
  }
}
