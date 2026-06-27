import 'package:flutter/foundation.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';

import 'package:space/src/game/shared/atoms/back_button.dart';
import 'package:space/src/game/control_panel/control_panel_world.dart';
import 'package:space/src/game/game.dart';

enum ControlPanelMode { standalone, miniGame }

class ControlPanelRoute extends Component with HasGameReference<SpaceGame> {
  static const ControlPanelMode standalone = ControlPanelMode.standalone;
  static const ControlPanelMode miniGame = ControlPanelMode.miniGame;

  ControlPanelRoute({
    this.mode = ControlPanelMode.standalone,
    this.onMiniGameFinishExit,
  });

  final ControlPanelMode mode;
  final VoidCallback? onMiniGameFinishExit;

  late final ControlPanelWorld _world;
  late final CameraComponent _camera;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _world = ControlPanelWorld(
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