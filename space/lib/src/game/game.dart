import 'package:flame/game.dart';
import 'package:space/src/game/menu.dart';
import 'package:space/src/game/minigames.dart';
import 'package:space/src/game/story_mode.dart';

class SpaceGame extends FlameGame {
  late final RouterComponent router;

  @override
  Future<void> onLoad() async {
    // Preload images before starting the game
    await images.load('white_logo.png');

    add(
      router = RouterComponent(
        routes: {
          'home': Route(Menu.new),
          'story-mode': Route(StoryMode.new),
          'minigame-selector': Route(MinigameSelector.new)
        },
        initialRoute: 'home',
      ),
    );
  }
}