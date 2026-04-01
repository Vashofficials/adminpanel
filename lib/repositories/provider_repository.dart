import 'package:dio/dio.dart'; // Ensure dio is imported
import '../services/api_service.dart';
import '../models/provider_model.dart';

class ProviderRepository {
  final ApiService _api = ApiService();

  // 1. GET ALL PROVIDERS
  Future<List<ProviderModel>> getAllProviders() async {
    try {
      final response = await _api.getAllServiceProviders();
      
      // Parse using the Model Wrapper
      final data = ProviderResponse.fromJson(response);
      return data.result;
    } catch (e) {
      print("Provider Repo Error: $e");
      return [];
    }
    
  }
  Future<bool> updateProviderStatus(String providerId, bool apiValue) async {
    try {
      // Logic remains: apiValue true = Inactive, false = Active
      final response = await _api.deleteServiceProvider(providerId, apiValue);
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Repository Error: $e");
      return false;
    }
  }
  

  // 2. ADD PROVIDER (Endpoint Placeholder)
  // You can update the Map structure based on your Add API requirements
  /*Future<bool> addProvider(Map<String, dynamic> providerData) async {
    try {
      final response = await _api.dio.post(
        '/admin/addServiceProvider', // Assuming this is the endpoint
        data: providerData,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Add Provider Error: $e");
      return false;
    }
  } */

  // 3. GET SERVICE. PROVIDER SERVICE MAP
  Future<dynamic> getServiceProviderServiceMap(String spId) async {
    try {
      return await _api.getServiceProviderServiceMap(spId);
    } catch (e) {
      print("Get Provider Service Map Error: $e");
      return [];
    }
  }
}