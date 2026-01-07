import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

class SoundController extends GetxController {
  static SoundController get instance => Get.isRegistered<SoundController>() 
      ? Get.find() 
      : Get.put(SoundController());

  final AudioPlayer _uiPlayer = AudioPlayer();
  final AudioPlayer _gamePlayer = AudioPlayer();

  Future<void> playClick() async {
    if (_uiPlayer.state == PlayerState.playing) await _uiPlayer.stop();
    await _uiPlayer.play(AssetSource('audio/click.wav')); 
  }

  Future<void> playCancel() async {
    if (_uiPlayer.state == PlayerState.playing) await _uiPlayer.stop();
    await _uiPlayer.play(AssetSource('audio/cancel.wav')); 
  }

  Future<void> playMove() async {
    await _gamePlayer.stop();
    await _gamePlayer.play(AssetSource('audio/move.mp3'));
  }

  Future<void> playOpponentMove() async {
    await _gamePlayer.stop();
    await _gamePlayer.play(AssetSource('audio/move.mp3'));
  }

  Future<void> playCapture() async {
    await _gamePlayer.stop();
    await _gamePlayer.play(AssetSource('audio/capture.mp3'));
  }
  
  Future<void> playCheck() async {
    await _gamePlayer.stop();
    await _gamePlayer.play(AssetSource('audio/check.mp3'));
  }

  Future<void> playGameStart() async {
    await _gamePlayer.stop();
    await _gamePlayer.play(AssetSource('audio/start.mp3'));
  }

  Future<void> playGameEnd() async {
    await _gamePlayer.stop();
    await _gamePlayer.play(AssetSource('audio/end.mp3'));
  }
}
