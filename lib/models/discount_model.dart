class DiscountModel {
  final String id;
  final String serviceId;
  final String serviceName;
  final int discountPercentage;
  final String startDate;
  final String endDate;
  final bool isActive;

  DiscountModel({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.discountPercentage,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory DiscountModel.fromJson(Map<String, dynamic> json) {
    return DiscountModel(
      id: json['id'] ?? "",
      serviceId: json['serviceId'] ?? "",
      serviceName: json['serviceName'] ?? "Unknown Service",
      discountPercentage: json['discountPercentage'] ?? 0,
      startDate: json['startDate'] ?? "",
      endDate: json['endDate'] ?? "",
      isActive: json['isActive'] ?? false,
    );
  }
}