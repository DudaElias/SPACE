import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ControlPanelBackdrop extends Component {
  late final RectangleComponent _spaceBackground;
  late final RectangleComponent _panelFrame;
  late final RectangleComponent _panelSurface;
  late final RectangleComponent _statusPanel;
  late final CircleComponent _nebulaLeft;
  late final CircleComponent _nebulaRight;

  final List<CircleComponent> _stars = <CircleComponent>[];
  final List<Vector2> _starSeeds = <Vector2>[];

  RectangleComponent get panelSurface => _panelSurface;

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
      radius: 220,
      paint: Paint()
        ..color = const Color(0xFF0EA5E9).withOpacity(0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
      anchor: Anchor.center,
      priority: -9,
    );

    _nebulaRight = CircleComponent(
      radius: 190,
      paint: Paint()
        ..color = const Color(0xFFF97316).withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
      anchor: Anchor.center,
      priority: -9,
    );

    _panelFrame = RectangleComponent(
      size: Vector2.all(1),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFF111827),
      priority: -1,
    );

    _panelSurface = RectangleComponent(
      size: Vector2.all(1),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFF0F172A),
      priority: 0,
    );

    _statusPanel = RectangleComponent(
      size: Vector2.all(1),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFF111827),
      priority: 10,
    );

    addAll([
      _spaceBackground,
      _nebulaLeft,
      _nebulaRight,
      _panelFrame,
      _panelSurface,
      _statusPanel,
    ]);

    final math.Random random = math.Random(42);
    for (int i = 0; i < 30; i++) {
      final Vector2 seed = Vector2(random.nextDouble(), random.nextDouble());
      _starSeeds.add(seed);

      final CircleComponent star = CircleComponent(
        radius: random.nextDouble() * 1.6 + 0.8,
        paint: Paint()..color = const Color(0xFFE2E8F0).withOpacity(0.75),
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

    _nebulaLeft.position = Vector2(size.x * 0.2, size.y * 0.18);
    _nebulaRight.position = Vector2(size.x * 0.82, size.y * 0.22);

    _panelFrame
      ..position = size / 2
      ..size = Vector2(size.x * 0.9, size.y * 0.76);

    _panelSurface
      ..position = size / 2
      ..size = Vector2(size.x * 0.86, size.y * 0.72);

    _statusPanel
      ..position = Vector2(size.x * 0.5, size.y - 44)
      ..size = Vector2(size.x * 0.84, 58);

    for (int i = 0; i < _stars.length; i++) {
      final Vector2 seed = _starSeeds[i];
      _stars[i].position = Vector2(
        seed.x * size.x,
        10 + seed.y * (size.y * 0.42),
      );
    }
  }
}
