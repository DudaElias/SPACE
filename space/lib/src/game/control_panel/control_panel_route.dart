import 'package:flame/camera.dart';
import 'package:flame/components.dart';

import 'package:space/src/game/components/back_button.dart';
import 'package:space/src/game/control_panel/control_panel_world.dart';
import 'package:space/src/game/game.dart';

class ControlPanelRoute extends Component with HasGameReference<SpaceGame> {
  late final ControlPanelWorld _world;
  late final CameraComponent _camera;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _world = ControlPanelWorld();
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