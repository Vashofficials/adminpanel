import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../models/data_models.dart';
import 'dart:ui'; // Required for Dashed Painter
import '../widgets/custom_center_dialog.dart';

class AddServiceScreen extends StatefulWidget {
  // Optional callbacks if you want to handle navigation manually from the parent
  final VoidCallback? onCancel; 
  final Function(bool success)? onSave;

  const AddServiceScreen({super.key, this.onCancel, this.onSave});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final ApiService _api = ApiService();
  final Color _primaryOrange = const Color(0xFFEF7822);
  final Color _bgGrey = const Color(0xFFF8F9FA);

  // Data
  List<CategoryModel> _mainCategories = [];
  List<ServiceCategoryModel> _svcCategories = [];
  
  // State
  bool _loadingSvcCats = false;
  bool _isSubmitting = false;
  String? _selectedMainCatId;
  String? _selectedSvcCatId;

  // Form Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _durCtrl = TextEditingController();
  
  Uint8List? _imgBytes;
  String? _imgName;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _api.getCategories();
      if (mounted) setState(() => _mainCategories = cats);
    } catch (e) {
      print("Error loading categories: $e");
    }
  }

  Future<void> _loadServiceCats(String mainCatId) async {
    setState(() => _loadingSvcCats = true);
    try {
      final data = await _api.getServiceCategories(mainCatId);
      if (mounted) {
        setState(() {
          _svcCategories = data;
          _loadingSvcCats = false;
          _selectedSvcCatId = null; 
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingSvcCats = false);
    }
  }

  Future<void> _pickImage() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['png', 'jpg', 'jpeg'],
    withData: true, // Ensure bytes are loaded
  );

  if (result != null) {
    Uint8List? bytes = result.files.first.bytes;
    String name = result.files.first.name;
    int sizeInBytes = result.files.first.size;

    // 1. Check size limit (2MB)
    if (sizeInBytes > 1 * 1024 * 1024) {
      CustomCenterDialog.show(
  context,
  title: "Error",
  message: "File size should be under 1 MB",
  type: DialogType.error,
);
      return;
    }

    // 2. Optional: Extra extension check (already filtered above)
    final ext = name.split('.').last.toLowerCase();
    if (!['png', 'jpg', 'jpeg'].contains(ext)) {
      CustomCenterDialog.show(
  context,
  title: "Error",
  message: "Only PNG and JPG files are allowed",
  type: DialogType.error,
);
      return;
    }

    setState(() {
      _imgBytes = bytes;
      _imgName = name;
    });
  }
}


  Future<void> _submit() async {
  if (_nameCtrl.text.isEmpty || _selectedMainCatId == null) {
      CustomCenterDialog.show(
  context,
  title: "Selection Required",
  message: "Please fill all required fields",
  type: DialogType.required,
);
    return;
  }

  if (_imgBytes == null) {
    CustomCenterDialog.show(
  context,
  title: "Selection Required",
  message: "Please select an image",
  type: DialogType.required,
);
    return;
  }

  setState(() => _isSubmitting = true);

  bool success = await _api.addService(
    {
      "categoryId": _selectedMainCatId,
      "serviceCategoryId": _selectedSvcCatId,
      "name": _nameCtrl.text,
      "description": _descCtrl.text,
      "price": double.tryParse(_priceCtrl.text) ?? 0,
      "duration": int.tryParse(_durCtrl.text) ?? 0,
    },
    _imgBytes,
    _imgName,
  );

  setState(() => _isSubmitting = false);

  if (success) {
    CustomCenterDialog.show(
  context,
  title: "Success",
  message: "Service added successfully",
  type: DialogType.success,
);
    // Optionally reset form or pop
    if (widget.onSave != null) widget.onSave!(true);
    else if (Navigator.canPop(context)) Navigator.pop(context, true);
  } else {
    CustomCenterDialog.show(
  context,
  title: "Error",
  message: "Failed to add service. Please try again.",
  type: DialogType.error,
);
  }
}


  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Wrapped in Scaffold to provide Material context for TextFields
    return Scaffold(
      backgroundColor: _bgGrey, 
      // No AppBar provided here, so no back button is shown automatically.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Custom Header
            const Text("Add New Service", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 5),
            const Text("Fill in the details below to create a new service.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // 2. Basic Setup Card
            _buildCard(
              title: "Basic Setup",
              subtitle: "Provide essential service details",
              child: Column(
                children: [
                  _buildTextField("Service Name (Default) *", _nameCtrl, hint: "e.g. AC Repair", showAI: true),
                  const SizedBox(height: 20),
                  _buildTextField("Long Description (Default) *", _descCtrl, hint: "Enter detailed description here...", maxLines: 4, showAI: true),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // 3. Responsive Layout for General Setup & Thumbnail
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildGeneralSetupCard()),
                      const SizedBox(width: 24),
                      Expanded(flex: 1, child: _buildThumbnailCard()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildGeneralSetupCard(),
                      const SizedBox(height: 24),
                      _buildThumbnailCard(),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 40),

            // 4. Footer Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _handleCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Next Step", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildCard({required String title, required String subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1)),
          child,
        ],
      ),
    );
  }

  Widget _buildGeneralSetupCard() {
    return _buildCard(
      title: "General Setup",
      subtitle: "Here you can set up the foundational details required for service creation.",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Choose Category *", style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        filled: true,
                        fillColor: Color(0xFFF9F9F9)
                      ),
                      value: _selectedMainCatId,
                      hint: const Text("Select Category"),
                      items: _mainCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (val) {
                        setState(() => _selectedMainCatId = val);
                        if (val != null) _loadServiceCats(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Choose Subcategory", style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _loadingSvcCats 
                    ? const LinearProgressIndicator(minHeight: 2)
                    : DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          filled: true,
                          fillColor: Color(0xFFF9F9F9)
                        ),
                        value: _selectedSvcCatId,
                        hint: const Text("Select Subcategory"),
                        items: _svcCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (val) => setState(() => _selectedSvcCatId = val),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTextField("Booking Duration *", _durCtrl, hint: "e.g. 30 minutes")),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField("Price *", _priceCtrl, hint: "\$ 0.00")),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField("Enter tags", TextEditingController(), hint: "Press enter to add tags"),
        ],
      ),
    );
  }

  Widget _buildThumbnailCard() {
    return _buildCard(
      title: "Thumbnail image *",
      subtitle: "Upload your thumbnail Image",
      child: GestureDetector(
        onTap: _pickImage,
        child: CustomPaint(
          painter: DashedBorderPainter(),
          child: Container(
            height: 250,
            width: double.infinity,
            color: const Color(0xFFF9FAFB),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _imgBytes != null
                ? Image.memory(_imgBytes!, height: 80, fit: BoxFit.contain)
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Color(0xFFFFE0CC), shape: BoxShape.circle),
                    child: Icon(Icons.cloud_upload, color: _primaryOrange, size: 28),
                  ),
                const SizedBox(height: 15),
                Text(_imgName ?? "Add image", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                const SizedBox(height: 5),
                const Text("Image format - png, jpg, jpeg, gif\nImage Size - Maximum size 1 MB", 
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {String? hint, int maxLines = 1, bool showAI = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            if (showAI) 
              TextButton.icon(
                onPressed: (){}, 
                icon: const Icon(Icons.auto_awesome, size: 14, color: Colors.orange),
                label: const Text("Generate", style: TextStyle(color: Colors.orange, fontSize: 12)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0,0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              )
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade300)),
            filled: true,
            fillColor: const Color(0xFFF9F9F9),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}

// --- Dashed Painter ---
class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 3, startX = 0;
    final paint = Paint()..color = Colors.grey[400]!..strokeWidth = 1..style = PaintingStyle.stroke;
    var path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)));
    Path dashPath = Path();
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (startX < pathMetric.length) {
        dashPath.addPath(pathMetric.extractPath(startX, startX + dashWidth), Offset.zero);
        startX += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}