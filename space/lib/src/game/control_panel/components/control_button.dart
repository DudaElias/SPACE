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
  double _leverProgress = 0.0;

  CircleComponent? _outerRing;
  CircleComponent? _innerCircle;
  CircleComponent? _glowRing;
  RectangleComponent? _leverBase;
  RectangleComponent? _leverStem;
  CircleComponent? _leverHead;
  CircleComponent? _leverPivot;

  static const double _controlSize = 160;
  static const double _circleHitRadius = 80;
  static const double _leverHitWidth = 80;
  static const double _leverHitHeight = 160;
  static const double _leverPivotYOffset = 20;
  static const double _leverStemLength = 74;
  static const double _leverHeadOffset = 58;
  static const double _leverRestAngle = -0.22;
  static const double _leverPressedAngle = 0.48;

  Vector2 _leverPivotPosition(Vector2 center) {
    return center + Vector2(0, _leverPivotYOffset);
  }

  double _leverEase(double progress) {
    return progress * progress * (3 - 2 * progress);
  }

  void _syncLeverPose(Vector2 center) {
    final Vector2 pivot = _leverPivotPosition(center);
    final double eased = _leverEase(_leverProgress);
    final double angle = _leverRestAngle + (_leverPressedAngle - _leverRestAngle) * eased;

    _leverStem
      ?..position = pivot
      ..angle = angle;
    _leverPivot?.position = pivot;
    _leverHead?.position = pivot + Vector2(
      math.sin(angle) * _leverHeadOffset,
      -math.cos(angle) * _leverHeadOffset,
    );
    _leverHead?.scale = Vector2.all(1.0 + eased * 0.08);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final Vector2 center = size / 2;

    if (isLever) {
      _leverBase = RectangleComponent(
        size: Vector2(90, 28),
        paint: Paint()..color = const Color(0xFF1F2937),
        anchor: Anchor.bottomCenter,
        position: center + Vector2(0, 48),
      );

      _leverStem = RectangleComponent(
        size: Vector2(10, _leverStemLength),
        paint: Paint()..color = const Color(0xFF94A3B8),
        anchor: Anchor.bottomCenter,
        position: center + Vector2(0, _leverPivotYOffset),
      );

      _leverPivot = CircleComponent(
        radius: 12,
        paint: Paint()..color = const Color(0xFF334155),
        anchor: Anchor.center,
        position: center + Vector2(0, _leverPivotYOffset),
      );

      _leverHead = CircleComponent(
        radius: 18,
        paint: Paint()..color = leverColor.withValues(alpha: 0.9),
        anchor: Anchor.center,
        position: center + Vector2(0, _leverPivotYOffset - _leverHeadOffset),
      );

      addAll([_leverBase!, _leverStem!, _leverPivot!, _leverHead!]);
      _syncLeverPose(center);
    } else {
      _glowRing = CircleComponent(
        radius: 80,
        paint: Paint()
          ..color = gradientColors[0].withValues(alpha: 0.4)
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
  bool containsLocalPoint(Vector2 point) {
    final double centerX = size.x / 2;
    final double centerY = size.y / 2;

    if (isLever) {
      return (point.x - centerX).abs() <= _leverHitWidth / 2 &&
          (point.y - centerY).abs() <= _leverHitHeight / 2;
    }

    final double dx = point.x - centerX;
    final double dy = point.y - centerY;
    return dx * dx + dy * dy <= _circleHitRadius * _circleHitRadius;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final Vector2 center = size / 2;

    if (isLever) {
      final double targetProgress = _highlighted ? 1.0 : 0.0;
      final double response = 1 - math.exp(-dt * 12);
      _leverProgress += (targetProgress - _leverProgress) * response;
      _syncLeverPose(center);
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
            highlighted ? gradientColors[1].withValues(alpha: 0.8) : gradientColors[0].withValues(alpha: 0.4);
      }
    } else {
      if (_leverHead != null) {
        _leverHead!.paint.color = highlighted
            ? leverColor.withValues(alpha: 1.0)
            : leverColor.withValues(alpha: 0.8);
      }
      if (_leverStem != null) {
        _leverStem!.paint.color = highlighted
            ? const Color(0xFFCBD5E1)
            : const Color(0xFF94A3B8);
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
