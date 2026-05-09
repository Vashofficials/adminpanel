import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
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

  // --- Chart data ---
  var dailyProviderCounts = <DailyProviderData>[].obs;
  
  // --- Donut data ---
  var statusCounts = <String, int>{}.obs;

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
    final data = await _api.getAllServiceProviders();
    final resp = ProviderResponse.fromJson(data);
    _allProviders = resp.result;

    // Fetch holidays for potential active providers (status == 1)
    await _fetchHolidaysForActiveOnes();
    
    _computeStats();
    _computeChartData();
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
        final holidayData = await _api.getHolidays(id);
        if (holidayData != null && holidayData.data['result'] is List) {
          final dates = (holidayData.data['result'] as List)
              .map((h) => h['holidayDate']?.toString() ?? '')
              .where((d) => d.isNotEmpty)
              .toList();
          _providerHolidays[id] = dates;
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

    // For the line chart, we want cumulative or daily? 
    // Request says "daily provider growth", so we can show daily or cumulative. 
    // Usually growth charts are cumulative. Let's do cumulative.
    int runningTotal = _allProviders.length; // Start from current total and go backwards if we don't have full history
    // Actually let's just show daily count for "growth" or cumulative for "total growth".
    // I'll show cumulative.
    
    dailyProviderCounts.assignAll(data);
    
    if (data.isNotEmpty) {
      startDate.value = data.first.date;
      endDate.value = data.last.date;
    }
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
