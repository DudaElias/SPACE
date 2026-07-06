import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:space/src/game/shared/atoms/modal_components.dart';
export 'package:space/src/game/shared/atoms/modal_components.dart';

class GameModal extends PositionComponent {
  GameModal({
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
    this.onBackdropTap,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.style = GameModalStyle.shared,
    this.titleColor = const Color(0xFFE2E8F0),
    this.messageColor = const Color(0xFFE2E8F0),
    Vector2? panelSize,
  }) : panelSize = panelSize ?? Vector2(480, 260),
       super(priority: 100);

  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;
  final VoidCallback? onBackdropTap;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final GameModalStyle style;
  final Color titleColor;
  final Color messageColor;
  final Vector2 panelSize;

  late GameModalBackdrop _backdrop;
  late GameModalShell _panel;
  late TextComponent _titleText;
  late GameModalActionButton _button;
  GameModalActionButton? _secondaryButton;
  TextBoxComponent<TextPaint>? _msgComponent;
  Vector2? _pendingLayoutSize;
  bool _uiReady = false;
  String _pendingMessage = '';

  @override
  Future<void> onLoad() async {
    _backdrop = GameModalBackdrop(onBackdropTap: onBackdropTap);
    _panel = GameModalShell(size: panelSize, style: style)..priority = 101;

    _titleText = TextComponent(
      text: title,
      anchor: Anchor.topCenter,
      priority: 102,
      textRenderer: TextPaint(
        style: TextStyle(fontFamily: GoogleFonts.silkscreen().fontFamily, color: titleColor, fontSize: 28, fontWeight: FontWeight.w700),
      ),
    );

    final hasSecondary = secondaryButtonText != null && onSecondaryPressed != null;

    _button = GameModalActionButton(
      label: buttonText,
      onPressed: onPressed,
      style: style,
      size: hasSecondary ? Vector2(180, 48) : null,
    )..priority = 102;

    addAll([_backdrop, _panel, _titleText, _button]);

    if (hasSecondary) {
      _secondaryButton = GameModalActionButton(
        label: secondaryButtonText!,
        onPressed: onSecondaryPressed!,
        style: style.copyWithInverse(),
        size: Vector2(180, 48),
      )..priority = 102;
      add(_secondaryButton!);
    }
    _uiReady = true;

    final targetSize = _pendingLayoutSize ?? findGame()!.size;
    _applyLayout(targetSize);
  }

  void _applyLayout(Vector2 gameSize) {
    size = gameSize;
    _backdrop..position = Vector2.zero()..size = gameSize..anchor = Anchor.topLeft;
    _panel.position = gameSize / 2;
    _titleText.position = _panel.position + Vector2(0, -panelSize.y / 2 + 36);

    if (_secondaryButton != null) {
      final gap = 20.0;
      final half = 90.0;
      _secondaryButton!.position = _panel.position + Vector2(-half - gap / 2, panelSize.y / 2 - 36);
      _button.position = _panel.position + Vector2(half + gap / 2, panelSize.y / 2 - 36);
    } else {
      _button.position = _panel.position + Vector2(0, panelSize.y / 2 - 36);
    }

    final text = _pendingMessage.isNotEmpty ? _pendingMessage : message;
    final msgPosition = Vector2(gameSize.x / 2, gameSize.y / 2 - panelSize.y / 2 + 80);

    if (_msgComponent == null) {
      _msgComponent = TextBoxComponent<TextPaint>(
        text: text,
        textRenderer: TextPaint(
          style: TextStyle(fontFamily: GoogleFonts.silkscreen().fontFamily, color: messageColor, fontSize: 18, height: 1.3),
        ),
        boxConfig: TextBoxConfig(maxWidth: panelSize.x - 80, timePerChar: 0),
        anchor: Anchor.topCenter,
        position: msgPosition,
        priority: 102,
      );
      add(_msgComponent!);
    } else {
      if (_msgComponent!.text != text) {
        _msgComponent!.text = text;
      }
      _msgComponent!.position = msgPosition;
    }
    _pendingLayoutSize = null;
    _pendingMessage = '';
  }

  void layoutForSize(Vector2 gameSize) {
    if (!isLoaded) { _pendingLayoutSize = gameSize.clone(); return; }
    _applyLayout(gameSize);
    _pendingLayoutSize = null;
  }

  VoidCallback? _onSecondaryCallback;

  void configure({String? title, String? message, String? buttonText, String? secondaryButtonText, VoidCallback? onSecondaryPressed}) {
    if (!_uiReady) return;
    final game = findGame();
    if (title != null) _titleText.text = title;
    if (message != null) {
      _pendingMessage = message;
      if (game != null) {
        _applyLayout(game.size);
      }
    }
    if (buttonText != null) _button.setLabel(buttonText);

    _onSecondaryCallback = onSecondaryPressed;
    if (secondaryButtonText != null && onSecondaryPressed != null) {
      if (_secondaryButton == null) {
        _secondaryButton = GameModalActionButton(
          label: secondaryButtonText,
          onPressed: () => _onSecondaryCallback?.call(),
          style: style.copyWithInverse(),
          size: Vector2(180, 48),
        )..priority = 102;
        add(_secondaryButton!);
      } else {
        _secondaryButton!.setLabel(secondaryButtonText);
      }
      if (game != null) _applyLayout(game.size);
    } else if (_secondaryButton != null) {
      _secondaryButton!.removeFromParent();
      _secondaryButton = null;
      _onSecondaryCallback = null;
      if (game != null) _applyLayout(game.size);
    }
  }
}
