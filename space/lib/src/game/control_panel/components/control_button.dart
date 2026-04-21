import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class ControlButton extends PositionComponent with TapCallbacks {
  ControlButton({
    required this.index,
    required this.isLever,
    required this.gradientColors,
    required this.leverColor,
    required this.onPressed,
  }) : super(
         anchor: Anchor.center,
         priority: 10,
         size: Vector2(_controlSize, _controlSize),
       );

  final int index;
  final bool isLever;
  final List<Color> gradientColors;
  final Color leverColor;
  final ValueChanged<int> onPressed;

  bool _highlighted = false;
  double _scale = 1.0;
  double _leverOffset = 0.0;

  CircleComponent? _outerRing;
  CircleComponent? _innerCircle;
  CircleComponent? _glowRing;
  RectangleComponent? _leverBase;
  RectangleComponent? _leverSlot;
  RectangleComponent? _leverStem;
  CircleComponent? _leverHead;
  CircleComponent? _leverPivot;

  static const double _controlSize = 160;
  static const double _circleHitRadius = 80;
  static const double _leverHitWidth = 80;
  static const double _leverHitHeight = 160;
  static const double _leverRestOffset = -44;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final Vector2 center = size / 2;

    if (isLever) {
      _leverBase = RectangleComponent(
        size: Vector2(88, 28),
        paint: Paint()..color = const Color(0xFF1F2937),
        anchor: Anchor.bottomCenter,
        position: center + Vector2(0, 48),
      );

      _leverSlot = RectangleComponent(
        size: Vector2(18, 94),
        paint: Paint()..color = const Color(0xFF020617),
        anchor: Anchor.bottomCenter,
        position: center + Vector2(0, 20),
      );

      _leverStem = RectangleComponent(
        size: Vector2(10, 74),
        paint: Paint()..color = const Color(0xFF94A3B8),
        anchor: Anchor.bottomCenter,
        position: center + Vector2(0, 20),
      );

      _leverPivot = CircleComponent(
        radius: 12,
        paint: Paint()..color = const Color(0xFF334155),
        anchor: Anchor.center,
        position: center + Vector2(0, 20),
      );

      _leverHead = CircleComponent(
        radius: 18,
        paint: Paint()..color = leverColor.withOpacity(0.9),
        anchor: Anchor.center,
        position: center + Vector2(0, _leverRestOffset),
      );

      addAll([_leverBase!, _leverSlot!, _leverStem!, _leverPivot!, _leverHead!]);
    } else {
      _glowRing = CircleComponent(
        radius: 80,
        paint: Paint()
          ..color = gradientColors[0].withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        anchor: Anchor.center,
        position: center,
      );

      _outerRing = CircleComponent(
        radius: 70,
        paint: Paint()
          ..color = gradientColors[0]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
        anchor: Anchor.center,
        position: center,
      );

      _innerCircle = CircleComponent(
        radius: 50,
        paint: Paint()..color = const Color(0xFF111827),
        anchor: Anchor.center,
        position: center,
      );

      addAll([_glowRing!, _outerRing!, _innerCircle!]);
    }
  }

  @override
  bool containsLocalPoint(Vector2 localPosition) {
    final double centerX = size.x / 2;
    final double centerY = size.y / 2;

    if (isLever) {
      return (localPosition.x - centerX).abs() <= _leverHitWidth / 2 &&
          (localPosition.y - centerY).abs() <= _leverHitHeight / 2;
    }

    final double dx = localPosition.x - centerX;
    final double dy = localPosition.y - centerY;
    return dx * dx + dy * dy <= _circleHitRadius * _circleHitRadius;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final Vector2 center = size / 2;

    if (isLever && _highlighted) {
      _leverOffset = math.max(_leverOffset - dt * 120, -24);
      _leverHead?.position = center + Vector2(0, _leverRestOffset + _leverOffset);
      _leverStem?.position = center + Vector2(0, 20 + _leverOffset * 0.25);
    } else if (isLever && _leverOffset < 0) {
      _leverOffset = math.min(_leverOffset + dt * 120, 0);
      _leverHead?.position = center + Vector2(0, _leverRestOffset + _leverOffset);
      _leverStem?.position = center + Vector2(0, 20 + _leverOffset * 0.25);
    }

    if (isLever) {
      _leverStem?.angle = 0;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    onPressed(index);
  }

  void setHighlighted(bool highlighted) {
    _highlighted = highlighted;

    if (!isLever) {
      if (_outerRing != null) {
        _outerRing!.paint.color = highlighted ? gradientColors[1] : gradientColors[0];
      }
      if (_glowRing != null) {
        _glowRing!.paint.color =
            highlighted ? gradientColors[1].withOpacity(0.8) : gradientColors[0].withOpacity(0.4);
      }
    } else {
      if (_leverHead != null) {
        _leverHead!.paint.color = highlighted
            ? leverColor.withOpacity(1.0)
            : leverColor.withOpacity(0.8);
      }
      if (_leverPivot != null) {
        _leverPivot!.paint.color = highlighted
            ? const Color(0xFF64748B)
            : const Color(0xFF334155);
      }
    }
  }

  void setScale(double scale) {
    _scale = scale;
    this.scale = Vector2.all(_scale);
  }
}
