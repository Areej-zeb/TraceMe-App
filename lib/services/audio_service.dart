import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playRing() async {
    try {
      debugPrint('AudioService: Preparing ring playback...');
      
      // Stop any previous instance
      await _player.stop();
      
      // Set the release mode to loop
      await _player.setReleaseMode(ReleaseMode.loop);
      
      debugPrint('AudioService: Playing from assets/ring.mp3...');
      // Note: AssetSource expects the path relative to the 'assets' folder
      // but without the 'assets/' prefix if it's directly under assets.
      await _player.play(AssetSource('ring.mp3'));
      
      debugPrint('AudioService: Playback command sent.');
    } catch (e, stack) {
      debugPrint('AudioService Error: $e');
      debugPrint(stack.toString());
    }
  }

  Future<void> stopRing() async {
    try {
      await _player.stop();
      debugPrint('AudioService: Playback stopped.');
    } catch (e) {
      debugPrint('AudioService Stop Error: $e');
    }
  }
}
