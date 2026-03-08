import 'data_models.dart';

class CouponModel {
  final String id;
  final CategoryModel? category;
  final ServiceModel? service;
  final String couponType;
  final String couponCode;
  final String discountType;
  final double amount;
  final double minPurchaseAmount;
  final double discountPercentage;
  final int sameUserLimit;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;

  CouponModel({
    required this.id,
    this.category,
    this.service,
    required this.couponType,
    required this.couponCode,
    required this.discountType,
    required this.amount,
    required this.minPurchaseAmount,
    required this.discountPercentage,
    required this.sameUserLimit,
    required this.isActive,
    required this.startDate, // Add to constructor
    required this.endDate,   // Add to constructor
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id']?.toString() ?? '',
      // Ensure category and service match your DataModel names
      category: json['category'] != null ? CategoryModel.fromJson(json['category']) : null,
      service: json['service'] != null ? ServiceModel.fromJson(json['service']) : null,
      couponType: json['couponType']?.toString() ?? '',
      couponCode: json['couponCode']?.toString() ?? '',
      discountType: json['discountType']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      minPurchaseAmount: (json['minPurchaseAmount'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      sameUserLimit: json['sameUserLimit'] ?? 0,
      isActive: json['isActive'] ?? true,
      // Parse the dates from JSON strings 👈
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : DateTime.now(),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : DateTime.now().add(const Duration(days: 7)),
    
    );
  }
}