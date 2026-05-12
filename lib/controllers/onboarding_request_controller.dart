import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'provider_controller.dart';
import '../models/provider_model.dart';

class OnboardingRequestModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String requestType; // e.g. "New Registration", "Bank Update"
  final DateTime requestDate;
  final String status; // "Pending", "Approved", "Rejected"
  final List<String> documents; // e.g. ["Aadhar Card", "PAN Card"]

  OnboardingRequestModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.requestType,
    required this.requestDate,
    required this.status,
    required this.documents,
  });
}
class OnboardingRequestController extends GetxController {
  var selectedTab = "All".obs;
  var requestList = <OnboardingRequestModel>[].obs;
  var allCount = 0.obs;
  var pendingCount = 0.obs;
  var approvedCount = 0.obs;
  final ProviderController _providerController = Get.find<ProviderController>();
  var approvedIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to changes in the global provider list
    ever(_providerController.allProviders, (_) => fetchRequests());
    fetchRequests();
  }

  void fetchRequests() {
    // Only show in Onboarding if imageUrl is null or empty
    final onboardingProviders = _providerController.allProviders.where((p) => p.imageUrl == null || p.imageUrl!.isEmpty).toList();
    
    var allReq = onboardingProviders.map((p) => OnboardingRequestModel(
      id: p.id,
      name: p.fullName,
      phone: p.mobileNo,
      email: p.emailId ?? "No Email",
      requestType: "New Registration",
      requestDate: DateTime.now(), 
      status: approvedIds.contains(p.id) ? "Approved" : "Pending",
      documents: p.aadharNo.isNotEmpty ? ["Aadhar Card"] : [],
    )).toList();

    allCount.value = allReq.length;
    pendingCount.value = allReq.where((req) => req.status == "Pending").length;
    approvedCount.value = allReq.where((req) => req.status == "Approved").length;

    // Filter based on selected tab
    if (selectedTab.value == "Pending") {
      allReq = allReq.where((req) => req.status == "Pending").toList();
    } else if (selectedTab.value == "Approved") {
      allReq = allReq.where((req) => req.status == "Approved").toList();
    }

    requestList.value = allReq;
  }

  void setTab(String tab) {
    selectedTab.value = tab;
    fetchRequests();
  }

  void approveRequest(String id) {
    final provider = _providerController.allProviders.firstWhereOrNull((p) => p.id == id);
    if (provider == null) return;

    if (provider.isAadharVerified) {
      Get.snackbar("Info", "Provider is already verified and moved to active list.", backgroundColor: Colors.blue, colorText: Colors.white);
    } else {
      approvedIds.add(id);
      fetchRequests();
      Get.snackbar("Success", "Provider approved locally. They will stay in 'Approved' tab until Aadhar is verified.", backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, maxWidth: 400);
    }
  }

  void rejectRequest(String id) {
    Get.snackbar("Rejected", "Request Rejected", backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, maxWidth: 400);
  }
}