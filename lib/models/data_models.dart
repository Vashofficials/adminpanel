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
  final bool isActive;

  CategoryModel({required this.id, required this.name, this.imgLink, this.isActive = true});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      imgLink: json['imgLink'],
      isActive: json['isActive'] ?? true,
    );
  }
}

class ServiceCategoryModel {
  final String id;
  final String name;
  final String? imgLink;
  final String categoryId; // We need this for the UI, but the API doesn't return it!

  ServiceCategoryModel({
    required this.id, 
    required this.name, 
    this.imgLink, 
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
    );
  }
}
class ServiceModel {
  final String id;
  final String name;
  final double price;
  final String? description;
  final int duration;
  final String? imgLink;
  final bool isActive; // 🟢 Added Field

  ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    required this.duration,
    this.imgLink,
    this.isActive = true, // Default to true
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Service',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      description: json['description'],
      duration: int.tryParse(json['duration'].toString()) ?? 0,
      imgLink: json['imgLink'],
      isActive: json['isActive'] ?? true, // 🟢 Map from JSON
    );
  }
}