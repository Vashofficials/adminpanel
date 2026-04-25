class UserModule {
  final String moduleName;
  final String moduleIdentifier;
  final bool isActive;

  UserModule({
    required this.moduleName,
    required this.moduleIdentifier,
    required this.isActive,
  });

  factory UserModule.fromJson(Map<String, dynamic> json) {
    return UserModule(
      moduleName: json['moduleName'],
      moduleIdentifier: json['moduleIdentifier'],
      isActive: json['isActive'] ?? false,
    );
  }
}