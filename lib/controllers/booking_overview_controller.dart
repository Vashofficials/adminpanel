import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/booking_models.dart';
import '../repositories/booking_repository.dart';
import '../services/audio_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

// =============================================================================
// DATA CLASSES
// =============================================================================

class TrendPoint {
  final String label; // e.g. "21 Apr" or "Week 16"
  final double x;
  final int count;

  const TrendPoint({required this.label, required this.x, required this.count});
}

class DonutSegment {
  final String label;
  final int count;
  final int colorHex;

  const DonutSegment(
      {required this.label, required this.count, required this.colorHex});
  double get value => count.toDouble();
}

// =============================================================================
// CONTROLLER
// =============================================================================

class BookingOverviewController extends GetxController {
  final BookingRepository _repo = BookingRepository();

  // --- Loading / Error ---
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  // --- KPI ---
  var totalBookings = 0.obs;
  var pendingCount = 0.obs;
  var completedCount = 0.obs;
  var canceledCount = 0.obs;
  var offlinePaymentCount = 0.obs;
  var totalRevenue = 0.0.obs;

  // --- Charts ---
  var trendPoints = <TrendPoint>[].obs;
  var trendMode = 'Daily'.obs; // 'Daily' | 'Weekly'
  var donutSegments = <DonutSegment>[].obs;

  // --- Recent Bookings (last 20) ---
  var recentBookings = <BookingModel>[].obs;

