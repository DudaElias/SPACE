import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:space/src/game/game.dart';
import 'package:space/src/game/shared/atoms/back_button.dart';
import 'package:space/src/game/shared/atoms/button.dart';
import 'package:space/src/game/shared/molecules/database.dart';
import 'package:space/src/game/shared/molecules/pre_game_panel.dart';
import 'package:space/src/game/shared/molecules/game_modal.dart';
import 'package:space/src/game/shared/settings.dart';

enum _StoryAction { nextOnly, launchMinigame1, launchMinigame2, launchMinigame3, finish }

class _LaikaRenderInfo {
  _LaikaRenderInfo(this.position, this.size);
  final Vector2 position;
  final Vector2 size;
}

class _AstronautRenderInfo {
  _AstronautRenderInfo(this.position, this.size);
  final Vector2 position;
  final Vector2 size;
}

class _Chapter {
  _Chapter({
    required this.text,
    required this.drawScene,
    required this.laikaInfo,
    this.action = _StoryAction.nextOnly,
    this.buttonLabel,
    this.astronautInfo,
  });

  final String text;
  final _StoryAction action;
  final String? buttonLabel;
  final void Function(Canvas canvas, Vector2 size) drawScene;
  final _LaikaRenderInfo laikaInfo;
  final _AstronautRenderInfo? astronautInfo;
}

class StoryMode extends Component with HasGameReference<SpaceGame> {
  int _chapterIndex = 0;
  late _StoryPage _page;
  bool _awaitingReturn = false;

  static final Vector2 _laikaBaseSize = Vector2(125, 200);

  List<_Chapter> get _chapters {
    return [
      _Chapter(
        text: 'Esta é Laika, uma cachorrinha muito corajosa.\nUm dia, seu melhor amigo humano viajou para o espaço e desapareceu!\nLaika decidiu ir buscá-lo, mas ela precisa da sua ajuda!',
        drawScene: _drawStarsOnly,
        laikaInfo: _LaikaRenderInfo(Vector2(0.5, 0.32), _laikaBaseSize * 1.0),
      ),
      _Chapter(
        text: 'Laika encontrou um foguete na base espacial!\nMas o motor está desligado.\nAjude Laika a ligar o foguete seguindo os comandos do painel!',
        drawScene: _drawStarsOnly,
        laikaInfo: _LaikaRenderInfo(Vector2(0.58, 0.32), _laikaBaseSize * 0.7),
        action: _StoryAction.launchMinigame1,
        buttonLabel: 'Ligar o Foguete!',
      ),
      _Chapter(
        text: 'O motor está ligado! Laika está voando pelo Espaço!\nMas ela precisa passar por um campo de asteroides.\nAjude Laika a desviar de todos!',
        drawScene: _drawAsteroidScene,
        laikaInfo: _LaikaRenderInfo(Vector2(0.5, 0.28), _laikaBaseSize * 0.9),
        action: _StoryAction.launchMinigame2,
        buttonLabel: 'Atravessar!',
      ),
      _Chapter(
        text: 'Laika passou pelos asteroides e encontrou seu humano!\nMas o foguete quebrou na aterrissagem.\nAjude a consertar as peças do foguete para que possam voltar!',
        drawScene: _drawStarsOnly,
        laikaInfo: _LaikaRenderInfo(Vector2(0.37, 0.35), _laikaBaseSize * 0.8),
        astronautInfo: _AstronautRenderInfo(Vector2(0.58, 0.34), _laikaBaseSize * 0.8),
        action: _StoryAction.launchMinigame3,
        buttonLabel: 'Consertar o Foguete!',
      ),
      _Chapter(
        text: 'Missão Cumprida!\nLaika e seu humano estão juntos outra vez!\nObrigado por ajudar, Piloto Espacial! 🌟',
        drawScene: _drawStarsOnly,
        laikaInfo: _LaikaRenderInfo(Vector2(0.6, 0.33), _laikaBaseSize * 0.8),
        astronautInfo: _AstronautRenderInfo(Vector2(0.35, 0.33), _laikaBaseSize * 0.8),
        action: _StoryAction.finish,
        buttonLabel: 'Fim',
      ),
    ];
  }

