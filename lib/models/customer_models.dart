// File: lib/models/customer_models.dart

// 1. THE UI MODEL (Used by your Overview and List screens)
class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? referralCode; // Add this
  final int bookings;
  final String joinedDate;
  final String location;
  final bool isActive;
  final String avatarColor; 
  final String? imgLink;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.bookings,
    this.referralCode,
    required this.joinedDate,
    required this.location,
    required this.isActive,
    required this.avatarColor,
    this.imgLink,
  });
}

// 2. THE API MODEL (Used to parse JSON from backend)
class CustomerModel {
  final String id;
  final String? referralCode;
  final String mobileNo;
  final String? emailId;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String? gender;
  final String? fcmToken;
  final double averageRating;
  final String? imgLink;
  final int status; // Keep as int for API consistency
  bool isActive;    // Mutable boolean for UI toggling

  CustomerModel({
    required this.id,
    this.referralCode,
    required this.mobileNo,
    this.emailId,
    required this.firstName,
    this.middleName,
    this.lastName,
    this.gender,
    this.fcmToken,
    required this.averageRating,
    this.imgLink,
    required this.status,
    this.isActive = false,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    // Map status 1 to true, others to false
    int apiStatus = json['status'] ?? 0;
    
    return CustomerModel(
      id: json['id'] ?? '',
      referralCode: json['referralCode'],
      mobileNo: json['mobileNo'] ?? '',
      emailId: json['emailId'],
      firstName: json['firstName'] ?? 'Unknown',
      middleName: json['middleName'] ?? '',
      lastName: json['lastName'] ?? '',
      gender: json['gender'],
      fcmToken: json['fcmToken'],
      // averageRating might come as int or double from JSON
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      imgLink: json['imgLink'],
      status: apiStatus,
      isActive: apiStatus == 1,
    );
  }
}

// 3. THE API RESPONSE WRAPPER
class CustomerResponse {
  final List<CustomerModel> content;
  final int totalPages;
  final int totalElements;
  final int currentPage;

  CustomerResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.currentPage,
  });

  factory CustomerResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    return CustomerResponse(
      content: (result['content'] as List)
          .map((e) => CustomerModel.fromJson(e))
          .toList(),
      totalPages: result['totalPages'] ?? 0,
      totalElements: result['totalElements'] ?? 0,
      currentPage: result['number'] ?? 1,
    );
  }
}

class ProviderRating {
  final String providerName;
  final String comment;
  final double rating;

  ProviderRating({
    required this.providerName,
    required this.comment,
    required this.rating,
  });

  factory ProviderRating.fromJson(Map<String, dynamic> json) {
    return ProviderRating(
      providerName: json['providerName'] ?? 'Unknown',
      comment: json['comment'] ?? 'No comment provided.',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}