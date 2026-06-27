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
  bool? _stateIsIntact;

  void showImage(ui.Image image) {
    _image = image;
    _circleColor = null;
    _stateIsIntact = null;
  }

  void showCircle(Color color) {
    _circleColor = color;
    _image = null;
    _stateIsIntact = null;
  }

  void showStateSymbol(bool isIntact) {
    _stateIsIntact = isIntact;
    _image = null;
    _circleColor = null;
  }

  @override
  void render(Canvas canvas) {
    if (_image != null) {
      final sr = Rect.fromLTWH(0, 0, _image!.width.toDouble(), _image!.height.toDouble());
      final dr = Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.drawImageRect(_image!, sr, dr, Paint());
    } else if (_circleColor != null) {
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, Paint()..color = _circleColor!);
    } else if (_stateIsIntact != null) {
      if (_stateIsIntact!) {
        final bgPaint = Paint()..color = const Color(0xFF22C55E);
        canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, bgPaint);
        final checkPaint = Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
        final path = Path()
          ..moveTo(size.x * 0.28, size.y * 0.5)
          ..lineTo(size.x * 0.45, size.y * 0.68)
          ..lineTo(size.x * 0.72, size.y * 0.32);
        canvas.drawPath(path, checkPaint);
      } else {
        final bgPaint = Paint()..color = const Color(0xFFEF4444);
        canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, bgPaint);
        final xPaint = Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(size.x * 0.3, size.y * 0.3),
          Offset(size.x * 0.7, size.y * 0.7),
          xPaint,
        );
        canvas.drawLine(
          Offset(size.x * 0.7, size.y * 0.3),
          Offset(size.x * 0.3, size.y * 0.7),
          xPaint,
        );
      }
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
        final images = findGame()!.images;
        _icon.showImage(images.fromCache(iconPath));
      case SortCriterion.color:
        _icon.showCircle(colorSwatch);
      case SortCriterion.state:
        _icon.showStateSymbol(side == BinSide.left);
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