  @override
  Future<void> onLoad() async {
    _chapterIndex = game.storyChapter;
    if (_chapterIndex >= _chapters.length) {
      _setStoryChapter(0);
      game.router.pop();
      return;
    }
    _buildPage();
  }

  void _setStoryChapter(int value) {
    game.storyChapter = value;
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    final userId = GameSettings.instance.currentUserId;
    if (userId == 0) return;
    final helper = await DatabaseHelper.getInstance();
    await helper.updateStoryProgress(userId, game.storyChapter);
  }

  void _buildPage() {
    final size = game.size;
    removeAll(children);

    final chapter = _chapters[_chapterIndex];

    Sprite? laikaSprite;
    try {
      final image = game.images.fromCache('laika.png');
      laikaSprite = Sprite(image);
    } catch (_) {}

    Sprite? bgSprite;
    try {
      final bgKey = chapter.action == _StoryAction.launchMinigame3
          ? 'background_history_ch4.png'
          : 'background_history.png';
      final image = game.images.fromCache(bgKey);
      bgSprite = Sprite(image);
    } catch (_) {}

    Sprite? spaceship;
    if (chapter.action == _StoryAction.launchMinigame1) {
      try {
        final image = game.images.fromCache('spaceship.png');
        spaceship = Sprite(image);
      } catch (_) {}
    }
    if (chapter.action == _StoryAction.launchMinigame2) {
      try {
        final image = game.images.fromCache('icon.png');
        spaceship = Sprite(image);
      } catch (_) {}
    }
    if (chapter.action == _StoryAction.launchMinigame3) {
      try {
        final image = game.images.fromCache('icon.png');
        spaceship = Sprite(image);
      } catch (_) {}
    }

    Sprite? astronautSprite;
    if (chapter.astronautInfo != null) {
      try {
        final image = game.images.fromCache('astronaut.png');
        astronautSprite = Sprite(image);
      } catch (_) {}
    }

    Sprite? combinedSprite;
    _LaikaRenderInfo? combinedInfo;
    if (chapter.action == _StoryAction.finish) {
      try {
        final image = game.images.fromCache('human_and_laika.png');
        combinedSprite = Sprite(image);
      } catch (_) {}
      combinedInfo = _LaikaRenderInfo(Vector2(0.5, 0.28), Vector2(250, 224));
    }

    _page = _StoryPage(
      chapter: chapter,
      gameSize: size,
      onNext: _onNext,
      laikaSprite: chapter.action == _StoryAction.finish ? null : laikaSprite,
      laikaInfo: chapter.laikaInfo,
      spaceshipSprite: spaceship,
      spaceshipAction: chapter.action,
      astronautSprite: chapter.action == _StoryAction.finish ? null : astronautSprite,
      astronautInfo: chapter.astronautInfo,
      combinedSprite: combinedSprite,
      combinedInfo: combinedInfo,
      bgSprite: bgSprite,
      chapterIndex: _chapterIndex,
      totalChapters: _chapters.length,
      onBack: () {
          game.router.pop();
      },
    );
    add(_page);
  }

  void _onNext(_StoryAction action) {
    switch (action) {
      case _StoryAction.nextOnly:
        _setStoryChapter(_chapterIndex + 1);
        if (_chapterIndex + 1 >= _chapters.length) {
          _setStoryChapter(0);
              game.router.pop();
        } else {
          _chapterIndex++;
          _buildPage();
        }
      case _StoryAction.launchMinigame1:
        _onMinigameLaunch('minigame-1', 'story-challenge-1', 'Painel de Controle');
      case _StoryAction.launchMinigame2:
        _onMinigameLaunch('minigame-2', 'story-challenge-2', 'Campo de Asteroides');
      case _StoryAction.launchMinigame3:
        _onMinigameLaunch('minigame-3', 'story-challenge-3', 'Conserto Espacial');
      case _StoryAction.finish:
        _showCongratulations();
    }
  }

