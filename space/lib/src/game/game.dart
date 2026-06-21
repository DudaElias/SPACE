import 'package:flame/game.dart';
import 'package:space/src/game/asteroid_field/asteroid_field.dart';
import 'package:space/src/game/broken_ship/broken_ship_route.dart';
import 'package:space/src/game/control_panel/control_panel_route.dart';
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
          'minigame-selector': Route(MinigameSelector.new),
          'minigame-1': Route(ControlPanelRoute.new),
          'minigame-2': Route(AsteroidField.new),
          'minigame-3': Route(BrokenShipRoute.new),
        },
        initialRoute: 'home',
      ),
    );
  }
}
