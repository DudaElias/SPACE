import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BrokenShipBackdrop extends Component {
  late final RectangleComponent _spaceBackground;
  late final CircleComponent _nebulaLeft;
  late final CircleComponent _nebulaRight;
  late final RectangleComponent _tubeLeft;
  late final RectangleComponent _tubeRight;
  late final RectangleComponent _floor;

  final List<CircleComponent> _stars = <CircleComponent>[];
  final List<Vector2> _starSeeds = <Vector2>[];

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _spaceBackground = RectangleComponent(
      position: Vector2.zero(),
      size: Vector2.all(1),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xFF020617),
      priority: -10,
    );

    _nebulaLeft = CircleComponent(
      radius: 180,
      paint: Paint()
        ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
      anchor: Anchor.center,
      priority: -9,
    );

    _nebulaRight = CircleComponent(
      radius: 160,
      paint: Paint()
        ..color = const Color(0xFFF97316).withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
      anchor: Anchor.center,
      priority: -9,
    );

    _tubeLeft = RectangleComponent(
      size: Vector2.all(1),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFF1E293B).withValues(alpha: 0.4),
      priority: -1,
    );

    _tubeRight = RectangleComponent(
      size: Vector2.all(1),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFF1E293B).withValues(alpha: 0.4),
      priority: -1,
    );

    _floor = RectangleComponent(
      size: Vector2.all(1),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFF0F172A),
      priority: -1,
    );

    addAll([
      _spaceBackground,
      _nebulaLeft,
      _nebulaRight,
      _tubeLeft,
      _tubeRight,
      _floor,
    ]);

    final rng = Random(42);
    for (int i = 0; i < 30; i++) {
      final seed = Vector2(rng.nextDouble(), rng.nextDouble());
      _starSeeds.add(seed);

      final star = CircleComponent(
        radius: rng.nextDouble() * 1.6 + 0.8,
        paint: Paint()..color = const Color(0xFFE2E8F0).withValues(alpha: 0.6),
        anchor: Anchor.center,
        priority: -8,
      );
      _stars.add(star);
      add(star);
    }
  }

  void layoutForSize(Vector2 size) {
    _spaceBackground
      ..position = Vector2.zero()
      ..size = size;

    _nebulaLeft.position = Vector2(size.x * 0.15, size.y * 0.2);
    _nebulaRight.position = Vector2(size.x * 0.85, size.y * 0.25);

    final tubeWidth = 4.0;
    final tubeXLeft = size.x * 0.28;
    final tubeXRight = size.x * 0.72;
    final tubeTop = size.y * 0.08;
    final tubeBottom = size.y * 0.85;
    final tubeHeight = tubeBottom - tubeTop;

    _tubeLeft
      ..position = Vector2(tubeXLeft, tubeTop + tubeHeight / 2)
      ..size = Vector2(tubeWidth, tubeHeight);

    _tubeRight
      ..position = Vector2(tubeXRight, tubeTop + tubeHeight / 2)
      ..size = Vector2(tubeWidth, tubeHeight);

    _floor
      ..position = Vector2(size.x * 0.5, size.y * 0.85)
      ..size = Vector2(tubeXRight - tubeXLeft, 6);

    for (int i = 0; i < _stars.length; i++) {
      final seed = _starSeeds[i];
      _stars[i].position = Vector2(
        seed.x * size.x,
        10 + seed.y * (size.y * 0.55),
      );
    }
  }
}
