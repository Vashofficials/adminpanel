class DocumentTypeModel {
  final String id;
  final String name;
  final bool isActive;
  final String creationTime; // New field

  DocumentTypeModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.creationTime,
  });

  factory DocumentTypeModel.fromJson(Map<String, dynamic> json) {
    return DocumentTypeModel(
      id: json['id'] ?? "",
      name: json['name'] ?? "Unknown Doc",
      isActive: json['isActive'] ?? false,
      creationTime: json['creationTime'] ?? "", // Safe default
    );
  }
}