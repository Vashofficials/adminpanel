import 'package:flutter/material.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  // Brand Colors
  final Color _primaryOrange = const Color(0xFFFF5722);
  final Color _bgGrey = const Color(0xFFF5F6FA);

  // Form Controllers
  final TextEditingController _fNameController = TextEditingController(text: "John");
  final TextEditingController _lNameController = TextEditingController(text: "Doe");
  final TextEditingController _phoneController = TextEditingController(text: "555-0123");
  final TextEditingController _emailController = TextEditingController(text: "john.doe@example.com");
  final TextEditingController _passController = TextEditingController(text: "password123");

  // --- STATE VARIABLES ---
  
  // Password Visibility
  bool _obscurePassword = true;

  // Checkbox States (Updated based on Sidebar Promotion section)
  bool _bannerChecked = true;
  bool _discountChecked = true;
  bool _couponChecked = false;
  
  // Notification States
  bool _sendNotifChecked = true;
  bool _pushNotifChecked = true;

  // Permission Access States (Mapped to Sidebar Sections)
  // Keys match the Sidebar Section Headers
  final Map<String, Map<String, bool>> _permissions = {
    'Booking Management': {
      'ADD': false, 'UPDATE': true, 'DELETE': false, 'EXPORT': true, 'STATUS': true, 'DENY': true
    },
    'Service Management': { // Covers Zone, Category, and Service Lists
      'ADD': true, 'UPDATE': true, 'DELETE': false, 'EXPORT': false, 'STATUS': true, 'DENY': false
    },
    'Provider Management': { // Covers Provider List, Onboarding
      'ADD': true, 'UPDATE': true, 'DELETE': false, 'EXPORT': true, 'STATUS': true, 'DENY': true
    },
    'User Management': { // Covers Customers
      'ADD': false, 'UPDATE': true, 'DELETE': false, 'EXPORT': true, 'STATUS': true, 'DENY': true
    },
    'Transaction & Analytics': { // Covers Reports & Keyword Search
      'ADD': false, 'UPDATE': false, 'DELETE': false, 'EXPORT': true, 'STATUS': false, 'DENY': false
    },
    'Promotion Management': { // Covers Banners, Discounts, Coupons
      'ADD': true, 'UPDATE': true, 'DELETE': true, 'EXPORT': true, 'STATUS': true, 'DENY': true
    },
    'Notification Management': {
      'ADD': true, 'UPDATE': false, 'DELETE': false, 'EXPORT': false, 'STATUS': true, 'DENY': false
    },
    'Employee Management': {
      'ADD': false, 'UPDATE': false, 'DELETE': false, 'EXPORT': false, 'STATUS': false, 'DENY': false
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 24,
        title: Row(
          children: [
            Container(
              height: 20,
              width: 1,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.symmetric(horizontal: 10),
            ),
            const Text(
              "Add New Employee",
              style: TextStyle(
                  color: Color(0xFF1A1D1F),
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepper(),
            const SizedBox(height: 30),
            _buildSection1EmployeeInfo(),
            const SizedBox(height: 20),
            _buildSection2AccountInfo(),
            const SizedBox(height: 20),
            _buildSection3Permissions(),
            const SizedBox(height: 30),
            _buildFooterButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepItem("1", "Basic Info", "Personal details", true),
          _buildStepDivider(),
          _buildStepItem("2", "Account", "Login credentials", true),
          _buildStepDivider(),
          _buildStepItem("3", "Set Permissions", "Role capabilities", true),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String subtitle, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isActive ? _primaryOrange : Colors.grey[200],
          child: Text(number, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isActive ? _primaryOrange : Colors.grey)),
        Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 80,
      height: 2,
      color: _primaryOrange.withOpacity(0.2),
      margin: const EdgeInsets.only(bottom: 25, left: 15, right: 15),
    );
  }

  Widget _buildSection1EmployeeInfo() {
    return _buildCardWrapper(
      title: "1. Employee Information",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTextField("First Name", _fNameController)),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField("Last Name", _lNameController)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(flex: 1, child: _buildTextField("Phone Number", _phoneController)),
              const Expanded(flex: 1, child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection2AccountInfo() {
    return _buildCardWrapper(
      title: "2. Account Information",
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Login Credentials", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text("These details will be used by the employee to sign in to the admin panel.", style: TextStyle(color: Colors.blue, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTextField("Email Address *", _emailController, icon: Icons.email_outlined)),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField(
                  "Password *",
                  _passController,
                  isPassword: true,
                  isObscured: _obscurePassword,
                  icon: Icons.lock_outline,
                  onSuffixPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  }
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection3Permissions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("3. Set Permissions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Text("Configure role-based access control matching the sidebar modules.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 15),

        // 1. Booking Management
        _buildPermissionCard(
          "Booking Management",
          const Text("Access to Offline Payments, Ongoing, Completed, and Canceled bookings.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          _buildAccessRow("Booking Management"),
        ),

        // 2. Service Management (Zone, Category, Service)
        _buildPermissionCard(
          "Service Management",
          const Text("Includes: Zone Setup (Map/Buffer), Category Setup, and Service Lists.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          _buildAccessRow("Service Management"),
        ),

        // 3. Provider Management
        _buildPermissionCard(
          "Provider Management",
          const Text("Includes: Provider List, Add Provider, and Onboarding Requests.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          _buildAccessRow("Provider Management"),
        ),

        // 4. User Management (Customers)
        _buildPermissionCard(
          "User Management",
          const Text("Access to Customer List and details.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          _buildAccessRow("User Management"),
        ),

        // 5. Transaction & Analytics
        _buildPermissionCard(
          "Transaction & Analytics",
           const Text("Includes: Transactions, Booking/Provider Reports, and Keyword Search Analytics.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          _buildAccessRow("Transaction & Analytics"),
        ),

        // 6. Promotion Management
        _buildPermissionCard(
          "Promotion Management",
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildCheckbox("Promotion Banners", _bannerChecked, (v) => setState(() => _bannerChecked = v!)),
              _buildCheckbox("Discounts", _discountChecked, (v) => setState(() => _discountChecked = v!)),
              _buildCheckbox("Coupons", _couponChecked, (v) => setState(() => _couponChecked = v!)),
            ],
          ),
          _buildAccessRow("Promotion Management"),
        ),

        // 7. Notification Management
        _buildPermissionCard(
          "Notification Management",
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildCheckbox("Send Notification", _sendNotifChecked, (v) => setState(() => _sendNotifChecked = v!)),
              _buildCheckbox("Push Notifications", _pushNotifChecked, (v) => setState(() => _pushNotifChecked = v!)),
            ],
          ),
          _buildAccessRow("Notification Management"),
        ),
        
        // 8. Employee Management
        _buildPermissionCard(
          "Employee Management",
          const Text("Warning: Granting this allows the user to create/edit other employees and roles.", style: TextStyle(color: Colors.redAccent, fontSize: 13)),
          _buildAccessRow("Employee Management"),
        ),
      ],
    );
  }

  // --- REUSABLE COMPONENTS ---

  Widget _buildCardWrapper({required String title, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!title.startsWith("3")) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ),
              Divider(height: 40, color: Colors.grey.shade200),
            ],
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(String title, Widget? content, Widget accessRow) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 15),
            if (content != null) ...[
              content,
              const SizedBox(height: 20),
            ],
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 15),
            Text("Manage Access", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            const SizedBox(height: 15),
            accessRow,
          ],
        ),
      ),
    );
  }

  Widget _buildAccessRow(String sectionKey) {
    // Keys for the toggles
    List<String> actions = ['ADD', 'UPDATE', 'DELETE', 'EXPORT', 'STATUS', 'DENY'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actions.map((action) {
          bool isActive = _permissions[sectionKey]?[action] ?? false;
          return _buildToggleItem(action, isActive, () {
            setState(() {
              _permissions[sectionKey]![action] = !isActive;
            });
          });
        }).toList(),
      ),
    );
  }

  Widget _buildToggleItem(String label, bool value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 30.0),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 8),

          // FUNCTIONAL SWITCH
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: value ? _primaryOrange : Colors.grey[300],
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeIn,
                    left: value ? 22 : 2,
                    top: 2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: value
                          ? Icon(Icons.check, size: 14, color: _primaryOrange)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
                value: value,
                activeColor: _primaryOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: BorderSide(color: Colors.grey.shade400),
                onChanged: onChanged
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      {
        bool isPassword = false,
        bool isObscured = false,
        IconData? icon,
        VoidCallback? onSuffixPressed
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? isObscured : false,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.grey) : null,
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                isObscured ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: onSuffixPressed,
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: _primaryOrange),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            backgroundColor: Colors.white,
          ),
          child: const Text("Previous", style: TextStyle(color: Colors.grey)),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            // Logic to print permissions to console for verification
            print(_permissions);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryOrange,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text("Finish", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }
}