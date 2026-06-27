import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../broken_ship_controller.dart';

class SortingObject extends PositionComponent with DragCallbacks, TapCallbacks {
  SortingObject({
    required this.piece,
  }) : super(
          priority: 20,
          anchor: Anchor.center,
          size: Vector2.all(100),
        );

  final SortingPiece piece;

  void Function(BinSide side)? onSorted;
  void Function()? onMissed;
  void Function()? onUnjammed;

  bool _isDragging = false;
  bool _isJammed = false;
  bool _isReturning = false;
  bool _isAnimatingToBin = false;
  bool _isFallingAway = false;
  bool _fingerDown = false;

  double _holdTimer = 0;
  double _rotationAngle = 0;
  double _fallSpeed = 0;
  double _floatPhase = 0;
  double _jamShakeIntensity = 0;

  Vector2 restPosition = Vector2.zero();
  Vector2 _binTarget = Vector2.zero();
  double _binScaleTarget = 0;

  double _displayedGrayness = 0;
  double _displayedOpacity = 1.0;

  static const double fallDriftSpeed = 75.0;
  static const double swipeThreshold = 100.0;
  static const double unjamHoldTime = 0.6;
  static const double returnSpringRate = 8.0;
  static const double maxRotationAngle = 0.3;

  late final SpriteComponent _sprite;
  late final CircleComponent _holdIndicatorBg;
  late final CircleComponent _holdIndicatorFill;

  bool get isJammed => _isJammed;
  bool get isAnimating => _isAnimatingToBin || _isFallingAway;

  double _jamPulsePhase = 0;

  void jam() {
    _isJammed = true;
    _jamShakeIntensity = 1.0;
    _jamPulsePhase = 0;
    _holdTimer = 0;
  }

  void unjam() {
    _isJammed = false;
    _fingerDown = false;
    _holdTimer = 0;
    _jamShakeIntensity = 0;
    _isReturning = true;
    onUnjammed?.call();
  }

  void setActive() {
    _isJammed = false;
    _isReturning = false;
    _isAnimatingToBin = false;
    _isFallingAway = false;
    _fallSpeed = 0;
    _displayedOpacity = 1.0;
    _displayedGrayness = 0;
    _holdTimer = 0;
  }

  void animateToBin(Vector2 target, void Function() onComplete) {
    _isAnimatingToBin = true;
    _binTarget = target;
    _binScaleTarget = 0.3;
    _onBinAnimationComplete = onComplete;
  }

  void animateFallAway(void Function() onComplete) {
    _isFallingAway = true;
    _fallSpeed = 60;
    _onFallComplete = onComplete;
  }

  void Function()? _onBinAnimationComplete;
  void Function()? _onFallComplete;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final images = findGame()!.images;
    _sprite = SpriteComponent(
      sprite: Sprite(images.fromCache(piece.imagePath)),
      size: Vector2.all(80),
      anchor: Anchor.center,
      position: size / 2,
    );

