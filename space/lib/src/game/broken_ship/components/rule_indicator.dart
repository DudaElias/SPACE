import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../broken_ship_controller.dart';

class _RuleIcon extends PositionComponent {
  _RuleIcon()
      : super(
          size: Vector2.all(36),
          anchor: Anchor.center,
        );

  ui.Image? _image;
  bool? _stateIsIntact;

  void setImage(ui.Image image) {
    _image = image;
    _stateIsIntact = null;
  }

  void setStateSymbol(bool isIntact) {
    _stateIsIntact = isIntact;
    _image = null;
  }

  @override
  void render(Canvas canvas) {
    if (_image != null) {
      final sr = Rect.fromLTWH(0, 0, _image!.width.toDouble(), _image!.height.toDouble());
      final dr = Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.drawImageRect(_image!, sr, dr, Paint());
    } else if (_stateIsIntact != null) {
      if (_stateIsIntact!) {
        final bgPaint = Paint()..color = const Color(0xFF22C55E);
        canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, bgPaint);
        final checkPaint = Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;
        final path = Path()
          ..moveTo(size.x * 0.25, size.y * 0.5)
          ..lineTo(size.x * 0.45, size.y * 0.7)
          ..lineTo(size.x * 0.75, size.y * 0.3);
        canvas.drawPath(path, checkPaint);
      } else {
        final bgPaint = Paint()..color = const Color(0xFFEF4444);
        canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, bgPaint);
        final xPaint = Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(size.x * 0.28, size.y * 0.28),
          Offset(size.x * 0.72, size.y * 0.72),
          xPaint,
        );
        canvas.drawLine(
          Offset(size.x * 0.72, size.y * 0.28),
          Offset(size.x * 0.28, size.y * 0.72),
          xPaint,
        );
      }
    }
  }
}

class RuleIndicator extends PositionComponent {
  RuleIndicator()
      : super(
          priority: 10,
          anchor: Anchor.center,
        );

  late final RectangleComponent _panel;
  late final TextComponent _ruleText;
  late final _RuleIcon _iconLeft;
  late final _RuleIcon _iconRight;
  late final TextComponent _arrowText;

  bool _flashing = false;
  double _flashTimer = 0;
  bool _flashVisible = true;

  double _displayedOpacity = 1.0;
  double _targetOpacity = 1.0;

  String _ruleTextStr = '';

  void setFlashing(bool flashing) {
    _flashing = flashing;
    _flashTimer = 0;
    _flashVisible = true;
  }

  void flashBrief() {
    _flashing = true;
    _flashTimer = 0;
    _flashVisible = true;
  }

  void updateRule({
    required String ruleText,
    required String iconLeftPath,
    required String iconRightPath,
    required SortCriterion criterion,
  }) {
    _ruleTextStr = ruleText;

    _ruleText.text = ruleText;

    if (criterion == SortCriterion.state) {
      _iconLeft.setStateSymbol(true);
      _iconRight.setStateSymbol(false);
    } else {
      final images = findGame()!.images;
      _iconLeft.setImage(images.fromCache(iconLeftPath));
      _iconRight.setImage(images.fromCache(iconRightPath));
    }
  }

  void setOpacity(double opacity) {
    _targetOpacity = opacity;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _panel = RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF0F172A),
      anchor: Anchor.center,
      position: size / 2,
    );

    _iconLeft = _RuleIcon()
      ..position = Vector2(60, size.y * 0.35);

    _iconRight = _RuleIcon()
      ..position = Vector2(size.x - 60, size.y * 0.35);

    _arrowText = TextComponent(
      text: '\u2192',
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.35),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    _ruleText = TextComponent(
      text: _ruleTextStr,
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.78),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    addAll([_panel, _iconLeft, _iconRight, _arrowText, _ruleText]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _displayedOpacity += (_targetOpacity - _displayedOpacity) * dt * 6;

    if (_flashing) {
      _flashTimer += dt;
      final period = 0.3;
      _flashVisible = (_flashTimer % period) < (period * 0.5);

      if (_flashTimer > 1.5) {
        _flashing = false;
        _flashVisible = true;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final opacity = _displayedOpacity * (_flashVisible ? 1.0 : 0.2);
    if (opacity <= 0.01) return;

    canvas.saveLayer(size.toRect(), Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: opacity));
    super.render(canvas);
    canvas.restore();
  }
}
