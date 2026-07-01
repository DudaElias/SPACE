import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../broken_ship_controller.dart';

class SortingObject extends PositionComponent {
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

  bool isBeingDragged = false;

  bool _isAnimatingToBin = false;
  bool _isFallingAway = false;
  bool _isBouncing = false;

  double _fallSpeed = 0;
  double _floatPhase = 0;

  Vector2 _binTarget = Vector2.zero();
  double _binScaleTarget = 0;
  double _displayedOpacity = 1.0;

  int _bouncePhase = 0; // 0=drop, 1=bounce
  double _bounceTimer = 0;
  double _bounceBaseY = 0;
  double _bounceStartY = 0;
  double _bounceVelY = 0;
  double _bounceSquish = 0;
  double _driftDir = 0;

  bool _isSnapping = false;
  double _snapTargetX = 0;

  static const double fallDriftSpeed = 85.0;

  late final SpriteComponent _sprite;

  bool get isAnimating => _isAnimatingToBin || _isFallingAway || _isBouncing;

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

  void bounceOffBin(double binTopY, double driftDir, void Function() onComplete) {
    _isBouncing = true;
    _bouncePhase = 0;
    _bounceTimer = 0;
    _bounceBaseY = binTopY - 40;
    _bounceStartY = position.y;
    _bounceVelY = 0;
    _bounceSquish = 0;
    _driftDir = driftDir;
    _onBounceComplete = onComplete;
  }

  void snapToCenter(double centerX) {
    _isSnapping = true;
    _snapTargetX = centerX;
  }

  void Function()? _onBinAnimationComplete;
  void Function()? _onFallComplete;
  void Function()? _onBounceComplete;

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

    add(_sprite);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _floatPhase += dt * 1.8;

    if (_isAnimatingToBin) {
      _updateBinAnimation(dt);
      return;
    }

    if (_isBouncing) {
      _updateBounce(dt);
      return;
    }

    if (_isFallingAway) {
      _updateFallAway(dt);
      return;
    }

    if (_isSnapping) {
      position.x += (_snapTargetX - position.x) * dt * 8;
      if ((position.x - _snapTargetX).abs() < 1) {
        position.x = _snapTargetX;
        _isSnapping = false;
      }
    }

    if (!isBeingDragged) {
      position.y += fallDriftSpeed * dt;
      position.x += sin(_floatPhase * 0.7) * dt * 6;
    } else {
      position.y += fallDriftSpeed * dt;
    }

    if (position.y > findGame()!.size.y - 120) {
      if (!_isFallingAway && !_isAnimatingToBin && !_isBouncing) {
        onMissed?.call();
      }
    }

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

  void _updateBounce(double dt) {
    if (_bouncePhase == 0) {
      _bounceTimer += dt;
      final t = (_bounceTimer / 0.18).clamp(0.0, 1.0);
      final eased = t * t * (3 - 2 * t);
      position.y = _bounceStartY + (_bounceBaseY - _bounceStartY) * eased;
      position.x += _driftDir * 120 * dt;
      if (t >= 1.0) {
        _bouncePhase = 1;
        _bounceVelY = -320;
        _bounceSquish = 1.0;
      }
    } else {
      _bounceVelY += 550 * dt;
      position.y += _bounceVelY * dt;
      position.x += _driftDir * 200 * dt;

      if (position.y >= _bounceBaseY && _bounceVelY > 0) {
        position.y = _bounceBaseY;
        _bounceVelY = -_bounceVelY * 0.5;
        _bounceSquish = 0.7;
      }

      _bounceSquish *= 1.0 - dt * 8;
      if (_bounceSquish < 0.01) _bounceSquish = 0;

      final sx = (1.0 + _bounceSquish * 0.4).clamp(0.5, 1.5).toDouble();
      final sy = (1.0 - _bounceSquish * 0.5).clamp(0.5, 1.5).toDouble();
      scale = Vector2(sx, sy);
    }

    if (position.x < -120 || position.x > findGame()!.size.x + 120) {
      _isBouncing = false;
      _onBounceComplete?.call();
      _onBounceComplete = null;
    }
  }

  @override
  void render(Canvas canvas) {
    final opacity = _displayedOpacity;

    if (opacity < 0.99) {
      canvas.saveLayer(
        size.toRect(),
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: opacity),
      );
    }

    super.render(canvas);

    if (opacity < 0.99) {
      canvas.restore();
    }
  }
}
