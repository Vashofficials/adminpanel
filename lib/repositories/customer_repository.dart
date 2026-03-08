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
}