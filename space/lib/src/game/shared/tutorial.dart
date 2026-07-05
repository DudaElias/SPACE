import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum TutorialAction {
  none,
  tapAnyButton,
  tapSpecificButton,
  dragAnywhere,
  dragToLeft,
  dragToRight,
  tapStart,
}

class TutorialStep {
  const TutorialStep({
    required this.text,
    this.highlightTarget,
    this.action = TutorialAction.none,
    this.bubblePlacement = BubblePlacement.below,
    this.isLastStep = false,
    this.autoAdvanceSeconds,
    this.padIndex,
    this.buttonLabel,
  });

  final String text;
  final TutorialHighlightTarget? highlightTarget;
  final TutorialAction action;
  final BubblePlacement bubblePlacement;
  final bool isLastStep;
  final double? autoAdvanceSeconds;
  final int? padIndex;
  final String? buttonLabel;
}

enum BubblePlacement { below, above, left, right }

class TutorialHighlightTarget {
  const TutorialHighlightTarget({
    this.rect,
    this.center,
    this.radius,
  }) : assert(rect != null || (center != null && radius != null));

  final Rect? rect;
  final Vector2? center;
  final double? radius;
}

class TutorialConfigs {
  static List<TutorialStep> controlPanelSteps(Vector2 gameSize) {
    final cx = gameSize.x / 2;
    final topY = gameSize.y * 0.35;
    final botY = gameSize.y * 0.65;
    const gap = 100.0;
    const btnSize = 160.0;

    return [
      TutorialStep(
        text: 'Estes s\u00E3o os 4 comandos\ndo painel do foguete!',
        highlightTarget: TutorialHighlightTarget(
          rect: Rect.fromLTRB(
            cx - gap / 2 - 50 - btnSize / 2,
            topY - btnSize / 2,
            cx + gap / 2 + 50 + btnSize / 2,
            botY + btnSize / 2,
          ),
        ),
        action: TutorialAction.none,
      ),
      TutorialStep(
        text: 'Veja: o computador\nmostra uma sequ\u00EAncia...',
        highlightTarget: TutorialHighlightTarget(
          rect: Rect.fromLTRB(
            cx - gap / 2 - 50 - btnSize / 2,
            topY - btnSize / 2 - 20,
            cx + gap / 2 + 50 + btnSize / 2,
            topY + btnSize / 2 + 20,
          ),
        ),
        action: TutorialAction.none,
      ),
      TutorialStep(
        text: 'Agora \u00E9 sua vez!\nToque no comando que piscou!',
        highlightTarget: TutorialHighlightTarget(
          rect: Rect.fromLTRB(
            cx - gap / 2 - 50 - btnSize / 2,
            topY - btnSize / 2,
            cx + gap / 2 + 50 + btnSize / 2,
            topY + btnSize / 2,
          ),
        ),
        action: TutorialAction.tapSpecificButton,
        padIndex: 0,
      ),
      TutorialStep(
        text: 'Se errar, tente de novo.\nBoa sorte, piloto!',
        highlightTarget: null,
        action: TutorialAction.tapStart,
        isLastStep: true,
        buttonLabel: 'Come\u00E7ar!',
      ),
    ];
  }

  static List<TutorialStep> asteroidFieldSteps(Vector2 gameSize) {
    final rocketX = 180.0;
    final rocketY = gameSize.y / 2;

    return [
      TutorialStep(
        text: 'Arraste o foguete\npara pilotar!',
        highlightTarget: TutorialHighlightTarget(
          center: Vector2(rocketX, rocketY),
          radius: 80,
        ),
        action: TutorialAction.dragAnywhere,
      ),
      TutorialStep(
        text: 'Desvie dos aster\u00F3ides\n(eles machucam!)',
        highlightTarget: null,
        action: TutorialAction.none,
      ),
      TutorialStep(
        text: 'Colete ossinhos\npara pontos extras!',
        highlightTarget: null,
        action: TutorialAction.none,
      ),
      TutorialStep(
        text: 'Chegue ao final do\ncampo de aster\u00F3ides!',
        highlightTarget: TutorialHighlightTarget(
          rect: Rect.fromLTWH(gameSize.x / 2 - 120, 4, 240, 28),
        ),
        action: TutorialAction.tapStart,
        isLastStep: true,
        buttonLabel: 'Voar!',
      ),
    ];
  }

