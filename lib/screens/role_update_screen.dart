import 'package:flutter/material.dart';



class RoleUpdateScreen extends StatefulWidget {
  const RoleUpdateScreen({super.key});

  @override
  State<RoleUpdateScreen> createState() => _RoleUpdateScreenState();
}

class _RoleUpdateScreenState extends State<RoleUpdateScreen> {
  // Brand Color
  final Color _primaryOrange = const Color(0xFFF05A28);
  final Color _bgGrey = const Color(0xFFF5F6FA);
  final Color _textGrey = const Color(0xFF666666);

  // Form Controller
  final TextEditingController _roleNameController =
      TextEditingController(text: "Jr. Digital Marketer");

  // Permission Data Structure
  // Using a list of maps to hold section data and its items
  List<Map<String, dynamic>> _permissionSections = [];
  bool _globalSelectAll = false;

  @override
  void initState() {
    super.initState();
    _initializePermissions();
    _updateGlobalSelectAllState();
  }

  void _initializePermissions() {
    _permissionSections = [
      {
        'title': null, // Top-level items
        'isSelectAll': false,
        'items': [
          {'name': 'Dashboard', 'isChecked': true},
          {'name': 'Booking Management', 'isChecked': true},
          {'name': 'System Addon', 'isChecked': false},
        ],
      },
      {
        'title': 'PROMOTION MANAGEMENT',
        'isSelectAll': false,
        'items': [
          {'name': 'Discounts', 'isChecked': true},
          {'name': 'Coupons', 'isChecked': true},
          {'name': 'Campaigns', 'isChecked': true},
          {'name': 'Advertisements', 'isChecked': true},
          {'name': 'Promotional Banners', 'isChecked': true},
        ],
      },
      {
        'title': 'NOTIFICATION MANAGEMENT',
        'isSelectAll': false,
        'items': [
          {'name': 'Send Push Notification', 'isChecked': true},
          {'name': 'Notification Messages', 'isChecked': false},
          {'name': 'Notification Channel', 'isChecked': false},
        ],
      },
      {
        'title': 'PROVIDER MANAGEMENT',
        'isSelectAll': false,
        'items': [
          {'name': 'Providers List', 'isChecked': false},
          {'name': 'Provider Verification', 'isChecked': false},
          {'name': 'Provider Details', 'isChecked': false},
          {'name': 'Onboarding Requests', 'isChecked': false},
        ],
      },
      {
        'title': 'SERVICE MANAGEMENT',
        'isSelectAll': false,
        'items': [
          {'name': 'Categories', 'isChecked': false},
          {'name': 'Services', 'isChecked': false},
        ],
      },
      {
        'title': 'CUSTOMER MANAGEMENT',
        'isSelectAll': false,
        'items': [
          {'name': 'Customers', 'isChecked': false},
          {'name': 'Newsletter Subscribed Users', 'isChecked': false},
        ],
      },
      {
        'title': 'TRANSACTION AND REPORT MANAGEMENT',
        'isSelectAll': false,
        'items': [
          {'name': 'Transaction', 'isChecked': false},
          {'name': 'Reports', 'isChecked': false},
          {'name': 'Analytics', 'isChecked': false},
        ],
      },
    ];
    for (var section in _permissionSections) {
      _updateGroupSelectAllState(section);
    }
  }

  // Logic to update a group's "Select All" state based on its items
  void _updateGroupSelectAllState(Map<String, dynamic> section) {
    List<Map<String, dynamic>> items = section['items'];
    bool allSelected = items.every((item) => item['isChecked'] == true);
    section['isSelectAll'] = allSelected;
  }

  // Logic to update the global "Select All" state based on all groups
  void _updateGlobalSelectAllState() {
    bool allSectionsSelected =
        _permissionSections.every((section) => section['isSelectAll'] == true);
    setState(() {
      _globalSelectAll = allSectionsSelected;
    });
  }

  // Toggle a single permission item
  void _toggleItem(Map<String, dynamic> item, Map<String, dynamic> section) {
    setState(() {
      item['isChecked'] = !item['isChecked'];
      _updateGroupSelectAllState(section);
      _updateGlobalSelectAllState();
    });
  }

  // Toggle all items in a group
  void _toggleGroup(Map<String, dynamic> section) {
    setState(() {
      bool newValue = !section['isSelectAll'];
      section['isSelectAll'] = newValue;
      for (var item in section['items']) {
        item['isChecked'] = newValue;
      }
      _updateGlobalSelectAllState();
    });
  }

  // Toggle all items globally
  void _toggleGlobal() {
    setState(() {
      _globalSelectAll = !_globalSelectAll;
      for (var section in _permissionSections) {
        section['isSelectAll'] = _globalSelectAll;
        for (var item in section['items']) {
          item['isChecked'] = _globalSelectAll;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
  
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Role Update",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Update role permissions and access levels for employees.",
              style: TextStyle(color: _textGrey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField("Role Name *", _roleNameController,
                        icon: Icons.business_center_outlined),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Permissions / Accesses",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Select the options you want to give access to this role",
                              style: TextStyle(color: _textGrey, fontSize: 14),
                            ),
                          ],
                        ),
                        _buildSelectAllToggle(
                            "Select All", _globalSelectAll, _toggleGlobal),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTopLevelPermissions(),
                    const SizedBox(height: 24),
                    ..._permissionSections
                        .where((section) => section['title'] != null)
                        .map((section) => _buildPermissionGroup(section))
                        .toList(),
                    const SizedBox(height: 30),
                    _buildFooterButtons(),
                  ],
                ),
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildTextField(String label, TextEditingController controller,
      {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: icon != null
                ? Icon(icon, size: 20, color: Colors.grey)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: _primaryOrange),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectAllToggle(
      String label, bool value, VoidCallback onToggle) {
    return InkWell(
      onTap: onToggle,
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: (v) => onToggle(),
              activeColor: _primaryOrange,
              activeTrackColor: _primaryOrange.withOpacity(0.2),
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopLevelPermissions() {
    var section =
        _permissionSections.firstWhere((s) => s['title'] == null);
    return Row(
      children: section['items'].map<Widget>((item) {
        return Expanded(
          child: _buildCheckbox(
            item['name'],
            item['isChecked'],
            () => _toggleItem(item, section),
            isCard: true,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPermissionGroup(Map<String, dynamic> section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border:
                  Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  section['title'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                _buildSelectAllToggle(
                  "Select All",
                  section['isSelectAll'],
                  () => _toggleGroup(section),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              children: section['items'].map<Widget>((item) {
                // A simple way to create a 3-column grid within Wrap
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 120) / 3,
                  child: _buildCheckbox(
                    item['name'],
                    item['isChecked'],
                    () => _toggleItem(item, section),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(
      String label, bool value, VoidCallback onToggle,
      {bool isCard = false}) {
    Widget checkbox = InkWell(
      onTap: onToggle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: Checkbox(
              value: value,
              onChanged: (v) => onToggle(),
              activeColor: _primaryOrange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              side: BorderSide(color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );

    if (isCard) {
      return Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(4),
        ),
        child: checkbox,
      );
    }
    return checkbox;
  }

  Widget _buildFooterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            backgroundColor: Colors.white,
          ),
          child: const Text("Reset", style: TextStyle(color: Colors.black87)),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            // Handle Update Role action
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Role Updated Successfully!")));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryOrange,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Text("Update Role",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}