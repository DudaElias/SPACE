import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:space/src/game/game.dart';

class GameCard extends PositionComponent
    with HasGameReference<SpaceGame>, TapCallbacks, HoverCallbacks {
  static final Vector2 defaultCardSize = Vector2(280, 280);

  final String imageAssetPath;
  final String title;
  final VoidCallback onTap;
  late Sprite? cardImage;

  bool isPressed = false;

  GameCard({
    required this.imageAssetPath,
    required this.title,
    required Vector2 position,
    required this.onTap,
    Vector2? cardSize,
  }) : super(position: position, size: cardSize ?? defaultCardSize);

  @override
  Future<void> onLoad() async {
    try {
      final image = await game.images.load(imageAssetPath);
      cardImage = Sprite(image);
    } catch (e) {
      debugPrint('Failed to load image for GameCard: $e');
      cardImage = null;
    }
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(16),
    );

    canvas.save();
    canvas.translate(4, 6);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.black.withAlpha(64)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.restore();

    if (cardImage != null) {
      canvas.save();
      canvas.clipRRect(rrect);
      cardImage!.render(canvas, size: size);
      canvas.restore();
    } else {
      final gradient = LinearGradient(
        colors: [Colors.grey[800]!, Colors.grey[900]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      final paint = Paint()
        ..shader = gradient.createShader(Offset.zero & size.toSize());
      canvas.drawRRect(rrect, paint);
    }

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = (isPressed || isHovered) ? Colors.white : Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = (isPressed || isHovered) ? 3 : 2,
    );
    var h = size.y;
    if (!isPressed && !isHovered) {
      h -= 200;
    }
    final overlayRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.y - h, size.x, h),
      const Radius.circular(16),
    );
    canvas.drawRRect(overlayRect, Paint()..color = Colors.black.withAlpha(120));

    final textPainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          shadows: const [
            Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black54),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: size.x - 16);
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - h) + (h - textPainter.height) / 2,
      ),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    isPressed = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    isPressed = false;
    onTap();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    isPressed = false;
  }
}