  static List<TutorialStep> brokenShipSteps(Vector2 gameSize) {
    final cx = gameSize.x / 2;
    final pieceY = gameSize.y * 0.35;
    const pieceSize = 100.0;

    return [
      TutorialStep(
        text: 'Arraste as pe\u00E7as para\nos lados para classificar!',
        highlightTarget: TutorialHighlightTarget(
          rect: Rect.fromLTWH(cx - pieceSize, pieceY - pieceSize / 2, pieceSize * 2, pieceSize),
        ),
        action: TutorialAction.dragToLeft,
      ),
      TutorialStep(
        text: 'Muito bem!\nVeja o reparo subir...',
        highlightTarget: TutorialHighlightTarget(
          rect: Rect.fromLTWH(cx - 160, gameSize.y * 0.17, 320, 60),
        ),
        action: TutorialAction.none,
      ),
      TutorialStep(
        text: 'Aten\u00E7\u00E3o! As regras\nv\u00E3o mudar de repente!',
        highlightTarget: TutorialHighlightTarget(
          rect: Rect.fromLTRB(
            gameSize.x * 0.28,
            gameSize.y * 0.04,
            gameSize.x * 0.72,
            gameSize.y * 0.22,
          ),
        ),
        action: TutorialAction.none,
      ),
      TutorialStep(
        text: 'Fique atento e continue\nclassificando certo!\nBoa sorte!',
        highlightTarget: null,
        action: TutorialAction.tapStart,
        isLastStep: true,
        buttonLabel: 'Consertar!',
      ),
    ];
  }
}

class TutorialOverlay extends PositionComponent {
  TutorialOverlay({
    required this.steps,
    required this.onTutorialComplete,
    required this.onTutorialSkip,
    required this.gameSize,
    required this.handImage,
  }) : super(size: gameSize, priority: 300);

  final List<TutorialStep> steps;
  final VoidCallback onTutorialComplete;
  final VoidCallback onTutorialSkip;
  final Vector2 gameSize;
  final ui.Image handImage;

  int _currentStep = 0;
  double _autoAdvanceTimer = 0;
  double _handAnimTimer = 0;
  double _handBounce = 0;
  bool _isCompleted = false;

  late final _CutoutBackdrop _backdrop;
  late RRect _highlightRRect;
  late Offset _highlightCenter;
  late double _highlightRadius;
  TutorialHighlightTarget? _currentHighlight;

  late final _SpeechBubble _bubble;
  late final _AnimatedHand _hand;
  late final _StepDots _dots;
  late final _GlowBorder _glowBorder;
  late final _SkipButton _skipButton;

  @override
  bool containsLocalPoint(Vector2 point) {
    final bubbleBounds = _bubble.size;
    final bubblePos = _bubble.position;
    if (point.x >= bubblePos.x && point.x <= bubblePos.x + bubbleBounds.x &&
        point.y >= bubblePos.y && point.y <= bubblePos.y + bubbleBounds.y) {
      return true;
    }
    final skipBounds = _skipButton.size;
    final skipPos = _skipButton.position;
    if (point.x >= skipPos.x - skipBounds.x / 2 &&
        point.x <= skipPos.x + skipBounds.x / 2 &&
        point.y >= skipPos.y - skipBounds.y / 2 &&
        point.y <= skipPos.y + skipBounds.y / 2) {
      return true;
    }
    return false;
  }

  bool get isShowing => !_isCompleted && _currentStep < steps.length;
  int get currentStepIndex => _currentStep;

  TutorialStep get currentStep => steps[_currentStep];

