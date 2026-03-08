import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/provider_model.dart';
import '../repositories/provider_repository.dart';

class ProviderController extends GetxController {
  final ProviderRepository _repo = ProviderRepository();

  // State
  var isLoading = true.obs;
  var allProviders = <ProviderModel>[].obs; // Original Data
  var providerList = <ProviderModel>[].obs; // Displayed Data (Filtered)

  // Filters
  var searchText = ''.obs;
  var selectedTab = 'All'.obs; // "All", "Active", "Inactive"

  @override
  void onInit() {
    super.onInit();

    fetchProviders();

    debounce(
      searchText,
      (_) => _applyFilters(),
      time: const Duration(milliseconds: 500),
    );

    ever(selectedTab, (_) => _applyFilters());
  }

  /// ✅ FIXED: now awaitable
  Future<void> fetchProviders() async {
    try {
      isLoading.value = true;
      final fetched = await _repo.getAllProviders();
      allProviders.assignAll(fetched);
      _applyFilters();
    } catch (e) {
      debugPrint("Fetch providers failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilters() {
    List<ProviderModel> temp = List.from(allProviders);

    // Filter by tab
    if (selectedTab.value == 'Active') {
      temp = temp.where((p) => p.isAadharVerified).toList();
    } else if (selectedTab.value == 'Inactive') {
      temp = temp.where((p) => !p.isAadharVerified).toList();
    }

    // Filter by search
    if (searchText.value.isNotEmpty) {
      final query = searchText.value.toLowerCase();
      temp = temp.where((p) {
        return p.fullName.toLowerCase().contains(query) ||
            p.mobileNo.contains(query) ||
            (p.emailId ?? '').toLowerCase().contains(query);
      }).toList();
    }

    providerList.assignAll(temp);
  }

  void toggleStatus(int index, bool val) {
    debugPrint(
      "Toggle status for ${providerList[index].fullName} to $val",
    );
  }
}
