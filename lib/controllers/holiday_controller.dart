import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/provider_controller.dart';
import '../services/api_service.dart'; // Import your dedicated API service

class HolidayController extends GetxController {
  late final ProviderController providerController;
  final ApiService _api = ApiService(); // Use dedicated API service

  // --- STATE ---
  var selectedProviderId = RxnString();
  var isLoadingHolidays = false.obs;
  var holidayList = <dynamic>[].obs; // Stores results from /admin/getHolidays

  // Calendar & Buffer State
  var focusedDate = DateTime.now().obs;
  var selectedDate = DateTime.now().obs;
  var checkFromDate = DateTime.now().obs;
  var availabilityResult = "".obs;
  var availabilityStatus = "".obs;

  @override
  void onInit() {
    super.onInit();
    providerController = Get.isRegistered<ProviderController>()
        ? Get.find<ProviderController>()
        : Get.put(ProviderController());

    if (providerController.allProviders.isEmpty) {
      providerController.fetchProviders();
    }
    calculateBuffer(DateTime.now());
  }

  // --- API CALLS ---

  Future<void> fetchProviderHolidays(String providerId) async {
    try {
      isLoadingHolidays.value = true;
      // Endpoint: GET /admin/getHolidays?providerId=...
      final response = await _api.getHolidays(providerId);

      if (response.statusCode == 200) {
        // Based on your JSON structure: response.data['result']
        holidayList.assignAll(response.data['result'] ?? []);
        calculateBuffer(checkFromDate.value); // Re-calculate buffer based on holidays
      }
    } catch (e) {
      debugPrint("❌ Holiday Fetch Error: $e");
      holidayList.clear();
    } finally {
      isLoadingHolidays.value = false;
    }
  }

  // --- LOGIC ---

  void onProviderChanged(String? val) {
    selectedProviderId.value = val;
    if (val != null) {
      fetchProviderHolidays(val);
    } else {
      holidayList.clear();
    }
  }

  // Helper to check if a date is a holiday in real-time
  bool isDateHoliday(DateTime date) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    return holidayList.any((h) => h['holidayDate'] == formattedDate && h['isActive'] == true);
  }

  void calculateBuffer(DateTime startDate) {
  // 1. New Baseline: Tomorrow (Today + 1 Day)
  // If today is March 15, we start checking from March 16.
  DateTime earliestSlot = startDate.add(const Duration(days: 1));

  // 2. Continuous Check: Skip any dates marked as holidays in your API
  // This will check 16, 17, 18... and stop at the first available date.
  while (isDateHoliday(earliestSlot)) {
    earliestSlot = earliestSlot.add(const Duration(days: 1));
  }

  // 3. Update the UI values
  availabilityResult.value = DateFormat("MMM dd, yyyy").format(earliestSlot);
  
  // Dynamic status message
  if (earliestSlot.isAtSameMomentAs(startDate.add(const Duration(days: 1)))) {
    availabilityStatus.value = "Available Tomorrow";
  } else {
    int daysFromNow = earliestSlot.difference(startDate).inDays;
    availabilityStatus.value = "Available in $daysFromNow days (after holidays)";
  }
}
  void changeMonth(int offset) {
    focusedDate.value = DateTime(focusedDate.value.year, focusedDate.value.month + offset, 1);
  }

  void onCheckDateChanged(DateTime date) {
    checkFromDate.value = date;
    calculateBuffer(date);
  }
}