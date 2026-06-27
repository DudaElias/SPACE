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
    await images.load('logo.png');

    final savedPrefix = images.prefix;
    images.prefix = '';
    const pieceNames = [
      'gear-blue', 'gear-blue-broken', 'gear-orange', 'gear-orange-broken',
      'battery-blue', 'battery-blue-broken', 'battery-orange', 'battery-orange-broken',
      'gear', 'gear-broken', 'battery', 'battery-broken',
    ];
    for (final name in pieceNames) {
      await images.load('assets/images/broken_ship_pieces/$name.png');
    }
    images.prefix = savedPrefix;

    add(
      router = RouterComponent(
        routes: {
          'home': Route(Menu.new),
          'story-mode': Route(StoryMode.new),
          'minigame-selector': Route(MinigameSelector.new),
          'minigame-1': Route(
            () => ControlPanelRoute(
              mode: ControlPanelRoute.miniGame,
              onMiniGameFinishExit: router.pop,
            ),
            maintainState: false,
          ),
          'minigame-2': Route(
            () => AsteroidField(
              mode: AsteroidFieldMode.miniGame,
              onMiniGameFinishExit: router.pop,
            ),
            maintainState: false,
          ),
          'minigame-3': Route(
            () => BrokenShipRoute(
              mode: BrokenShipRoute.miniGame,
              onMiniGameFinishExit: router.pop,
            ),
            maintainState: false,
          )
        },
        initialRoute: 'home',
      ),
    );
  }
}
