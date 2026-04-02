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
  
  final String rescheduleReason;
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
    required this.rescheduleReason,
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
      
      rescheduleReason: json['rescheduleReason']?.toString() ?? '',
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
    );
  }

  // --- Getters for UI Compatibility ---
  double get totalServicePrice => services.fold(0.0, (sum, item) => sum + item.price);

/// Total discount (Original Price - Discount Price) across all services
double get totalServiceDiscount => services.fold(0.0, (sum, item) => sum + (item.price - item.discountPrice));

/// Logic: Total Price - Total Discount Price (represents the coupon/offer value)
double get couponDiscountValue => totalServicePrice - services.fold(0.0, (sum, item) => sum + item.discountPrice);

/// Grand Total Calculation: (Service Total - Coupon Discount) + GST
/// Platform Fee is NOT added here as per your requirement.
double get grandTotalPrice {
  double afterDiscount = totalServicePrice - couponDiscountValue;
  return afterDiscount + gstAmount;
}
  /// Sum of original prices before any discount


  /// Discount from global coupon if applicable
  double get totalCouponDiscountAmount {
    if (coupon == null || coupon!.discountPercentage == null) return 0.0;
    double priceAfterServiceDiscount = totalServicePrice - totalServiceDiscount;
    return priceAfterServiceDiscount * (coupon!.discountPercentage! / 100);
  }

  /// Total discount (Service Level + Coupon Level)
  double get totalDiscountPrice => totalServiceDiscount + totalCouponDiscountAmount;

  /// Final amount: (Price - Discount) + Tax + Platform Fee
  double get totalFinalPrice => (totalServicePrice - totalDiscountPrice) + gstAmount + platformFee;

  double get totalAmount {
    if (services.isEmpty) return 0.0;
    return services.fold(0.0, (sum, item) => sum + item.price);
  }

  double get totalDiscountAmount {
    return totalServiceDiscount;
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

  String get customerPhone {
    return customerDetails?.mobileNo ?? "N/A";
  }
}

// --- Sub-Models (No Changes Needed) ---

class CustomerDetails {
  final String firstName;
  final String lastName;
  final String mobileNo;

  CustomerDetails({
    required this.firstName,
    required this.lastName,
    required this.mobileNo,
  });

  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    return CustomerDetails(
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
  final double price;
  final double discountPrice; // Price after service-specific discount
  final double discountPercentage;

  BookingService({
    required this.id,
    required this.serviceName,
    required this.price,
    required this.discountPrice, required this.discountPercentage
  });

  factory BookingService.fromJson(Map<String, dynamic> json) {
    return BookingService(
      id: json['id']?.toString() ?? '',
      serviceName: json['serviceIName']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discountPrice: (json['discountPrice'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
class CouponModel {
  final String? couponCode;
  final double? discountPercentage;
  final String? couponType;

  CouponModel({this.couponCode, this.discountPercentage, this.couponType});

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      couponCode: json['couponCode']?.toString(),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      couponType: json['couponType']?.toString(),
    );
  }
}