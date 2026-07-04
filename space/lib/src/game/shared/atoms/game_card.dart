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
  final bool isLocked;
  late Sprite? cardImage;

  bool isPressed = false;

  GameCard({
    required this.imageAssetPath,
    required this.title,
    required Vector2 position,
    required this.onTap,
    Vector2? cardSize,
    this.isLocked = false,
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

    if (isLocked) {
      canvas.drawRRect(
        rrect,
        Paint()..color = Colors.black.withAlpha(160),
      );
      _drawLockIcon(canvas);
      return;
    }

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

  void _drawLockIcon(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final lockPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    final fillPaint = Paint()..color = Colors.white70;

    canvas.drawCircle(
      Offset(cx, cy - 6),
      9,
      lockPaint,
    );
    canvas.drawLine(
      Offset(cx, cy - 6),
      Offset(cx, cy - 14),
      lockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 8), width: 22, height: 18),
        const Radius.circular(3),
      ),
      fillPaint,
    );
    canvas.drawLine(
      Offset(cx, cy + 4),
      Offset(cx, cy + 12),
      Paint()
        ..color = const Color(0xFF050816)
        ..strokeWidth = 2.5,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isLocked) return;
    isPressed = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    isPressed = false;
    if (!isLocked) onTap();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    isPressed = false;
  }
}
