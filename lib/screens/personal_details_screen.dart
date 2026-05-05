import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  String _name = '';
  String _email = '';
  String _role = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('admin_name') ?? 'Admin';
      _email = prefs.getString('admin_email') ?? 'admin@admin.com';
      _role = prefs.getString('admin_role') ?? 'super-admin';
      _isLoading = false;
    });
  }

  // --- COLORS ---
  static const Color _primary = Color(0xFFEA5800);
  static const Color _bgColor = Color(0xFFF7F9FC);
  static const Color _cardBg = Colors.white;
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Text(
              "Personal Details",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "View your account information and session details.",
              style: TextStyle(fontSize: 14, color: _textSecondary),
            ),
            const SizedBox(height: 28),

            // --- PROFILE CARD ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // --- AVATAR & NAME ---
                  Row(
                    children: [
                      // Big avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEA5800), Color(0xFFF59E0B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _name.isNotEmpty ? _name[0].toUpperCase() : 'A',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Role badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _role.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  Divider(color: _border, height: 1),
                  const SizedBox(height: 28),

                  // --- DETAIL ROWS ---
                  _buildDetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Full Name',
                    value: _name,
                    iconColor: const Color(0xFF4361EE),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    icon: Icons.email_outlined,
                    label: 'Email Address',
                    value: _email,
                    iconColor: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    icon: Icons.shield_outlined,
                    label: 'Role',
                    value: _role,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Current Session Time',
                    value: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
                    iconColor: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    icon: Icons.devices_rounded,
                    label: 'Platform',
                    value: 'Web (Admin Panel)',
                    iconColor: const Color(0xFFEF4444),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- SECURITY SECTION ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.security_rounded, color: Color(0xFF10B981), size: 22),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        "Security & Session",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSecurityItem(
                    icon: Icons.verified_user_outlined,
                    label: 'Authentication',
                    value: 'JWT Token Based',
                    statusColor: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 14),
                  _buildSecurityItem(
                    icon: Icons.login_rounded,
                    label: 'Login Status',
                    value: 'Active',
                    statusColor: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 14),
                  _buildSecurityItem(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Access Level',
                    value: _role == 'super-admin' ? 'Full Access' : 'Limited Access',
                    statusColor: _role == 'super-admin' ? const Color(0xFF4361EE) : const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: _textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String label,
    required String value,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, color: _textSecondary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: _textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
