import 'dart:convert';

class BookingResponse {
  final List<BookingModel> content;
  final int totalPages;
  final int totalElements;

  BookingResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
  });

  // --- 1. EXISTING: Handles Admin Paginated Response ---
  // Structure: { "result": { "content": [...], "totalPages": 1 } }
  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'] ?? {};
    // Check if 'content' exists (Pagination style)
    final contentList = (result['content'] as List?) ?? [];

    return BookingResponse(
      content: contentList.map((e) => BookingModel.fromJson(e)).toList(),
      totalPages: result['totalPages'] ?? 0,
      totalElements: result['totalElements'] ?? 0,
    );
  }

  // --- 2. NEW: Handles Customer List Response ---
  // Structure: { "result": [...] } (Direct List)
  static List<BookingModel> parseCustomerList(Map<String, dynamic> json) {
    final result = json['result'];
    
    if (result is List) {
      return result.map((e) => BookingModel.fromJson(e)).toList();
    }
    return [];
  }
}

class BookingModel {
  final String id;
  final String bookingRef;
  final String bookingDate;
  final String bookingTime;
  final String creationTime;
  final String status;
  final String paymentStatus;
  final String paymentMode;
  final int bookingPin;
  
  final String? rescheduleReason;
  final String cancelReason;
  final String cancelledBy;

  final CustomerAddress? address;
  final ServiceProvider? provider;
  final CustomerDetails? customerDetails;
  final List<BookingService> services;
  final CouponModel? coupon;

  // Billing fields extracted from amountString JSON
  final double actualAmount;
  final double platformFee;
  final double gstAmount;
  final double gstPercentage;
  final int totalDuration;

  BookingModel({
    required this.id,
    required this.bookingRef,
    required this.bookingDate,
    required this.bookingTime,
    required this.creationTime,
    required this.status,
    required this.paymentStatus,
    required this.paymentMode,
    required this.bookingPin,
    this.rescheduleReason,
    required this.cancelReason,
    required this.cancelledBy,
    this.address,
    this.provider,
    this.customerDetails,
    required this.services,
    this.coupon,
    required this.actualAmount,
    required this.platformFee,
    required this.gstAmount,
    required this.gstPercentage,
    this.totalDuration = 0,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> amountData = {};
    if (json['amountString'] != null) {
      try {
        amountData = jsonDecode(json['amountString']);
      } catch (e) {
        amountData = {};
      }
    }
    return BookingModel(
      id: json['id']?.toString() ?? '',
      bookingRef: json['bookingReferenceNumber']?.toString() ?? 'N/A',
      bookingDate: json['bookingDate']?.toString() ?? '',
      bookingTime: json['bookingTime']?.toString() ?? '',
      creationTime: json['creationTime']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      paymentStatus: json['paymentStatus']?.toString() ?? 'UnPaid',
      paymentMode: json['paymentMode']?.toString() ?? 'N/A',
      bookingPin: (json['bookingPin'] as num?)?.toInt() ?? 0,
      
      rescheduleReason: json['rescheduleReason']?.toString(),
      cancelReason: json['cancelReason']?.toString() ?? '',
      cancelledBy: json['cancelledBy']?.toString() ?? '',

      address: json['customerAddress'] != null
          ? CustomerAddress.fromJson(json['customerAddress'])
          : null,
      provider: json['serviceProvider'] != null
          ? ServiceProvider.fromJson(json['serviceProvider'])
          : null,
      customerDetails: json['customerDetails'] != null
          ? CustomerDetails.fromJson(json['customerDetails'])
          : null,
      services: (json['bookingService'] as List? ?? [])
          .map((e) => BookingService.fromJson(e))
          .toList(),
          coupon: json['coupon'] != null ? CouponModel.fromJson(json['coupon']) : null,
      
      actualAmount: (amountData['actualAmount'] as num?)?.toDouble() ?? 0.0,
      platformFee: (amountData['plateFormFee'] as num?)?.toDouble() ?? 0.0,
      gstAmount: (amountData['gstAmount'] as num?)?.toDouble() ?? 0.0,
      gstPercentage: (amountData['gstPercentage'] as num?)?.toDouble() ?? 0.0,
      totalDuration: (json['totalDuration'] as num?)?.toInt() ?? 0,
    );
  }

  // --- Getters for UI Compatibility ---
/// 1. Original total price
double get originalPrice =>
    services.fold(0.0, (sum, item) => sum + item.price);

/// 2. Total discount (service + coupon already combined)
double get totalDiscount =>
    services.fold(0.0, (sum, item) => sum + item.discountPrice);

/// 3. Final price before GST
double get priceAfterDiscount =>
    originalPrice - totalDiscount;

/// 4. Grand Total (FINAL BILL)
double get grandTotalPrice =>
    priceAfterDiscount + gstAmount;

/// 5. Coupon (UI only — NEVER use in calculation)
double get couponDiscountValue =>
    coupon?.amount ?? 0.0;
double get serviceDiscount {
  return services.fold(0.0, (sum, item) {
    double serviceLevelDiscount =
        (item.price * item.discountPercentage) / 100;
    return sum + serviceLevelDiscount;
  });
}    

  /*double get totalCouponDiscountAmount {
    return 0.0; // Placeholder until integrated with real API data
  }
*/
  double get totalTaxAmount {
    return gstAmount; 
  }

  String get mainServiceName {
    if (services.isEmpty) return "Unknown Service";
    return services.first.serviceName;
  }

  String get customerName {
    if (customerDetails == null) return "Guest/Unknown";
    return "${customerDetails!.firstName} ${customerDetails!.lastName}";
  }
  // Add this getter in BookingModel class
String get customerId => customerDetails?.id ?? '';

  String get customerPhone {
    return customerDetails?.mobileNo ?? "N/A";
  }
 
  bool get hasRescheduleReason {
  return rescheduleReason != null && rescheduleReason!.trim().isNotEmpty;
}
}

// --- Sub-Models (No Changes Needed) ---

class CustomerDetails {
  final String id; // Add this line
  final String firstName;
  final String lastName;
  final String mobileNo;