  void _onMinigameLaunch(String minigameKey, String routeName, String title) async {
    final result = await PreGamePanel.show(
      _page,
      title: title,
      showTutorialDefault: !game.completedTutorials.contains(minigameKey),
    );
    if (!result.proceed) return;
    game.storyReturned = false;
    _awaitingReturn = true;
    game.launchMinigameRoute(routeName, skipTutorial: result.skipTutorial);
  }

  void _showCongratulations() {
    _setStoryChapter(0);
    final modal = GameModal(
      title: 'Parabéns!',
      message: 'Você completou toda a história!\nLaika e seu humano estão em casa graças a você.\n\nVolte para o menu e pratique os minijogos!',
      buttonText: 'Voltar ao Menu',
      onPressed: () {
        game.router.pop();
      },
      style: GameModalStyle.success,
      panelSize: Vector2(500, 300),
    );
    modal.layoutForSize(game.size);
    _page.add(modal);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_awaitingReturn && game.storyReturned) {
      _awaitingReturn = false;
      _setStoryChapter(_chapterIndex + 1);
      _chapterIndex = game.storyChapter;
      if (_chapterIndex >= _chapters.length) {
        _setStoryChapter(0);
          game.router.pop();
      } else {
        _buildPage();
      }
    }
  }
}

class _StoryPage extends Component with TapCallbacks {
  _StoryPage({
    required this.chapter,
    required this.gameSize,
    required this.onNext,
    this.laikaSprite,
    required this.laikaInfo,
    this.spaceshipSprite,
    required this.spaceshipAction,
    this.astronautSprite,
    this.astronautInfo,
    this.combinedSprite,
    this.combinedInfo,
    this.bgSprite,
    required this.chapterIndex,
    required this.totalChapters,
    this.onBack,
  });

  final _Chapter chapter;
  final Vector2 gameSize;
  final void Function(_StoryAction action) onNext;
  final Sprite? laikaSprite;
  final _LaikaRenderInfo laikaInfo;
  final Sprite? spaceshipSprite;
  final _StoryAction spaceshipAction;
  final Sprite? astronautSprite;
  final _AstronautRenderInfo? astronautInfo;
  final Sprite? combinedSprite;
  final _LaikaRenderInfo? combinedInfo;
  final Sprite? bgSprite;
  final int chapterIndex;
  final int totalChapters;
  final VoidCallback? onBack;

  late final TextComponent _text;
  late final RoundedButton _button;
  String _fullText = '';
  int _charsToShow = 0;
  double _typeTimer = 0;
  bool _textComplete = false;
  static const double _typeSpeed = 0.025;

