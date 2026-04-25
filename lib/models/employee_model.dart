class EmployeeModel {
  final String id;
  final int userType;
  final String name;
  final String mobileNo;
  final String emailId;
  final String address;
  final String userName;
  final bool isActive;

  EmployeeModel({
    required this.id,
    required this.userType,
    required this.name,
    required this.mobileNo,
    required this.emailId,
    required this.address,
    required this.userName,
    required this.isActive,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] ?? '',
      userType: json['userType'] ?? 0,
      name: json['name'] ?? '',
      mobileNo: json['mobileNo'] ?? '',
      emailId: json['emailId'] ?? '',
      address: json['address'] ?? '',
      userName: json['userName'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}