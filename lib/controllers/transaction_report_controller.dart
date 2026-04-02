import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../models/provider_model.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'dart:html' as html;

class TransactionReportController extends GetxController {
  final ApiService _api = ApiService();

  // Observable State
  var isLoading = false.obs;
  var reportList = <ProviderBookingPayment>[].obs;
  var filteredList = <ProviderBookingPayment>[].obs;
  
  // Dates
  var fromDate = DateTime.now().subtract(const Duration(days: 365)).obs;
  var toDate = DateTime.now().add(const Duration(days: 1)).obs;
  
  // Search
  var searchText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Default search listener
    debounce(searchText, (_) => _applySearch(), time: const Duration(milliseconds: 300));
    fetchReport();
  }

  // Reactive sum for the KPI card
  double get totalProviderEarning => reportList.fold(0.0, (sum, item) => sum + item.totalPayment);

  Future<void> fetchReport() async {
    try {
      isLoading.value = true;
      final fDateStr = DateFormat('yyyy-MM-dd').format(fromDate.value);
      final tDateStr = DateFormat('yyyy-MM-dd').format(toDate.value);
      
      final results = await _api.getProviderBookingPayment(fDateStr, tDateStr);
      if (results != null) {
        reportList.assignAll(results.map((e) => ProviderBookingPayment.fromJson(e)).toList());
        _applySearch();
      } else {
        reportList.clear();
        filteredList.clear();
      }
    } catch (e) {
      debugPrint("Fetch report failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _applySearch() {
    if (searchText.value.isEmpty) {
      filteredList.assignAll(reportList);
    } else {
      final query = searchText.value.toLowerCase();
      filteredList.assignAll(reportList.where((p) => p.providerName.toLowerCase().contains(query)).toList());
    }
  }

  void exportToCSV() {
    if (reportList.isEmpty) {
      Get.snackbar(
        "Info", 
        "No data available to download.",
        backgroundColor: Colors.blue.withOpacity(0.7),
        colorText: Colors.white,
      );
      return;
    }

    final StringBuffer csv = StringBuffer();
    // Headers
    csv.writeln("SL,Provider Name,Total Bookings,Total Payment,Total Settled");

    // Rows
    for (int i = 0; i < reportList.length; i++) {
      final item = reportList[i];
      csv.writeln("${i + 1},${item.providerName},${item.totalBookings},${item.totalPayment},${item.totalSettled}");
    }

    // Web Download using dart:html
    try {
      final bytes = utf8.encode(csv.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "provider_earn_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
      
      Get.snackbar(
        "Success", 
        "Report for ${reportList.length} providers downloaded successfully.",
        backgroundColor: Colors.green.withOpacity(0.7),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("Error", "Download failed: $e");
    }
  }
}
