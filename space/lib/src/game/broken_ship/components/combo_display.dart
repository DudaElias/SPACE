import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ComboDisplay extends PositionComponent {
  ComboDisplay()
      : super(
          priority: 13,
          anchor: Anchor.center,
          size: Vector2(80, 30),
        );

  late final TextComponent _label;

  int _combo = 0;
  int _displayedMultiplier = 1;
  double _pulseScale = 1.0;
  double _displayedOpacity = 0.0;
  double _targetOpacity = 0.0;

  void setCombo(int comboCount) {
    final newMultiplier = _multiplierFromCombo(comboCount);
    if (newMultiplier > _displayedMultiplier) {
      _pulseScale = 1.5;
    }
    _combo = comboCount;
    _targetOpacity = newMultiplier >= 2 ? 1.0 : 0.0;
  }

  void reset() {
    _combo = 0;
    _displayedMultiplier = 1;
    _pulseScale = 1.0;
    _targetOpacity = 0.0;
  }

  int _multiplierFromCombo(int combo) {
    final level = 1 + (combo ~/ 2);
    return level > 3 ? 3 : level;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _label = TextComponent(
      text: '',
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFBBF24),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    add(_label);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _displayedOpacity += (_targetOpacity - _displayedOpacity) * dt * 4;
    _pulseScale += (1.0 - _pulseScale) * dt * 6;

    final multiplier = _multiplierFromCombo(_combo);
    _displayedMultiplier = multiplier;

    if (_displayedMultiplier >= 2) {
      _label.text = 'x$_displayedMultiplier';
    } else {
      _label.text = '';
    }

    scale = Vector2.all(_pulseScale);
  }
}
