class ModuleModel {
  final String id;
  final String moduleName;
  final String moduleIdentifier;
  final bool isActive;

  ModuleModel({
    required this.id,
    required this.moduleName,
    required this.moduleIdentifier,
    required this.isActive,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      id: json['id'] ?? '',
      moduleName: json['moduleName'] ?? '',
      moduleIdentifier: json['moduleIdentifier'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}