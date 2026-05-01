import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:space/src/game/components/back_button.dart'
    show SimpleBackButton;
import 'package:space/src/game/components/game_card.dart';
import 'package:space/src/game/game.dart';

class MinigameSelector extends Component with HasGameReference<SpaceGame> {
  @override
  Future<void> onLoad() async {
    final cardSize = GameCard.defaultCardSize;
    final spacing = Vector2(20, 20); // space between cards
    final columns = 3;
    final rows = 1;

    final totalWidth = columns * cardSize.x + (columns - 1) * spacing.x;
    final totalHeight = rows * cardSize.y + (rows - 1) * spacing.y;

    final startX = (game.size.x - totalWidth) / 2;
    final startY = (game.size.y - totalHeight) / 2;

    add(
      TextComponent(
        text: 'Minigames',
        textRenderer: TextPaint(
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontFamily: GoogleFonts.silkscreen().fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        anchor: Anchor.topCenter,
        position: Vector2(game.size.x / 2, 50),
      ),
    );
    for (int col = 0; col < 3; col++) {
      final position = Vector2(startX + col * (cardSize.x + spacing.x), startY);

      add(
        GameCard(
          imageAssetPath: 'game_1.png', // Placeholder image for all minigames
          title: 'Campo de Asteróides',
          position: position,
          onTap: () => game.router.pushNamed('minigame-${col + 1}'),
        ),
      );
    }
  }

  final hudComponents = <Component>[];

  @override
  void onMount() {
    hudComponents.addAll([SimpleBackButton()]);
    game.camera.viewport.addAll(hudComponents);
  }

  @override
  void onRemove() {
    game.camera.viewport.removeAll(hudComponents);
    super.onRemove();
  }
}