  void advance() {
    if (_isCompleted) return;
    _goToNextStep();
  }

  void completeTutorial() {
    if (_isCompleted) return;
    _isCompleted = true;
    removeFromParent();
    onTutorialComplete();
  }

  void skip() {
    if (_isCompleted) return;
    _isCompleted = true;
    removeFromParent();
    onTutorialSkip();
  }

  void _goToNextStep() {
    _currentStep++;
    if (_currentStep >= steps.length) {
      completeTutorial();
      return;
    }
    _autoAdvanceTimer = 0;
    _applyStep();
  }

  void _applyStep() {
    final step = steps[_currentStep];
    _currentHighlight = step.highlightTarget;

    _bubble.setText(step.text);
    _bubble.setAction(step.action, step.isLastStep, step.buttonLabel);
    _dots.setStep(_currentStep, steps.length);
    _skipButton.setVisible(!step.isLastStep);

    _layoutForCurrentStep();
  }

  void _layoutForCurrentStep() {
    final step = steps[_currentStep];
    final target = step.highlightTarget;
    if (target != null) {
      _glowBorder.setVisible(true);
      if (target.rect != null) {
        final r = target.rect!;
        _glowBorder.position = Vector2(r.left, r.top);
        _glowBorder.size = Vector2(r.width, r.height);
        _highlightRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, r.width, r.height),
          const Radius.circular(12),
        );
        _highlightCenter = r.center;
        _highlightRadius = (r.width + r.height) / 4;
      } else if (target.center != null) {
        final c = target.center!;
        final r = target.radius ?? 60;
        _glowBorder.position = Vector2(c.x - r, c.y - r);
        _glowBorder.size = Vector2(r * 2, r * 2);
        _highlightRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, r * 2, r * 2),
          Radius.circular(r),
        );
        _highlightCenter = c.toOffset();
        _highlightRadius = r;
      }
      _glowBorder.setRrect(_highlightRRect);
      final isDragAction = step.action == TutorialAction.dragAnywhere ||
          step.action == TutorialAction.dragToLeft ||
          step.action == TutorialAction.dragToRight;
      _hand.setVisible(isDragAction);
      if (isDragAction) {
        _hand.setTarget(_highlightCenter, _highlightRadius);
      }
    } else {
      _glowBorder.setVisible(false);
      _hand.setVisible(false);
    }

    _backdrop
      ..size = gameSize
      ..position = Vector2.zero();
    _backdrop.cutoutTarget = _currentHighlight;

    _layoutBubble();
    _skipButton.position = Vector2(gameSize.x - 160, gameSize.y - 40);
  }

  void _layoutBubble() {
    const bubbleW = 380.0;
    const bubbleH = 160.0;
    final cx = gameSize.x / 2;
    final cy = gameSize.y / 2;

    double bx, by;
    Offset targetCenter = Offset(cx, cy * 0.5);

    final target = _currentHighlight;
    if (target != null) {
      if (target.rect != null) {
        targetCenter = target.rect!.center;
      } else if (target.center != null) {
        targetCenter = target.center!.toOffset();
      }
    } else {
      targetCenter = Offset(cx, cy * 0.4);
    }

    switch (currentStep.bubblePlacement) {
      case BubblePlacement.below:
        bx = targetCenter.dx - bubbleW / 2;
        by = targetCenter.dy + _highlightRadius + 40;
      case BubblePlacement.above:
        bx = targetCenter.dx - bubbleW / 2;
        by = targetCenter.dy - bubbleH - _highlightRadius - 40;
      case BubblePlacement.left:
        bx = targetCenter.dx - bubbleW - _highlightRadius - 40;
        by = targetCenter.dy - bubbleH / 2;
      case BubblePlacement.right:
        bx = targetCenter.dx + _highlightRadius + 40;
        by = targetCenter.dy - bubbleH / 2;
    }

    bx = bx.clamp(20, gameSize.x - bubbleW - 20);
    by = by.clamp(20, gameSize.y - bubbleH - 20);

    _bubble.position = Vector2(bx, by);
    _bubble.size = Vector2(bubbleW, bubbleH);
    _bubble.tailTarget = targetCenter - Offset(bx, by);
    _dots.position = Vector2(bx + bubbleW / 2, by + 24);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _backdrop = _CutoutBackdrop()
      ..size = gameSize
      ..position = Vector2.zero()
      ..priority = 0;
    add(_backdrop);

    _glowBorder = _GlowBorder();
    _glowBorder.priority = 1;
    add(_glowBorder);

    _hand = _AnimatedHand(handImage: handImage);
    _hand.priority = 2;
    add(_hand);

    _dots = _StepDots();
    _dots.priority = 3;
    add(_dots);

    _bubble = _SpeechBubble(
      onActionPressed: () {
        final step = steps[_currentStep];
        if (step.isLastStep) {
          completeTutorial();
        } else if (step.action == TutorialAction.none) {
          _goToNextStep();
        }
      },
    );
    _bubble.priority = 3;
    add(_bubble);

    _skipButton = _SkipButton(onPressed: skip);
    _skipButton.priority = 3;
    add(_skipButton);

    final defaultCenter = Offset(gameSize.x / 2, gameSize.y * 0.3);
    _highlightRRect = RRect.fromRectAndRadius(Rect.zero, const Radius.circular(12));
    _highlightCenter = defaultCenter;
    _highlightRadius = 60;

    _applyStep();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isCompleted) return;

    final step = steps[_currentStep];
    if (step.autoAdvanceSeconds != null && step.action == TutorialAction.none) {
      _autoAdvanceTimer += dt;
      if (_autoAdvanceTimer >= step.autoAdvanceSeconds!) {
        _goToNextStep();
        return;
      }
    }

    _handAnimTimer += dt;
    _handBounce = sin(_handAnimTimer * 3.0) * 10;

    if (_hand.isVisible) {
      final topEdge = _highlightCenter.dy - _highlightRadius;
      _hand.setAnimatedPosition(_highlightCenter.dx, topEdge - 85 + _handBounce);
    }
  }
}

