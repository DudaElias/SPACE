import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:space/src/game/game.dart';
import 'package:space/src/game/shared/atoms/button.dart';
import 'package:space/src/game/shared/atoms/back_button.dart';
import 'package:space/src/game/shared/molecules/game_modal.dart';
import 'package:space/src/game/shared/settings.dart';
import 'package:space/src/game/shared/sound_manager.dart';

class Menu extends Component with HasGameReference<SpaceGame> {
  late SpriteComponent _logo;
  late RoundedButton _btnStory;
  late RoundedButton _btnMinigames;
  late RoundedButton _btnRanking;
  late RoundedButton _btnHelp;
  late RoundedButton _btnConfig;
  Component? _activeOverlay;
  bool _laidOut = false;
  final List<Component> _hudComponents = [];

  @override
  Future<void> onMount() async {
    super.onMount();
    removeAll(children);
    _laidOut = false;
    _activeOverlay = null;
    game.setOverlayOpen(false);
    final logoImage = game.images.fromCache('logo.png');

    _logo = SpriteComponent(sprite: Sprite(logoImage), size: Vector2(380, 380), anchor: Anchor.center);
    _btnStory = RoundedButton(text: 'Iniciar Missão', action: () { SoundManager.instance.stopBgm(); game.router.pushNamed('story-mode'); }, color: const Color(0xffFF986A));
    _btnMinigames = RoundedButton(text: 'Mini Jogos', action: () => game.router.pushNamed('minigame-selector'), color: const Color(0xffFF986A));
    _btnRanking = RoundedButton(text: 'Ranking', action: () => game.router.pushNamed('ranking'), color: const Color(0xFF1F3A5F));
    _btnHelp = RoundedButton(text: 'Ajuda', action: _openHelp, color: const Color(0xFF1F3A5F));
    _btnConfig = RoundedButton(text: 'Configurações', action: _openSettings, color: const Color(0xFF1F3A5F));

    addAll([_logo, _btnStory, _btnMinigames, _btnRanking, _btnHelp, _btnConfig]);

    _hudComponents.add(SimpleBackButton());
    game.camera.viewport.addAll(_hudComponents);

    SoundManager.instance.playBgm('shared/menu_bgm.mp3');

    _updateStoryButton();
  }

  @override
  void onRemove() {
    SoundManager.instance.stopBgm();
    game.setOverlayOpen(false);
    game.camera.viewport.removeAll(_hudComponents);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_laidOut && game.size.x > 0) {
      _laidOut = true;
      _doLayout(game.size);
    }
    _updateStoryButton();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isMounted) return;
    _doLayout(size);
    _laidOut = true;
  }

  void _doLayout(Vector2 size) {
    final cx = size.x / 2;
    final logoY = size.y * 0.30;
    _logo.position = Vector2(cx, logoY);

    final gap = 64;
    final startY = logoY + 190;
    _btnStory.position = Vector2(cx, startY);
    _btnMinigames.position = Vector2(cx, startY + gap);
    _btnRanking.position = Vector2(cx, startY + gap * 2);
    _btnHelp.position = Vector2(cx, startY + gap * 3);
    _btnConfig.position = Vector2(cx, startY + gap * 4);
  }

  void _updateStoryButton() {
    if (game.storyChapter > 0 && _btnStory.text == 'Iniciar Missão') {
      _btnStory.setText('Continuar Missão');
    } else if (game.storyChapter == 0 && _btnStory.text == 'Continuar Missão') {
      _btnStory.setText('Iniciar Missão');
    }
  }

  void _closeOverlay() {
    _activeOverlay?.removeFromParent();
    _activeOverlay = null;
    game.setOverlayOpen(false);
  }

  void _openHelp() {
    _activeOverlay?.removeFromParent();
    final modal = GameModal(
      title: 'Como Jogar',
      message: 'Modo História: Acompanhe a Laika em uma aventura pelo espaço para encontrar seu humano. Passe pelos desafios para avançar na história.\n\nMini Jogos: Pratique os desafios separadamente. Cada jogo fica disponível após ser completado no Modo História.\n\nDesafios:\n\n* Painel de Controle:\n  memorize a sequência de luzes e repita na ordem certa.\n\n* Campo de Asteroides:\n  arraste o foguete para desviar dos asteroides e colete petiscos.\n\n* Conserto Espacial:\n  classifique as peças nos cestos corretos para consertar a nave.\n\nDica: O tutorial aparece na primeira vez que você joga cada minijogo. Para revê-lo, ative "Mostrar tutorial" ao iniciar o minijogo pela tela de seleção.',
      buttonText: 'Entendi!',
      onPressed: _closeOverlay,
      onBackdropTap: _closeOverlay,
      panelSize: Vector2(510, 560),
    );
    _activeOverlay = modal;
    game.setOverlayOpen(true);
    modal.layoutForSize(game.size);
    add(modal);
  }

  void _openSettings() {
    _activeOverlay?.removeFromParent();
    final panel = _SettingsPanel(
      gameSize: game.size,
      onClose: _closeOverlay,
      onDifficultyChanged: () {},
      onVolumeChanged: (v) { game.setGlobalVolume(v); },
      onMuteToggled: () {},
    );
    _activeOverlay = panel;
    game.setOverlayOpen(true);
    add(panel);
  }
}

