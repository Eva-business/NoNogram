import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _bgmPlayer = AudioPlayer();
  static bool _initialized = false;

  static Future<void> initBgm() async {
    if (_initialized) return;
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    _initialized = true;
  }

  static Future<void> playBgm() async {
    await initBgm();
    await _bgmPlayer.setVolume(1.0);
    await _bgmPlayer.play(AssetSource('audio/music.mp3'));
  }

  static Future<void> stopBgm() async {
    await _bgmPlayer.stop();
  }

  static Future<void> pauseBgm() async {
    await _bgmPlayer.pause();
  }

  static Future<void> resumeBgm() async {
    await _bgmPlayer.resume();
  }

  static Future<void> setVolume(double volume) async {
    await _bgmPlayer.setVolume(volume);
  }
}