    _holdIndicatorBg = CircleComponent(
      radius: 54,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0x00000000),
    );

    _holdIndicatorFill = CircleComponent(
      radius: 54,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0x00000000)
        ..strokeCap = StrokeCap.round,
    );

    addAll([_sprite, _holdIndicatorBg, _holdIndicatorFill]);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_isJammed || _isAnimatingToBin || _isFallingAway) return;
    _isDragging = true;
    _isReturning = false;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_isDragging) return;
    position.add(event.canvasDelta);
    position.x = position.x.clamp(-40, findGame()!.size.x + 40);
    position.y = position.y.clamp(0, findGame()!.size.y);

    _rotationAngle =
        ((position.x - restPosition.x) / swipeThreshold * maxRotationAngle)
            .clamp(-maxRotationAngle, maxRotationAngle);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_isDragging) return;
    _isDragging = false;

    final dx = position.x - restPosition.x;

    if (dx < -swipeThreshold) {
      onSorted?.call(BinSide.left);
    } else if (dx > swipeThreshold) {
      onSorted?.call(BinSide.right);
    } else {
      _isReturning = true;
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _isDragging = false;
    if (!_isJammed) {
      _isReturning = true;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_isJammed) {
      _fingerDown = true;
      _holdTimer = 0;
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    _fingerDown = false;
    _holdTimer = 0;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _fingerDown = false;
    _holdTimer = 0;
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final dx = point.x - cx;
    final dy = point.y - cy;
    return (dx * dx + dy * dy) <= 55 * 55;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _floatPhase += dt * 1.8;

    if (_isAnimatingToBin) {
      _updateBinAnimation(dt);
      return;
    }

    if (_isFallingAway) {
      _updateFallAway(dt);
      return;
    }

    if (_isJammed) {
      _updateJammed(dt);
      return;
    }

    if (!_isDragging && !_isReturning) {
      position.y += fallDriftSpeed * dt;
      position.x += sin(_floatPhase * 0.7) * dt * 6;
    }

    if (_isReturning) {
      final diff = restPosition - position;
      position.add(diff * (dt * returnSpringRate));
      _rotationAngle *= (1.0 - dt * 5);
      if (diff.length < 2.0) {
        position.setFrom(restPosition);
        _isReturning = false;
        _rotationAngle = 0;
      }
    }

    if (position.y > findGame()!.size.y - 120) {
      if (!_isFallingAway && !_isAnimatingToBin && !_isJammed) {
        onMissed?.call();
      }
    }

    _displayedGrayness += ((_isJammed ? 1.0 : 0.0) - _displayedGrayness) * dt * 8;
    _displayedOpacity += ((_isFallingAway ? 0.0 : 1.0) - _displayedOpacity) * dt * 3;
  }

  void _updateBinAnimation(double dt) {
    final diff = _binTarget - position;
    position.add(diff * (dt * 10));

    final currentScale = scale.x;
    final newScale = currentScale + (_binScaleTarget - currentScale) * dt * 10;
    scale = Vector2.all(newScale);

    if (diff.length < 5 && (currentScale - _binScaleTarget).abs() < 0.05) {
      _isAnimatingToBin = false;
      scale = Vector2.all(_binScaleTarget);
      _onBinAnimationComplete?.call();
      _onBinAnimationComplete = null;
    }
  }

  void _updateFallAway(double dt) {
    _fallSpeed += dt * 200;
    position.y += _fallSpeed * dt;

    if (position.y > findGame()!.size.y + 120) {
      _isFallingAway = false;
      _onFallComplete?.call();
      _onFallComplete = null;
    }
  }

  void _updateJammed(double dt) {
    _jamShakeIntensity *= (1.0 - dt * 5);
    if (_jamShakeIntensity < 0.01) _jamShakeIntensity = 0;

    _jamPulsePhase += dt * 2.5;

    if (_fingerDown) {
      _holdTimer += dt;
      if (_holdTimer >= unjamHoldTime) {
        unjam();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final grayFilter = ColorFilter.mode(
      Color.fromARGB(
        (_displayedGrayness * 200).round(),
        100,
        100,
        100,
      ),
      BlendMode.modulate,
    );

    final opacity = _displayedOpacity;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_rotationAngle);
    canvas.translate(-size.x / 2, -size.y / 2);

    if (_displayedGrayness > 0.01) {
      canvas.saveLayer(size.toRect(), Paint()..colorFilter = grayFilter);
    }
    if (opacity < 0.99) {
      canvas.saveLayer(
        size.toRect(),
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: opacity),
      );
    }

    super.render(canvas);

    if (_displayedGrayness > 0.01) {
      final linePaint = Paint()
        ..color = const Color(0xFFFF4444).withValues(alpha: _displayedGrayness * 0.6)
        ..strokeWidth = 3;
      canvas.drawLine(
        Offset(size.x * 0.25, size.y * 0.25),
        Offset(size.x * 0.75, size.y * 0.75),
        linePaint,
      );
      canvas.drawLine(
        Offset(size.x * 0.75, size.y * 0.25),
        Offset(size.x * 0.25, size.y * 0.75),
        linePaint,
      );
      canvas.restore();
    }
    if (opacity < 0.99) {
      canvas.restore();
    }

    canvas.restore();

    if (_isJammed) {
      final pulseAlpha = (sin(_jamPulsePhase) + 1) / 2 * 0.5 + 0.2;
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFFFFFFF).withValues(alpha: pulseAlpha)
        ..strokeCap = StrokeCap.round;

      if (_fingerDown && _holdTimer > 0) {
        final fillPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = const Color(0xFF22C55E).withValues(alpha: 0.9)
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(size.x / 2, size.y / 2), width: 108, height: 108),
          -1.5708,
          6.2832 * (_holdTimer / unjamHoldTime),
          false,
          fillPaint,
        );
      } else {
        canvas.drawCircle(Offset(size.x / 2, size.y / 2), 54, ringPaint);
      }
    }
  }
}