class _GlowBorder extends PositionComponent {
  _GlowBorder() : _visible = true;

  bool _visible;
  RRect _rrect = RRect.fromRectAndRadius(Rect.zero, const Radius.circular(12));
  double _pulseTimer = 0;

  bool get isVisible => _visible;
  void setVisible(bool v) => _visible = v;
  void setRrect(RRect r) => _rrect = r;

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!_visible) return;
    final alpha = 0.4 + sin(_pulseTimer * 2.5) * 0.3;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF62D5FF).withValues(alpha: alpha.clamp(0.25, 0.9));
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF9EEAFF).withValues(alpha: alpha.clamp(0.15, 0.5));
    canvas.drawRRect(_rrect, paint);
    canvas.drawRRect(_rrect.inflate(4), outer);
  }
}

class _AnimatedHand extends PositionComponent {
  _AnimatedHand({required this.handImage})
    : _visible = true,
      super(size: Vector2(64, 64), anchor: Anchor.center);

  final ui.Image handImage;
  bool _visible;
  double _targetX = 0;
  double _targetY = 0;

  bool get isVisible => _visible;
  void setVisible(bool v) => _visible = v;

  void setTarget(Offset center, double radius) {
    _visible = true;
  }

  void setAnimatedPosition(double x, double y) {
    _targetX = x;
    _targetY = y;
    position = Vector2(_targetX, _targetY);
  }

  @override
  void render(Canvas canvas) {
    if (!_visible) return;
    final srcRect = Rect.fromLTWH(0, 0, handImage.width.toDouble(), handImage.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawImageRect(handImage, srcRect, dstRect, Paint());
  }
}

class _SpeechBubble extends PositionComponent with TapCallbacks {
  _SpeechBubble({required this.onActionPressed});

