class RefundBank {
  final String id;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String upiId;
  final bool isActive;

  RefundBank({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.upiId,
    required this.isActive,
  });

  factory RefundBank.fromJson(Map<String, dynamic> json) {
    return RefundBank(
      id: json['id'] ?? '',
      bankName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      upiId: json['upiId'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}
class BookingReview {
  final String bookingId;
  final String bookingDate;
  final double rating;
  final String review;

  BookingReview({
    required this.bookingId,
    required this.bookingDate,
    required this.rating,
    required this.review,
  });

  factory BookingReview.fromJson(Map<String, dynamic> json) {
    return BookingReview(
      bookingId: json['bookingRef'] ?? '', // Adjust key based on exact API response
      bookingDate: json['creationTime'] ?? '', 
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      review: json['review'] ?? 'No comment provided.',
    );
  }
}