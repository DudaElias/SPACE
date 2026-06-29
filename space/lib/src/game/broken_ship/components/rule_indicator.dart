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
  Color? _circleColor;

  void setImage(ui.Image image) {
    _image = image;
    _circleColor = null;
  }

  void setCircle(Color color) {
    _circleColor = color;
    _image = null;
  }

  @override
  void render(Canvas canvas) {
    if (_image != null) {
      final imgW = _image!.width.toDouble();
      final imgH = _image!.height.toDouble();
      final imageAspect = imgW / imgH;
      final boxAspect = size.x / size.y;
      double drawW, drawH;
      if (imageAspect > boxAspect) {
        drawW = size.x;
        drawH = size.x / imageAspect;
      } else {
        drawH = size.y;
        drawW = size.y * imageAspect;
      }
      final dx = (size.x - drawW) / 2;
      final dy = (size.y - drawH) / 2;
      final sr = Rect.fromLTWH(0, 0, imgW, imgH);
      final dr = Rect.fromLTWH(dx, dy, drawW, drawH);
      canvas.drawImageRect(_image!, sr, dr, Paint());
    } else if (_circleColor != null) {
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, Paint()..color = _circleColor!);
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
  late final TextComponent _labelLeft;
  late final TextComponent _labelRight;

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
    required String labelLeft,
    required String labelRight,
    Color? colorLeft,
    Color? colorRight,
  }) {
    _ruleTextStr = ruleText;

    _ruleText.text = ruleText;
    _labelLeft.text = labelLeft;
    _labelRight.text = labelRight;

    if (criterion == SortCriterion.color) {
      _iconLeft.setCircle(colorLeft ?? const Color(0xFF3B82F6));
      _iconRight.setCircle(colorRight ?? const Color(0xFFF97316));
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
      ..position = Vector2(60, size.y * 0.28);

    _iconRight = _RuleIcon()
      ..position = Vector2(size.x - 60, size.y * 0.28);

    _labelLeft = TextComponent(
      text: '',
      anchor: Anchor.center,
      position: Vector2(60, size.y * 0.65),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    _labelRight = TextComponent(
      text: '',
      anchor: Anchor.center,
      position: Vector2(size.x - 60, size.y * 0.65),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    _ruleText = TextComponent(
      text: _ruleTextStr,
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.88),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    addAll([_panel, _iconLeft, _iconRight, _labelLeft, _labelRight, _ruleText]);
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