class _SettingsPanel extends PositionComponent {
  _SettingsPanel({
    required Vector2 gameSize,
    required this.onClose,
    required this.onDifficultyChanged,
    required this.onVolumeChanged,
    required this.onMuteToggled,
  }) : _gameSize = gameSize,
       super(size: gameSize, priority: 100);

  final Vector2 _gameSize;
  final VoidCallback onClose;
  final VoidCallback onDifficultyChanged;
  final void Function(double volume) onVolumeChanged;
  final VoidCallback onMuteToggled;

  static final Vector2 _panelSize = Vector2(480, 380);

  late _SettingsBackdrop _backdrop;
  late _SettingsShell _shell;
  late TextComponent _titleText;
  late _SettingsCloseButton _closeBtn;

  late TextComponent _diffLabel;
  late _DifficultyButton _btnEasy;
  late _DifficultyButton _btnMedium;
  late _DifficultyButton _btnHard;

  late TextComponent _soundLabel;
  late _MuteButton _muteBtn;
  late _VolumeSlider _volumeSlider;

  @override
  Future<void> onLoad() async {
    final cx = _gameSize.x / 2;
    final cy = _gameSize.y / 2;
    final panelCenter = Vector2(cx, cy);
    final textStyle = TextStyle(
      fontFamily: GoogleFonts.silkscreen().fontFamily,
      color: const Color(0xFFE2E8F0),
    );

    _backdrop = _SettingsBackdrop(
      position: Vector2.zero(),
      size: _gameSize,
      onTap: onClose,
    )..priority = 100;
    add(_backdrop);

    _shell = _SettingsShell(size: _panelSize)
      ..position = panelCenter
      ..anchor = Anchor.center
      ..priority = 101;
    add(_shell);

    _titleText = TextComponent(
      text: 'Configurações',
      anchor: Anchor.topCenter,
      priority: 102,
      textRenderer: TextPaint(
        style: textStyle.copyWith(fontSize: 26, fontWeight: FontWeight.w700),
      ),
    )..position = panelCenter + Vector2(0, -_panelSize.y / 2 + 30);
    add(_titleText);

    _closeBtn = _SettingsCloseButton(
      position: panelCenter + Vector2(_panelSize.x / 2 - 30, -_panelSize.y / 2 + 30),
      onTap: onClose,
    )..priority = 102;
    add(_closeBtn);

    final sectionY = panelCenter.y - _panelSize.y / 2 + 85;

    _diffLabel = TextComponent(
      text: 'Dificuldade',
      anchor: Anchor.topCenter,
      priority: 102,
      textRenderer: TextPaint(
        style: textStyle.copyWith(fontSize: 16, color: const Color(0xFF9EEAFF)),
      ),
    )..position = Vector2(cx, sectionY);
    add(_diffLabel);

    final diff = GameSettings.instance;
    final btnY = sectionY + 55;
    final btnSpacing = 135;

    _btnEasy = _DifficultyButton(
      label: 'Fácil',
      selected: diff.difficulty == GameSettings.easy,
      position: Vector2(cx - btnSpacing, btnY),
      onTap: () { diff.difficulty = GameSettings.easy; _refreshDifficulty(); onDifficultyChanged(); },
    )..priority = 102;
    _btnMedium = _DifficultyButton(
      label: 'Médio',
      selected: diff.difficulty == GameSettings.medium,
      position: Vector2(cx, btnY),
      onTap: () { diff.difficulty = GameSettings.medium; _refreshDifficulty(); onDifficultyChanged(); },
    )..priority = 102;
    _btnHard = _DifficultyButton(
      label: 'Difícil',
      selected: diff.difficulty == GameSettings.hard,
      position: Vector2(cx + btnSpacing, btnY),
      onTap: () { diff.difficulty = GameSettings.hard; _refreshDifficulty(); onDifficultyChanged(); },
    )..priority = 102;

    addAll([_btnEasy, _btnMedium, _btnHard]);

    final diffDescStyle = TextStyle(
      fontFamily: GoogleFonts.silkscreen().fontFamily,
      color: const Color(0xFF94A3B8),
      fontSize: 11,
    );
    final descY = btnY + 30;
    add(TextComponent(
      text: 'para começar',
      anchor: Anchor.topCenter,
      priority: 102,
      textRenderer: TextPaint(style: diffDescStyle),
    )..position = Vector2(cx - btnSpacing, descY));
    add(TextComponent(
      text: 'mais rápido',
      anchor: Anchor.topCenter,
      priority: 102,
      textRenderer: TextPaint(style: diffDescStyle),
    )..position = Vector2(cx, descY));
    add(TextComponent(
      text: 'para experts',
      anchor: Anchor.topCenter,
      priority: 102,
      textRenderer: TextPaint(style: diffDescStyle),
    )..position = Vector2(cx + btnSpacing, descY));

    final soundSectionY = btnY + 65;

    _soundLabel = TextComponent(
      text: 'Volume',
      anchor: Anchor.topCenter,
      priority: 102,
      textRenderer: TextPaint(
        style: textStyle.copyWith(fontSize: 16, color: const Color(0xFF9EEAFF)),
      ),
    )..position = Vector2(cx, soundSectionY);
    add(_soundLabel);

    _muteBtn = _MuteButton(
      position: Vector2(cx - _panelSize.x / 2 + 60, soundSectionY + 54),
      muted: GameSettings.instance.soundVolume <= 0,
      onTap: () {
        final s = GameSettings.instance;
        if (s.soundVolume > 0) {
          _prevVolume = s.soundVolume;
          s.soundVolume = 0;
        } else {
          s.soundVolume = _prevVolume > 0 ? _prevVolume : 1.0;
        }
        final spaceGame = findGame()! as SpaceGame;
        spaceGame.setGlobalVolume(s.soundVolume);
        _muteBtn.setMuted(s.soundVolume <= 0);
        _volumeSlider.setVolume(s.soundVolume);
        onMuteToggled();
        onVolumeChanged(s.soundVolume);
      },
    )..priority = 102;
    add(_muteBtn);

    _volumeSlider = _VolumeSlider(
      position: Vector2(cx - _panelSize.x / 2 + 110, soundSectionY + 36),
      size: Vector2(_panelSize.x - 160, 36),
      volume: GameSettings.instance.soundVolume,
      onChanged: (v) {
        GameSettings.instance.soundVolume = v;
        _muteBtn.setMuted(v <= 0);
        onVolumeChanged(v);
      },
    )..priority = 102;
    add(_volumeSlider);
  }

