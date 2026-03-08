import 'package:get/get.dart';
import 'package:flutter/material.dart';

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

  @override
  void onInit() {
    super.onInit();
    fetchRequests();
  }

  void fetchRequests() {
    // Mock Data matching your screenshot
    requestList.value = [
      OnboardingRequestModel(
        id: "1",
        name: "Amit Verma",
        phone: "+91 8887776665",
        email: "amit.v@example.com",
        requestType: "New Registration",
        requestDate: DateTime(2023, 11, 20),
        status: "Pending",
        documents: ["Aadhar Card", "PAN Card"],
      ),
      OnboardingRequestModel(
        id: "2",
        name: "Suman Gupta",
        phone: "+91 7778889991",
        email: "suman.g@example.com",
        requestType: "Bank Update",
        requestDate: DateTime(2023, 11, 21),
        status: "Pending",
        documents: ["Passbook Front"],
      ),
      OnboardingRequestModel(
        id: "3",
        name: "Karan Mehra",
        phone: "+91 9996667776",
        email: "karan.m@example.com",
        requestType: "New Registration",
        requestDate: DateTime(2023, 11, 22),
        status: "Pending",
        documents: ["Driving License", "Training Certificate"],
      ),
    ];
  }

  void setTab(String tab) {
    selectedTab.value = tab;
    // In a real app, you would filter requestList here
  }

  void approveRequest(String id) {
    Get.snackbar("Success", "Request Approved", backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, maxWidth: 400);
  }

  void rejectRequest(String id) {
    Get.snackbar("Rejected", "Request Rejected", backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, maxWidth: 400);
  }
}