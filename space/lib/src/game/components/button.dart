import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoundedButton extends PositionComponent with TapCallbacks {
  RoundedButton({
    required this.text,
    required this.action,
    required Color color,
    super.position,
    super.anchor = Anchor.center,
  }) : _textDrawable = TextPaint(
         style: TextStyle(
           fontSize: 20,
           fontFamily: GoogleFonts.silkscreen().fontFamily,
           color: const Color(0xFFFFFFFF),
           fontWeight: FontWeight.w800,
         ),
       ).toTextPainter(text) {
    size = Vector2(250, 50);
    _textOffset = Offset(
      (size.x - _textDrawable.width) / 2,
      (size.y - _textDrawable.height) / 2,
    );
    _rrect = RRect.fromLTRBR(0, 0, size.x, size.y, Radius.circular(size.y / 2));
    _bgPaint = Paint()..color = color;
  }

  final String text;
  final void Function() action;
  final TextPainter _textDrawable;
  late final Offset _textOffset;
  late final RRect _rrect;
  late final Paint _bgPaint;

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(_rrect, _bgPaint);
    _textDrawable.paint(canvas, _textOffset);
  }

  @override
  void onTapDown(TapDownEvent event) {
    scale = Vector2.all(1.05);
  }

  @override
  void onTapUp(TapUpEvent event) {
    scale = Vector2.all(1.0);
    action();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    scale = Vector2.all(1.0);
  }
}
