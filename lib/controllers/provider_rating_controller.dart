import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/provider_controller.dart';
import '../models/customer_models.dart';
import '../services/api_service.dart';

class ProviderRatingController extends GetxController {
  late final ProviderController providerController;
  final ApiService _api = ApiService();

  // --- STATE ---
  var selectedProviderId = RxnString();
  var isLoadingRatings = false.obs;
  var ratingsList = <ServiceProviderRating>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Ensure ProviderController is available for the dropdown list
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
        final List<dynamic> result = response.data['result'] ?? [];
        ratingsList.assignAll(result.map((json) => ServiceProviderRating.fromJson(json)).toList());
      }
    } catch (e) {
      debugPrint("❌ Provider Rating Fetch Error: $e");
      ratingsList.clear();
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
      ratingsList.clear();
    }
  }
}
