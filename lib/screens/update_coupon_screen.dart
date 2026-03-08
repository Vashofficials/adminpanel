import 'package:flutter/material.dart';

class UpdateCouponScreen extends StatefulWidget {
  const UpdateCouponScreen({super.key});

  @override
  State<UpdateCouponScreen> createState() => _UpdateCouponScreenState();
}

class _UpdateCouponScreenState extends State<UpdateCouponScreen> {
  // --- Controllers ---
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _limitController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(); // Added for discount amount

  // --- State Variables ---
  String? _couponType;
  String? _discountType;
  String _status = 'Active';

  // --- Brand Color ---
  final Color _brandColor = const Color(0xFFEB5725);

  @override
  void initState() {
    super.initState();
    // Pre-fill with data from Row 1 of your list
    _titleController.text = "Discount for premium customers";
    _codeController.text = "ptest@2op622";
    _limitController.text = "15";
    _amountController.text = "10"; // Dummy percentage/amount
    _couponType = "Customer Wise";
    _discountType = "Service";
    _status = "Active";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _limitController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Screen Title ---
            const Text(
              'Update Coupon',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. Main Form Card ---
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Title & Code
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildLabelledField(
                          label: "Coupon Title",
                          child: _buildTextField(
                            controller: _titleController,
                            hint: "Enter coupon title",
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildLabelledField(
                          label: "Coupon Code",
                          child: _buildTextField(
                            controller: _codeController,
                            hint: "Enter unique code",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Row 2: Coupon Type & Discount Type
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildLabelledField(
                          label: "Coupon Type",
                          child: _buildDropdown(
                            value: _couponType,
                            items: ['Customer Wise', 'First Booking', 'Default'],
                            hint: "Select Type",
                            onChanged: (val) => setState(() => _couponType = val),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildLabelledField(
                          label: "Discount Type",
                          child: _buildDropdown(
                            value: _discountType,
                            items: ['Service', 'Category', 'Mixed'],
                            hint: "Select Type",
                            onChanged: (val) => setState(() => _discountType = val),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Row 3: Limit & Amount (or Percentage)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildLabelledField(
                          label: "Limit Per User",
                          child: _buildTextField(
                            controller: _limitController,
                            hint: "0 for unlimited",
                            isNumber: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildLabelledField(
                          label: "Discount Amount / %",
                          child: _buildTextField(
                            controller: _amountController,
                            hint: "Enter value",
                            isNumber: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Row 4: Status (Half width)
                  Row(
                    children: [
                      Expanded(
                        child: _buildLabelledField(
                          label: "Status",
                          child: _buildDropdown(
                            value: _status,
                            items: ['Active', 'Inactive'],
                            hint: "Select Status",
                            onChanged: (val) => setState(() => _status = val!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      const Expanded(child: SizedBox()), // Empty spacer for layout balance
                    ],
                  ),

                  const SizedBox(height: 40),

                  // --- Action Buttons ---
                  Row(
                    children: [
                      // Update Button
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Add Update Logic
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Coupon Updated Successfully")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandColor,
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Update Coupon',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Cancel Button
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            // Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
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

  // --- Helper Widgets (Same as previous Update Screen for consistency) ---

  Widget _buildLabelledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: _brandColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}