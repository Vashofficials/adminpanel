import 'dart:convert';
import '../services/api_service.dart';
import '../models/booking_models.dart';

class BookingRepository {
  final ApiService _api = ApiService();

  // --- EXISTING FUNCTION (Admin: Paginated) ---
  Future<BookingResponse> fetchBookings({int page = 1, int size = 10}) async {
    try {
      print("--- REPO: Fetching All Bookings (Page: $page) ---");
      final response = await _api.getBookings(page: page, size: size);
      return BookingResponse.fromJson(response); // Uses wrapper logic
    } catch (e) {
      print("Repo Error (Fetch All): $e");
      throw Exception("Failed to load bookings");
    }
  }

  // --- NEW FUNCTION (Customer: List) ---
  Future<List<BookingModel>> fetchCustomerBookings(String customerId) async {
    try {
      print("--- REPO: Fetching Customer Bookings (ID: $customerId) ---");
      
      // Use your API service to call: /customer/bookings/$customerId
      // Assuming you added: Future<Map<String, dynamic>> getCustomerBookings(String id)
      final response = await _api.getCustomerBookings(customerId); 
      
      // DEBUG
      // print("RAW CUSTOMER RESPONSE: ${jsonEncode(response)}");

      // Use the smart parser we added to BookingResponse
      return BookingResponse.parseCustomerList(response);
    } catch (e) {
      print("Repo Error (Fetch Customer): $e");
      return []; // Return empty list on error instead of crashing
    }
  }
}