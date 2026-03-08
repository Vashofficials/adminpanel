import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/provider_controller.dart'; // Import existing ProviderController

class HolidayController extends GetxController {
  // Dependency Injection: Use the existing ProviderController for the list
  late final ProviderController providerController;

  // --- STATE ---
  var selectedProviderId = RxnString(); // Stores the ID of the selected provider

  // Calendar State
  var focusedDate = DateTime.now().obs;
  var selectedDate = DateTime.now().obs;

  // Buffer Logic (T+3 Days)
  var checkFromDate = DateTime.now().obs;
  var availabilityResult = "".obs;
  var availabilityStatus = "".obs; // "Available", "Half Day", etc.

  @override
  void onInit() {
    super.onInit();
    // 1. Find or Put the ProviderController
    if (Get.isRegistered<ProviderController>()) {
      providerController = Get.find<ProviderController>();
    } else {
      providerController = Get.put(ProviderController());
    }
    
    // 2. Trigger fetch if empty
    if (providerController.allProviders.isEmpty) {
      providerController.fetchProviders();
    }
    
    // Initialize buffer text
    calculateBuffer(DateTime.now());
  }

  // --- LOGIC ---
  
  void onProviderChanged(String? val) {
    selectedProviderId.value = val;
    if (val != null) {
      print("Fetching holidays for Provider ID: $val");
      // TODO: Call API to get holidays for this provider
    }
  }

  void changeMonth(int offset) {
    focusedDate.value = DateTime(focusedDate.value.year, focusedDate.value.month + offset, 1);
  }

  void onDateSelected(DateTime date) {
    selectedDate.value = date;
  }

  void onCheckDateChanged(DateTime date) {
    checkFromDate.value = date;
    calculateBuffer(date);
  }

  void calculateBuffer(DateTime startDate) {
    // Logic: T + 3 Days
    DateTime bufferDate = startDate.add(const Duration(days: 3));
    availabilityResult.value = DateFormat("MMM dd, yyyy").format(bufferDate);
    
    // Mock Availability Check for that specific future date
    // In real app, check if bufferDate falls on a holiday
    availabilityStatus.value = "Full Day Available"; 
  }
}