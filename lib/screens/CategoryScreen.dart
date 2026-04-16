import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../models/data_models.dart';
import 'dart:ui'; // Required for PathMetric
import '../widgets/custom_center_dialog.dart';
import '../widgets/image_preview_dialog.dart';

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
  Uint8List? _selectedBannerBytes;
  String? _selectedBannerName;
  bool _isUploading = false;
  // Inside _CategoryScreenState class
final TextEditingController _searchCtrl = TextEditingController(); // 👈 Add this

@override
void dispose() {
  _searchCtrl.dispose(); // 👈 Good practice to dispose
  super.dispose();
}

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
  Future<void> _pickImage() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['png'],
    withData: true,
  );

  if (result != null && result.files.isNotEmpty) {
    final file = result.files.first;
    // Calculate size in MB
    double sizeInMb = file.size / (1024 * 1024);

    if (sizeInMb > 1.0) {
      CustomCenterDialog.show(
        context,
        title: "File Too Large",
        message: "The Icon is ${sizeInMb.toStringAsFixed(2)} MB. Please upload an image under 1 MB.",
        type: DialogType.error,
      );
      return;
    }

    setState(() {
      _selectedImageBytes = file.bytes;
      _selectedImageName = file.name;
    });
  }
}

Future<void> _pickBanner() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['png', 'jpg', 'jpeg'],
    withData: true,
  );

  if (result != null && result.files.isNotEmpty) {
    final file = result.files.first;
    double sizeInMb = file.size / (1024 * 1024);

    if (sizeInMb > 1.0) {
      CustomCenterDialog.show(
        context,
        title: "File Too Large",
        message: "The Banner is ${sizeInMb.toStringAsFixed(2)} MB. Please upload an image under 1 MB.",
        type: DialogType.error,
      );
      return;
    }

    setState(() {
      _selectedBannerBytes = result.files.first.bytes;
      _selectedBannerName = result.files.first.name;
    });
  }
}
  void _resetForm() {
    setState(() {
      _nameCtrl.clear();
      _selectedImageBytes = null;
      _selectedImageName = null;
      _selectedBannerBytes = null; // 👈 Clear banner
    _selectedBannerName = null;
    });
  }

  Future<void> _submitCategory() async {
  // 1. Validation: Ensure everything is selected
  if (_nameCtrl.text.isEmpty || _selectedImageBytes == null || _selectedBannerBytes == null) {
    CustomCenterDialog.show(
      context,
      title: "Selection Required",
      message: "Category name, Icon, and Banner are all required.",
      type: DialogType.required,
    );
    return;
  }

  setState(() => _isUploading = true);

  // 2. Corrected API Call with Named Parameters
  bool success = await _api.addCategory(
    name: _nameCtrl.text,
    iconBytes: _selectedImageBytes!,
    iconName: _selectedImageName,
    bannerBytes: _selectedBannerBytes!,
    bannerName: _selectedBannerName,
  );

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
      message: "Failed to add category. Please try again.",
      type: DialogType.error,
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.toLowerCase();
  final filteredCategories = _categories.where((cat) {
    return cat.name.toLowerCase().contains(query);
  }).toList();
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
           _buildListCard(filteredCategories),
          ],
        ),
      ),
    );
  }

 Widget _buildSetupCard() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.add_circle, color: _primaryOrange, size: 20),
            const SizedBox(width: 8),
            const Text("Category Setup",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const Divider(height: 20),

        LayoutBuilder(
          builder: (context, constraints) {
            // Increased threshold to 950 to fit 3 columns comfortably
            bool isWide = constraints.maxWidth > 950;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Name Input
                  Expanded(flex: 2, child: _buildNameInput()),
                  const SizedBox(width: 20),
                  
                  // 2. Icon Upload
                  Expanded(
                    flex: 3,
                    child: _buildImageUploadArea(
                      label: "Category Icon",
                      formatText: "PNG only",
                      bytes: _selectedImageBytes,
                      fileName: _selectedImageName,
                      onTap: _pickImage,
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // 3. Banner Upload
                  Expanded(
                    flex: 3,
                    child: _buildImageUploadArea(
                      label: "Category Banner",
                      formatText: "PNG/JPG",
                      bytes: _selectedBannerBytes,
                      fileName: _selectedBannerName,
                      onTap: _pickBanner,
                    ),
                  ),
                ],
              );
            } else {
              // Mobile / Narrow Layout
              return Column(
                children: [
                  _buildNameInput(),
                  const SizedBox(height: 20),
                  _buildImageUploadArea(
                    label: "Category Icon",
                    formatText: "PNG only",
                    bytes: _selectedImageBytes,
                    fileName: _selectedImageName,
                    onTap: _pickImage,
                    networkUrl: null, // 👈 Add this to fix errors on the main screen
                  ),
                  const SizedBox(height: 20),
                  _buildImageUploadArea(
                    label: "Category Banner",
                    formatText: "PNG/JPG",
                    bytes: _selectedBannerBytes,
                    fileName: _selectedBannerName,
                    onTap: _pickBanner,
                  ),
                ],
              );
            }
          },
        ),

        const SizedBox(height: 24),
        
        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _resetForm,
              style: OutlinedButton.styleFrom(
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
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
  void _handleToggleStatus(CategoryModel category, bool newValue) {
  CustomCenterDialog.show(
    context,
    title: "Change Status",
    message: "Are you sure you want to ${newValue ? 'Activate' : 'Deactivate'} this category?",
    type: DialogType.warning,
    confirmText: "Yes, Change",
    onConfirm: () async {
      // Reusing your deleteCategory API which handles status toggling
      bool success = await _api.deleteCategory(category.id, category.isActive);

      if (!mounted) return;

      if (success) {
        CustomCenterDialog.show(
          context,
          title: "Success",
          message: "Category status updated successfully",
          type: DialogType.success,
        );
        _loadCategories(); // Refresh the list
      } else {
        CustomCenterDialog.show(
          context,
          title: "Error",
          message: "Failed to update status",
          type: DialogType.error,
        );
      }
    },
  );
}
Future<void> _showUpdateCategoryDialog(CategoryModel category) async {
  final nameController = TextEditingController(text: category.name);
  
  // States for Icon
  Uint8List? newImageBytes;
  String? newImageName;
  
  // States for Banner
  Uint8List? newBannerBytes;
  String? newBannerName;
  
  bool isUpdating = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          
          // Helper to pick Icon
          Future<void> pickUpdateImage() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['png'],
    withData: true,
  );

  if (result != null && result.files.isNotEmpty) {
    final file = result.files.first;
    double sizeInMb = file.size / (1024 * 1024);

    if (sizeInMb > 1.0) {
      // Note: Use 'this.context' to show dialog over the current dialog
      CustomCenterDialog.show(
        this.context,
        title: "File Too Large",
        message: "The Icon is ${sizeInMb.toStringAsFixed(2)} MB. Please upload an image under 1 MB.",
        type: DialogType.error,
      );
      return;
    }
    setDialogState(() {
      newImageBytes = file.bytes;
      newImageName = file.name;
    });
  }
}

