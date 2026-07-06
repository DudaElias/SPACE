import 'package:flame/camera.dart';
import 'package:flame/components.dart';

import 'package:space/src/game/shared/atoms/back_button.dart';
import 'package:space/src/game/broken_ship/broken_ship_world.dart';
import 'package:space/src/game/game.dart';

enum BrokenShipMode { standalone, miniGame, story }

class BrokenShipRoute extends Component with HasGameReference<SpaceGame> {
  static const BrokenShipMode standalone = BrokenShipMode.standalone;
  static const BrokenShipMode miniGame = BrokenShipMode.miniGame;

  BrokenShipRoute({
    this.mode = BrokenShipMode.standalone,
    this.onMiniGameFinishExit,
  });

  final BrokenShipMode mode;
  final void Function(int score)? onMiniGameFinishExit;

  late final BrokenShipWorld _world;
  late final CameraComponent _camera;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _world = BrokenShipWorld(
      mode: mode,
      onMiniGameFinishExit: onMiniGameFinishExit,
    );
    // Add the world as a child so it participates in the lifecycle and layout
    await add(_world);

    // Camera that looks at the newly added world
    _camera = CameraComponent(world: _world);
    // Anchor the camera viewfinder to the top-left so world coordinates map to screen coordinates
    _camera.viewfinder.anchor = Anchor.topLeft;
    _camera.viewfinder.position = Vector2.zero();

    await add(_camera);

    // HUD/back button in the camera viewport
    _camera.viewport.add(SimpleBackButton());
  }
}