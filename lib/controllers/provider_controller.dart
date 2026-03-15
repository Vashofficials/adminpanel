import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/provider_model.dart';
import '../repositories/provider_repository.dart';
import '../widgets/custom_center_dialog.dart';

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

    // Filter: Only show verified providers in the main list
    temp = temp.where((p) => p.isAadharVerified).toList();

    // Filter by tab
    if (selectedTab.value == 'Active') {
      temp = temp.where((p) => p.isAadharVerified).toList(); // Redundant but consistent
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

 Future<bool> updateProviderStatus(String id, bool apiValue) async {
  return await _repo.updateProviderStatus(id, apiValue);
}

Future<void> handleToggleStatus(BuildContext context, int index, bool newValue) async {
  final provider = providerList[index];
  
  CustomCenterDialog.show(
    context,
    title: "Change Status",
    message: "Are you sure you want to ${newValue ? 'Activate' : 'Deactivate'} this provider?",
    type: DialogType.warning,
    confirmText: "Yes, Change",
    onConfirm: () async {
      // 1. Requirement Logic: Inactive = true, Active = false
      bool apiValue = !newValue; 

      // 2. Call the newly defined method
      bool success = await updateProviderStatus(provider.id, apiValue);

      if (success) {
        // 3. Update Model (Ensure isActive is not 'final' in ProviderModel)
        provider.isActive = newValue; 
        providerList.refresh(); 

        CustomCenterDialog.show(
          context,
          title: "Success",
          message: "Provider status updated successfully",
          type: DialogType.success,
        );
      } else {
        CustomCenterDialog.show(
          context,
          title: "Error",
          message: "Failed to update status",
          type: DialogType.error,
        );
      }
    },
  );
}
}
