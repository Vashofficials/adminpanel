import '../services/api_service.dart'; // Import your api service
import '../models/customer_models.dart'; // Import the model above

class CustomerRepository {
  final ApiService _apiService = ApiService();

  Future<CustomerResponse> fetchCustomers(int page, int size) async {
    try {
      final response = await _apiService.getAllCustomers(page: page, size: size);
      return CustomerResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load customers: $e');
    }
  }
  Future<bool> updateCustomerStatus({
    required String customerId, 
    required bool isActive,
  }) async {
    try {
      final response = await _apiService.updateCustomerStatus(
        customerId: customerId,
        isActive: isActive,
      );
      
      // Return true if the status code indicates success (200 or 204)
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Repository Error: $e");
      return false; 
    }
  }
}