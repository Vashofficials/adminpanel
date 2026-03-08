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
    required this.aadharNo,
    required this.isAadharVerified,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'] ?? '',
      mobileNo: json['mobileNo'] ?? '',
      emailId: json['emailId'],
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
      isAadharVerified: json['isAadharVerified'] ?? false,
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
    if (isAadharVerified) return "Approved";
    if (aadharNo.isEmpty) return "Pending Docs";
    return "Pending";
  }
}