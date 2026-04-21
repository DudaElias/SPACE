import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:space/src/game/game.dart';

class SimpleBackButton extends PositionComponent with HasGameReference<SpaceGame>, TapCallbacks {
  SimpleBackButton()
    : _iconPath = Path()
          ..moveTo(22, 8)
          ..lineTo(10, 20)
          ..lineTo(22, 32)
          ..moveTo(12, 20)
          ..lineTo(34, 20),
      super(size: Vector2.all(40), anchor: Anchor.topLeft, position: Vector2(30, 30));

  final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.transparent;
  final Paint _iconPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xffaaaaaa)
    ..strokeWidth = 7;
  final Path _iconPath;

  void action() {
    game.router.pop();
  }
  
  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(8)),
      _borderPaint,
    );
    canvas.drawPath(_iconPath, _iconPaint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _iconPaint.color = const Color(0xffffffff);
  }

  @override
  void onTapUp(TapUpEvent event) {
    _iconPaint.color = const Color(0xffaaaaaa);
    action();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _iconPaint.color = const Color(0xffaaaaaa);
  }
}
