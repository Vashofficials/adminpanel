import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  final RxBool _isPlaying = false.obs;
  Timer? _stopTimer;

  RxBool get isPlaying => _isPlaying;

  /// Plays the custom booking sound in a loop for 30 seconds
  Future<void> playBookingSound() async {
    if (_isPlaying.value) return; // Debounce: Already playing

    debugPrint("🔔 New Booking detected! Playing notification sound...");
    _isPlaying.value = true;
    
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      // AssetSource searches inside 'assets/' by default
      await _player.play(AssetSource('1.mp3'));

      // Force stop after 30 seconds
      _stopTimer?.cancel();
      _stopTimer = Timer(const Duration(seconds: 30), () {
        stopSound();
      });
    } catch (e) {
      _isPlaying.value = false;
      debugPrint("❌ Error playing sound: $e");
    }
  }

  /// Manually stop the sound (e.g. from a UI button)
  Future<void> stopSound() async {
    await _player.stop();
    _stopTimer?.cancel();
    _isPlaying.value = false;
    debugPrint("🔕 Sound stopped.");
  }
}
