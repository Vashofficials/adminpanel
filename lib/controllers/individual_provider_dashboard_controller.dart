import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'dart:async';
import '../models/provider_model.dart';
import '../services/api_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:dio/dio.dart';

class IndividualProviderDashboardController extends GetxController {
  final ApiService _api = ApiService();

  var isLoading = false.obs;
  var providerId = ''.obs;

  // Provider Data
  var providerModel = Rxn<ProviderModel>();

  // Metrics
  var todayBookings = 0.obs;
  var completedBookings = 0.obs; // This month or overall, let's say total
  var todayEarnings = 0.0.obs;
  var totalEarnings = 0.0.obs;

  // Graph Data
  var weeklyEarnings = <double>[0, 0, 0, 0, 0, 0, 0].obs;
  var graphBookings = 0.obs;
  var graphCompleted = 0.obs;
  var graphCancelled = 0.obs;

  // Lists
  var todaysSchedule = <Map<String, dynamic>>[].obs;
  var recentBookings = <Map<String, dynamic>>[].obs;

  // Ratings
  var averageRating = 0.0.obs;
  var totalReviews = 0.obs;
  var ratingDistribution = <int, int>{
    5: 0,
    4: 0,
    3: 0,
    2: 0,
    1: 0,
  }.obs;

  // Profile
  var profileCompletion = 0.0.obs;

  // Exporting status
  var isExporting = false.obs;

