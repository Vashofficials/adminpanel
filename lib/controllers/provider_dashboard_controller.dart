import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:dio/dio.dart';
import '../models/provider_model.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ProviderDashboardController extends GetxController {
  final ApiService _api = ApiService();
  Timer? _refreshTimer;

  // --- KPI Stats ---
  var totalProviders = 0.obs;
  var activeProviders = 0.obs;
  var newRegistrationsToday = 0.obs;
  var pendingApproval = 0.obs;
  var inactiveProviders = 0.obs;

  // --- Booking Stats (from API) ---
  var totalBookings = 0.obs;
  var todayBookings = 0.obs;
  var completedBookings = 0.obs;
  var cancelledBookings = 0.obs;
  var pendingBookings = 0.obs;

  // --- Earnings (from API) ---
  var totalEarnings = 0.0.obs;
  var todayEarnings = 0.0.obs;
  var monthlyEarnings = 0.0.obs;

  // --- Chart data ---
  var dailyProviderCounts = <DailyProviderData>[].obs;
  
  // --- Donut data ---
  var statusCounts = <String, int>{}.obs;

  // --- Booking Status Donut ---
  var bookingStatusCounts = <String, int>{}.obs;

  // --- Date range ---
  var startDate = DateTime.now().subtract(const Duration(days: 6)).obs;
  var endDate = DateTime.now().obs;

  // --- Loading ---
  var isLoading = true.obs;
  var isRefreshing = false.obs;

  // --- Selected time filter ---
  var selectedFilter = 'Last 7 Days'.obs;

  // --- All providers cache ---
  List<ProviderModel> _allProviders = [];
  final Map<String, List<String>> _providerHolidays = {}; // providerId -> list of holiday dates

  // --- Top providers by rating ---
  var topRatedProviders = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchProviderDashboardData();
    _startRefreshTimer();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) => refreshData());
  }

  Future<void> fetchProviderDashboardData() async {
    try {
      isLoading.value = true;
      await _loadData();
    } catch (e) {
      debugPrint("❌ Provider Dashboard Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    try {
      isRefreshing.value = true;
      await _loadData();
    } catch (e) {
      debugPrint("❌ Refresh Error: $e");
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadProviders(),
      _loadBookings(),
      _loadEarnings(),
    ]);
  }

  Future<void> _loadProviders() async {
    try {
      final data = await _api.getAllServiceProviders();
      final resp = ProviderResponse.fromJson(data);
      _allProviders = resp.result;

      // Fetch holidays for potential active providers (status == 1)
      await _fetchHolidaysForActiveOnes();
      
      _computeStats();
      _computeChartData();
      _computeTopRatedProviders();
    } catch (e) {
      debugPrint("❌ Load Providers Error: $e");
    }
  }

  Future<void> _loadBookings() async {
    try {
      final res = await _api.getBookings(page: 1, size: 500);
      if (res['statusCode'] == 200 && res['result'] != null) {
        List<dynamic> allBookings = res['result']['data'] ?? [];
        
        final now = DateTime.now();
        final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        int tToday = 0;
        int tCompleted = 0;
        int tCancelled = 0;
        int tPending = 0;

        for (var b in allBookings) {
          final String status = b['status']?.toString().toUpperCase() ?? '';
          final String bookingDate = b['bookingDate']?.toString().split('T').first ?? '';

          if (bookingDate == todayStr) tToday++;
          if (status == 'COMPLETED') tCompleted++;
          if (status == 'CANCELLED') tCancelled++;
          if (status == 'PENDING' || status == 'CONFIRMED') tPending++;
        }

        totalBookings.value = allBookings.length;
        todayBookings.value = tToday;
        completedBookings.value = tCompleted;
        cancelledBookings.value = tCancelled;
        pendingBookings.value = tPending;

        bookingStatusCounts.value = {
          'Completed': tCompleted,
          'Pending': tPending,
          'Cancelled': tCancelled,
        };
      }
    } catch (e) {
      debugPrint("❌ Load Bookings Error: $e");
    }
  }

  Future<void> _loadEarnings() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final monthStartStr = "${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}-${monthStart.day.toString().padLeft(2, '0')}";
      // Use a wide range for total
      final yearStartStr = "${now.year}-01-01";

      // Fetch monthly earnings
      final monthlyData = await _api.getProviderBookingPayment(monthStartStr, todayStr);
      double mEarn = 0.0;
      if (monthlyData != null) {
        for (var item in monthlyData) {
          mEarn += (item['totalPayment'] ?? 0.0).toDouble();
        }
      }
      monthlyEarnings.value = mEarn;

      // Fetch total yearly earnings
      final yearData = await _api.getProviderBookingPayment(yearStartStr, todayStr);
      double tEarn = 0.0;
      double tToday = 0.0;
      if (yearData != null) {
        for (var item in yearData) {
          tEarn += (item['totalPayment'] ?? 0.0).toDouble();
        }
      }
      totalEarnings.value = tEarn;

      // Today's earnings from bookings
      final res = await _api.getBookings(page: 1, size: 100);
      if (res['statusCode'] == 200 && res['result'] != null) {
        List<dynamic> allBookings = res['result']['data'] ?? [];
        for (var b in allBookings) {
          final String bookingDate = b['bookingDate']?.toString().split('T').first ?? '';
          final String status = b['status']?.toString().toUpperCase() ?? '';
          if (bookingDate == todayStr && status == 'COMPLETED') {
            tToday += (b['totalAmount'] ?? 0.0).toDouble();
          }
        }
      }
      todayEarnings.value = tToday;
    } catch (e) {
      debugPrint("❌ Load Earnings Error: $e");
    }
  }

  Future<void> _fetchHolidaysForActiveOnes() async {
    final activeCandidateIds = _allProviders
        .where((p) => p.isActive)
        .map((p) => p.id)
        .toList();

    // Limit to 50 for performance
    final limitedIds = activeCandidateIds.take(50).toList(); 

    for (var id in limitedIds) {
      if (!_providerHolidays.containsKey(id)) {
        try {
          final holidayData = await _api.getHolidays(id);
          if (holidayData.data != null && holidayData.data['result'] is List) {
            final dates = (holidayData.data['result'] as List)
                .map((h) => h['holidayDate']?.toString() ?? '')
                .where((d) => d.isNotEmpty)
                .toList();
            _providerHolidays[id] = dates;
          }
        } catch (e) {
          debugPrint("⚠️ Holiday fetch failed for $id: $e");
          _providerHolidays[id] = [];
        }
      }
    }
  }

  void _computeStats() {
    int total = _allProviders.length;
    int active = 0;
    int pending = 0;
    int registrationsToday = 0;
    int inactive = 0;

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final todayStart = DateTime(now.year, now.month, now.day);

    for (var p in _allProviders) {
      // 2. New Registration (today)
      if (p.createdAt != null && p.createdAt!.isAfter(todayStart)) {
        registrationsToday++;
      }

      // 3. Status logic
      bool onHoliday = _providerHolidays[p.id]?.contains(todayStr) ?? false;

      if (p.isActive) {
        if (!onHoliday) {
          active++;
        }
      } else {
        pending++;
      }

      if (!p.isActive) {
        inactive++;
      }
    }

    totalProviders.value = total;
    activeProviders.value = active;
    newRegistrationsToday.value = registrationsToday;
    pendingApproval.value = pending;
    inactiveProviders.value = inactive;
    
    statusCounts.value = {
      'Active': active,
      'Pending': pending,
      'Inactive': inactive,
    };
  }

  void _computeChartData() {
    final now = DateTime.now();
    int days = 7;
    if (selectedFilter.value == 'Last 30 Days') days = 30;
    if (selectedFilter.value == 'Last 6 Months') days = 180;

    Map<String, int> grouped = {};
    
    // Initialize map with 0s for the range
    for (int i = 0; i < days; i++) {
      final d = now.subtract(Duration(days: i));
      grouped[DateFormat('yyyy-MM-dd').format(d)] = 0;
    }

    // Fill with real data
    for (var p in _allProviders) {
      if (p.createdAt != null) {
        final key = DateFormat('yyyy-MM-dd').format(p.createdAt!);
        if (grouped.containsKey(key)) {
          grouped[key] = grouped[key]! + 1;
        }
      }
    }

    // Convert to list and sort
    List<DailyProviderData> data = [];
    grouped.forEach((key, count) {
      data.add(DailyProviderData(date: DateTime.parse(key), count: count));
    });
    data.sort((a, b) => a.date.compareTo(b.date));

    dailyProviderCounts.assignAll(data);
    
    if (data.isNotEmpty) {
      startDate.value = data.first.date;
      endDate.value = data.last.date;
    }
  }

  void _computeTopRatedProviders() {
    // Sort by rating, take top 5
    final sorted = List<ProviderModel>.from(_allProviders)
      ..sort((a, b) => b.totalRating.compareTo(a.totalRating));
    
    topRatedProviders.value = sorted.take(5).map((p) => {
      'name': p.fullName,
      'rating': p.totalRating,
      'reviews': p.totalReview,
      'imageUrl': p.imageUrl ?? '',
      'isActive': p.isActive,
    }).toList();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    _computeChartData();
  }

  String get dateRangeText {
    final formatter = DateFormat('MMM dd');
    final yearFormatter = DateFormat('MMM dd, yyyy');
    return '${formatter.format(startDate.value)} - ${yearFormatter.format(endDate.value)}';
  }

  double get activePercent => totalProviders.value > 0 ? (activeProviders.value / totalProviders.value * 100) : 0;
  double get pendingPercent => totalProviders.value > 0 ? (pendingApproval.value / totalProviders.value * 100) : 0;
  double get newRegPercent => totalProviders.value > 0 ? (newRegistrationsToday.value / totalProviders.value * 100) : 0;
  double get inactivePercent => totalProviders.value > 0 ? (inactiveProviders.value / totalProviders.value * 100) : 0;

  Future<void> exportData(String format) async {
    if (format == 'CSV') {
      _exportCSV();
    } else if (format == 'Excel') {
      _exportExcel();
    } else if (format == 'PDF') {
      _exportPDF();
    }
  }

  void _exportCSV() {
    String csv = "Metric,Value\n";
    csv += "Total Providers,${totalProviders.value}\n";
    csv += "Active Providers,${activeProviders.value}\n";
    csv += "New Registrations Today,${newRegistrationsToday.value}\n";
    csv += "Pending Approval,${pendingApproval.value}\n";
    csv += "Total Bookings,${totalBookings.value}\n";
    csv += "Today's Bookings,${todayBookings.value}\n";
    csv += "Completed Bookings,${completedBookings.value}\n";
    csv += "Total Earnings,${totalEarnings.value}\n";
    csv += "\nStatus Distribution\n";
    csv += "Active %,${activePercent.toStringAsFixed(1)}%\n";
    csv += "Pending %,${pendingPercent.toStringAsFixed(1)}%\n";

    _downloadWebFile(csv, "Provider_Analytics_${DateTime.now().millisecondsSinceEpoch}.csv", "text/csv");
  }

  void _exportExcel() {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Provider_Report'];
    excel.setDefaultSheet('Provider_Report');

    sheetObject.appendRow([TextCellValue('Metric'), TextCellValue('Value')]);
    sheetObject.appendRow([TextCellValue('Total Providers'), IntCellValue(totalProviders.value)]);
    sheetObject.appendRow([TextCellValue('Active Providers'), IntCellValue(activeProviders.value)]);
    sheetObject.appendRow([TextCellValue('New Registrations Today'), IntCellValue(newRegistrationsToday.value)]);
    sheetObject.appendRow([TextCellValue('Pending Approval'), IntCellValue(pendingApproval.value)]);
    sheetObject.appendRow([TextCellValue('Total Bookings'), IntCellValue(totalBookings.value)]);
    sheetObject.appendRow([TextCellValue('Completed Bookings'), IntCellValue(completedBookings.value)]);
    sheetObject.appendRow([TextCellValue('Total Earnings'), DoubleCellValue(totalEarnings.value)]);

    final bytes = excel.save();
    if (bytes != null) {
      _downloadWebFileBytes(bytes, "Provider_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
    }
  }

  Future<void> _exportPDF() async {
    final pdfDoc = pw.Document();

    pdfDoc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Provider Analytics Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Generated on: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}"),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: [
                  ['Metric', 'Value'],
                  ['Total Providers', totalProviders.value.toString()],
                  ['Active Providers', activeProviders.value.toString()],
                  ['New Registrations Today', newRegistrationsToday.value.toString()],
                  ['Pending Approval', pendingApproval.value.toString()],
                  ['Total Bookings', totalBookings.value.toString()],
                  ['Completed Bookings', completedBookings.value.toString()],
                  ['Total Earnings', '₹${totalEarnings.value.toStringAsFixed(2)}'],
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdfDoc.save());
  }

  void _downloadWebFile(String content, String fileName, String mimeType) {
    debugPrint("Downloading $fileName...");
  }

  void _downloadWebFileBytes(List<int> bytes, String fileName, String mimeType) {
     debugPrint("Downloading bytes for $fileName...");
  }
}

class DailyProviderData {
  final DateTime date;
  final int count;
  DailyProviderData({required this.date, required this.count});
}
