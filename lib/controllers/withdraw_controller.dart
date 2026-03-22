import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WithdrawController extends GetxController {
  var isLoading = false.obs;
  var withdrawList = <dynamic>[].obs;
  final ApiService _apiService = ApiService();

  @override
  void onInit() {
    fetchRequests();
    super.onInit();
  }

  Future<void> fetchRequests() async {
    try {
      isLoading(true);
      var response = await _apiService.getWithdrawRequests();
      if (response.statusCode == 200) {
        withdrawList.value = response.data['result'];
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch data: $e", snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      // Optional: Show a loading overlay or dialog
      var response = await _apiService.updateWithdrawStatus(id, status);
      
      if (response.statusCode == 200) {
        Get.snackbar("Success", "Withdraw status updated successfully", 
            backgroundColor: Colors.green, colorText: Colors.white);
        await fetchRequests(); // Refresh the list from the server
      }
    } catch (e) {
      Get.snackbar("Update Failed", e.toString(), 
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}