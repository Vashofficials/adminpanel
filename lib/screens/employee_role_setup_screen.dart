import 'package:flutter/material.dart';

class EmployeeRoleSetupScreen extends StatefulWidget {
  final VoidCallback? onBack; 
  const EmployeeRoleSetupScreen({super.key, this.onBack});

  @override
  State<EmployeeRoleSetupScreen> createState() => _EmployeeRoleSetupScreenState();
}

class _EmployeeRoleSetupScreenState extends State<EmployeeRoleSetupScreen> {
  // ---------------------------------------------------------------------------
  // 1. STATE & DATA
  // ---------------------------------------------------------------------------
  final TextEditingController _roleNameController = TextEditingController(text: "Jr. Digital Marketer");

  // Updated Structure to match DashboardSidebar exactly
  final Map<String, Map<String, bool>> _permissions = {
    // Single Item in Sidebar, treated as a section here
    'Dashboard': {
      'Access Dashboard': true,
    },
    'Booking Management': {
      'Offline Payment': false,
      'Ongoing': false,
      'Completed': false,
      'Canceled': false,
    },
    'Service Management': {
      'Zone Setup (Map & Buffer)': false,
      'Category Setup': false,
      'Service List': false,
      'Add New Service': false,
    },
    'Provider Management': {
      'Provider List': false,
      'Add Provider': false,
      'Onboarding Requests': false,
    },
    'User Management': {
      'Customer List': false,
    },
    'Transaction & Analytics': {
      'Transaction Report': false,
      'Booking Report': false,
      'Provider Report': false,
      'Keyword Search': false,
    },
    'Promotion Management': {
      'Promotion Banners': true,
      'Discount List': true,
      'Add Discount': true,
      'Coupon List': true,
      'Add Coupon': true,
    },
    'Notification Management': {
      'Send Notification': true,
      'Push Notifications': true,
    },
    'Employee Management': {
      'Employee Role Setup': false,
      'Employee List': false,
      'Add New Employee': false,
    },
  };

  // Helper to check if ALL permissions in the entire form are checked
  bool get _isGlobalAllSelected {
    for (var section in _permissions.values) {
      if (section.containsValue(false)) return false;
    }
    return true;
  }

  // Helper to toggle everything
  void _toggleGlobalAll(bool? value) {
    setState(() {
      final newValue = value ?? false;
      for (var sectionKey in _permissions.keys) {
        _permissions[sectionKey]!.updateAll((key, val) => newValue);
      }
    });
  }

  // Helper to check if a specific section has all items selected
  bool _isSectionAllSelected(String sectionKey) {
    final section = _permissions[sectionKey];
    if (section == null) return false;
    return !section.containsValue(false);
  }

  // Helper to toggle a specific section
  void _toggleSectionAll(String sectionKey, bool? value) {
    setState(() {
      final newValue = value ?? false;
      _permissions[sectionKey]!.updateAll((key, val) => newValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Light grey background
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (widget.onBack != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: IconButton(
                          onPressed: widget.onBack, 
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          tooltip: 'Back',
                        ),
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Employee Role Setup",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1D1F)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Configure user roles and permissions for the Chayankaro admin panel.",
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                // Global Save Button Top Right
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text("Save Role"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Role Name Input
                  _buildLabel("Role Name *"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _roleNameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.business_center_outlined, color: Colors.grey),
                      hintText: "Ex: Manager, Editor...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF6B00))),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 2. Permissions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Permissions / Accesses",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Select the options you want to give access to this role",
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                      // Global Select All
                      _buildSelectAllToggle(
                        label: "Select All Permissions",
                        value: _isGlobalAllSelected,
                        onChanged: _toggleGlobalAll,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Dashboard Access (Top Single Card)
                  _buildSinglePermissionCard("Dashboard", "Access Dashboard"),
                  const SizedBox(height: 24),

                  // 4. Detailed Permission Sections (Iterating to match structure)
                  // We map through the keys to ensure order matches sidebar
                  ...[
                    "Booking Management",
                    "Service Management",
                    "Provider Management",
                    "User Management",
                    "Transaction & Analytics",
                    "Promotion Management",
                    "Notification Management",
                    "Employee Management"
                  ].map((section) => _buildSection(section)).toList(),
                  
                  const SizedBox(height: 16),
                  
                  // 5. Footer Buttons
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          _toggleGlobalAll(false);
                          _roleNameController.clear();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Reset"),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Submit Logic
                          print(_permissions);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00), // Orange
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text("Submit"),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI WIDGET BUILDERS
  // ---------------------------------------------------------------------------

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: text.endsWith('*') ? const Color(0xFFFF6B00) : Colors.black87,
      ),
    );
  }

  // The toggle for "Select All"
  Widget _buildSelectAllToggle({required String label, required bool value, required Function(bool?) onChanged}) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: value ? const Color(0xFFFF6B00) : Colors.grey.shade400, width: 2),
              color: value ? const Color(0xFFFF6B00) : Colors.transparent,
            ),
            child: value ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  // Specialized card for single items (like Dashboard)
  Widget _buildSinglePermissionCard(String sectionKey, String permissionKey) {
    // Safety check
    if (_permissions[sectionKey] == null) return const SizedBox.shrink();
    
    bool isChecked = _permissions[sectionKey]?[permissionKey] ?? false;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(permissionKey, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
          _CustomCheckbox(
            value: isChecked,
            onChanged: (val) {
              setState(() {
                _permissions[sectionKey]![permissionKey] = val;
              });
            },
          ),
        ],
      ),
    );
  }

  // Standard section builder
  Widget _buildSection(String title) {
    // Get permissions for this section
    final sectionData = _permissions[title];
    if (sectionData == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50], // Very light background for the group
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with "Select All"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                _buildSelectAllToggle(
                  label: "Select All",
                  value: _isSectionAllSelected(title),
                  onChanged: (val) => _toggleSectionAll(title, val),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          
          // Grid of Permissions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              children: sectionData.entries.map((entry) {
                return SizedBox(
                  width: 200, // Fixed width for alignment like grid
                  child: Row(
                    children: [
                      _CustomCheckbox(
                        value: entry.value,
                        onChanged: (val) {
                          setState(() {
                            _permissions[title]![entry.key] = val;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CUSTOM CHECKBOX WIDGET (ORANGE CIRCLE)
// -----------------------------------------------------------------------------
class _CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CustomCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value ? const Color(0xFFFF6B00) : Colors.transparent,
          border: Border.all(
            color: value ? const Color(0xFFFF6B00) : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: value
            ? const Center(child: Icon(Icons.check, size: 14, color: Colors.white))
            : null,
      ),
    );
  }
}