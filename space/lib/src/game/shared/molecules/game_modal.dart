import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:space/src/game/shared/atoms/modal_components.dart';
export 'package:space/src/game/shared/atoms/modal_components.dart';

class GameModal extends PositionComponent with DragCallbacks {
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

  double _scrollOffset = 0;
  double _maxScroll = 0;
  double _visibleMsgHeight = 0;
  double _fullMsgHeight = 0;

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
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: titleColor,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    _visibleMsgHeight = panelSize.y - 120.0;

    final tp = TextPainter(
      text: TextSpan(
        text: message,
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          fontSize: 18,
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: panelSize.x - 80);
    _fullMsgHeight = tp.height;
    if (_fullMsgHeight < _visibleMsgHeight) _fullMsgHeight = _visibleMsgHeight;

    _messageText = TextBoxComponent(
      text: message,
      size: Vector2(panelSize.x - 80, _fullMsgHeight),
      anchor: Anchor.topCenter,
      priority: 102,
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
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
    size = gameSize;

    _backdrop
      ..position = Vector2.zero()
      ..size = gameSize
      ..anchor = Anchor.topLeft;

    _panel.position = gameSize / 2;
    _titleText.position = _panel.position + Vector2(0, -panelSize.y / 2 + 34);
    _button.position = _panel.position + Vector2(0, panelSize.y / 2 - 34);

    _visibleMsgHeight = panelSize.y - 120.0;
    _maxScroll = (_fullMsgHeight - _visibleMsgHeight).clamp(0.0, 2000.0);
    if (_scrollOffset > _maxScroll) _scrollOffset = _maxScroll;
    if (_scrollOffset < 0) _scrollOffset = 0;

    _messageText.position = _panel.position + Vector2(0, -panelSize.y / 2 + 60 - _scrollOffset);
    _pendingLayoutSize = null;
  }

  void layoutForSize(Vector2 gameSize) {
    if (!isLoaded) {
      _pendingLayoutSize = gameSize.clone();
      return;
    }

    _applyLayout(gameSize);
    _pendingLayoutSize = null;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_maxScroll > 0) {
      _drawScrollbar(canvas);
    }
  }

  void _drawScrollbar(Canvas canvas) {
    final panelRight = _panel.position.x + panelSize.x / 2;
    final panelTop = _panel.position.y - panelSize.y / 2;
    final barX = panelRight - 14;
    final barTop = panelTop + 60.0;
    final barHeight = _visibleMsgHeight;
    final barW = 6.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, barTop, barW, barHeight), const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );

    if (_maxScroll > 0) {
      final thumbH = (barHeight * barHeight / (_visibleMsgHeight + _maxScroll)).clamp(20.0, barHeight);
      final thumbY = barTop + (_scrollOffset / _maxScroll) * (barHeight - thumbH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(barX, thumbY, barW, thumbH), const Radius.circular(3)),
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_maxScroll <= 0) return;
    _scrollOffset -= event.canvasDelta.y;
    if (_scrollOffset < 0) _scrollOffset = 0;
    if (_scrollOffset > _maxScroll) _scrollOffset = _maxScroll;
    _messageText.position = _messageText.position..y = _panel.position.y - panelSize.y / 2 + 60 - _scrollOffset;
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
    if (message != null) {
      _messageText.text = message;
      final tp = TextPainter(
        text: TextSpan(
          text: message,
          style: TextStyle(
            fontFamily: GoogleFonts.silkscreen().fontFamily,
            fontSize: 18,
            height: 1.3,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout(maxWidth: panelSize.x - 80);
      _fullMsgHeight = tp.height;
      if (_fullMsgHeight < _visibleMsgHeight) _fullMsgHeight = _visibleMsgHeight;
      _messageText.size = Vector2(panelSize.x - 80, _fullMsgHeight);
      _maxScroll = (_fullMsgHeight - _visibleMsgHeight).clamp(0.0, 2000.0);
      if (_scrollOffset > _maxScroll) _scrollOffset = _maxScroll;
      _messageText.position = _messageText.position..y = _panel.position.y - panelSize.y / 2 + 60 - _scrollOffset;
    }
    if (buttonText != null) _button.setLabel(buttonText);
  }
}
