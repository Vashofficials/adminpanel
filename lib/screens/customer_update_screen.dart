import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/customer_models.dart'; // Ensure this import points to your model file

// --- Constants ---
const Color kPrimaryOrange = Color(0xFFFF6B00);
const Color kTextDark = Color(0xFF1E293B);
const Color kTextLight = Color(0xFF64748B);
const Color kBorderColor = Color(0xFFE2E8F0);
const Color kBgColor = Color(0xFFF1F5F9);

class CustomerUpdateScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final Customer customer; // ADDED: Receive the customer object

  const CustomerUpdateScreen({
    super.key, 
    this.onBack,
    required this.customer, // ADDED
  });

  @override
  State<CustomerUpdateScreen> createState() => _CustomerUpdateScreenState();
}

class _CustomerUpdateScreenState extends State<CustomerUpdateScreen> {
  // --- State Variables ---
  bool _isUploading = false;
  String? _pickedFileName;
  bool _isSubmitting = false;
  int _selectedAddressIndex = 0;

  // Controllers for form fields
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with customer data
    // Assuming 'name' field combines first and last, we might need to split it for editing
    // or just put the whole name in first name field if splitting is unreliable.
    final nameParts = widget.customer.name.split(' ');
    String firstName = nameParts.isNotEmpty ? nameParts.first : '';
    String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _emailController = TextEditingController(text: widget.customer.email);
    _phoneController = TextEditingController(text: widget.customer.phone);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- Actions ---
  void _pickImage() async {
    if (_pickedFileName != null) return;
    setState(() => _isUploading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isUploading = false;
        _pickedFileName = "new_profile_photo.jpg"; 
      });
    }
  }

  void _removeImage() {
    setState(() {
      _pickedFileName = null;
    });
  }

  void _submitForm() async {
    setState(() => _isSubmitting = true);
    
    // Here you would call your API update method using:
    // _firstNameController.text, _lastNameController.text, etc.
    
    await Future.delayed(const Duration(seconds: 2)); 
    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green),
      );
      if (widget.onBack != null) widget.onBack!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor, // Added background color
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if(widget.onBack != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: kTextDark),
                              onPressed: widget.onBack,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        const Text('Customer Update', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextDark)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('Update customer details and manage addresses', style: TextStyle(color: kTextLight, fontSize: 14)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Main Card ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT SIDE: FORM
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
                              const SizedBox(height: 24),
                              
                              _buildLabel('First Name *'),
                              _buildTextField(_firstNameController, icon: Icons.person_outline),
                              const SizedBox(height: 20),
                              
                              _buildLabel('Last Name *'),
                              _buildTextField(_lastNameController, icon: Icons.person_outline),
                              const SizedBox(height: 20),

                              _buildLabel('Email *'),
                              _buildTextField(_emailController, icon: Icons.email_outlined),
                              const SizedBox(height: 20),

                              _buildLabel('Phone *'),
                              _buildPhoneField(_phoneController), 
                              const SizedBox(height: 32),

                              // Saved Addresses (Static for now as API doesn't provide them yet)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Saved Addresses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)),
                                 
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildAddressCard(0, Icons.home, 'HOME', 'Flat 402, Lotus Apartments, MG Road,\nBangalore, Karnataka - 560001'),
                              const SizedBox(height: 12),
                              _buildAddressCard(1, Icons.work, 'OFFICE', 'Tech Park, Building 3, Sector 5,\nGurugram, Haryana - 122002'),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 40),
                        Container(width: 1, height: 600, color: const Color(0xFFF1F5F9)), 
                        const SizedBox(width: 40),

                        // RIGHT SIDE: PROFILE IMAGE
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              const Text('Profile Image', style: TextStyle(color: kTextLight, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 24),
                              
                              // Profile Avatar
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 65,
                                    backgroundColor: const Color(0xFFE2E8F0),
                                    backgroundImage: _pickedFileName != null 
                                      ? const NetworkImage('https://img.freepik.com/free-photo/portrait-white-man-isolated_53876-40306.jpg') // Mock Local file
                                      : (widget.customer.imgLink != null && widget.customer.imgLink!.isNotEmpty) 
                                          ? NetworkImage(widget.customer.imgLink!) // Use customer image
                                          : null, // Fallback to icon
                                    child: (_pickedFileName == null && (widget.customer.imgLink == null || widget.customer.imgLink!.isEmpty))
                                        ? Text(widget.customer.name.isNotEmpty ? widget.customer.name[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 40, color: kTextLight))
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0, right: 0,
                                    child: InkWell(
                                      onTap: _pickImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: kPrimaryOrange, 
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 3),
                                          boxShadow: [BoxShadow(color: kPrimaryOrange.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                                        ),
                                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Text('Allowed format: png, jpg, jpeg', style: TextStyle(fontSize: 12, color: kTextLight)),
                              const Text('Max size: 2MB', style: TextStyle(fontSize: 12, color: kTextLight)),
                              
                              const SizedBox(height: 32),
                              
                              // Interactive File Upload Box
                              GestureDetector(
                                onTap: _isUploading ? null : _pickImage,
                                child: CustomPaint(
                                  painter: _DashedBorderPainter(color: _pickedFileName != null ? Colors.green : kPrimaryOrange),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                                    color: _pickedFileName != null ? Colors.green.withOpacity(0.05) : kPrimaryOrange.withOpacity(0.02),
                                    child: _isUploading 
                                      ? Column(
                                          children: const [
                                            SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryOrange)),
                                            SizedBox(height: 12),
                                            Text('Uploading...', style: TextStyle(color: kTextLight, fontSize: 12))
                                          ],
                                        )
                                      : _pickedFileName != null 
                                      ? Column(
                                          children: [
                                            const Icon(Icons.check_circle, color: Colors.green, size: 32),
                                            const SizedBox(height: 8),
                                            Text(_pickedFileName!, style: const TextStyle(color: kTextDark, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 8),
                                            InkWell(
                                              onTap: _removeImage,
                                              child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12, decoration: TextDecoration.underline)),
                                            )
                                          ],
                                        )
                                      : Column(
                                          children: const [
                                            Icon(Icons.cloud_upload_outlined, color: kPrimaryOrange, size: 32),
                                            SizedBox(height: 12),
                                            Text('Click to upload', style: TextStyle(color: kPrimaryOrange, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1, color: kBorderColor),
                  
                  // Footer Actions
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                          ElevatedButton(
                          onPressed: () {
                             // Reset Logic
                             setState(() {
                               _pickedFileName = null;
                               // Reset text fields to initial customer values
                               _firstNameController.text = widget.customer.name.split(' ').first;
                               // ... etc
                             });
                           },
                           style: ElevatedButton.styleFrom(
                             backgroundColor: const Color(0xFFF1F5F9), 
                             elevation: 0,
                             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                           ),
                           child: const Text('Reset', style: TextStyle(color: kTextDark)),
                         ),
                         const SizedBox(width: 16),
                         ElevatedButton(
                           onPressed: _isSubmitting ? null : _submitForm,
                           style: ElevatedButton.styleFrom(
                             backgroundColor: kPrimaryOrange, 
                             padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                             elevation: 2,
                             shadowColor: kPrimaryOrange.withOpacity(0.4),
                           ),
                           child: _isSubmitting 
                             ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                             : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                         ),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2),
      child: RichText(
        text: TextSpan(
          text: text.replaceAll('*', ''),
          style: const TextStyle(fontSize: 13, color: kTextLight, fontWeight: FontWeight.w600),
          children: const [
            TextSpan(text: ' *', style: TextStyle(color: Colors.red))
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {IconData? icon}) {
    return TextFormField(
      controller: controller, // Use controller instead of initialValue
      style: const TextStyle(color: kTextDark, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon, color: kTextLight, size: 20) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimaryOrange, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  Widget _buildPhoneField(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kBorderColor),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                 Text('+91', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark, fontSize: 15)),
                 SizedBox(width: 4),
                 Icon(Icons.keyboard_arrow_down_rounded, color: kTextLight, size: 18)
              ],
            ),
          ),
          Container(width: 1, height: 24, color: kBorderColor),
          Expanded(
            child: TextFormField(
              controller: controller,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                hintText: "Phone Number"
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAddressCard(int index, IconData icon, String title, String address) {
    final isSelected = _selectedAddressIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedAddressIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryOrange.withOpacity(0.04) : Colors.white,
          border: Border.all(color: isSelected ? kPrimaryOrange : kBorderColor, width: isSelected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? kPrimaryOrange : kTextLight, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? kPrimaryOrange : kTextLight)),
                  const SizedBox(height: 6),
                  Text(address, style: const TextStyle(fontSize: 13, color: kTextDark, height: 1.5)),
                ],
              ),
            ),
            if (isSelected) 
              const Icon(Icons.check_circle, color: kPrimaryOrange, size: 18)
          ],
        ),
      ),
    );
  }
}

// --- Custom Painter for Dotted Border ---
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    
    // Top
    double startX = 0;
    while (startX < size.width) {
      path.moveTo(startX, 0);
      path.lineTo(startX + dashWidth, 0);
      startX += dashWidth + dashSpace;
    }
    // Bottom
    startX = 0;
    while (startX < size.width) {
      path.moveTo(startX, size.height);
      path.lineTo(startX + dashWidth, size.height);
      startX += dashWidth + dashSpace;
    }
    // Left
    double startY = 0;
    while (startY < size.height) {
      path.moveTo(0, startY);
      path.lineTo(0, startY + dashWidth);
      startY += dashWidth + dashSpace;
    }
    // Right
    startY = 0;
    while (startY < size.height) {
      path.moveTo(size.width, startY);
      path.lineTo(size.width, startY + dashWidth);
      startY += dashWidth + dashSpace;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}