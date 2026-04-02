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
  var providerCategoriesMap = <String, String>{}.obs; // Add categories map

  // Filters
  var searchText = ''.obs;
  var selectedTab = 'All'.obs; // "All", "Active", "Inactive"
  var selectedCategory = 'All'.obs; // Category-wise filter

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
    ever(selectedCategory, (_) => _applyFilters());
  }

  Future<void> fetchProviders() async {
    try {
      isLoading.value = true;
      final fetched = await _repo.getAllProviders();
      providerCategoriesMap.clear(); // 👈 Clear cache for real-time updates
      allProviders.assignAll(fetched);
      _applyFilters();
      
      // Async fetch mapped categories without blocking UI
      for (var p in fetched) {
        _fetchCategoryForProvider(p.id);
      }
    } catch (e) {
      debugPrint("Fetch providers failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchCategoryForProvider(String id) async {
    if (providerCategoriesMap.containsKey(id)) return;
    try {
      final services = await _repo.getServiceProviderServiceMap(id);
      if (services != null && (services as List).isNotEmpty) {
        // Collect unique categories
        final categories = (services as List).map((s) => s.category.toString()).toSet().toList();
        providerCategoriesMap[id] = categories.isEmpty ? "No Categories" : categories.join(", ");
      } else {
        providerCategoriesMap[id] = "No Mapped Services";
      }
    } catch (e) {
      providerCategoriesMap[id] = "N/A (Error)";
    }
  }

  void _applyFilters() {
    List<ProviderModel> temp = List.from(allProviders);

    // Only show providers that have an imageUrl in the dashboard list
    temp = temp.where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty).toList();

    // Filter by tab
    if (selectedTab.value == 'Active') {
      temp = temp.where((p) => p.isAadharVerified || p.aadharNo.isNotEmpty).toList(); 
    } else if (selectedTab.value == 'Inactive') {
      temp = temp.where((p) => !p.isAadharVerified && p.aadharNo.isEmpty).toList();
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

    // Filter by category
    if (selectedCategory.value != 'All') {
      final cat = selectedCategory.value.toLowerCase();
      temp = temp.where((p) {
        final mapped = providerCategoriesMap[p.id] ?? '';
        return mapped.toLowerCase().contains(cat);
      }).toList();
    }

    providerList.assignAll(temp);
  }

  /// Returns unique list of categories from already-fetched providerCategoriesMap
  List<String> get availableCategories {
    final cats = <String>{};
    for (final val in providerCategoriesMap.values) {
      if (val != 'N/A') {
        for (final c in val.split(',')) {
          final trimmed = c.trim();
          if (trimmed.isNotEmpty) cats.add(trimmed);
        }
      }
    }
    return ['All', ...cats.toList()..sort()];
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
