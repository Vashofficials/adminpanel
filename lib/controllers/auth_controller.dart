import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';

class AuthController {
  final AuthRepository _repo = AuthRepository();

  // Returns true if login successful
  Future<bool> login(String username, String password, BuildContext context) async {
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields"), backgroundColor: Colors.orange),
      );
      return false;
    }

    // Call Repository
    bool success = await _repo.login(username, password);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Credentials or Server Error"), backgroundColor: Colors.red),
      );
    }
    
    return success;
  }
}