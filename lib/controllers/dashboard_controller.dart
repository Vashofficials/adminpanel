import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/booking_report_model.dart';
import '../models/provider_model.dart';
import '../models/customer_models.dart';

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
        
        // Calculate Total Revenue from Completed Months
        double rev = 0;
        for (var month in res.completedMonth ?? []) {
          rev += (month.cashBooking ?? 0) + (month.onlineBooking ?? 0);
        }
        totalRevenue.value = rev;
      }

      // 2. Fetch Active Services count (Filter for isActive == true)
      final services = await _api.getServices();
      activeServices.value = services.where((s) => s.isActive).length;

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
