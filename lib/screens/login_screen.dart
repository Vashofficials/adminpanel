import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Clipboard
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Required for SVG Logo
import 'package:shared_preferences/shared_preferences.dart'; // <--- 1. ADDED THIS IMPORT
import '../services/api_service.dart';
import '../services/permission_manager.dart';

import '../controllers/auth_controller.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthController _authController = AuthController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  // I changed default to true so users stay logged in by default unless they uncheck it
  bool _rememberMe = false; 

  // Colors
  final Color _primaryOrange = const Color(0xFFF97316); 
  final Color _textDark = const Color(0xFF111827);
  final Color _textGrey = const Color(0xFF6B7280);

  // Constants for credentials
  final String _demoEmail = "Admin";
  final String _demoPass = "123456789";

  // ---------------------------------------------------------
  // UPDATED LOGIN LOGIC
  // ---------------------------------------------------------
void _handleLogin() async {
  setState(() => _isLoading = true);

  bool success = await _authController.login(
    _usernameController.text.trim(),
    _passwordController.text,
    context,
  );

  setState(() => _isLoading = false);

  if (!success) return;

  final prefs = await SharedPreferences.getInstance();

  // ================================
  // 1. SESSION HANDLING
  // ================================
  if (_rememberMe) {
    await prefs.setBool('isLoggedIn', true);
  } else {
    await prefs.remove('isLoggedIn');
  }

  // ================================
  // 2. GET AUTH DATA (TEMP STATIC / OR FROM LOGIN RESPONSE LATER)
  // ================================
  const String staticUserId = "7011fe1a-e73a-4070-82af-326efe0f0042";

  // If your login API returns token later, replace this
  final String? token = prefs.getString("token");

  // ================================
  // 3. FETCH PERMISSIONS (IMPORTANT ADDITION)
  // ================================
  try {
    final api = ApiService();

    final permissions = await api.getUserActivePermissions();

    PermissionManager.set(permissions);
    await PermissionManager.saveToLocal(); // 🔥 ADD THIS
  } catch (e) {
    debugPrint("Permission fetch failed: $e");
  }

  // ================================
  // 4. NAVIGATE TO DASHBOARD
  // ================================
  if (mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const PopScope(
          canPop: false,
          child: DashboardScreen(),
        ),
      ),
    );
  }
}

  void _copyCredentials() {
    Clipboard.setData(ClipboardData(text: "Email: $_demoEmail\nPassword: $_demoPass"));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Credentials copied to clipboard!", style: GoogleFonts.publicSans()),
        backgroundColor: _primaryOrange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // -----------------------
          // LEFT SIDE (Visuals)
          // -----------------------
          Expanded(
            flex: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                Image.asset(
                  'assets/bg.jpg',
                  fit: BoxFit.cover,
                ),
                
                // The Glass Card Content
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 500,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo Area
                            Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/logo.svg',
                                  height: 40, 
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Chayankaro",
                                  style: GoogleFonts.publicSans(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: _textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            // Headline
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.publicSans(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: _textDark,
                                  height: 1.2,
                                ),
                                children: [
                                  const TextSpan(text: "Manage "),
                                  TextSpan(text: "Thousands\n", style: TextStyle(color: _primaryOrange)),
                                  TextSpan(text: "Of ", style: TextStyle(color: _primaryOrange)),
                                  TextSpan(text: "Bookings\n", style: TextStyle(color: _primaryOrange)),
                                  const TextSpan(text: "Effortlessly"),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Streamline your service delivery with our powerful admin dashboard.",
                              style: GoogleFonts.publicSans(fontSize: 16, color: _textDark.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // -----------------------
          // RIGHT SIDE (Form)
          // -----------------------
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              child: Stack(
                children: [
                  // Form Area
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Admin Sign In", style: GoogleFonts.publicSans(fontSize: 26, fontWeight: FontWeight.bold, color: _textDark)),
                          const SizedBox(height: 8),
                          Text("Sign in to stay connected", style: GoogleFonts.publicSans(fontSize: 14, color: _textGrey)),
                          const SizedBox(height: 40),

                          // Email Field
                          _buildLabel("Email"),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _usernameController,
                            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                            decoration: _inputDecoration("Email", Icons.mail_outline),
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          _buildLabel("Password"),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration("Password", Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _textGrey),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          // Remember Me
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: _primaryOrange,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (v) => setState(() => _rememberMe = v!),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text("Remember Me", style: GoogleFonts.publicSans(color: _textGrey)),
                            ],
                          ),
                          
                          const SizedBox(height: 30),

                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryOrange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.white) 
                                : const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Banner
                  /* Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      color: _primaryOrange,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: _copyCredentials,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                 color: Colors.white.withOpacity(0.2),
                                 borderRadius: BorderRadius.circular(8)
                              ),
                              child: const Icon(Icons.copy_outlined, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText("Email : $_demoEmail", style: GoogleFonts.publicSans(color: Colors.white, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              SelectableText("Password : $_demoPass", style: GoogleFonts.publicSans(color: Colors.white, fontWeight: FontWeight.w500)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ) */
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      hintText: label,
      hintStyle: TextStyle(color: _textGrey.withOpacity(0.5)),
      prefixIcon: Icon(icon, color: _textGrey, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _primaryOrange),
      ),
    );
  }
  
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.w500, color: _textGrey),
    );
  }
}