import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:space/src/game/shared/sound_manager.dart';

class RoundedButton extends PositionComponent with TapCallbacks {
  RoundedButton({
    required String text,
    required this.action,
    required this.color,
    super.position,
    super.anchor = Anchor.center,
  }) : _text = text {
    size = Vector2(250, 50);
    _updateDrawable();
  }

  String _text;
  final void Function() action;
  final Color color;
  late TextPainter _textDrawable;
  late Offset _textOffset;
  late RRect _rrect;
  late Paint _bgPaint;

  String get text => _text;

  void setText(String newText) {
    _text = newText;
    _updateDrawable();
  }

  void _updateDrawable() {
    _textDrawable = TextPaint(
      style: TextStyle(
        fontSize: 20,
        fontFamily: GoogleFonts.silkscreen().fontFamily,
        color: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w800,
      ),
    ).toTextPainter(_text);
    _textOffset = Offset(
      (size.x - _textDrawable.width) / 2,
      (size.y - _textDrawable.height) / 2,
    );
    _rrect = RRect.fromLTRBR(0, 0, size.x, size.y, Radius.circular(size.y / 2));
    _bgPaint = Paint()..color = color;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(_rrect, _bgPaint);
    _textDrawable.paint(canvas, _textOffset);
  }

  @override
  void onTapDown(TapDownEvent event) {
    SoundManager.instance.playSfx('ui_click');
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
