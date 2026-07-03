import 'package:flame/game.dart';
import 'package:space/src/game/asteroid_field/asteroid_field.dart';
import 'package:space/src/game/control_panel/control_panel_route.dart';
import 'package:space/src/game/menu.dart';
import 'package:space/src/game/minigames.dart';
import 'package:space/src/game/ranking.dart';
import 'package:space/src/game/story_mode.dart';
import 'package:space/src/game/user_select.dart';
import 'package:space/src/game/shared/molecules/database.dart';
import 'package:space/src/game/shared/settings.dart';

class SpaceGame extends FlameGame {
  late final RouterComponent router;
  int storyChapter = 0;
  bool storyReturned = false;
  final Set<String> unlockedMinigames = <String>{};

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

  void onChallenge1Complete() {
    unlockedMinigames.add('minigame-1');
    storyReturned = true;
    _recordRanking('minigame-1', 'win', 0);
    _saveUnlock('minigame-1');
    router.pop();
  }

  void onChallenge2Complete() {
    unlockedMinigames.add('minigame-2');
    storyReturned = true;
    _recordRanking('minigame-2', 'win', 0);
    _saveUnlock('minigame-2');
    router.pop();
  }

  void onMinigame1Complete() {
    _recordRanking('minigame-1', 'win', 0);
    router.pop();
  }

  void onMinigame2Complete() {
    _recordRanking('minigame-2', 'win', 0);
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
    // Preload images before starting the game
    await images.load('logo.png');
    await images.load('spaceship.png');
    await images.load('laika.png');
    await images.load('background_history.png');
    await images.load('bone.png');

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
            () => AsteroidField(
              mode: AsteroidFieldMode.miniGame,
              onMiniGameFinishExit: router.pop,
              onBackPressed: _popRoute,
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
          )
        },
        initialRoute: 'user-select',
      ),
    );
  }
}
