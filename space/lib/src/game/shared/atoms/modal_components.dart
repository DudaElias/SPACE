import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameModalStyle {
  const GameModalStyle({
    required this.panelTopColor,
    required this.panelBottomColor,
    required this.panelBorderColor,
    required this.panelGlowColor,
    required this.buttonTopColor,
    required this.buttonBottomColor,
    required this.buttonPressedTopColor,
    required this.buttonPressedBottomColor,
    required this.buttonBorderColor,
    this.buttonTextColor = const Color(0xFFFFFFFF),
  });

  final Color panelTopColor;
  final Color panelBottomColor;
  final Color panelBorderColor;
  final Color panelGlowColor;
  final Color buttonTopColor;
  final Color buttonBottomColor;
  final Color buttonPressedTopColor;
  final Color buttonPressedBottomColor;
  final Color buttonBorderColor;
  final Color buttonTextColor;

  static const GameModalStyle shared = GameModalStyle(
    panelTopColor: Color(0xEE111F39),
    panelBottomColor: Color(0xEE0A1429),
    panelBorderColor: Color(0xFF62D5FF),
    panelGlowColor: Color(0xFF9EEAFF),
    buttonTopColor: Color(0xFF2AB7DE),
    buttonBottomColor: Color(0xFF1A8DB2),
    buttonPressedTopColor: Color(0xFF1B88A8),
    buttonPressedBottomColor: Color(0xFF166E88),
    buttonBorderColor: Color(0xFFBEF3FF),
  );

  static const GameModalStyle success = GameModalStyle.shared;

  GameModalStyle copyWithInverse() {
    return GameModalStyle(
      panelTopColor: panelTopColor,
      panelBottomColor: panelBottomColor,
      panelBorderColor: panelBorderColor,
      panelGlowColor: panelGlowColor,
      buttonTopColor: const Color(0xFF3A5068),
      buttonBottomColor: const Color(0xFF243447),
      buttonPressedTopColor: const Color(0xFF2C3E50),
      buttonPressedBottomColor: const Color(0xFF1A2530),
      buttonBorderColor: const Color(0xFF5A7A9A),
      buttonTextColor: buttonTextColor,
    );
  }

  static const GameModalStyle danger = GameModalStyle(
    panelTopColor: Color(0xEE33161C),
    panelBottomColor: Color(0xEE170D18),
    panelBorderColor: Color(0xFFFF8F8F),
    panelGlowColor: Color(0xFFFFC8C8),
    buttonTopColor: Color(0xFF2AB7DE),
    buttonBottomColor: Color(0xFF1A8DB2),
    buttonPressedTopColor: Color(0xFF1B88A8),
    buttonPressedBottomColor: Color(0xFF166E88),
    buttonBorderColor: Color(0xFFBEF3FF),
  );
}

class GameModalBackdrop extends RectangleComponent with TapCallbacks {
  GameModalBackdrop({Color color = const Color(0xCC020617), this.onBackdropTap})
      : super(paint: Paint()..color = color);

  final VoidCallback? onBackdropTap;

  @override
  @mustCallSuper
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    onBackdropTap?.call();
  }
}

class GameModalShell extends PositionComponent with TapCallbacks {
  GameModalShell({required this.style, required super.size}) : super(anchor: Anchor.center);

  final GameModalStyle style;

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [style.panelTopColor, style.panelBottomColor],
    );
    final panel = RRect.fromRectAndRadius(rect, const Radius.circular(22));

    canvas.drawRRect(
      panel,
      Paint()..shader = gradient.createShader(rect),
    );

    canvas.drawRRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = style.panelBorderColor.withAlpha(170),
    );

    canvas.drawRRect(
      panel.inflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = style.panelGlowColor.withAlpha(70),
    );
  }
}

class GameModalActionButton extends PositionComponent with TapCallbacks {
  GameModalActionButton({
    required String label,
    required this.onPressed,
    required this.style,
    Vector2? size,
  }) : super(size: size ?? Vector2(210, 48), anchor: Anchor.center) {
    _labelText = TextComponent(
      text: label,
      anchor: Anchor.center,
      position: this.size / 2,
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: style.buttonTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  final VoidCallback onPressed;
  final GameModalStyle style;

  late final TextComponent _labelText;
  bool _pressed = false;

  void setLabel(String label) {
    _labelText.text = label;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_labelText);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    _pressed = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    _pressed = false;
    onPressed();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    super.onTapCancel(event);
    _pressed = false;
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final button = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    final topColor = _pressed ? style.buttonPressedTopColor : style.buttonTopColor;
    final bottomColor = _pressed ? style.buttonPressedBottomColor : style.buttonBottomColor;

    canvas.drawRRect(
      button,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor],
        ).createShader(rect),
    );

    canvas.drawRRect(
      button,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = style.buttonBorderColor.withAlpha(210),
    );
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return point.x >= 0 && point.y >= 0 && point.x <= size.x && point.y <= size.y;
  }
}