  double _prevVolume = 1.0;

  void _refreshDifficulty() {
    final diff = GameSettings.instance;
    _btnEasy.selected = diff.difficulty == GameSettings.easy;
    _btnMedium.selected = diff.difficulty == GameSettings.medium;
    _btnHard.selected = diff.difficulty == GameSettings.hard;
  }
}

class _SettingsBackdrop extends RectangleComponent with TapCallbacks {
  _SettingsBackdrop({
    required super.position,
    required super.size,
    required this.onTap,
  }) : super(paint: Paint()..color = const Color(0xCC020617));

  final VoidCallback onTap;

  @override
  @mustCallSuper
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    onTap();
  }
}

class _SettingsShell extends PositionComponent with TapCallbacks {
  _SettingsShell({required super.size}) : super(anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [Color(0xEE111F39), Color(0xEE0A1429)],
    );
    final panel = RRect.fromRectAndRadius(rect, const Radius.circular(22));

    canvas.drawRRect(panel, Paint()..shader = gradient.createShader(rect));
    canvas.drawRRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF62D5FF).withAlpha(170),
    );
    canvas.drawRRect(
      panel.inflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF9EEAFF).withAlpha(70),
    );
  }
}

class _SettingsCloseButton extends PositionComponent with TapCallbacks {
  _SettingsCloseButton({required super.position, required this.onTap})
    : super(size: Vector2.all(36), anchor: Anchor.center);

  final VoidCallback onTap;

  @override
  void render(Canvas canvas) {
    final bgPaint = Paint()..color = Colors.white.withValues(alpha: 0.15);
    canvas.drawCircle(const Offset(18, 18), 16, bgPaint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(11, 11), const Offset(25, 25), linePaint);
    canvas.drawLine(const Offset(25, 11), const Offset(11, 25), linePaint);
  }

