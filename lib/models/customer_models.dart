// File: lib/models/customer_models.dart

// 1. THE UI MODEL (Used by your Overview and List screens)
class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
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
  final String mobileNo;
  final String? emailId;
  final String firstName;
  final String? lastName;
  final String? imgLink;
  final int status; // 1 for active

  CustomerModel({
    required this.id,
    required this.mobileNo,
    this.emailId,
    required this.firstName,
    this.lastName,
    this.imgLink,
    required this.status,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] ?? '',
      mobileNo: json['mobileNo'] ?? '',
      emailId: json['emailId'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'],
      imgLink: json['imgLink'],
      status: json['status'] ?? 0,
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