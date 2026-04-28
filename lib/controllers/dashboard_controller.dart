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

  // --- KPI STATE ---
  var totalRevenue = 0.0.obs;
  var totalBookings = 0.obs;
  var activeServices = 0.obs;
  var totalCustomers = 0.obs;
  var totalProviders = 0.obs;
  var completedBookings = 0.obs;

  // --- BOOKING STATUS ---
  var pendingBookings = 0.obs;
  var cancelledBookings = 0.obs;
  var ongoingBookings = 0.obs;

  // --- CATEGORY DATA ---
  var categoryNames = <String>[].obs;
  var categoryCounts = <int>[].obs;

  // --- CHART STATE ---
  var chartData = <MonthData>[].obs;

  // --- MOCK TODAY'S DATA ---
  var todayRevenue = 245000.0.obs;
  var todayBookings = 24.obs;
  var newCustomers = 32.obs;
  var newProviders = 8.obs;
  var averageRating = 4.6.obs;

  // --- TOP PROVIDERS ---
  var topProviders = <ProviderModel>[].obs;

  var isLoading = true.obs;
  Timer? _refreshTimer;

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

  Future<void> refreshDashboard({bool isAutoRefresh = false}) async {
    try {
      if (!isAutoRefresh) isLoading.value = true;
      
      // 1. Fetch Bookings to count metrics, Pending, and Cancellations
      try {
        final bookingData = await _api.getBookings(page: 0, size: 1000);
        if (bookingData != null && bookingData['result'] != null) {
          final bookingResp = BookingResponse.fromJson(bookingData);
          final List<BookingModel> bookings = bookingResp.content;
          
          final now = DateTime.now();
          final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
          
          double revToday = 0.0;
          int ordersToday = 0;
          int pendingCount = 0;
          int cancelledCount = 0;
          int completedCount = 0;
          int ongoingCount = 0;

          // Monthly revenue tracker
          List<MonthData> monthlyRevenue = List.generate(12, (index) => MonthData(
            mothName: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][index], 
            cashBooking: 0, 
            onlineBooking: 0
          ));

          // Category count tracker
          Map<String, int> catCounts = {};
          
          for (var b in bookings) {
            String status = b.status.toLowerCase();
            if (status == 'pending') {
              pendingCount++;
            } else if (status == 'cancelled') {
              cancelledCount++;
            } else if (status == 'completed') {
              completedCount++;
            } else if (status == 'ongoing') {
              ongoingCount++;
            }
            
            // Calculate Monthly Trend Data
            try {
              String bDateStr = b.bookingDate;
              if (bDateStr.contains('T')) {
                bDateStr = bDateStr.split('T').first;
              }
              final bDateParsed = DateTime.parse(bDateStr);
              if (bDateParsed.year == now.year) {
                int monthIdx = bDateParsed.month - 1;
                if (monthIdx >= 0 && monthIdx < 12) {
                  if (b.paymentMode.toUpperCase() == 'CASH') {
                    final int currentCash = monthlyRevenue[monthIdx].cashBooking ?? 0;
                    monthlyRevenue[monthIdx].cashBooking = currentCash + b.grandTotalPrice.toInt();
                  } else {
                    final int currentOnline = monthlyRevenue[monthIdx].onlineBooking ?? 0;
                    monthlyRevenue[monthIdx].onlineBooking = currentOnline + b.grandTotalPrice.toInt();
                  }
                }
              }
            } catch (e) {
              // Date parsing fallback
            }

            // Calculate Category counts
            for (var s in b.services) {
              final cName = s.categoryName;
              if (cName.isNotEmpty) {
                catCounts[cName] = (catCounts[cName] ?? 0) + 1;
              }
            }

            String bDate = b.bookingDate;
            if (bDate.contains('T')) {
              bDate = bDate.split('T').first;
            }
            
            if (bDate == todayStr) {
              ordersToday++;
              if (status != 'cancelled') {
                revToday += b.grandTotalPrice;
              }
            }
          }
          
          todayRevenue.value = revToday;
          todayBookings.value = ordersToday;
          pendingBookings.value = pendingCount;
          cancelledBookings.value = cancelledCount;
          completedBookings.value = completedCount;
          ongoingBookings.value = ongoingCount;
          
          totalBookings.value = bookings.length;

          // Assign Chart Data
          chartData.assignAll(monthlyRevenue);

          // Assign Category Counts
          if (catCounts.isNotEmpty) {
            var sortedKeys = catCounts.keys.toList()..sort((a, b) => catCounts[b]!.compareTo(catCounts[a]!));
            categoryNames.assignAll(sortedKeys.take(5).toList());
            categoryCounts.assignAll(sortedKeys.take(5).map((k) => catCounts[k]!).toList());
          } else {
            categoryNames.assignAll(['Cleaning', 'Plumbing', 'Electrician', 'Salon', 'Appliances']);
            categoryCounts.assignAll([0, 0, 0, 0, 0]);
          }
        }
      } catch (e) {
        debugPrint("❌ Error calculating real-time bookings for dashboard: $e");
      }

      // 2. Fetch Categories & active services for extra logic
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
        debugPrint("❌ Error calculating categories for dashboard: $e");
      }

      // 4. Fetch Total Customers count
      try {
        final customerData = await _api.getAllCustomers(page: 0, size: 10);
        if (customerData != null && customerData['result'] != null) {
          final resp = CustomerResponse.fromJson(customerData);
          totalCustomers.value = resp.totalElements;
        }
      } catch (e) {
        debugPrint("❌ Error calculating customer count for dashboard: $e");
      }

      // 5. Fetch Total Providers count and Top Providers
      try {
        final providerData = await _api.getAllServiceProviders();
        final providerResp = ProviderResponse.fromJson(providerData);
        
        totalProviders.value = providerResp.result.length;

        List<ProviderModel> providers = List.from(providerResp.result);
        providers.sort((a, b) => b.totalRating.compareTo(a.totalRating));
        topProviders.assignAll(providers.take(5).toList());
      } catch (e) {
        debugPrint("❌ Error calculating provider counts for dashboard: $e");
      }

    } catch (e) {
      debugPrint("❌ Dashboard Refresh Error: $e");
    } finally {
      isLoading.value = false;
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
      sheetObject.appendRow([TextCellValue('Total Collection'), IntCellValue((totalRevenue.value).toInt())]);
      sheetObject.appendRow([TextCellValue('Total Bookings'), IntCellValue(totalBookings.value)]);
      sheetObject.appendRow([TextCellValue('Active Services'), IntCellValue(activeServices.value)]);
      sheetObject.appendRow([TextCellValue('Total Customers'), IntCellValue(totalCustomers.value)]);
      sheetObject.appendRow([TextCellValue('Total Providers'), IntCellValue(totalProviders.value)]);
      sheetObject.appendRow([TextCellValue('Completed Bookings'), IntCellValue(completedBookings.value)]);

      sheetObject.appendRow([TextCellValue('')]);
      sheetObject.appendRow([TextCellValue('Booking Status')]);
      sheetObject.appendRow([TextCellValue('Completed'), IntCellValue(completedBookings.value)]);
      sheetObject.appendRow([TextCellValue('Ongoing'), IntCellValue(ongoingBookings.value)]);
      sheetObject.appendRow([TextCellValue('Pending'), IntCellValue(pendingBookings.value)]);
      sheetObject.appendRow([TextCellValue('Cancelled'), IntCellValue(cancelledBookings.value)]);

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
