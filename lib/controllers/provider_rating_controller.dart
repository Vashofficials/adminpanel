import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/provider_controller.dart';
import '../services/api_service.dart';

class ProviderRatingController extends GetxController {
  late final ProviderController providerController;
  final ApiService _api = ApiService();

  // --- STATE ---
  var selectedProviderId = RxnString();
  var isLoadingRatings = false.obs;
  var ratingList = <dynamic>[].obs; // Stores results from /admin/getServiceProviderRating

  @override
  void onInit() {
    super.onInit();
    providerController = Get.isRegistered<ProviderController>()
        ? Get.find<ProviderController>()
        : Get.put(ProviderController());

    if (providerController.allProviders.isEmpty) {
      providerController.fetchProviders();
    }
  }

  // --- API CALLS ---

  Future<void> fetchProviderRatings(String providerId) async {
    try {
      isLoadingRatings.value = true;
      final response = await _api.getServiceProviderRating(providerId);

      if (response.statusCode == 200) {
        // response.data['result'] is a list of ratings
        ratingList.assignAll(response.data['result'] ?? []);
      }
    } catch (e) {
      debugPrint("❌ Provider Rating Fetch Error: $e");
      ratingList.clear();
    } finally {
      isLoadingRatings.value = false;
    }
  }

  // --- LOGIC ---

  void onProviderChanged(String? val) {
    selectedProviderId.value = val;
    if (val != null) {
      fetchProviderRatings(val);
    } else {
      ratingList.clear();
    }
  }
}