  @override
  void onTapUp(TapUpEvent event) => onTap();
}

class _DifficultyButton extends PositionComponent with TapCallbacks {
  _DifficultyButton({
    required String label,
    required this.selected,
    required super.position,
    required this.onTap,
  }) : _label = label,
       super(size: Vector2(110, 40), anchor: Anchor.center);

  final String _label;
  final VoidCallback onTap;
  bool selected;

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    final bgColor = selected ? const Color(0xffFF986A) : const Color(0xFF1F3A5F);
    canvas.drawRRect(rrect, Paint()..color = bgColor);

    final tp = TextPainter(
      text: TextSpan(
        text: _label,
        style: TextStyle(
          fontFamily: GoogleFonts.silkscreen().fontFamily,
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2));
  }

  @override
  void onTapUp(TapUpEvent event) => onTap();
}

class _MuteButton extends PositionComponent with TapCallbacks {
  _MuteButton({
    required super.position,
    required bool muted,
    required this.onTap,
  }) : _muted = muted,
       super(size: Vector2.all(40), anchor: Anchor.center);

  final VoidCallback onTap;
  bool _muted;

  void setMuted(bool muted) => _muted = muted;

  @override
  void render(Canvas canvas) {
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawCircle(const Offset(20, 20), 18, bgPaint);

    final iconPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(12, 18)
      ..lineTo(17, 18)
      ..lineTo(22, 13)
      ..lineTo(22, 27)
      ..lineTo(17, 22)
      ..lineTo(12, 22)
      ..close();
    canvas.drawPath(path, iconPaint);

    canvas.drawLine(
      const Offset(26, 24),
      const Offset(30, 17),
      iconPaint..style = PaintingStyle.stroke..strokeWidth = 2,
    );
    canvas.drawLine(
      const Offset(26, 17),
      const Offset(30, 24),
      iconPaint..style = PaintingStyle.stroke..strokeWidth = 2,
    );

    if (_muted) {
      final xPaint = Paint()
        ..color = const Color(0xFFFF4444)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawLine(const Offset(25, 14), const Offset(31, 27), xPaint);
      canvas.drawLine(const Offset(31, 14), const Offset(25, 27), xPaint);
    }
  }

  @override
  void onTapUp(TapUpEvent event) => onTap();
}

class _VolumeSlider extends PositionComponent with DragCallbacks, TapCallbacks {
  _VolumeSlider({
    required super.position,
    required super.size,
    required double volume,
    required this.onChanged,
  }) : _volume = volume.clamp(0.0, 1.0);

  final void Function(double volume) onChanged;
  double _volume;

  void setVolume(double v) => _volume = v.clamp(0.0, 1.0);

  double get _knobX => _trackLeft + (_volume * (_trackRight - _trackLeft));

  static const double _trackLeft = 0;
  double get _trackRight => size.x;
  double get _trackY => size.y / 2;
  static const double _knobRadius = 10;
  static const double _trackHeight = 5;

  @override
  void render(Canvas canvas) {
    final trackRect = RRect.fromLTRBR(
      _trackLeft, _trackY - _trackHeight / 2,
      _trackRight, _trackY + _trackHeight / 2,
      const Radius.circular(3),
    );
    canvas.drawRRect(trackRect, Paint()..color = Colors.white.withValues(alpha: 0.18));

    final fillRect = RRect.fromLTRBR(
      _trackLeft, _trackY - _trackHeight / 2,
      _knobX, _trackY + _trackHeight / 2,
      const Radius.circular(3),
    );
    canvas.drawRRect(fillRect, Paint()..color = const Color(0xFF62D5FF).withValues(alpha: 0.7));

    canvas.drawCircle(
      Offset(_knobX, _trackY),
      _knobRadius,
      Paint()..color = const Color(0xFF62D5FF),
    );
    canvas.drawCircle(
      Offset(_knobX, _trackY),
      _knobRadius - 2,
      Paint()..color = Colors.white,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    _updateFromCanvasX(event.canvasPosition.x);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _updateFromCanvasX(event.canvasPosition.x);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _updateFromCanvasX(event.canvasEndPosition.x);
  }

  void _updateFromCanvasX(double canvasX) {
    final localX = canvasX - absolutePosition.x;
    final newVolume = ((localX - _trackLeft) / (_trackRight - _trackLeft)).clamp(0.0, 1.0);
    if ((newVolume - _volume).abs() > 0.001) {
      _volume = newVolume;
      onChanged(_volume);
    }
  }
}
