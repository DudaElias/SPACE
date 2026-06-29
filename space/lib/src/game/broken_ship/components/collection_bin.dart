import 'dart:math';

import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../broken_ship_controller.dart';

class _BinIcon extends PositionComponent {
  _BinIcon()
      : super(
          size: Vector2.all(40),
          anchor: Anchor.center,
        );

  ui.Image? _image;
  Color? _circleColor;

  void showImage(ui.Image image) {
    _image = image;
    _circleColor = null;
  }

  void showCircle(Color color) {
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

class CollectionBin extends PositionComponent {
  CollectionBin({
    required this.side,
    required this.colorSwatch,
  }) : super(
          priority: 5,
          anchor: Anchor.center,
          size: Vector2(160, 110),
        );

  final BinSide side;
  final Color colorSwatch;

  late final RectangleComponent _background;
  final _BinIcon _icon = _BinIcon();
  late final TextComponent _labelText;
  late final RectangleComponent _glowBorder;

  double _displayedLabelOpacity = 1.0;
  double _correctFlashTimer = 0;
  double _incorrectFlashTimer = 0;

  double labelOpacity = 1.0;

  void updateForRule({
    required SortCriterion criterion,
    required String iconPath,
    required String label,
  }) {
    _labelText.text = label;

    switch (criterion) {
      case SortCriterion.shape:
      case SortCriterion.state:
        final images = findGame()!.images;
        _icon.showImage(images.fromCache(iconPath));
      case SortCriterion.color:
        _icon.showCircle(colorSwatch);
    }
  }

  void flashCorrect() {
    _correctFlashTimer = 0.35;
  }

  void flashIncorrect() {
    _incorrectFlashTimer = 0.35;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _background = RectangleComponent(
      size: size,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.85),
    );

    _glowBorder = RectangleComponent(
      size: size,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF334155),
    );

    _icon.position = Vector2(size.x / 2, size.y * 0.35);

    _labelText = TextComponent(
      text: '',
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.72),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    addAll([_background, _glowBorder, _icon, _labelText]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _displayedLabelOpacity += (labelOpacity - _displayedLabelOpacity) * dt * 1.5;

    if (_correctFlashTimer > 0) {
      _correctFlashTimer -= dt;
      final alpha = min(1.0, _correctFlashTimer / 0.15);
      _glowBorder.paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF22C55E).withValues(alpha: alpha);
    } else if (_incorrectFlashTimer > 0) {
      _incorrectFlashTimer -= dt;
      final alpha = min(1.0, _incorrectFlashTimer / 0.15);
      _glowBorder.paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFEF4444).withValues(alpha: alpha);
    } else {
      _glowBorder.paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF334155);
    }

    _labelText.textRenderer = TextPaint(
      style: TextStyle(
        color: const Color(0xFFCBD5E1).withValues(alpha: _displayedLabelOpacity),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