  // Internal: full fetched list used for computation
  final List<BookingModel> _allFetched = [];
  final Set<String> _previousBookingIds = {};
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    fetchOverviewData();
    _startPolling();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  void _startPolling() {
    // Poll every 60 seconds for new bookings
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      fetchOverviewData(showLoading: false);
    });
  }

  // ---------------------------------------------------------------------------
  // MAIN FETCH
  // ---------------------------------------------------------------------------
  Future<void> fetchOverviewData({bool showLoading = true}) async {
    try {
      if (showLoading) isLoading.value = true;
      errorMessage.value = '';

      // Fetch a large page to compute stats in-memory.
      // If the API has a dedicated stats endpoint in future, replace this.
      final response = await _repo.fetchBookings(page: 0, size: 500);

      _allFetched
        ..clear()
        ..addAll(response.content);

      _computeKpis();
      _computeTrend();
      _computeDonut();
      _computeRecentBookings();
      _checkNewBookings();
    } catch (e) {
      errorMessage.value = 'Failed to load data. Please refresh.';
      debugPrint('BookingOverviewController Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // KPI COMPUTATION
  // ---------------------------------------------------------------------------
  void _computeKpis() {
    totalBookings.value = _allFetched.length;

    pendingCount.value = _allFetched
        .where((b) => b.status.toLowerCase() == 'pending')
        .length;

    completedCount.value = _allFetched
        .where((b) => b.status.toLowerCase() == 'completed')
        .length;

    canceledCount.value = _allFetched
        .where((b) => b.status.toLowerCase() == 'cancelled' ||
            b.status.toLowerCase() == 'canceled')
        .length;

    offlinePaymentCount.value = _allFetched
        .where((b) =>
            b.paymentMode.toUpperCase() == 'CASH' ||
            b.paymentMode.toUpperCase() == 'OFFLINE')
        .length;

    // Revenue = sum of grandTotalPrice from completed bookings
    totalRevenue.value = _allFetched
        .where((b) => b.status.toLowerCase() == 'completed')
        .fold(0.0, (sum, b) => sum + b.grandTotalPrice);
  }

  // ---------------------------------------------------------------------------
  // TREND CHART COMPUTATION
  // ---------------------------------------------------------------------------
  void _computeTrend() {
    if (_allFetched.isEmpty) {
      trendPoints.clear();
      return;
    }

    if (trendMode.value == 'Daily') {
      _buildDailyTrend();
    } else {
      _buildWeeklyTrend();
    }
  }

  void _buildDailyTrend() {
    // Group by creation date (last 30 days)
    final Map<String, int> countByDay = {};
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 29));

    for (final b in _allFetched) {
      if (b.creationTime.isEmpty) continue;
      try {
        final dt = DateTime.parse(b.creationTime);
        if (dt.isBefore(cutoff)) continue;
        final key = DateFormat('dd MMM').format(dt);
        countByDay[key] = (countByDay[key] ?? 0) + 1;
      } catch (_) {}
    }

    // Build sorted list
    final sorted = countByDay.entries.toList()
      ..sort((a, b) {
        try {
          final da = DateFormat('dd MMM').parse(a.key);
          final db = DateFormat('dd MMM').parse(b.key);
          return da.compareTo(db);
        } catch (_) {
          return 0;
        }
      });

    final points = <TrendPoint>[];
    for (int i = 0; i < sorted.length; i++) {
      points.add(TrendPoint(
          label: sorted[i].key, x: i.toDouble(), count: sorted[i].value));
    }
    trendPoints.assignAll(points);
  }

  void _buildWeeklyTrend() {
    // Group by ISO week number
    final Map<int, int> countByWeek = {};
    for (final b in _allFetched) {
      if (b.creationTime.isEmpty) continue;
      try {
        final dt = DateTime.parse(b.creationTime);
        final weekNum = _isoWeek(dt);
        countByWeek[weekNum] = (countByWeek[weekNum] ?? 0) + 1;
      } catch (_) {}
    }

    final sorted = countByWeek.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final points = <TrendPoint>[];
    for (int i = 0; i < sorted.length; i++) {
      points.add(TrendPoint(
          label: 'Wk ${sorted[i].key}',
          x: i.toDouble(),
          count: sorted[i].value));
    }
    trendPoints.assignAll(points);
  }

  int _isoWeek(DateTime date) {
    final dayOfYear = int.parse(DateFormat('D').format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  void switchTrendMode(String mode) {
    trendMode.value = mode;
    _computeTrend();
  }

  // ---------------------------------------------------------------------------
  // DONUT CHART COMPUTATION
  // ---------------------------------------------------------------------------
  void _computeDonut() {
    donutSegments.assignAll([
      DonutSegment(
          label: 'Pending',
          count: pendingCount.value,
          colorHex: 0xFFF59E0B),
      DonutSegment(
          label: 'Completed',
          count: completedCount.value,
          colorHex: 0xFF22C55E),
      DonutSegment(
          label: 'Cancelled',
          count: canceledCount.value,
          colorHex: 0xFFEF4444),
      DonutSegment(
          label: 'Offline',
          count: offlinePaymentCount.value,
          colorHex: 0xFF8B5CF6),
    ]);
  }

  // ---------------------------------------------------------------------------
  // RECENT BOOKINGS
  // ---------------------------------------------------------------------------
  void _computeRecentBookings() {
    final sorted = List<BookingModel>.from(_allFetched);
    sorted.sort((a, b) => b.creationTime.compareTo(a.creationTime));
    recentBookings.assignAll(sorted.take(20).toList());
  }

  // ---------------------------------------------------------------------------
  // PERCENTAGE HELPERS (for KPI cards)
  // ---------------------------------------------------------------------------
  String percentOf(int part) {
    if (totalBookings.value == 0) return '0%';
    return '${((part / totalBookings.value) * 100).toStringAsFixed(1)}%';
  }

  // ---------------------------------------------------------------------------
  // NEW BOOKING DETECTION
  // ---------------------------------------------------------------------------
  void _checkNewBookings() {
    if (_allFetched.isEmpty) return;

    final currentIds = _allFetched.map((b) => b.id).toSet();

    // If we already have a previous state, check for differences
    if (_previousBookingIds.isNotEmpty) {
      final newIds = currentIds.difference(_previousBookingIds);
      if (newIds.isNotEmpty) {
        // Trigger sound
        AudioService().playBookingSound();

        // Show UI notification
        Get.snackbar(
          'New Order Received!',
          'You have ${newIds.length} new booking(s).',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFFFF9800),
          colorText: Colors.white,
          icon: const Icon(Icons.notifications_active, color: Colors.white),
          duration: const Duration(seconds: 15),
          mainButton: TextButton(
            onPressed: () {
              AudioService().stopSound();
              if (Get.isSnackbarOpen) Get.back();
            },
            child: const Text('STOP SOUND', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      }
    }

    // Update the set for the next comparison
    _previousBookingIds.clear();
    _previousBookingIds.addAll(currentIds);
  }
}
