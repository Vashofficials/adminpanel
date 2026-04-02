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
 Future<void> settleWithdrawRequest({
  required String providerId,
  required String? providerBankId,
  required double amount,
  required String comment,
}) async {
  // 1. Validation Check using Custom Dialog instead of Snackbar
  if (providerBankId == null || providerBankId.isEmpty) {
    CustomCenterDialog.show(
      Get.context!,
      title: "Missing Data",
      message: "Provider bank details are not available. Please ensure the provider has completed their profile.",
      type: DialogType.error,
    );
    return;
  }

  try {
    isLoading(true);

    Map<String, dynamic> payload = {
      "providerId": providerId,
      "providerBankId": providerBankId,
      "amount": amount,
      "comment": comment
    };

    // Calling the ApiService
    var response = await _apiService.addWithdrawRequest(payload);

   if (response.statusCode == 200 || response.statusCode == 201) {
  // 1. Close the Settle Modal
  if (Get.isDialogOpen ?? false) {
    Get.back(); 
  }

  // 2. Refresh your data
  await fetchRequests(); 

  // 3. SHOW SUCCESS POPUP 
  // Wrap in a microtask or small delay to ensure the modal is fully closed
  Future.delayed(const Duration(milliseconds: 100), () {
    if (Get.context != null) {
      CustomCenterDialog.show(
        Get.context!,
        title: "Success",
        message: "Withdraw Settled successfully.",
        type: DialogType.success,
      );
    }
  });
}
} catch (e) {
    // 5. ERROR HANDLING
    CustomCenterDialog.show(
      Get.context!,
      title: "Settlement Failed",
      message: "An error occurred: ${e.toString()}",
      type: DialogType.error,
    );
  } finally {
    isLoading(false);
  }
}
}