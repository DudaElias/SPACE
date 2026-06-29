import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:space/src/game/game.dart';
import 'package:space/src/game/shared/atoms/button.dart';
import 'package:space/src/game/shared/molecules/game_modal.dart';
import 'package:space/src/game/shared/settings.dart';

class Menu extends Component with HasGameReference<SpaceGame> {
  late final SpriteComponent _logo;
  late final RoundedButton _btnStory;
  late final RoundedButton _btnMinigames;
  late final RoundedButton _btnRanking;
  late final RoundedButton _btnHelp;
  late final RoundedButton _btnConfig;
  GameModal? _activeModal;
  bool _laidOut = false;

  @override
  Future<void> onMount() async {
    super.onMount();
    final logoImage = game.images.fromCache('logo.png');

    _logo = SpriteComponent(sprite: Sprite(logoImage), size: Vector2(380, 380), anchor: Anchor.center);
    _btnStory = RoundedButton(text: 'Iniciar Missão', action: () => game.router.pushNamed('story-mode'), color: const Color(0xffFF986A));
    _btnMinigames = RoundedButton(text: 'Mini Jogos', action: () => game.router.pushNamed('minigame-selector'), color: const Color(0xffFF986A));
    _btnRanking = RoundedButton(text: 'Ranking', action: () => game.router.pushNamed('ranking'), color: const Color(0xFF1F3A5F));
    _btnHelp = RoundedButton(text: 'Ajuda', action: _openHelp, color: const Color(0xFF1F3A5F));
    _btnConfig = RoundedButton(text: 'Configurações', action: _openSettings, color: const Color(0xFF1F3A5F));

    addAll([_logo, _btnStory, _btnMinigames, _btnRanking, _btnHelp, _btnConfig]);

    _updateStoryButton();
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
    }
  }

  void _openHelp() {
    _activeModal?.removeFromParent();
    _activeModal = GameModal(
      title: 'Como Jogar',
      message: 'Modo História: Acompanhe a Laika em uma aventura pelo Espaço para encontrar seu humano. Passe pelos desafios para avançar na história.\n\nMini Jogos: Pratique os desafios separadamente. Cada jogo fica disponível após ser completado no Modo História.\n\nDesafios:\n- Painel de Controle: memorize a sequência de luzes e repita na ordem certa.\n- Campo de Asteroides: arraste o foguete para desviar dos asteroides e colete ossinhos.\n- Conserto Espacial: em breve!',
      buttonText: 'Entendi!',
      onPressed: () { _activeModal?.removeFromParent(); _activeModal = null; },
      panelSize: Vector2(480, 500),
    );
    _activeModal!.layoutForSize(game.size);
    add(_activeModal!);
  }

  void _openSettings() {
    final diff = GameSettings.instance;
    _activeModal?.removeFromParent();
    _activeModal = GameModal(
      title: 'Configurações',
      message: 'Dificuldade: ${diff.difficultyLabel}\nToque abaixo para mudar.',
      buttonText: 'Mudar Dificuldade',
      onPressed: _cycleDifficulty,
    );
    _activeModal!.layoutForSize(game.size);
    add(_activeModal!);
  }

  void _cycleDifficulty() {
    final d = GameSettings.instance;
    if (d.difficulty == GameSettings.easy) {
      d.difficulty = GameSettings.medium;
    } else if (d.difficulty == GameSettings.medium) {
      d.difficulty = GameSettings.hard;
    } else {
      d.difficulty = GameSettings.easy;
    }
    _activeModal?.configure(message: 'Dificuldade: ${d.difficultyLabel}\nToque abaixo para mudar.');
  }
}
