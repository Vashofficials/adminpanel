import 'package:get/get.dart';
import '../models/bank_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_center_dialog.dart';
import 'package:file_picker/file_picker.dart'; // Add this import

class BankingController extends GetxController {
  final ApiService _apiService = ApiService();
  Rx<ProviderBankDetails?> providerBankDetails = Rx<ProviderBankDetails?>(null);


  var isLoading = false.obs;
  var bankList = <BankModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchBanks();
  }

  Future<void> fetchBanks() async {
    try {
      isLoading.value = true;
      final banks = await _apiService.getAllBanks();
      bankList.assignAll(banks);
    } catch (e) {
      print("❌ Failed to load banks: $e");
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> fetchProviderBankDetails(String spId) async {
  try {
    isLoading.value = true;

    final data = await _apiService.getProviderBankDetails(spId);

    if (data != null && data['result'] != null) {
      providerBankDetails.value =
          ProviderBankDetails.fromJson(data['result']);
    } else {
      providerBankDetails.value = null;
    }
  } catch (e) {
    print("❌ Error loading provider bank details: $e");
    providerBankDetails.value = null;
  } finally {
    isLoading.value = false;
  }
}
Future<void> updateBank(String id, String name, PlatformFile file) async {
    isLoading(true);
    bool success = await _apiService.updateBank(id, name, file);
    if (success) {
      fetchBanks(); // Refresh list
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Success",
  message: "Bank details updated successfully!",
  type: DialogType.success,
);    } else {
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Error",
  message: "Failed to update bank. Please try again.",
  type: DialogType.error,
);            }
    isLoading(false);
  }

  Future<void> deleteBank(String id, bool isActive) async {
    isLoading(true);
    bool success = await _apiService.deleteBank(id, isActive);
    if (success) {
      fetchBanks(); // Refresh list
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Success",
  message: "Bank deleted successfully",
  type: DialogType.success,
);    } else {
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Error",
  message: "Failed to delete bank",
  type: DialogType.error,
);    }
    isLoading(false);
  }
Future<bool> addBank(String name, PlatformFile? logoFile) async {
    try {
      isLoading.value = true;
      
      // Assuming apiService.addBank takes name and optional file
      final success = await _apiService.addBank(name, logoFile);

      if (success) {
        await fetchBanks(); // Refresh list
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Success",
  message: "Bank details saved successfully!",
  type: DialogType.success,
);         return true;
      } else {
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Error",
  message: "Failed to save add bank. Please try again.",
  type: DialogType.error,
);        return false;
      }
    } catch (e) {
      print("❌ Add bank error: $e");
CustomCenterDialog.show(
  Get.context!, // Use Get.context!
  title: "Error",
  message: "Something went wrong",
  type: DialogType.error,
);      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