  final VoidCallback onActionPressed;
  String _text = '';
  Offset tailTarget = Offset.zero;
  bool _isLastStep = false;
  String? _buttonLabel;
  bool _showButton = true;

  late TextComponent _textComp;
  late TextComponent _buttonLabelComp;

  void setText(String text) {
    _text = text;
    if (isLoaded) {
      _textComp.text = text;
    }
  }

  void setAction(TutorialAction action, bool isLastStep, String? buttonLabel) {
    _isLastStep = isLastStep;
    _buttonLabel = buttonLabel;
    _showButton = isLastStep || action == TutorialAction.none;
    if (isLoaded) {
      _buttonLabelComp.text = buttonLabel ?? (isLastStep ? 'Comecar!' : 'OK!');
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _textComp = TextComponent(
      text: _text,
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.35),
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: const Color(0xFFE2E8F0),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
    add(_textComp);

    _buttonLabelComp = TextComponent(
      text: _buttonLabel ?? (_isLastStep ? 'Comecar!' : 'OK!'),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y - 28),
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    add(_buttonLabelComp);
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final panel = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xEE111F39), Color(0xEE0A1429)],
    );
    canvas.drawRRect(panel, Paint()..shader = gradient.createShader(rect));
    canvas.drawRRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF62D5FF).withAlpha(170),
    );
    canvas.drawRRect(
      panel.inflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF9EEAFF).withAlpha(70),
    );

    if (_showButton) {
      final btnWidth = 140.0;
      final btnHeight = 40.0;
      final btnRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x / 2 - btnWidth / 2, size.y - 48, btnWidth, btnHeight),
        const Radius.circular(20),
      );
      canvas.drawRRect(btnRect, Paint()..color = const Color(0xffFF986A));
      _buttonLabelComp.textRenderer = TextPaint(
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      );
    } else {
      _buttonLabelComp.textRenderer = TextPaint(
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: Colors.transparent,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      );
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!_showButton) return;
    onActionPressed();
  }
}

class _StepDots extends PositionComponent {
  _StepDots() : super(anchor: Anchor.center, size: Vector2(60, 12));

  int _current = 0;
  int _total = 0;

  void setStep(int current, int total) {
    _current = current;
    _total = total;
  }

  @override
  void render(Canvas canvas) {
    if (_total == 0) return;
    final dotRadius = 4.0;
    final spacing = 14.0;
    final startX = (size.x - (_total * spacing)) / 2;
    for (int i = 0; i < _total; i++) {
      final color = i < _current
          ? const Color(0xFF4ADE80)
          : i == _current
              ? const Color(0xffFF986A)
              : const Color(0xFF4B5563);
      canvas.drawCircle(
        Offset(startX + i * spacing, size.y / 2),
        dotRadius,
        Paint()..color = color,
      );
    }
  }
}

class _CutoutBackdrop extends PositionComponent {
  _CutoutBackdrop() : super();

  TutorialHighlightTarget? cutoutTarget;

  @override
  void render(Canvas canvas) {
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.x, size.y));

    final target = cutoutTarget;
    if (target != null) {
      if (target.rect != null) {
        path.addRRect(RRect.fromRectAndRadius(
          target.rect!,
          const Radius.circular(12),
        ));
      } else if (target.center != null) {
        final r = target.radius ?? 60;
        path.addOval(Rect.fromCircle(
          center: target.center!.toOffset(),
          radius: r,
        ));
      }
    }
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, Paint()..color = const Color(0xAA020617));
  }
}

class _SkipButton extends PositionComponent with TapCallbacks {
  _SkipButton({required this.onPressed})
    : super(size: Vector2(140, 30), anchor: Anchor.center);

  final VoidCallback onPressed;
  bool _visible = true;

  void setVisible(bool v) => _visible = v;

  @override
  void render(Canvas canvas) {
    if (!_visible) return;
    final tp = TextPainter(
      text: TextSpan(
        text: 'Pular tutorial \u00BB',
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2));
  }

  @override
  void onTapUp(TapUpEvent event) => onPressed();
}
