import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/booking_report_model.dart';
import '../models/provider_model.dart';
import '../models/customer_models.dart';
import '../models/data_models.dart'; // ServiceModel

class DashboardController extends GetxController {
  final ApiService _api = ApiService();

  // --- KPI STATE ---
  var totalRevenue = 0.0.obs;
  var totalBookings = 0.obs;
  var activeServices = 0.obs;
  var totalCustomers = 0.obs;

  // --- CHART STATE ---
  var chartData = <MonthData>[].obs;

  // --- TOP PROVIDERS ---
  var topProviders = <ProviderModel>[].obs;

  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    refreshDashboard();
  }

  Future<void> refreshDashboard() async {
    try {
      isLoading.value = true;
      
      // 1. Fetch Booking Report for Current Year
      final currentYear = DateTime.now().year.toString();
      final report = await _api.getBookingReport(currentYear);
      
      if (report != null && report.result != null) {
        final res = report.result!;
        
        // Calculate Total Bookings
        totalBookings.value = (res.completed ?? 0) + 
                             (res.ongoing ?? 0) + 
                             (res.pending ?? 0) + 
                             (res.cancelled ?? 0);
        
        // Chart Data (Completed Months)
        chartData.assignAll(res.completedMonth ?? []);
        
        // Per user request: Revenue show total of completed booking
        totalRevenue.value = (res.completed ?? 0).toDouble();
      }

      // 2. Fetch Active Services count (Aggregating services from all categories)
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

      // 3. Fetch Total Customers count (Use totalElements from paginated metadata)
      final customerData = await _api.getAllCustomers(page: 0, size: 10);
      if (customerData != null && customerData['result'] != null) {
        final resp = CustomerResponse.fromJson(customerData);
        totalCustomers.value = resp.totalElements;
      }

      // 4. Fetch Top Providers (Sorted by rating)
      final providerData = await _api.getAllServiceProviders();
      final providerResp = ProviderResponse.fromJson(providerData);
      
      // Sort providers by totalRating descending and take top 5
      List<ProviderModel> providers = List.from(providerResp.result);
      providers.sort((a, b) => b.totalRating.compareTo(a.totalRating));
      topProviders.assignAll(providers.take(5).toList());

    } catch (e) {
      debugPrint("❌ Dashboard Refresh Error: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