  CustomerDetails({
    required this.id, // Add this line
    required this.firstName,
    required this.lastName,
    required this.mobileNo,
  });

  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    return CustomerDetails(
      id: json['id']?.toString() ?? '', // Parse the ID here
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      mobileNo: json['mobileNo']?.toString() ?? '',
    );
  }
}

class CustomerAddress {
  final String id;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postCode;
  final String geoBoundary;

  CustomerAddress({
    required this.id,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postCode,
    required this.geoBoundary,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id']?.toString() ?? '',
      addressLine1: json['addressLine1']?.toString() ?? '',
      addressLine2: json['addressLine2']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      postCode: json['postCode']?.toString() ?? '',
      geoBoundary: json['geoBoundary']?.toString() ?? '',
    );
  }

  String get fullFormattedAddress {
    List<String> parts = [addressLine1, addressLine2, city, state, postCode];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }
}

class ServiceProvider {
  final String id;
  final String firstName;
  final String lastName;
  final String mobile;
  final String gender;

  ServiceProvider({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.gender,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      mobile: json['mobileNo']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
    );
  }
}

class BookingService {
  final String id;
  final String serviceName;
  final String categoryName;   // ← from API: categoryName
  final double price;
  final double discountPrice;
  final double discountPercentage;
  final int serviceDuration;
  final int quantity;
  final String categoryId;
  final String serviceId;

  BookingService({
    required this.id,
    required this.serviceName,
    required this.categoryName,
     required this.categoryId,   // ✅ ADD
  required this.serviceId,    // ✅ ADD
    required this.price,
    required this.discountPrice,
    required this.discountPercentage,
    this.serviceDuration = 0,
    this.quantity = 1,
  });

  factory BookingService.fromJson(Map<String, dynamic> json) {
    return BookingService(
      id: json['id']?.toString() ?? '',
      serviceName: json['serviceIName']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? 'No Mapped Services',
        categoryId: json['categoryId']?.toString() ?? '',   // ✅ ADD
  serviceId: json['serviceId']?.toString() ?? '',     // ✅ ADD
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discountPrice: (json['discountPrice'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      serviceDuration: (json['serviceDuration'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
class CouponModel {
  final String? couponCode;
  final double? discountPercentage;
  final String? couponType;
  final double amount; // <--- ADD THIS FIELD

  CouponModel({this.couponCode, this.discountPercentage, this.couponType,this.amount = 0.0, });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      couponCode: json['couponCode']?.toString(),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      couponType: json['couponType']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}