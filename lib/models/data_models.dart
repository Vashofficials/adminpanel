class LoginResponseModel {
  final String message;
  final String token;

  LoginResponseModel({required this.message, required this.token});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    // Handling structure: { "result": { "message": "...", "result": "TOKEN" } }
    final innerResult = json['result']; 
    
    return LoginResponseModel(
      message: innerResult['message'] ?? 'Success',
      token: innerResult['result'] ?? '', // This grabs the actual token string
    );
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String? imgLink;
  final String? bannerLink; // 👈 New Field
  final bool isActive;

  CategoryModel({required this.id, required this.name, this.imgLink, this.bannerLink, this.isActive = true});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      imgLink: json['imgLink'],
      isActive: json['isActive'] ?? true,
      bannerLink: json['bannerLink'], // 👈 Map here
    );
  }
}

class ServiceCategoryModel {
  final String id;
  final String name;
  final String? imgLink;
  final bool isActive; // 👈 1. ADD THIS FIELD
  final String categoryId; // We need this for the UI, but the API doesn't return it!
  

  ServiceCategoryModel({
    required this.id, 
    required this.name, 
    this.imgLink, 
    this.isActive = true, // 👈 2. ADD TO CONSTRUCTOR WITH DEFAULT
    required this.categoryId
  });

  // We add an optional 'injectedCategoryId' because the API response 
  // doesn't tell us which parent this belongs to, but we know it from the request.
  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json, {String linkCategoryId = ''}) {
    return ServiceCategoryModel(
      // FIX 1: Map the correct keys from Swagger
      id: json['serviceCategoryId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['serviceCategoryName'] ?? json['name'] ?? 'Unknown',
      imgLink: json['imgLink'],
      // FIX 2: Use the ID we pass in, because the JSON doesn't contain it
      categoryId: linkCategoryId, 
      isActive: json['isActive'] ?? true,
    );
  }
}
class ServiceModel {
  final String id;
  final String categoryId; // 🟢 Added
  final String serviceCategoryId; // 🟢 Added
  final String name;
  final double price;
  final String? description;
  final int duration;
  final String? imgLink;
  final bool isActive;

  ServiceModel({
    required this.id,
    required this.categoryId,
    required this.serviceCategoryId,
    required this.name,
    required this.price,
    this.description,
    required this.duration,
    this.imgLink,
    this.isActive = true,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '', // 🟢 Map from JSON
      serviceCategoryId: json['serviceCategoryId']?.toString() ?? '', // 🟢 Map from JSON
      name: json['name'] ?? 'Unknown Service',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      description: json['description'],
      duration: int.tryParse(json['duration'].toString()) ?? 0,
      imgLink: json['imgLink'],
      isActive: json['isActive'] ?? true,
    );
  }
}

class ServiceTimingModel {
  final String serviceTimingId;
  final String categoryId;
  final String startTime;
  final String endTime;

  ServiceTimingModel({
    required this.serviceTimingId,
    required this.categoryId,
    required this.startTime,
    required this.endTime,
  });

  factory ServiceTimingModel.fromJson(Map<String, dynamic> json) {
    return ServiceTimingModel(
      serviceTimingId: json['serviceTimingId']?.toString() ?? json['id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      startTime: json['startTime'] ?? json['start_time'] ?? '',
      endTime: json['endTime'] ?? json['end_time'] ?? '',
    );
  }
}
