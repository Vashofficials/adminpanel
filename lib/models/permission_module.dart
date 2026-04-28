class UserModule {
  final String mappingId;    // e.g. "e2315131-03b1-43c1-83f3-6bfdcbf3d9cc"
  final String userName;     // e.g. "Admin"
  final String moduleName;
  final String moduleIdentifier;
  final bool isActive;

  UserModule({
    this.mappingId = '',
    this.userName = '',
    required this.moduleName,
    required this.moduleIdentifier,
    required this.isActive,
  });

  factory UserModule.fromJson(Map<String, dynamic> json) {
    return UserModule(
      mappingId: json['mappingId'] ?? '',
      userName: json['userName'] ?? '',
      moduleName: json['moduleName'] ?? '',
      moduleIdentifier: json['moduleIdentifier'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}