  @override
  Future<void> onLoad() async {
    _fullText = chapter.text;
    _charsToShow = 0;
    _typeTimer = 0;
    _textComplete = false;

    _text = TextComponent(
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: const Color(0xFFE2E8F0),
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(gameSize.x / 2, gameSize.y * 0.7),
      priority: 10,
    );
    add(_text);

    final label = chapter.buttonLabel ?? (chapter.action == _StoryAction.finish ? 'Fim' : 'Próximo');
    _button = RoundedButton(
      text: label,
      action: () => onNext(chapter.action),
      color: const Color(0xffFF986A),
      size: Vector2(320, 56),
      position: Vector2(gameSize.x / 2, gameSize.y * 0.88),
    );
    _button.priority = 10;
    add(_button);

    final chapterIndicator = TextComponent(
      text: 'Capítulo ${chapterIndex + 1} / $totalChapters',
      textRenderer: TextPaint(
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: const Color(0xFFFFD94D),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(gameSize.x / 2, gameSize.y * 0.04),
      priority: 20,
    );
    add(chapterIndicator);

    if (onBack != null) {
      final backBtn = GameBackButton(
        onPressed: onBack!,
        position: Vector2(24, 24),
        anchor: Anchor.topLeft,
        size: Vector2.all(40),
      );
      backBtn.priority = 20;
      add(backBtn);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_textComplete) {
      _typeTimer += dt;
      while (_typeTimer >= _typeSpeed && _charsToShow < _fullText.length) {
        _typeTimer -= _typeSpeed;
        _charsToShow++;
      }
      if (_charsToShow >= _fullText.length) {
        _charsToShow = _fullText.length;
        _textComplete = true;
      }
      _text.text = _fullText.substring(0, _charsToShow);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!_textComplete) {
      _charsToShow = _fullText.length;
      _text.text = _fullText;
      _textComplete = true;
      _typeTimer = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    if (bgSprite != null) {
      bgSprite!.render(canvas, size: gameSize);
    } else {
      chapter.drawScene(canvas, gameSize);
    }

    if (spaceshipAction == _StoryAction.launchMinigame3) {
      _drawAsteroid(canvas, gameSize.x * 0.48, gameSize.y * 0.45, 12);
    }

    if (spaceshipSprite != null) {
      if (spaceshipAction == _StoryAction.launchMinigame2) {
        spaceshipSprite!.render(
          canvas,
          position: Vector2(gameSize.x * 0.45, gameSize.y * 0.20),
          size: Vector2(160, 144),
        );
      } else if (spaceshipAction == _StoryAction.launchMinigame3) {
        spaceshipSprite!.render(
          canvas,
          position: Vector2(gameSize.x * 0.30, gameSize.y * 0.28),
          size: Vector2(160, 144),
        );
      } else {
        spaceshipSprite!.render(
          canvas,
          position: Vector2(gameSize.x / 2 - 90, gameSize.y * 0.30 - 70),
          size: Vector2(130, 117),
        );
      }
    }

    if (combinedSprite != null && combinedInfo != null) {
      combinedSprite!.render(
        canvas,
        position: Vector2(
          gameSize.x * combinedInfo!.position.x,
          gameSize.y * combinedInfo!.position.y,
        ),
        size: combinedInfo!.size,
        anchor: Anchor.center,
      );
    } else {
      if (laikaSprite != null && spaceshipAction != _StoryAction.launchMinigame2 && spaceshipAction != _StoryAction.launchMinigame3) {
        laikaSprite!.render(
          canvas,
          position: Vector2(
            gameSize.x * laikaInfo.position.x,
            gameSize.y * laikaInfo.position.y,
          ),
          size: laikaInfo.size,
          anchor: Anchor.center,
        );
      }

      if (astronautSprite != null && astronautInfo != null) {
        astronautSprite!.render(
          canvas,
          position: Vector2(
            gameSize.x * astronautInfo!.position.x,
            gameSize.y * astronautInfo!.position.y,
          ),
          size: astronautInfo!.size,
          anchor: Anchor.center,
        );
      }
    }

    canvas.drawRect(
      Rect.fromLTWH(0, gameSize.y * 0.56, gameSize.x, gameSize.y * 0.50),
      Paint()..color = const Color(0x99050816),
    );

    super.render(canvas);
  }
}

void _drawStarsOnly(Canvas canvas, Vector2 size) {
  _drawStars(canvas, size);
}

void _drawAsteroidScene(Canvas canvas, Vector2 size) {
  final cx = size.x / 2;
  final cy = size.y * 0.30;

  _drawStars(canvas, size);

  _drawAsteroid(canvas, cx + 100, cy + 50, 0.8);
}

void _drawStars(Canvas canvas, Vector2 size) {
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.x, size.y),
    Paint()..color = const Color(0xFF050816),
  );

  final rng = Random(42);
  for (int i = 0; i < 60; i++) {
    final x = rng.nextDouble() * size.x;
    final y = rng.nextDouble() * size.y * 0.55;
    final r = 0.5 + rng.nextDouble() * 1.5;
    final alpha = 40 + rng.nextInt(120);
    canvas.drawCircle(
      Offset(x, y),
      r,
      Paint()..color = Colors.white.withAlpha(alpha),
    );
  }
}

void _drawAsteroid(Canvas canvas, double cx, double cy, double scale) {
  canvas.save();
  canvas.translate(cx, cy);
  canvas.scale(scale);

  canvas.drawCircle(
    const Offset(0, 0),
    18,
    Paint()..color = const Color(0xFF8D6E63),
  );
  canvas.drawCircle(
    const Offset(-5, -3),
    5,
    Paint()..color = const Color(0xFF6D4C41),
  );
  canvas.drawCircle(
    const Offset(6, 4),
    3,
    Paint()..color = const Color(0xFF6D4C41),
  );

  canvas.restore();
}