  Timer? _refreshTimer;

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  void loadProvider(String id, ProviderModel model) {
    providerId.value = id;
    providerModel.value = model;
    
    _calculateProfileCompletion(model);
    _fetchDashboardData();

    // Auto-refresh every 5 minutes
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _fetchDashboardData();
    });
  }

  void _calculateProfileCompletion(ProviderModel model) {
    int totalFields = 10;
    int filledFields = 0;

    if (model.firstName.isNotEmpty) filledFields++;
    if (model.lastName != null && model.lastName!.isNotEmpty) filledFields++;
    if (model.mobileNo.isNotEmpty) filledFields++;
    if (model.emailId != null && model.emailId!.isNotEmpty) filledFields++;
    if (model.aadharNo.isNotEmpty) filledFields++;
    if (model.isAadharVerified) filledFields++;
    if (model.imageUrl != null && model.imageUrl!.isNotEmpty) filledFields++;
    if (model.city != null && model.city!.isNotEmpty) filledFields++;
    if (model.state != null && model.state!.isNotEmpty) filledFields++;
    if (model.zipCode != null && model.zipCode!.isNotEmpty) filledFields++;

    profileCompletion.value = (filledFields / totalFields) * 100;
  }

  Future<void> _fetchDashboardData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _fetchBookings(),
        _fetchEarnings(),
        _fetchRatings(),
      ]);
    } catch (e) {
      debugPrint("Error fetching individual provider stats: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchBookings() async {
    try {
      final res = await _api.getBookings(page: 1, size: 100);
      if (res['statusCode'] == 200 && res['result'] != null) {
        List<dynamic> allBookings = res['result']['data'] ?? [];
        
        // Filter by this provider
        var providerBookings = allBookings.where((b) {
          final sId = b['serviceProviderId']?['id'] ?? b['serviceProviderId'];
          return sId == providerId.value;
        }).toList();

        final now = DateTime.now();
        final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        int tBookings = 0;
        int tCompleted = 0;
        int tCancelled = 0;
        List<Map<String, dynamic>> schedule = [];
        List<Map<String, dynamic>> recent = [];

        for (var b in providerBookings) {
          final String status = b['status']?.toString().toUpperCase() ?? '';
          final String bookingDate = b['bookingDate']?.toString().split('T').first ?? '';

          if (status == 'COMPLETED') tCompleted++;
          if (status == 'CANCELLED') tCancelled++;

          if (bookingDate == todayStr) {
            tBookings++;
            schedule.add(b as Map<String, dynamic>);
          }

          recent.add(b as Map<String, dynamic>);
        }

        // Sort schedule by time
        schedule.sort((a, b) => (a['bookingTime'] ?? '').compareTo(b['bookingTime'] ?? ''));
        // Sort recent by date descending
        recent.sort((a, b) => (b['bookingDate'] ?? '').compareTo(a['bookingDate'] ?? ''));

        todayBookings.value = tBookings;
        completedBookings.value = tCompleted;
        graphBookings.value = providerBookings.length;
        graphCompleted.value = tCompleted;
        graphCancelled.value = tCancelled;
        
        todaysSchedule.value = schedule;
        recentBookings.value = recent.take(5).toList();
      }
    } catch (e) {
      debugPrint("Error fetching bookings: $e");
    }
  }

  Future<void> _fetchEarnings() async {
    try {
      final now = DateTime.now();
      
      // Calculate earnings for the last 7 days
      final sevenDaysAgo = now.subtract(const Duration(days: 6));
      final fromDateStr = "${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}";
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final paymentData = await _api.getProviderBookingPayment(fromDateStr, todayStr);
      
      double tEarn = 0.0;
      double todayEarn = 0.0;
      List<double> weekEarn = List.filled(7, 0.0);

      if (paymentData != null) {
        var pData = paymentData.firstWhere(
          (p) => (p['providerId'] ?? p['serviceProviderId']) == providerId.value, 
          orElse: () => null
        );

        if (pData != null) {
          tEarn = (pData['totalPayment'] ?? 0.0).toDouble();
          
          // Assuming the API gives daily breakdown, or we calculate it. 
          // If the API doesn't give daily breakdown in getProviderBookingPayment, we might need to parse bookings.
          // For now, let's just use the totals from this API if they provide them, or fallback to 0.
        }
      }

      // To accurately get daily earnings, we'll parse the bookings we already fetched in recentBookings
      // Wait, _fetchBookings already populated provider bookings. Let's re-fetch them or use them if we save them globally.
      // Since it's easier to just fetch all time here:
      final res = await _api.getBookings(page: 1, size: 500); // Need more to calculate total earnings
      if (res['statusCode'] == 200 && res['result'] != null) {
         List<dynamic> allBookings = res['result']['data'] ?? [];
         var providerBookings = allBookings.where((b) {
          final sId = b['serviceProviderId']?['id'] ?? b['serviceProviderId'];
          return sId == providerId.value && b['status']?.toString().toUpperCase() == 'COMPLETED';
        }).toList();

        double calcTotalEarn = 0.0;
        double calcTodayEarn = 0.0;
        List<double> calcWeekEarn = List.filled(7, 0.0);

        for (var b in providerBookings) {
          double amt = (b['totalAmount'] ?? 0.0).toDouble();
          calcTotalEarn += amt;

          final bDateStr = b['bookingDate']?.toString().split('T').first ?? '';
          if (bDateStr == todayStr) {
            calcTodayEarn += amt;
          }

          // Check if in last 7 days
          try {
             DateTime bDate = DateTime.parse(bDateStr);
             int diff = now.difference(bDate).inDays;
             if (diff >= 0 && diff < 7) {
               calcWeekEarn[6 - diff] += amt;
             }
          } catch(e) {}
        }
        
        todayEarnings.value = calcTodayEarn;
        totalEarnings.value = calcTotalEarn;
        weeklyEarnings.value = calcWeekEarn;
      }
    } catch (e) {
      debugPrint("Error fetching earnings: $e");
    }
  }

  Future<void> _fetchRatings() async {
    try {
      final Response? resAvg = await _api.getServiceProviderRating(providerId.value);
      if (resAvg != null && resAvg.statusCode == 200) {
        averageRating.value = (resAvg.data['result']?['averageRating'] ?? 0.0).toDouble();
      }

      final Response? resCust = await _api.getProviderRatings(providerId.value);
      if (resCust != null && resCust.statusCode == 200) {
        List<dynamic> ratingsData = resCust.data['result'] ?? [];
        totalReviews.value = ratingsData.length;

        Map<int, int> dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
        for (var r in ratingsData) {
          int score = (r['rating'] ?? 0).toInt();
          if (dist.containsKey(score)) {
            dist[score] = dist[score]! + 1;
          }
        }
        ratingDistribution.value = dist;
      }
    } catch (e) {
      debugPrint("Error fetching ratings: $e");
    }
  }

  // --- EXPORT FUNCTIONALITY ---

  Future<void> exportCSV() async {
    isExporting.value = true;
    try {
      final String name = providerModel.value?.fullName ?? "Provider";
      String csv = "Individual Performance Report - $name\n\n";
      csv += "Category,Metric,Value\n";
      csv += "Stats,Today's Bookings,${todayBookings.value}\n";
      csv += "Stats,Completed Bookings,${completedBookings.value}\n";
      csv += "Stats,Today's Earnings,${todayEarnings.value}\n";
      csv += "Stats,Total Earnings,${totalEarnings.value}\n";
      csv += "Ratings,Average Rating,${averageRating.value}\n";
      csv += "Ratings,Total Reviews,${totalReviews.value}\n";
      
      csv += "\nRecent Bookings\n";
      csv += "Date,Service,Customer,Amount,Status\n";
      for (var b in recentBookings) {
        csv += "${b['bookingDate']},${b['service']?['name']},${b['customer']?['firstName']},${b['totalAmount']},${b['status']}\n";
      }

      if (kIsWeb) {
        final bytes = utf8.encode(csv);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = 'Provider_${providerId.value}_Report.csv';
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      }
      
      Get.snackbar("Success", "CSV Exported successfully", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "Failed to export CSV: $e", snackPosition: SnackPosition.BOTTOM);
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> exportExcel() async {
    isExporting.value = true;
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Sheet1'];

      final String name = providerModel.value?.fullName ?? "Provider";
      sheet.appendRow([TextCellValue("Provider Performance Report"), TextCellValue(name)]);
      sheet.appendRow([]);
      sheet.appendRow([TextCellValue("Metric"), TextCellValue("Value")]);
      sheet.appendRow([TextCellValue("Today's Bookings"), IntCellValue(todayBookings.value)]);
      sheet.appendRow([TextCellValue("Completed Bookings"), IntCellValue(completedBookings.value)]);
      sheet.appendRow([TextCellValue("Today's Earnings"), DoubleCellValue(todayEarnings.value)]);
      sheet.appendRow([TextCellValue("Total Earnings"), DoubleCellValue(totalEarnings.value)]);
      sheet.appendRow([TextCellValue("Average Rating"), DoubleCellValue(averageRating.value)]);
      
      sheet.appendRow([]);
      sheet.appendRow([TextCellValue("Recent Bookings")]);
      sheet.appendRow([TextCellValue("Date"), TextCellValue("Service"), TextCellValue("Customer"), TextCellValue("Amount"), TextCellValue("Status")]);
      
      for (var b in recentBookings) {
        sheet.appendRow([
          TextCellValue(b['bookingDate']?.toString() ?? ''),
          TextCellValue(b['service']?['name']?.toString() ?? ''),
          TextCellValue(b['customer']?['firstName']?.toString() ?? ''),
          DoubleCellValue((b['totalAmount'] ?? 0).toDouble()),
          TextCellValue(b['status']?.toString() ?? ''),
        ]);
      }

      if (kIsWeb) {
        final bytes = excel.encode();
        if (bytes != null) {
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.document.createElement('a') as html.AnchorElement
            ..href = url
            ..style.display = 'none'
            ..download = 'Provider_${providerId.value}_Report.xlsx';
          html.document.body!.children.add(anchor);
          anchor.click();
          html.document.body!.children.remove(anchor);
          html.Url.revokeObjectUrl(url);
        }
      }
      
      Get.snackbar("Success", "Excel Report generated", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "Excel Export failed: $e", snackPosition: SnackPosition.BOTTOM);
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> generatePDFReport() async {
    isExporting.value = true;
    try {
      final pdf = pw.Document();
      final String name = providerModel.value?.fullName ?? "Provider";

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Header(level: 0, child: pw.Text("Provider Performance Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 10),
            pw.Text("Provider: $name"),
            pw.Text("ID: ${providerId.value}"),
            pw.Text("Date Generated: ${DateTime.now()}"),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text("Key Metrics", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Metric', 'Value'],
                <String>["Today's Bookings", "${todayBookings.value}"],
                <String>['Completed Bookings', "${completedBookings.value}"],
                <String>["Today's Earnings", "INR ${todayEarnings.value}"],
                <String>['Total Earnings', "INR ${totalEarnings.value}"],
                <String>['Average Rating', "${averageRating.value} / 5.0"],
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Text("Recent Bookings", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Date', 'Service', 'Customer', 'Amount', 'Status'],
                ...recentBookings.map((b) => [
                  b['bookingDate']?.toString() ?? '',
                  b['service']?['name']?.toString() ?? '',
                  b['customer']?['firstName']?.toString() ?? '',
                  "INR ${b['totalAmount']}",
                  b['status']?.toString() ?? '',
                ]),
              ],
            ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
      Get.snackbar("Success", "PDF Report generated", snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("Error", "PDF generation failed: $e", snackPosition: SnackPosition.BOTTOM);
    } finally {
      isExporting.value = false;
    }
  }
}
