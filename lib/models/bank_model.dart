class BankModel {
  final String id;
  final String name;
  final String imgLink;
  final bool isActive;

  BankModel({
    required this.id,
    required this.name,
    required this.imgLink,
    required this.isActive,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imgLink: json['imgLink'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}
class ProviderBankDetails {
  final String? bankId;
  final String? bankName; // Added for display
  final String accountHolderName;
  final String accountNo;
  final String ifscCode;
  final String? upiId;
  final bool isPanAvailable;
  final String? panNo;
  final String? passbookUrl; // Added
  final String? panUrl;      // Added

  ProviderBankDetails({
    this.bankId,
    this.bankName,
    required this.accountHolderName,
    required this.accountNo,
    required this.ifscCode,
    this.upiId,
    required this.isPanAvailable,
    this.panNo,
    this.passbookUrl,
    this.panUrl,
  });

  factory ProviderBankDetails.fromJson(Map<String, dynamic> json) {
    return ProviderBankDetails(
      bankId: json['bankId']?.toString(), // Might be null in your result JSON, usually mapped or ID
      bankName: json['bankName']?.toString(), // Use this for display
      accountHolderName: json['accountHolderName']?.toString() ?? '',
      accountNo: json['accountNo']?.toString() ?? '',
      ifscCode: json['ifscCode']?.toString() ?? '',
      upiId: json['upiId']?.toString(),
      isPanAvailable: json['isPanAvailable'] == true || json['isPanAvailable'] == 1,
      panNo: json['panNo']?.toString(),
      passbookUrl: json['passbookUrl']?.toString(),
      panUrl: json['panUrl']?.toString(),
    );
  }
}