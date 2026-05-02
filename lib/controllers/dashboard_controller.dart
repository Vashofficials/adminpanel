import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/booking_report_model.dart';
import '../models/provider_model.dart';
import '../models/customer_models.dart';
import '../models/data_models.dart'; // ServiceModel
import 'package:excel/excel.dart';
import '../models/booking_models.dart';


class DashboardController extends GetxController {
  final ApiService _api = ApiService();

  // --- 1. COLLECTION ---
  var allTimeCollection = 0.0.obs;
  var todayCollection = 0.0.obs;

  // --- 2. ORDERS ---
  var totalOrders = 0.obs;
  var todayOrders = 0.obs;
  var todayScheduledBookings = 0.obs;

  // --- 3. PROVIDERS ---
  var totalProviders = 0.obs;
  var activeProviders = 0.obs;
  var inactiveProviders = 0.obs;
  var approvedProviders = 0.obs;
  var unApprovedProviders = 0.obs;
  var todayActiveProviders = 0.obs;

  // --- 4. PENDING BOOKINGS ---
  var totalPending = 0.obs;
  var todayPending = 0.obs;

  // --- 5. CANCELLATIONS ---
  var totalCancelled = 0.obs;
  var todayCancelled = 0.obs;

  // --- 6. USERS ---
  var totalUsers = 0.obs;
  var activeUsers = 0.obs;
  var inactiveUsers = 0.obs;

  // --- BOOKING STATUS (kept for other screens) ---
  var completedBookings = 0.obs;
  var ongoingBookings = 0.obs;
  var pendingBookings = 0.obs;
  var cancelledBookings = 0.obs;

  // --- LEGACY KPI (kept for export/other screens) ---
  var totalRevenue = 0.0.obs;
  var totalBookings = 0.obs;
  var activeServices = 0.obs;
  var totalCustomers = 0.obs;

  // --- CATEGORY DATA ---
  var categoryNames = <String>[].obs;
  var categoryCounts = <int>[].obs;

  // --- CHART STATE ---
  var chartData = <MonthData>[].obs;

  // --- TOP PROVIDERS ---
  var topProviders = <ProviderModel>[].obs;

  // --- TOP SERVICES (computed from bookings) ---
  var topServices = <_TopServiceData>[].obs;

  // --- PLATFORM SUMMARY (computed) ---
  var avgBookingValue = 0.0.obs;     // avg actualAmount of completed bookings
  var refundRate = 0.0.obs;          // (cancelled / total) * 100
  var customerRetentionRate = 0.0.obs; // (active users / total users) * 100

  var isLoading = true.obs;
  var isRefreshing = false.obs;
  Timer? _refreshTimer;
  DateTime? _lastFetchTime;

