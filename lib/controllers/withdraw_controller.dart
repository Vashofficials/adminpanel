import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_center_dialog.dart';

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
      var response = await _apiService.updateWithdrawStatus(id, status);
      
      if (response.statusCode == 200) {
        await fetchRequests(); // Refresh the list from the server
        
        // Show Success Popup
        if (Get.context != null) {
          CustomCenterDialog.show(
            Get.context!,
            title: "Success",
            message: "Withdraw status updated successfully!",
            type: DialogType.success,
          );
        }
      }
    } catch (e) {
      // Show Error Popup matching your requested static text
      if (Get.context != null) {
        CustomCenterDialog.show(
          Get.context!,
          title: "Error",
          message: "Failed to update service",
          type: DialogType.error,
        );
      }
    }
  }
}