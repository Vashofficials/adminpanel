import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_center_dialog.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final ApiService _api = ApiService();

  // Brand Colors
  final Color _primaryOrange = const Color(0xFFFF5722);
  final Color _bgGrey = const Color(0xFFF5F6FA);

  // Form Controllers mapped to API keys
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _obscurePassword = true;
  bool _isRegistering = false;

  Future<void> _handleRegister() async {
  if (_nameController.text.isEmpty ||
      _phoneController.text.isEmpty ||
      _emailController.text.isEmpty ||
      _usernameController.text.isEmpty ||
      _passController.text.isEmpty) {
    CustomCenterDialog.show(context,
        title: "Required Fields",
        message: "Please fill all required information.",
        type: DialogType.required);
    return;
  }

  setState(() => _isRegistering = true);

  try {
    // Calling the updated API method
    bool success = await _api.registerEmployee(
      name: _nameController.text,
      mobileNo: _phoneController.text,
      emailId: _emailController.text,
      address: _addressController.text,
      username: _usernameController.text,
      password: _passController.text,
    );

    if (!mounted) return;

    if (success) {
      CustomCenterDialog.show(context,
          title: "Success",
          message: "Employee registered successfully with User Type 2",
          type: DialogType.success);
      _clearForm();
    } else {
      CustomCenterDialog.show(context,
          title: "Error",
          message: "Registration failed.",
          type: DialogType.error);
    }
  } finally {
    if (mounted) setState(() => _isRegistering = false);
  }
}

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();
    _usernameController.clear();
    _passController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text("Add New Employee",
            style: TextStyle(
                color: Color(0xFF1A1D1F),
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildCardWrapper(
              title: "1. Personal Information",
              child: Column(
                children: [
                  _buildTextField("Full Name *", _nameController, icon: Icons.person_outline),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildTextField("Mobile Number *", _phoneController, icon: Icons.phone_android_outlined)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildTextField("Email ID *", _emailController, icon: Icons.email_outlined)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTextField("Office/Home Address", _addressController, icon: Icons.location_on_outlined),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildCardWrapper(
              title: "2. Account Credentials",
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildTextField("Username *", _usernameController, icon: Icons.alternate_email)),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildTextField(
                          "Password *",
                          _passController,
                          isPassword: true,
                          isObscured: _obscurePassword,
                          icon: Icons.lock_outline,
                          onSuffixPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildFooterButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardWrapper({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isPassword = false, bool isObscured = false, IconData? icon, VoidCallback? onSuffixPressed}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? isObscured : false,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 18) : null,
            suffixIcon: isPassword
                ? IconButton(icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, size: 18), onPressed: onSuffixPressed)
                : null,
            filled: true,
            fillColor: _bgGrey.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _primaryOrange)),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: _clearForm, child: const Text("Reset Form", style: TextStyle(color: Colors.grey))),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isRegistering ? null : _handleRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryOrange,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isRegistering
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Register Employee", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}