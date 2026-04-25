import 'package:get/get.dart';
import '../services/api_service.dart'; // Import your dedicated API service

class EmployeeManagementController extends GetxController {
  final ApiService _apiService = ApiService(); // Use your actual instance

  // State Variables
  var isLoading = false.obs;
  var employeeList = <Map<String, dynamic>>[].obs;
  var availableModules = <Map<String, dynamic>>[].obs;
  
  // Permission UI State: { "SectionName": { "PermissionName": bool } }
  var permissionsState = <String, Map<String, bool>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchEmployees();
    fetchModules();
  }

  // --- LOGIC FOR LIST SCREEN ---
  Future<void> fetchEmployees() async {
    try {
      isLoading(true);
      final response = await _apiService.getEmployees();
      if (response.statusCode == 200) {
        employeeList.value = List<Map<String, dynamic>>.from(response.data['result']);
      }
    } finally {
      isLoading(false);
    }
  }

  // --- LOGIC FOR SETUP SCREEN ---
  Future<void> fetchModules() async {
    try {
      final response = await _apiService.getModules();
      if (response.statusCode == 200) {
        availableModules.value = List<Map<String, dynamic>>.from(response.data['result']);
      }
    } catch (e) {
      print("Error fetching modules: $e");
    }
  }

  void updatePermission(String section, String key, bool value) {
    var sectionData = permissionsState[section] ?? {};
    sectionData[key] = value;
    permissionsState[section] = Map<String, bool>.from(sectionData);
  }

  Future<void> submitRolePermissions(String userId) async {
    isLoading(true);
    try {
      // 1. Identify which module identifiers were selected in UI
      // 2. Map those identifiers to the 'id' from availableModules
      List<String> selectedIds = [];
      
      // Basic mapping logic: if any child in a section is true, add that module ID
      for (var module in availableModules) {
        String identifier = module['moduleIdentifier']; // e.g., 'booking_management'
        // Logic to match UI string to identifier
        if (_isModuleActiveInUI(identifier)) {
          selectedIds.add(module['id']);
        }
      }

      await _apiService.addAdminPermission(userId, selectedIds);
      Get.back(); // Return to list
      Get.snackbar("Success", "Permissions Assigned");
    } finally {
      isLoading(false);
    }
  }

  bool _isModuleActiveInUI(String identifier) {
    // Helper to check if the UI checkbox for a specific module identifier is checked
    // Map your UI Section Names to backend identifiers here
    return true; // Simplified for this example
  }
}