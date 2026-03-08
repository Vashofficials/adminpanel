class LocationModel {
  final String? id;
  final String? areaId;
  final String areaName;
  final String? postCode;
  final String? city;
  final String? state;
  final String? geoBoundary;
  // --- NEW FIELDS ADDED ---
  final String? geoPolygonType;
  final bool isActive;

  LocationModel({
    this.id,
    this.areaId,
    required this.areaName,
    this.postCode,
    this.city,
    this.state,
    this.geoBoundary,
    // --- NEW FIELDS IN CONSTRUCTOR ---
    this.geoPolygonType,
    this.isActive = true, // Default to true if not provided
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      areaId: json['areaId'],
      areaName: json['areaName'] ?? '',
      postCode: json['postCode'],
      // --- UPDATED MAPPING ---
      city: json['city'],
      state: json['state'],
      geoBoundary: json['geoBoundary'],
      geoPolygonType: json['geoPolygonType'],
      isActive: json['isActive'] ?? true, // Safe default
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "areaId": areaId,
      "areaName": areaName,
      // Use the actual value if available, else fallback to hardcoded
      "geoPolygonType": geoPolygonType ?? "POLYGON", 
      "geoBoundary": geoBoundary,
      "city": city,
      "state": state,
      "postCode": postCode,
      // --- INCLUDE NEW FIELD ---
      "isActive": isActive,
    };
  }
}