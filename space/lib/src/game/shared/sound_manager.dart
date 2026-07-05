import 'package:flame_audio/flame_audio.dart';

import 'settings.dart';

class _SfxEntry {
  const _SfxEntry(this.key, this.path, {this.maxPlayers = 4});
  final String key;
  final String path;
  final int maxPlayers;
}

class SoundManager {
  static final SoundManager _instance = SoundManager._();
  static SoundManager get instance => _instance;
  SoundManager._();

  bool _initialized = false;
  final Map<String, AudioPool> _pools = {};

  static const _sfx = [
    _SfxEntry('correct', 'shared/correct.mp3'),
    _SfxEntry('incorrect', 'shared/incorrect.mp3'),
    _SfxEntry('success', 'shared/success.mp3'),
    _SfxEntry('whoosh', 'broken_ship/whoosh.mp3'),
    _SfxEntry('ui_click', 'shared/ui_click.ogg'),
    _SfxEntry('pad_a', 'control_panel/pad_a.mp3', maxPlayers: 2),
    _SfxEntry('pad_b', 'control_panel/pad_b.mp3', maxPlayers: 2),
    _SfxEntry('pad_c', 'control_panel/pad_c.mp3', maxPlayers: 2),
    _SfxEntry('pad_d', 'control_panel/pad_d.mp3', maxPlayers: 2),
    _SfxEntry('asteroid_hit', 'asteroid_field/asteroid_hit.mp3'),
  ];

  Future<void> init() async {
    if (_initialized) return;

    AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );

    FlameAudio.audioCache.prefix = 'assets/sounds/';

    for (final entry in _sfx) {
      _pools[entry.key] = await FlameAudio.createPool(
        entry.path,
        maxPlayers: entry.maxPlayers,
      );
    }

    _initialized = true;
  }

  void playSfx(String key, {double? volume}) {
    _pools[key]?.start(
      volume: volume ?? GameSettings.instance.soundVolume,
    );
  }

  Future<void> playBgm(String path) async {
    await FlameAudio.bgm.stop();
    await FlameAudio.bgm.play(path, volume: GameSettings.instance.soundVolume);
  }

  Future<void> stopBgm() async {
    await FlameAudio.bgm.stop();
  }
}
