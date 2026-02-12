class ServiceProviderService {
  final String? mappingId;
  final String category;
  final String serviceCategory;
  final String service;
  final double averageRating;
  final int totalReview;
  bool isActive;

  ServiceProviderService({
    this.mappingId,
    required this.category,
    required this.serviceCategory,
    required this.service,
    this.averageRating = 0.0,
    this.totalReview = 0,
    this.isActive = false,
  });

  factory ServiceProviderService.fromJson(Map<String, dynamic> json) {
    return ServiceProviderService(
      mappingId: json['mappingId']?.toString(),
      category: json['category'] ?? '',
      serviceCategory: json['serviceCategory'] ?? '',
      service: json['service'] ?? '',
      averageRating: (json['averageRating'] is num)
          ? (json['averageRating'] as num).toDouble()
          : 0.0,
      totalReview: (json['totalReview'] is num)
          ? (json['totalReview'] as num).toInt()
          : 0,
      isActive: json['isActive'] ?? false,
    );
  }
}