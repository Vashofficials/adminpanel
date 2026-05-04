import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
        
        // Save email
        await prefs.setString('admin_email', username);
        
        // Extract identity from JWT token
        try {
          final parts = response.token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            String normalized = base64Url.normalize(payload);
            String resp = utf8.decode(base64Url.decode(normalized));
            Map<String, dynamic> decoded = json.decode(resp);
            
            // Name extraction
            String adminName = 'Admin';
            if (decoded.containsKey('name')) {
              adminName = decoded['name'];
            } else if (decoded.containsKey('sub')) {
              adminName = decoded['sub'];
            } else if (decoded.containsKey('username')) {
              adminName = decoded['username'];
            }
            await prefs.setString('admin_name', adminName);
            
            // Role extraction
            String adminRole = 'super-admin';
            if (decoded.containsKey('role')) {
              adminRole = decoded['role'];
            }
            await prefs.setString('admin_role', adminRole);
          }
        } catch (e) {
          // If decoding fails, set fallbacks
          await prefs.setString('admin_name', 'Admin');
          await prefs.setString('admin_role', 'super-admin');
        }
        
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
    await prefs.clear();
  }
}