import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/data_models.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();

  Future<bool> login(String username, String password) async {
    try {
      // 1. Get Model from API
      LoginResponseModel response = await _apiService.login(username, password);
      
      // 2. Check if token exists
      if (response.token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response.token);
        return true;
      }
      return false;
    } catch (e) {
      print("Repo Login Error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}