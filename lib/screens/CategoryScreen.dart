import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../models/data_models.dart';
import 'dart:ui'; // Required for PathMetric
import '../widgets/custom_center_dialog.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ApiService _api = ApiService();

  // Data State
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  // Form State
  final TextEditingController _nameCtrl = TextEditingController();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isUploading = false;

  // Colors
  final Color _primaryOrange = const Color(0xFFEF7822);
  final Color _bgGrey = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await _api.getCategories();
      if (mounted) {
        setState(() {
          _categories = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Form Logic ---
  Future<void> _pickImage() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['png'], // ✅ only PNG
    withData: true, // need bytes
  );

  if (result != null && result.files.isNotEmpty) {
    final file = result.files.first;

    // Check size (< 1 MB)
    if (file.size > 1024 * 1024) {
      CustomCenterDialog.show(
  context,
  title: "File Size Error",
  message: "File size should be under 1 MB",
  type: DialogType.error,
);
      return;
    }

    setState(() {
      _selectedImageBytes = file.bytes;
      _selectedImageName = file.name;
    });

   CustomCenterDialog.show(
  context,
  title: "Success",
  message: "${file.name} selected successfully",
  type: DialogType.success,
);
  }
}

  void _resetForm() {
    setState(() {
      _nameCtrl.clear();
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  Future<void> _submitCategory() async {
  if (_nameCtrl.text.isEmpty) {
     CustomCenterDialog.show(
  context,
  title: "Selection Required",
  message: "Category name cannot be empty",
  type: DialogType.required,
);
    return;
  }

  if (_selectedImageBytes == null) {
     CustomCenterDialog.show(
  context,
  title: "Selection Required",
  message: "Please select an image",
  type: DialogType.required,
);
    return;
  }

  setState(() => _isUploading = true);

  bool success = await _api.addCategory(_nameCtrl.text, _selectedImageBytes, _selectedImageName);

  if (!mounted) return;
  setState(() => _isUploading = false);

  if (success) {
    CustomCenterDialog.show(
  context,
  title: "Success",
  message: "Category added successfully",
  type: DialogType.success,
);
    
    _resetForm();
    _loadCategories();
  } else {
    CustomCenterDialog.show(
  context,
  title: "Error",
  message: "Failed to update category. Please try again.",
  type: DialogType.error,
);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      // 1. SingleChildScrollView enables page-level scrolling
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 2. Category Setup Card (Compact Version)
            _buildSetupCard(),
            
            const SizedBox(height: 24),

            // 3. Category List Card 
            // Removed 'Expanded' here so it flows naturally within the ScrollView
            _buildListCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupCard() {
    return Container(
      // Reduced Padding for compactness
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle, color: _primaryOrange, size: 20),
              const SizedBox(width: 8),
              const Text("Category Setup", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 20), // Reduced height

          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 800;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildNameInput()),
                        const SizedBox(width: 30),
                        Expanded(child: _buildImageUploadArea()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildNameInput(),
                        const SizedBox(height: 15),
                        _buildImageUploadArea(),
                      ],
                    );
            },
          ),

          const SizedBox(height: 20), // Reduced spacing
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _resetForm,
                style: OutlinedButton.styleFrom(
                  // Slightly smaller buttons
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Reset", style: TextStyle(color: Colors.black54)),
              ),
              const SizedBox(width: 15),
              ElevatedButton(
                onPressed: _isUploading ? null : _submitCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isUploading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Submit", style: TextStyle(color: Colors.white)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: "Category Name ",
            style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
            children: [TextSpan(text: "*", style: TextStyle(color: Colors.red))],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            hintText: "e.g. Home Cleaning",
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Compact padding
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _primaryOrange)),
          ),
        ),
      ],
    );
  }
