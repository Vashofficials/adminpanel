class ProviderResponse {
  final List<ProviderModel> result;

  ProviderResponse({required this.result});

  factory ProviderResponse.fromJson(Map<String, dynamic> json) {
    return ProviderResponse(
      result: (json['result'] as List? ?? [])
          .map((e) => ProviderModel.fromJson(e))
          .toList(),
    );
  }
}

class ProviderModel {
  final String id;
  final String mobileNo;
  final String? emailId;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String? gender;
  final String? addressLine1;
  final String? addressLine2;
  final String? locality;
  final String? city;
  final String? state;
  final String? zipCode;
  final String aadharNo;
  final bool isAadharVerified;
  final String? imageUrl; // Added imageUrl
  final double totalRating; // 👈 NEW
  final int totalReview;    // 👈 NEW
  bool isActive; 

  ProviderModel({
    required this.id,
    required this.mobileNo,
    this.emailId,
    required this.firstName,
    this.middleName,
    this.lastName,
    this.gender,
    this.addressLine1,
    this.addressLine2,
    this.locality,
    this.city,
    this.state,
    this.zipCode,
    this.isActive = false, // Default value
    required this.aadharNo,
    required this.isAadharVerified,
    this.imageUrl,
    this.totalRating = 0.0,
    this.totalReview = 0,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'] ?? '',
      mobileNo: json['mobileNo'] ?? '',
      emailId: json['emailId'] ?? json['email'], // Safe fallback
      firstName: json['firstName'] ?? 'Unknown',
      middleName: json['middleName'],
      lastName: json['lastName'],
      gender: json['gender'],
      addressLine1: json['addressLine1'],
      addressLine2: json['addressLine2'],
      locality: json['locality'],
      city: json['city'],
      state: json['state'],
      zipCode: json['postCode'],
      aadharNo: json['aadharNo'] ?? '',
      isActive: json['status'] == 1 || json['status'] == true || json['status']?.toString() == '1',
      // Handle both bool and int (1/0) or String representations
      isAadharVerified: json['isAadharVerified'] == true || 
                       json['isAadharVerified'] == 1 || 
                       json['isAadharVerified']?.toString() == 'true',
      imageUrl: json['imageUrl'] ?? json['profilePic'],
      totalRating: (json['totalRating'] ?? 0).toDouble(),
      totalReview: (json['totalReview'] ?? 0).toInt(),
    );
  }

  // --- Helpers for UI ---

  String get fullName {
    String middle = (middleName != null && middleName!.isNotEmpty) ? " $middleName" : "";
    String last = (lastName != null && lastName!.isNotEmpty) ? " $lastName" : "";
    return "$firstName$middle$last".trim();
  }

  String get fullAddress {
    List<String> parts = [];
    if (locality != null) parts.add(locality!);
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    return parts.isEmpty ? "Location N/A" : parts.join(", ");
  }

  String get onboardingStatus {
    if (isAadharVerified || aadharNo.isNotEmpty) return "Approved";
    return "Pending";
  }
}

class ProviderBookingPayment {
  final String providerId;
  final String providerName;
  final int totalBookings;
  final double totalPayment;
  final double totalSettled;

  ProviderBookingPayment({
    required this.providerId,
    required this.providerName,
    required this.totalBookings,
    required this.totalPayment,
    required this.totalSettled,
  });

  factory ProviderBookingPayment.fromJson(Map<String, dynamic> json) {
    return ProviderBookingPayment(
      providerId: json['providerId'] ?? '',
      providerName: json['providerName'] ?? 'Unknown',
      totalBookings: (json['totalBookings'] ?? 0).toInt(),
      totalPayment: (json['totalPayment'] ?? 0).toDouble(),
      totalSettled: (json['totalSettled'] ?? 0).toDouble(),
    );
  }
}