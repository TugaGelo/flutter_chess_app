import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

class SoundController extends GetxController {
  static SoundController get instance => Get.isRegistered<SoundController>() 
      ? Get.find() 
      : Get.put(SoundController());

  final AudioPlayer _player = AudioPlayer();

  Future<void> playClick() async {
    await _player.stop(); 
    await _player.play(AssetSource('audio/click.wav')); 
  }

  Future<void> playCancel() async {
    await _player.stop(); 
    await _player.play(AssetSource('audio/cancel.wav')); 
  }

  Future<void> playMove() async {
    await _player.stop();
    await _player.play(AssetSource('audio/move.mp3'));
  }

  Future<void> playOpponentMove() async {
    await _player.stop();
    await _player.play(AssetSource('audio/move.mp3'));
  }

  Future<void> playCapture() async {
    await _player.stop();
    await _player.play(AssetSource('audio/capture.mp3'));
  }
  
  Future<void> playCheck() async {
    await _player.stop();
    await _player.play(AssetSource('audio/check.mp3'));
  }

  Future<void> playGameStart() async {
    await _player.stop();
    await _player.play(AssetSource('audio/start.mp3'));
  }

  Future<void> playGameEnd() async {
    await _player.stop();
    await _player.play(AssetSource('audio/end.mp3'));
  }
}
