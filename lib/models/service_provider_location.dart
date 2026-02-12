// models/service_provider_location.dart

class ServiceProviderLocation {
  final String? mappingId; // matches "mappingId"
  final String? areaId;    // matches "areaId"
  final String areaName;   // matches "location"
   bool isActive;     // matches "isActive"

  ServiceProviderLocation({
    this.mappingId,
    this.areaId,
    required this.areaName,
    this.isActive = false,
  });

  factory ServiceProviderLocation.fromJson(Map<String, dynamic> json) {
    return ServiceProviderLocation(
      mappingId: json['mappingId']?.toString(),
      areaId: json['areaId']?.toString(),
      // 🟢 JSON key is "location", mapping it to our internal name "areaName"
      areaName: json['location'] ?? json['areaName'] ?? 'Unknown Area', 
      isActive: json['isActive'] ?? false,
    );
  }
}