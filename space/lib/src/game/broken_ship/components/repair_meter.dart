import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class RepairMeter extends PositionComponent {
  RepairMeter()
      : super(
          priority: 12,
          anchor: Anchor.center,
          size: Vector2(320, 30),
        );

  late final RectangleComponent _background;
  late final RectangleComponent _fill;
  late final TextComponent _label;

  double _displayedProgress = 0.0;
  double _targetProgress = 0.0;

  void setProgress(double percent) {
    _targetProgress = percent.clamp(0.0, 1.0);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _background = RectangleComponent(
      size: size,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()..color = const Color(0xFF1E293B),
    );

    _fill = RectangleComponent(
      size: Vector2(0, size.y),
      anchor: Anchor.centerLeft,
      position: Vector2(0, size.y / 2),
      paint: Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF22C55E)],
        ).createShader(Rect.fromLTWH(0, 0, size.x, size.y)),
    );

    _label = TextComponent(
      text: 'Reparo: 0%',
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    addAll([_background, _fill, _label]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _displayedProgress += (_targetProgress - _displayedProgress) * dt * 5;

    _fill.size.x = size.x * _displayedProgress;

    final pct = (_displayedProgress * 100).round();
    _label.text = 'Reparo: $pct%';
  }
}
