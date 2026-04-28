import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/booking_models.dart';

class BookingNotificationService {
  static final BookingNotificationService _instance = BookingNotificationService._internal();

  factory BookingNotificationService() {
    return _instance;
  }

  BookingNotificationService._internal();

  DateTime? _highestSeenCreationTime;
  RxBool _isPlaying = false.obs;
  final AudioPlayer _player = AudioPlayer();
  Timer? _stopTimer;

  void checkNewBooking(List<BookingModel> currentBookings, String currentRoute) {
    if (currentBookings.isEmpty) return;

    // Condition to ONLY enable on specific pages
    if (currentRoute != 'AllTransactionReportScreen' && currentRoute != 'OfflinePaymentScreen') {
      return;
    }

    // Identify newest booking by sorting by creationTime descending.
    final sortedBookings = List<BookingModel>.from(currentBookings);
    sortedBookings.sort((a, b) => b.creationTime.compareTo(a.creationTime));
    final latestBooking = sortedBookings.first;

    DateTime? latestDt;
    try {
      latestDt = DateTime.parse(latestBooking.creationTime);
    } catch (_) {
      return;
    }

    if (_highestSeenCreationTime == null) {
      // First load, initialize the high watermark
      _highestSeenCreationTime = latestDt;
      return;
    }

    // Only trigger if the latest booking's creation time is STRICTLY GREATER than the high watermark
    if (latestDt.isAfter(_highestSeenCreationTime!)) {
      _highestSeenCreationTime = latestDt;
      playSound();
      showPopup(latestBooking.id);
    }
  }

  void playSound() async {
    if (_isPlaying.value) return;
    _isPlaying.value = true;
    
    await _player.play(AssetSource('1.mp3'));

    // Auto-stop after 10 seconds
    _stopTimer?.cancel();
    _stopTimer = Timer(const Duration(seconds: 10), () {
      stopSound();
    });
  }

  /// Manually stop the sound (e.g. from a UI button)
  Future<void> stopSound() async {
    await _player.stop();
    _stopTimer?.cancel();
    _isPlaying.value = false;
    debugPrint("🔕 Sound stopped.");
  }

  void showPopup(String bookingId) {
    Get.snackbar(
      'New Order Received!',
      'You have a new booking (ID: $bookingId).',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFFF9800),
      colorText: Colors.white,
      icon: const Icon(Icons.notifications_active, color: Colors.white),
      duration: const Duration(seconds: 10),
      mainButton: TextButton(
        onPressed: () {
          stopSound();
          if (Get.isSnackbarOpen) {
            Get.closeCurrentSnackbar();
          }
        },
        child: const Text('STOP SOUND', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