void _handleDelete(String categoryId, bool currentStatus) {
    // 1. Show Confirmation using CustomCenterDialog
    CustomCenterDialog.show(
      context,
      title: "Delete Category",
      message: "Are you sure you want to delete this category?",
      type: DialogType.warning, // Orange warning for destructive actions
      confirmText: "Delete",
      cancelText: "Cancel",
      onConfirm: () async {
        // 2. Call API (Runs after user clicks Delete)
        bool success = await _api.deleteCategory(categoryId, currentStatus);

        if (!mounted) return;

        // 3. Handle Result
        if (success) {
          CustomCenterDialog.show(
            context,
            title: "Success",
            message: "Category deleted successfully",
            type: DialogType.success,
          );
          _loadCategories(); // Refresh the list
        } else {
          CustomCenterDialog.show(
            context,
            title: "Error",
            message: "Failed to delete category",
            type: DialogType.error,
          );
        }
      },
    );
  }
  Future<void> _showUpdateCategoryDialog(CategoryModel category) async {
    final nameController = TextEditingController(text: category.name);
    Uint8List? newImageBytes;
    String? newImageName;
    bool isUpdating = false;

    // We use a StatefulBuilder to update the Dialog's internal state (loading/image preview)
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            // Helper to pick image inside dialog
            Future<void> pickUpdateImage() async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['png'],
                withData: true,
              );

              if (result != null && result.files.isNotEmpty) {
                if (result.files.first.size > 1024 * 1024) {
                   // Show error (reuse your custom dialog logic or simple snackbar for simplicity inside dialog)
                   return; 
                }
                setDialogState(() {
                  newImageBytes = result.files.first.bytes;
                  newImageName = result.files.first.name;
                });
              }
            }

            // Helper to submit update
            Future<void> submitUpdate() async {
              if (newImageBytes == null) {
                // Assuming file is mandatory per Swagger screenshot
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a new image file")));
                 return;
              }
              
              setDialogState(() => isUpdating = true);

              bool success = await _api.updateCategory(
                category.id, 
                nameController.text, 
                newImageBytes!, 
                newImageName!
              );

              setDialogState(() => isUpdating = false);

              if (success) {
                Navigator.pop(ctx); // Close Dialog
                _loadCategories(); // Refresh Parent List
                CustomCenterDialog.show(
                  this.context, // Use parent context
                  title: "Success",
                  message: "Category updated successfully",
                  type: DialogType.success,
                );
              } else {
                 Navigator.pop(ctx);
                 CustomCenterDialog.show(
                  this.context,
                  title: "Error",
                  message: "Update failed",
                  type: DialogType.error,
                );
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.white,
              child: Container(
                width: 400, // Fixed width for center popup feel
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(Icons.edit, color: _primaryOrange),
                        const SizedBox(width: 10),
                        const Text("Update Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 30),

                    // Name Field
                    const Text("Category Name", style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Image Picker
                    const Text("Update Icon (Required)", style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: pickUpdateImage,
                      child: Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9F5),
                          border: Border.all(color: _primaryOrange.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (newImageBytes != null)
                              Image.memory(newImageBytes!, width: 40, height: 40)
                            else 
                              const Icon(Icons.cloud_upload_outlined, color: Colors.orange),
                            const SizedBox(height: 4),
                            Text(
                              newImageName ?? "Click to change image",
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            )
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isUpdating ? null : submitUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: isUpdating 
                             ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                             : const Text("Update", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  Widget _buildImageUploadArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: "Category Icon ",
            style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
            children: [
              TextSpan(text: "* ", style: TextStyle(color: Colors.red)),
              TextSpan(text: "(PNG format only)", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: CustomPaint(
            painter: DashedBorderPainter(),
            child: Container(
              height: 105, // Significantly reduced height (was 150)
              width: double.infinity,
              color: const Color(0xFFFFF9F5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _selectedImageBytes != null
                      ? Image.memory(_selectedImageBytes!, height: 40, width: 40)
                      : Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Color(0xFFFFE0CC), shape: BoxShape.circle),
                          child: const Icon(Icons.cloud_upload, color: Color(0xFFEF7822), size: 20),
                        ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedImageName ?? "Click to upload",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header of List
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.list_alt, color: _primaryOrange),
                    const SizedBox(width: 8),
                    const Text("Category List", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(
                  width: 200,
                  height: 40,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search...",
                      prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    ),
                  ),
                )
              ],
            ),
          ),
          const Divider(height: 1),

          // Table Section
          // Removed 'Expanded' here. We rely on the page scroll.
          _isLoading
              ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      // Only Horizontal Scroll needed for table columns.
                      // Vertical scroll is handled by the main body.
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth > 800 ? constraints.maxWidth : 800,
                        ),
                        child: DataTable(
                          horizontalMargin: 24,
                          columnSpacing: 20,
                          headingRowColor: MaterialStateProperty.all(const Color(0xFFF9F9F9)),
                          columns: [
                            DataColumn(label: Text("SL", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text("CATEGORY NAME", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text("SUB CATEGORY COUNT", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text("CATEGORY ICON", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text("STATUS", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text("ACTION", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                          rows: List<DataRow>.generate(_categories.length, (index) {
                            final cat = _categories[index];
                            return DataRow(
                              cells: [
                                DataCell(Text("${index + 1}")),
                                DataCell(Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(12)),
                                    child: const Text("12", style: TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.bold, fontSize: 12)),
                                  )
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(4)),
                                    child: _buildImage(cat.imgLink),
                                  )
                                ),
                                DataCell(
                                  Switch(
                                    value: cat.isActive,
                                    activeColor: _primaryOrange,
                                    onChanged: (val) {}
                                  )
                                ),
                                DataCell(Row(
  children: [
   IconButton(
      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
      onPressed: () {
        // Trigger the new dialog here
        _showUpdateCategoryDialog(cat); 
      },
    ),
    IconButton(
      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
      // 👇 UPDATED ONPRESSED:
      onPressed: () => _handleDelete(cat.id, cat.isActive), 
    ),
  ],
)),
                              ],
                            );
                          }),
                        ),
                      ),
                    );
                  }
                ),
        ],
      ),
    );
  }

  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) return const Icon(Icons.image, size: 24, color: Colors.grey);
    if (url.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(url, width: 24, height: 24, placeholderBuilder: (_) => const Icon(Icons.image, size: 24, color: Colors.grey));
    }
    return Image.network(url, width: 24, height: 24, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, size: 24, color: Colors.grey));
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 3, startX = 0;
    final paint = Paint()
      ..color = const Color(0xFFEF7822).withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    var path = Path();
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)));

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