// Helper to pick Banner inside dialog
Future<void> pickUpdateBanner() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['png', 'jpg', 'jpeg'],
    withData: true,
  );

  if (result != null && result.files.isNotEmpty) {
    final file = result.files.first;
    double sizeInMb = file.size / (1024 * 1024);

    if (sizeInMb > 1.0) {
      CustomCenterDialog.show(
        this.context,
        title: "File Too Large",
        message: "The Banner is ${sizeInMb.toStringAsFixed(2)} MB. Please upload an image under 1 MB.",
        type: DialogType.error,
      );
      return;
    }
    setDialogState(() {
      newBannerBytes = file.bytes;
      newBannerName = file.name;
    });
  }
}
          // Helper to submit update
      // Helper to submit update inside StatefulBuilder
Future<void> submitUpdate() async {
  // 1. Validation: check if we have either a new file OR an existing network image
  bool hasIcon = newImageBytes != null || (category.imgLink != null && category.imgLink!.isNotEmpty);
  bool hasBanner = newBannerBytes != null || (category.bannerLink != null && category.bannerLink!.isNotEmpty);

  if (!hasIcon || !hasBanner) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Both Icon and Banner are required to proceed"))
    );
    return;
  }
  
  setDialogState(() => isUpdating = true);

  try {
    // 🔑 FIX: Remove the '!' operators. Pass the variables directly.
    bool success = await _api.updateCategory(
      id: category.id, 
      name: nameController.text, 
      iconBytes: newImageBytes, // Now allows null if not re-picked
      iconName: newImageName,
      bannerBytes: newBannerBytes, // Now allows null if not re-picked
      bannerName: newBannerName,
    );

    if (!mounted) return;
    setDialogState(() => isUpdating = false);

    if (success) {
      Navigator.pop(ctx);
      _loadCategories();
      CustomCenterDialog.show(this.context, title: "Success", message: "Updated successfully", type: DialogType.success);
    } else {
      CustomCenterDialog.show(this.context, title: "Error", message: "Update failed", type: DialogType.error);
    }
  } catch (e) {
    setDialogState(() => isUpdating = false);
    debugPrint("Update error: $e");
  }
}

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.white,
            child: Container(
              width: 500, // Slightly wider to accommodate two image areas
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView( // Added scroll for smaller screens
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit, color: _primaryOrange),
                        const SizedBox(width: 10),
                        const Text("Update Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 30),

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

                    // Icon Picker
                   _buildImageUploadArea(
  label: "Update Icon",
  formatText: "PNG only",
  bytes: newImageBytes,
  fileName: newImageName,
  onTap: pickUpdateImage,
  networkUrl: category.imgLink, // 👈 Pass existing icon link
),

const SizedBox(height: 20),

// 2. Banner Picker
_buildImageUploadArea(
  label: "Update Banner",
  formatText: "PNG/JPG",
  bytes: newBannerBytes,
  fileName: newBannerName,
  onTap: pickUpdateBanner,
  networkUrl: category.bannerLink, // 👈 Pass existing banner link
),
                    
                    const SizedBox(height: 30),

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
            ),
          );
        },
      );
    },
  );
}
  Widget _buildImageUploadArea({
  required String label,
  required String formatText,
  required Uint8List? bytes,
  required String? fileName,
  required VoidCallback onTap,
  String? networkUrl, // 👈 ADD THIS PARAMETER
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RichText(
        text: TextSpan(
          text: "$label ",
          style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
          children: [
            const TextSpan(text: "* ", style: TextStyle(color: Colors.red)),
            TextSpan(text: "($formatText)", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: DashedBorderPainter(),
          child: Container(
            height: 105,
            width: double.infinity,
            color: const Color(0xFFFFF9F5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (bytes != null) // 1. Show new local file if picked
                   (fileName?.toLowerCase().endsWith('.svg') ?? false 
                    ? const Icon(Icons.insert_drive_file, color: Colors.orange)
                    : Image.memory(bytes, height: 40, width: 40))
                else if (networkUrl != null && networkUrl.isNotEmpty) // 2. Fallback to existing network image
                   SizedBox(
                     height: 40, 
                     width: 40, 
                     child: _buildImage(networkUrl) // Uses your existing _buildImage helper
                   )
                else // 3. Show upload icon if nothing exists
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFFFE0CC), shape: BoxShape.circle),
                    child: const Icon(Icons.cloud_upload, color: Color(0xFFEF7822), size: 20),
                  ),
                const SizedBox(height: 8),
                Text(
                  fileName ?? (networkUrl != null ? "Current Image" : "Click to upload"),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
  Widget _buildListCard(List<CategoryModel> displayList) {
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
  controller: _searchCtrl, // 👈 Connect controller
  onChanged: (val) => setState(() {}), // 👈 Rebuild list as user types
  decoration: InputDecoration(
    hintText: "Search", // Updated hint
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
                  // 1. CHECK IF LIST IS EMPTY
                  if (displayList.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text(
                          "No categories match your search.",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    );
                  }

                  // 2. IF NOT EMPTY, SHOW THE TABLE
                  return SingleChildScrollView(
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
                          //  DataColumn(label: Text("SUB CATEGORY COUNT", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text("BANNER", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))), // 👈 ADD THIS
                            DataColumn(label: Text("CATEGORY ICON", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text("STATUS", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text("ACTION", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                          rows: List<DataRow>.generate(displayList.length, (index) {
                           final cat = displayList[index];
                            return DataRow(
                              cells: [
                                DataCell(Text("${index + 1}")),
                                DataCell(Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                               
                               DataCell(
  GestureDetector(
    onTap: () => ImagePreviewDialog.show(context, url: cat.bannerLink, title: "Banner View"),
    child: Container(
      width: 80, 
      padding: const EdgeInsets.all(5),
      child: _buildImage(cat.bannerLink), 
    ),
  ),
),
                                DataCell(
  GestureDetector(
    onTap: () {
      if (cat.imgLink != null && cat.imgLink!.isNotEmpty) {
        ImagePreviewDialog.show(
          context, 
          url: cat.imgLink, 
          title: "${cat.name} Icon"
        );
      }
    },
    child: MouseRegion( // Optional: changes cursor to pointer on web
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!), 
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey[50], // Subtle background to show it's clickable
        ),
        child: _buildImage(cat.imgLink),
      ),
    ),
  ),
),
                               // 1. Updated Toggle Logic
      DataCell(
        Switch(
          value: cat.isActive,
          activeColor: _primaryOrange,
          onChanged: (bool newValue) {
            _handleToggleStatus(cat, newValue);
          },
        )
      ),
      // 2. Simplified Action Cell (Removed Delete Button)
      DataCell(
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
          onPressed: () => _showUpdateCategoryDialog(cat), 
        ),
      ),
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