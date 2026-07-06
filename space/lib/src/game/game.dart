import 'dart:async';
import 'dart:ui' show Color;

import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:space/src/game/asteroid_field/asteroid_field.dart';
import 'package:space/src/game/broken_ship/broken_ship_route.dart';
import 'package:space/src/game/control_panel/control_panel_route.dart';
import 'package:space/src/game/menu.dart';
import 'package:space/src/game/minigames.dart';
import 'package:space/src/game/ranking.dart';
import 'package:space/src/game/story_mode.dart';
import 'package:space/src/game/user_select.dart';
import 'package:space/src/game/shared/molecules/database.dart';
import 'package:space/src/game/shared/settings.dart';
import 'package:space/src/game/shared/sound_manager.dart';

class SpaceGame extends FlameGame {
  late final RouterComponent router;
  int storyChapter = 0;
  bool storyReturned = false;
  final Set<String> unlockedMinigames = <String>{};

  final ValueNotifier<Color> barColor = ValueNotifier<Color>(const Color(0xFF5D6598));

  static const _gameplayRoutes = {
    'story-mode',
    'minigame-1', 'minigame-2', 'minigame-3',
    'story-challenge-1', 'story-challenge-2', 'story-challenge-3',
  };

  static const _menuBarColor = Color(0xFF5D6598);
  static const _gameBarColor = Color(0xFF020617);

  String? _lastRouteName;
  bool _overlayOpen = false;

  void setGlobalVolume(double volume) {
    GameSettings.instance.soundVolume = volume;
    FlameAudio.bgm.audioPlayer.setVolume(volume);
  }

  void _applyBarColor() {
    final route = router.currentRoute.name;
    if (route == null) return;
    Color base = _gameplayRoutes.contains(route) ? _gameBarColor : _menuBarColor;
    if (_overlayOpen) {
      base = Color.alphaBlend(const Color(0xCC020617), base);
    }
    barColor.value = base;
  }

  void _updateRoute(String? route) {
    if (route == _lastRouteName) return;

    if (route != null && _gameplayRoutes.contains(route)) {
      SoundManager.instance.stopBgm();
    } else if (route == 'home') {
      SoundManager.instance.playBgm('shared/menu_bgm.mp3');
    }

    _lastRouteName = route;
    _applyBarColor();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateRoute(router.currentRoute.name);
  }

  void setOverlayOpen(bool open) {
    _overlayOpen = open;
    _applyBarColor();
  }

  Completer<String?>? _nameInputCompleter;

  Future<String?> requestPlayerName() {
    _nameInputCompleter?.complete(null);
    _nameInputCompleter = Completer<String?>();
    overlays.add('nameInput');
    setOverlayOpen(true);
    return _nameInputCompleter!.future;
  }

  void onNameInputConfirm(String name) {
    overlays.remove('nameInput');
    setOverlayOpen(false);
    _nameInputCompleter?.complete(name);
    _nameInputCompleter = null;
  }

  void onNameInputCancel() {
    overlays.remove('nameInput');
    setOverlayOpen(false);
    _nameInputCompleter?.complete(null);
    _nameInputCompleter = null;
  }

  Future<void> loadUserUnlocks(int userId) async {
    if (userId == 0) return;
    final helper = await DatabaseHelper.getInstance();
    final list = await helper.getUserUnlockedMinigames(userId);
    unlockedMinigames.clear();
    unlockedMinigames.addAll(list);
  }

  Future<void> _saveUnlock(String minigame) async {
    final userId = GameSettings.instance.currentUserId;
    if (userId == 0) return;
    final helper = await DatabaseHelper.getInstance();
    await helper.unlockMinigameForUser(userId, minigame);
  }

  void _popRoute() => router.pop();

  void onChallenge1Complete(int score) {
    unlockedMinigames.add('minigame-1');
    storyReturned = true;
    _recordRanking('minigame-1', 'win', score);
    _saveUnlock('minigame-1');
    router.pop();
  }

  void onChallenge2Complete(int score) {
    unlockedMinigames.add('minigame-2');
    storyReturned = true;
    _recordRanking('minigame-2', 'win', score);
    _saveUnlock('minigame-2');
    router.pop();
  }

  void onChallenge3Complete(int score) {
    unlockedMinigames.add('minigame-3');
    storyReturned = true;
    _recordRanking('minigame-3', 'win', score);
    _saveUnlock('minigame-3');
    router.pop();
  }

  void onMinigame1Complete(int score) {
    _recordRanking('minigame-1', 'win', score);
    router.pop();
  }

  void onMinigame2Complete(int score) {
    _recordRanking('minigame-2', 'win', score);
    router.pop();
  }

  void onMinigame3Complete(int score) {
    _recordRanking('minigame-3', 'win', score);
    router.pop();
  }

  Future<void> _recordRanking(String minigame, String result, int score) async {
    final userId = GameSettings.instance.currentUserId;
    if (userId == 0) return;
    final helper = await DatabaseHelper.getInstance();
    await helper.insertRanking(
      userId: userId,
      minigame: minigame,
      result: result,
      score: score,
      difficulty: GameSettings.instance.difficulty,
    );
  }

  @override
  Future<void> onLoad() async {
    await SoundManager.instance.init();

    // Preload images before starting the game
    await images.load('logo.png');
    await images.load('spaceship.png');
    await images.load('laika.png');
    await images.load('background_history.png');
    await images.load('bone.png');

    final pieceNames = [
      'gear-blue', 'gear-blue-broken', 'gear-orange', 'gear-orange-broken',
      'battery-blue', 'battery-blue-broken', 'battery-orange', 'battery-orange-broken',
      'gear', 'gear-broken', 'battery', 'battery-broken',
      'whole', 'broken',
    ];
    for (final name in pieceNames) {
      await images.load('broken_ship_pieces/$name.png');
    }

    add(
      router = RouterComponent(
        routes: {
          'user-select': Route(UserSelectScreen.new, maintainState: false),
          'home': Route(Menu.new),
          'story-mode': Route(StoryMode.new, maintainState: true),
          'minigame-selector': Route(MinigameSelector.new, maintainState: false),
          'ranking': Route(RankingScreen.new, maintainState: false),
          'minigame-1': Route(
            () => ControlPanelRoute(
              mode: ControlPanelMode.miniGame,
              onMiniGameFinishExit: onMinigame1Complete,
            ),
            maintainState: false,
          ),
          'minigame-2': Route(
            () => AsteroidField(
              mode: AsteroidFieldMode.miniGame,
              onMiniGameFinishExit: onMinigame2Complete,
              onBackPressed: _popRoute,
            ),
            maintainState: false,
          ),
          'minigame-3': Route(
            () => BrokenShipRoute(
              mode: BrokenShipMode.miniGame,
              onMiniGameFinishExit: onMinigame3Complete,
            ),
            maintainState: false,
          ),
          'story-challenge-1': Route(
            () => ControlPanelRoute(
              mode: ControlPanelMode.storyMode,
              onMiniGameFinishExit: onChallenge1Complete,
            ),
            maintainState: false,
          ),
          'story-challenge-2': Route(
            () => AsteroidField(
              mode: AsteroidFieldMode.story,
              onMiniGameFinishExit: onChallenge2Complete,
              onBackPressed: _popRoute,
            ),
            maintainState: false,
          ),
          'story-challenge-3': Route(
            () => BrokenShipRoute(
              mode: BrokenShipMode.story,
              onMiniGameFinishExit: onChallenge3Complete,
            ),
            maintainState: false,
          )
        },
        initialRoute: 'user-select',
      ),
    );
  }
}
