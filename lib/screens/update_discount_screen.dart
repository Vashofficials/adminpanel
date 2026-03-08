import 'package:flutter/material.dart';

class UpdateDiscountScreen extends StatefulWidget {
  const UpdateDiscountScreen({super.key});

  @override
  State<UpdateDiscountScreen> createState() => _UpdateDiscountScreenState();
}

class _UpdateDiscountScreenState extends State<UpdateDiscountScreen> {
  // Controllers for form fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // State variables for Dropdowns
  String? _selectedType;
  String _selectedStatus = 'Active';

  // Branding color from your previous screen
  final Color _brandColor = const Color(0xFFEB5725);

  @override
  void initState() {
    super.initState();
    // Simulate fetching existing data to edit (e.g., Row 1 from your list)
    _titleController.text = "FLAT 10% OFF ON CAR SHIFTING";
    _amountController.text = "10";
    _selectedType = "Category"; // Matching your list data
    _descriptionController.text = "Applicable for all car shifting services within city limits.";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC), // Same light grey background
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Screen Title ---
            const Text(
              'Update Discount',
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
                  
                  // Row 1: Title & Type
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildLabelledField(
                          label: "Discount Title",
                          child: _buildTextField(
                            controller: _titleController,
                            hint: "Enter discount title",
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildLabelledField(
                          label: "Discount Type",
                          child: _buildDropdown(
                            value: _selectedType,
                            items: ['Category', 'Service', 'Mixed'],
                            hint: "Select Type",
                            onChanged: (val) => setState(() => _selectedType = val),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Row 2: Amount & Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildLabelledField(
                          label: "Discount Percentage (%)",
                          child: _buildTextField(
                            controller: _amountController,
                            hint: "Enter percentage",
                            isNumber: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildLabelledField(
                          label: "Status",
                          child: _buildDropdown(
                            value: _selectedStatus,
                            items: ['Active', 'Inactive'],
                            hint: "Select Status",
                            onChanged: (val) => setState(() => _selectedStatus = val!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Row 3: Description (Full Width)
                  _buildLabelledField(
                    label: "Description",
                    child: _buildTextField(
                      controller: _descriptionController,
                      hint: "Enter discount details...",
                      maxLines: 4,
                    ),
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
                            // Handle Update Logic Here
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Discount Updated Successfully")),
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
                            'Update Discount',
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
                             // Handle Cancel/Back Logic
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

  // --- Helper: Label + Input Container ---
  Widget _buildLabelledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B), // Slate grey
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  // --- Helper: Text Field ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
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

  // --- Helper: Dropdown ---
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