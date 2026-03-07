class SliderBannerModel {
  final String id;
  final BannerCategory category;
  final BannerServiceCategory serviceCategory;
  final String description;
  final String bannerUrl;
  final bool isActive;
  final DateTime? creationTime;

  SliderBannerModel({
    required this.id,
    required this.category,
    required this.serviceCategory,
    required this.description,
    required this.bannerUrl,
    required this.isActive,
    this.creationTime,
  });

  factory SliderBannerModel.fromJson(Map<String, dynamic> json) {
    return SliderBannerModel(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      bannerUrl: json['bannerUrl'] ?? '', // Fixed from bannerLink to bannerUrl
      isActive: json['isActive'] ?? false,
      category: BannerCategory.fromJson(json['category'] ?? {}),
      serviceCategory: BannerServiceCategory.fromJson(json['serviceCategory'] ?? {}),
      creationTime: json['creationTime'] != null 
          ? DateTime.parse(json['creationTime']) 
          : null,
    );
  }
}

class BannerCategory {
  final String id;
  final String name;
  final String? imgLink;

  BannerCategory({required this.id, required this.name, this.imgLink});

  factory BannerCategory.fromJson(Map<String, dynamic> json) {
    return BannerCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      imgLink: json['imgLink'],
    );
  }
}

class BannerServiceCategory {
  final String id;
  final String name;

  BannerServiceCategory({required this.id, required this.name});

  factory BannerServiceCategory.fromJson(Map<String, dynamic> json) {
    return BannerServiceCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
    );
  }
}