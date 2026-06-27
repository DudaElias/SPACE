import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../shared/molecules/game_modal.dart';
import 'broken_ship_route.dart';

class BrokenShipWorld extends World {
  BrokenShipWorld({
    this.mode = BrokenShipMode.standalone,
    this.onMiniGameFinishExit,
  });

final BrokenShipMode mode;
  final VoidCallback? onMiniGameFinishExit;
}