  @override
  void onInit() {
    super.onInit();
    refreshDashboard();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      refreshDashboard(isAutoRefresh: true);
    });
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  /// Check if cache is still valid (45 seconds)
  bool _isCacheValid() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!).inSeconds < 45;
  }

  /// Manual refresh from UI button
  Future<void> manualRefresh() async {
    _lastFetchTime = null; // Invalidate cache
    isRefreshing.value = true;
    await refreshDashboard(isAutoRefresh: true);
    isRefreshing.value = false;
  }

  /// Helper: Check if a datetime string is today in IST
  bool _isTodayIST(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return false;
    try {
      final nowUtc = DateTime.now().toUtc();
      final nowIST = nowUtc.add(const Duration(hours: 5, minutes: 30));
      
      String dateStr = dateTimeStr;
      if (dateStr.contains('T')) {
        dateStr = dateStr.split('T').first;
      }
      final parsed = DateTime.parse(dateStr);
      return parsed.year == nowIST.year && parsed.month == nowIST.month && parsed.day == nowIST.day;
    } catch (e) {
      return false;
    }
  }

  Future<void> refreshDashboard({bool isAutoRefresh = false}) async {
    // Skip if cache is still valid for auto-refresh
    if (isAutoRefresh && _isCacheValid()) return;

    try {
      if (!isAutoRefresh) isLoading.value = true;

      // --- PARALLEL API CALLS ---
      final results = await Future.wait([
        _fetchBookingData(),
        _fetchProviderData(),
        _fetchCustomerData(),
        _fetchCategoryData(),
      ]);

      _lastFetchTime = DateTime.now();
    } catch (e) {
      debugPrint("❌ Dashboard Refresh Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch and process all booking data
  Future<void> _fetchBookingData() async {
    try {
      final bookingData = await _api.getBookings(page: 0, size: 1000);
      if (bookingData == null || bookingData['result'] == null) return;

      final bookingResp = BookingResponse.fromJson(bookingData);
      final List<BookingModel> bookings = bookingResp.content;
      final now = DateTime.now();

      double allTimeRev = 0.0;
      double todayRev = 0.0;
      int todayOrderCount = 0;
      int todayScheduledCount = 0;
      int pendingTotal = 0;
      int pendingToday = 0;
      int cancelledTotal = 0;
      int cancelledToday = 0;
      int completedCount = 0;
      int ongoingCount = 0;

      // Monthly revenue tracker
      List<MonthData> monthlyRevenue = List.generate(12, (index) => MonthData(
        mothName: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][index],
        cashBooking: 0,
        onlineBooking: 0,
      ));

      // Category count tracker
      Map<String, int> catCounts = {};

      for (var b in bookings) {
        String status = b.status.toLowerCase();
        String paymentStatus = b.paymentStatus.toLowerCase();
        bool isTodayCreation = _isTodayIST(b.creationTime);
        bool isTodayBooking = _isTodayIST(b.bookingDate);

        // --- All Time Collection ---
        if (status == 'completed') {
          allTimeRev += b.actualAmount;
        }

        // --- Today Collection ---
        if (isTodayBooking && status == 'completed' && paymentStatus == 'paid') {
          todayRev += b.actualAmount;
        }

        // --- Today orders ---
        if (isTodayCreation) {
          todayOrderCount++;
        }

        if (isTodayBooking) {
          todayScheduledCount++;
        }

        // --- Status counts ---
        if (status == 'pending') {
          pendingTotal++;
          if (isTodayBooking) pendingToday++;
        } else if (status == 'cancelled' || status == 'canceled') {
          cancelledTotal++;
          if (isTodayBooking) cancelledToday++;
        } else if (status == 'completed') {
          completedCount++;
        } else if (status == 'ongoing') {
          ongoingCount++;
        }

        // --- Monthly Booking Count Data ---
        try {
          String bDateStr = b.bookingDate;
          if (bDateStr.contains('T')) {
            bDateStr = bDateStr.split('T').first;
          }
          final bDateParsed = DateTime.parse(bDateStr);
          if (bDateParsed.year == now.year) {
            int monthIdx = bDateParsed.month - 1;
            if (monthIdx >= 0 && monthIdx < 12) {
              final int currentCount = monthlyRevenue[monthIdx].cashBooking ?? 0;
              monthlyRevenue[monthIdx].cashBooking = currentCount + 1;
            }
          }
        } catch (e) {
          // Date parsing fallback
        }

        // --- Category counts ---
        for (var s in b.services) {
          final cName = s.categoryName;
          if (cName.isNotEmpty) {
            catCounts[cName] = (catCounts[cName] ?? 0) + 1;
          }
        }
      }

      // --- TOP SERVICES: count bookings per service name ---
      Map<String, _TopServiceData> svcMap = {};
      for (var b in bookings) {
        for (var s in b.services) {
          final key = s.serviceName.isNotEmpty ? s.serviceName : 'Unknown';
          if (!svcMap.containsKey(key)) {
            svcMap[key] = _TopServiceData(
              name: key,
              category: s.categoryName,
              bookingCount: 0,
              revenue: 0.0,
            );
          }
          svcMap[key]!.bookingCount++;
          if (b.status.toLowerCase() == 'completed') {
            svcMap[key]!.revenue += b.actualAmount;
          }
        }
      }
      final sortedSvcs = svcMap.values.toList()
        ..sort((a, b) => b.bookingCount.compareTo(a.bookingCount));
      topServices.assignAll(sortedSvcs.take(5).toList());

      // --- PLATFORM SUMMARY metrics ---
      avgBookingValue.value = completedCount > 0 ? (allTimeRev / completedCount) : 0.0;
      refundRate.value = bookings.isNotEmpty ? (cancelledTotal / bookings.length) * 100 : 0.0;
      // retention computed after customer fetch — updated in _fetchCustomerData

      // Assign values
      allTimeCollection.value = allTimeRev;
      todayCollection.value = todayRev;
      totalOrders.value = bookings.length;
      todayOrders.value = todayOrderCount;
      todayScheduledBookings.value = todayScheduledCount;
      totalPending.value = pendingTotal;
      todayPending.value = pendingToday;
      totalCancelled.value = cancelledTotal;
      todayCancelled.value = cancelledToday;
      completedBookings.value = completedCount;
      ongoingBookings.value = ongoingCount;

      // Legacy fields
      totalRevenue.value = allTimeRev;
      totalBookings.value = bookings.length;
      pendingBookings.value = pendingTotal;
      cancelledBookings.value = cancelledTotal;

      // Chart Data
      chartData.assignAll(monthlyRevenue);

      // Category Counts
      if (catCounts.isNotEmpty) {
        var sortedKeys = catCounts.keys.toList()..sort((a, b) => catCounts[b]!.compareTo(catCounts[a]!));
        categoryNames.assignAll(sortedKeys.take(5).toList());
        categoryCounts.assignAll(sortedKeys.take(5).map((k) => catCounts[k]!).toList());
      } else {
        categoryNames.assignAll(['Cleaning', 'Plumbing', 'Electrician', 'Salon', 'Appliances']);
        categoryCounts.assignAll([0, 0, 0, 0, 0]);
      }
    } catch (e) {
      debugPrint("❌ Error fetching booking data: $e");
    }
  }

  /// Fetch and process provider data
  Future<void> _fetchProviderData() async {
    try {
      final providerData = await _api.getAllServiceProviders();
      final providerResp = ProviderResponse.fromJson(providerData);
      final providers = providerResp.result;

      int activeCount = 0;
      int inactiveCount = 0;
      int approvedCount = 0;
      int unApprovedCount = 0;

      for (var p in providers) {
        if (p.isActive) {
          activeCount++;
        } else {
          inactiveCount++;
        }

        if (p.isAadharVerified) {
          approvedCount++;
        } else {
          unApprovedCount++;
        }
      }

      totalProviders.value = providers.length;
      activeProviders.value = activeCount;
      inactiveProviders.value = inactiveCount;
      approvedProviders.value = approvedCount;
      unApprovedProviders.value = unApprovedCount;

      // --- TODAY ACTIVE PROVIDERS ---
      // Eligible = status==1 (isActive) AND isAadharVerified==true
      final eligibleProviders = providers.where((p) => p.isActive && p.isAadharVerified).toList();

      // Fetch holidays for ALL eligible providers in parallel (avoids N+1)
      final todayIST = _getTodayIST();
      final holidayFutures = eligibleProviders.map((p) => _getProviderHolidaysForToday(p.id, todayIST));
      final holidayResults = await Future.wait(holidayFutures);

      // Count providers with NO holiday today
      int todayActiveCount = 0;
      for (final hasHolidayToday in holidayResults) {
        if (!hasHolidayToday) todayActiveCount++;
      }
      todayActiveProviders.value = todayActiveCount;

      // Top providers by rating
      List<ProviderModel> sorted = List.from(providers);
      sorted.sort((a, b) => b.totalRating.compareTo(a.totalRating));
      topProviders.assignAll(sorted.take(5).toList());
    } catch (e) {
      debugPrint("❌ Error fetching provider data: $e");
    }
  }

  /// Returns today's date string (YYYY-MM-DD) in IST timezone.
  String _getTodayIST() {
    final nowIST = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    return '${nowIST.year.toString().padLeft(4, '0')}-'
        '${nowIST.month.toString().padLeft(2, '0')}-'
        '${nowIST.day.toString().padLeft(2, '0')}';
  }

  /// Returns true if provider has an active holiday record for today.
  /// Swallows errors silently (treats as no holiday) to keep the dashboard loading.
  Future<bool> _getProviderHolidaysForToday(String providerId, String todayStr) async {
    try {
      final response = await _api.getHolidays(providerId);
      final data = response.data;
      List<dynamic> holidays = [];
      if (data is Map && data['result'] is List) {
        holidays = data['result'] as List;
      } else if (data is List) {
        holidays = data;
      }
      for (final h in holidays) {
        final holidayDate = h['holidayDate']?.toString() ?? '';
        // Normalize: take only the date part (strip time component)
        final dateOnly = holidayDate.contains('T') ? holidayDate.split('T').first : holidayDate;
        if (dateOnly == todayStr) return true;
      }
      return false;
    } catch (_) {
      // On error, assume provider is available (no holiday)
      return false;
    }
  }

  /// Fetch and process customer data
  Future<void> _fetchCustomerData() async {
    try {
      final customerData = await _api.getAllCustomers(page: 0, size: 5000);
      if (customerData == null || customerData['result'] == null) return;

      final resp = CustomerResponse.fromJson(customerData);
      final customers = resp.content;

      int activeCount = 0;
      int inactiveCount = 0;

      for (var c in customers) {
        if (c.isActive) {
          activeCount++;
        } else {
          inactiveCount++;
        }
      }

      totalUsers.value = resp.totalElements;
      activeUsers.value = activeCount;
      inactiveUsers.value = inactiveCount;

      // Customer retention = active / total * 100
      customerRetentionRate.value = resp.totalElements > 0
          ? (activeCount / resp.totalElements) * 100
          : 0.0;

      // Legacy
      totalCustomers.value = resp.totalElements;
    } catch (e) {
      debugPrint("❌ Error fetching customer data: $e");
    }
  }

  /// Fetch category/service data
  Future<void> _fetchCategoryData() async {
    try {
      final categories = await _api.getCategories();

      List<Future<List<ServiceModel>>> serviceFutures = [];
      for (var cat in categories) {
        serviceFutures.add(_api.getServices(categoryId: cat.id));
      }

      final serviceResults = await Future.wait(serviceFutures);
      int activeCount = 0;
      for (var list in serviceResults) {
        activeCount += list.where((s) => s.isActive).length;
      }
      activeServices.value = activeCount;
    } catch (e) {
      debugPrint("❌ Error fetching category data: $e");
    }
  }

  Future<void> exportDashboardData() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Dashboard_Report'];
      excel.setDefaultSheet('Dashboard_Report');

      // Add Headers
      sheetObject.appendRow([
        TextCellValue('Metric'),
        TextCellValue('Value'),
      ]);

      // Add Data
      sheetObject.appendRow([TextCellValue('All Time Collection'), IntCellValue((allTimeCollection.value).toInt())]);
      sheetObject.appendRow([TextCellValue('Today Collection'), IntCellValue((todayCollection.value).toInt())]);
      sheetObject.appendRow([TextCellValue('Total Bookings'), IntCellValue(totalOrders.value)]);
      sheetObject.appendRow([TextCellValue('Today Orders'), IntCellValue(todayOrders.value)]);
      sheetObject.appendRow([TextCellValue('Today Scheduled'), IntCellValue(todayScheduledBookings.value)]);
      sheetObject.appendRow([TextCellValue('Total Providers'), IntCellValue(totalProviders.value)]);
      sheetObject.appendRow([TextCellValue('Active Providers'), IntCellValue(activeProviders.value)]);
      sheetObject.appendRow([TextCellValue('Inactive Providers'), IntCellValue(inactiveProviders.value)]);
      sheetObject.appendRow([TextCellValue('Approved Providers'), IntCellValue(approvedProviders.value)]);
      sheetObject.appendRow([TextCellValue('Unapproved Providers'), IntCellValue(unApprovedProviders.value)]);
      sheetObject.appendRow([TextCellValue('Today Active Providers'), IntCellValue(todayActiveProviders.value)]);
      sheetObject.appendRow([TextCellValue('Total Users'), IntCellValue(totalUsers.value)]);
      sheetObject.appendRow([TextCellValue('Active Users'), IntCellValue(activeUsers.value)]);
      sheetObject.appendRow([TextCellValue('Inactive Users'), IntCellValue(inactiveUsers.value)]);

      sheetObject.appendRow([TextCellValue('')]);
      sheetObject.appendRow([TextCellValue('Booking Status')]);
      sheetObject.appendRow([TextCellValue('Total Pending'), IntCellValue(totalPending.value)]);
      sheetObject.appendRow([TextCellValue('Today Pending'), IntCellValue(todayPending.value)]);
      sheetObject.appendRow([TextCellValue('Total Cancelled'), IntCellValue(totalCancelled.value)]);
      sheetObject.appendRow([TextCellValue('Today Cancelled'), IntCellValue(todayCancelled.value)]);
      sheetObject.appendRow([TextCellValue('Completed'), IntCellValue(completedBookings.value)]);
      sheetObject.appendRow([TextCellValue('Ongoing'), IntCellValue(ongoingBookings.value)]);

      excel.save(fileName: "Dashboard_Report_${DateTime.now().toIso8601String().split('T').first}.xlsx");

      Get.snackbar(
        "Export Successful",
        "Dashboard report exported successfully.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint("Export Error: $e");
      Get.snackbar(
        "Export Failed",
        "Could not export report.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

/// Helper data class used internally by DashboardController to aggregate
/// per-service booking counts and revenue from raw booking data.
class _TopServiceData {
  final String name;
  final String category;
  int bookingCount;
  double revenue;

  _TopServiceData({
    required this.name,
    required this.category,
    required this.bookingCount,
    required this.revenue,
  });
}
