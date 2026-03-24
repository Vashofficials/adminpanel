import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../models/data_models.dart';
import 'dart:ui'; // Required for PathMetric
import '../widgets/custom_center_dialog.dart';
import '../widgets/image_preview_dialog.dart';

class ServiceCategoryScreen extends StatefulWidget {
  const ServiceCategoryScreen({super.key});

  @override
  State<ServiceCategoryScreen> createState() => _ServiceCategoryScreenState();
}

class _ServiceCategoryScreenState extends State<ServiceCategoryScreen> {
  final ApiService _api = ApiService();

  // Data State
  List<CategoryModel> _parentCategories = []; // For Dropdown and Table Lookup
  List<ServiceCategoryModel> _serviceCategories = []; // The list data
  bool _isLoading = true;

  // Form State
  String? _selectedParentId;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isUploading = false;

  // Colors
  final Color _primaryOrange = const Color(0xFFEF7822);
  final Color _bgGrey = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // 1. Load Parent Categories first
      final parents = await _api.getCategories();
      
      List<ServiceCategoryModel> allServices = [];

      // 2. Loop through EVERY parent category and fetch its specific services
      for (var parent in parents) {
        // Fetch services for this specific parent ID
        final services = await _api.getServiceCategories(parent.id);
        
        // Add them to the master list
        allServices.addAll(services);
      }
      
      if (mounted) {
        setState(() {
          _parentCategories = parents;
          _serviceCategories = allServices; // This now contains data from ALL categories
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // --- Form Logic ---
  Future<void> _pickImage() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['png'], // ✅ PNG only
    withData: true,
  );

  if (result != null && result.files.isNotEmpty) {
    final file = result.files.first;

    // Optional: size limit (< 1MB)
    if (file.size > 1024 * 1024) {
      CustomCenterDialog.show(
  context,
  title: "Error",
  message: "File size should be under 1 MB",
  type: DialogType.error,
);
      return;
    }

    setState(() {
      _selectedImageBytes = file.bytes;
      _selectedImageName = file.name;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${file.name} selected successfully")),
    );
  }
}


  void _resetForm() {
    setState(() {
      _selectedParentId = null;
      _nameCtrl.clear();
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  Future<void> _submitServiceCategory() async {
  if (_selectedParentId == null) {
    CustomCenterDialog.show(
  context,
  title: "Selection Required",
  message: "Please select a parent category",
  type: DialogType.required,
);
    return;
  }

  if (_nameCtrl.text.isEmpty) {
    CustomCenterDialog.show(
  context,
  title: "Selection Required",
  message: "Service category name cannot be empty",
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

  bool success = await _api.addServiceCategory(
    _selectedParentId!,
    _nameCtrl.text,
    _selectedImageBytes,
    _selectedImageName
  );

  if (!mounted) return;
  setState(() => _isUploading = false);

  if (success) {
    CustomCenterDialog.show(
  context,
  title: "Success",
  message: "Service category added successfully",
  type: DialogType.success,
);
    _resetForm();
    _loadData();
  } else {
    CustomCenterDialog.show(
  context,
  title: "Error",
  message: "Failed to add service category. Please try again.",
  type: DialogType.error,
);
  }
}

  
  // Helper to resolve parent name from ID
  String _getParentName(String categoryId) {
    try {
      return _parentCategories.firstWhere((cat) => cat.id == categoryId).name;
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header
            _buildHeader(),
            const SizedBox(height: 24),

            // 2. Setup Card
            _buildSetupCard(),
            const SizedBox(height: 24),

            // 3. List Card
            _buildListCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      
        const Text("Service Category Management",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)
        ),
      ],
    );
  }

  Widget _buildSetupCard() {
    return Container(
      padding: const EdgeInsets.all(20), // Compact padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle, color: _primaryOrange, size: 20),
              const SizedBox(width: 8),
              const Text("Service Category Setup", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 800;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildDropdown(),
                              const SizedBox(height: 15),
                              _buildNameInput(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 30),
                        Expanded(child: _buildImageUploadArea()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildDropdown(),
                        const SizedBox(height: 15),
                        _buildNameInput(),
                        const SizedBox(height: 15),
                        _buildImageUploadArea(),
                      ],
                    );
            },
          ),

          const SizedBox(height: 20),
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
                onPressed: _isUploading ? null : _submitServiceCategory,
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
  void _handleToggleStatus(ServiceCategoryModel item, bool newValue) {
  CustomCenterDialog.show(
    context,
    title: "Change Status",
    message: "Are you sure you want to ${newValue ? 'Activate' : 'Deactivate'} this service category?",
    type: DialogType.warning,
    confirmText: "Yes, Change",
    onConfirm: () async {
      // Reusing your deleteServiceCategory API which flips the active state
      bool success = await _api.deleteServiceCategory(item.id, item.isActive);

      if (!mounted) return;

      if (success) {
        CustomCenterDialog.show(
          context,
          title: "Success",
          message: "Status updated successfully",
          type: DialogType.success,
        );
        _loadData(); // Refresh the list
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

  Future<void> _showUpdateServiceCategoryDialog(ServiceCategoryModel serviceItem) async {
    // Initialize controllers with existing data
    final nameController = TextEditingController(text: serviceItem.name);
    String? selectedParentId = serviceItem.categoryId; // Pre-select current parent
    
    // New Image state
    Uint8List? newImageBytes;
    String? newImageName;
    bool isUpdating = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // StatefulBuilder allows us to update the UI inside the Dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            // Helper: Pick Image
            Future<void> pickUpdateImage() async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['png'],
                withData: true,
              );

              if (result != null && result.files.isNotEmpty) {
                if (result.files.first.size > 1024 * 1024) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File too large")));
                   return; 
                }
                setDialogState(() {
                  newImageBytes = result.files.first.bytes;
                  newImageName = result.files.first.name;
                });
              }
            }

            // Helper: Submit
            Future<void> submitUpdate() async {
              if (selectedParentId == null) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Parent Category is required")));
                 return;
              }
              // Based on swagger, file is required (*)
              if (newImageBytes == null) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a new image")));
                 return;
              }
              
              setDialogState(() => isUpdating = true);

              bool success = await _api.updateServiceCategory(
                serviceItem.id, 
                selectedParentId!,
                nameController.text, 
                newImageBytes!, 
                newImageName!
              );

              setDialogState(() => isUpdating = false);

              if (success) {
                Navigator.pop(ctx); // Close Dialog
                _loadData(); // Refresh Parent List
                CustomCenterDialog.show(
                  this.context,
                  title: "Success",
                  message: "Service Category updated successfully",
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
                width: 450, // Slightly wider for dropdown
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
                        const Text("Update Service Category", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 30),

                    // 1. Parent Category Dropdown
                    const Text("Parent Category", style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _parentCategories.any((p) => p.id == selectedParentId) ? selectedParentId : null,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: _parentCategories.map((cat) {
                        return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedParentId = val),
                    ),
                    const SizedBox(height: 16),

                    // 2. Name Field
                    const Text("Service Name", style: TextStyle(fontWeight: FontWeight.w500)),
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
                    const SizedBox(height: 16),

                    // 3. Image Picker
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

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: "Select Category Name ",
            style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
            children: [TextSpan(text: "*", style: TextStyle(color: Colors.red))],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedParentId,
          decoration: InputDecoration(
            hintText: "Select Category",
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _primaryOrange)),
          ),
          items: _parentCategories.map((cat) {
            return DropdownMenuItem(value: cat.id, child: Text(cat.name));
          }).toList(),
          onChanged: (val) => setState(() => _selectedParentId = val),
        ),
      ],
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: "Service Category Name ",
            style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
            children: [TextSpan(text: "*", style: TextStyle(color: Colors.red))],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            hintText: "e.g. Split AC Cleaning",
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _primaryOrange)),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: "Service Category Icon ",
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
              height: 160, // Matches height of two inputs
              width: double.infinity,
              color: const Color(0xFFFFF9F5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _selectedImageBytes != null
                      ? Image.memory(_selectedImageBytes!, height: 50, width: 50)
                      : Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Color(0xFFFFE0CC), shape: BoxShape.circle),
                          child: const Icon(Icons.cloud_upload, color: Color(0xFFEF7822), size: 24),
                        ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedImageName ?? "Click to upload\nor drag and drop",
                    textAlign: TextAlign.center,
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.list_alt, color: _primaryOrange),
                    const SizedBox(width: 8),
                    const Text("Service Category List", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(
                  width: 200,
                  height: 40,
                  child: TextField(
                    controller: _searchCtrl,
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

          _isLoading
              ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final searchText = _searchCtrl.text.toLowerCase();
                    final filteredList = _serviceCategories.where((cat) {
                      return cat.name.toLowerCase().contains(searchText);
                    }).toList();

                    if (filteredList.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            "No service categories found for \"${_searchCtrl.text}\"",
                            style: TextStyle(color: Colors.grey[600]),
                          )
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth > 800 ? constraints.maxWidth : 800),
                        child: DataTable(
                          horizontalMargin: 24,
                          columnSpacing: 20,
                          headingRowColor: MaterialStateProperty.all(const Color(0xFFF9F9F9)),
                          columns: [
                            DataColumn(label: Text("SL", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text("CATEGORY NAME", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text("SERVICE CATEGORY NAME", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text("ICON", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text("STATUS", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text("ACTION", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                          rows: List<DataRow>.generate(filteredList.length, (index) {
                            final item = filteredList[index];
                            return DataRow(
                              cells: [
                                DataCell(Text("${index + 1}")),
                                // Look up parent name
                                DataCell(Text(_getParentName(item.categoryId), style: TextStyle(color: Colors.grey[700]))),
                                DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                               DataCell(
  GestureDetector(
    onTap: () {
      if (item.imgLink != null && item.imgLink!.isNotEmpty) {
        ImagePreviewDialog.show(
          context, 
          url: item.imgLink, 
          title: "${item.name} Icon"
        );
      }
    },
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!), 
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey[50], // Light background indicating it's an interactive area
        ),
        child: _buildImage(item.imgLink),
      ),
    ),
  ),
),
                                // 1. Updated Toggle Logic
      DataCell(
        Switch(
          value: item.isActive, // Use the actual value from your model
          activeColor: _primaryOrange,
          onChanged: (bool newValue) {
            _handleToggleStatus(item, newValue);
          },
        )
      ),
      // 2. Simplified Action Cell (Removed Delete Button)
      DataCell(
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
          onPressed: () => _showUpdateServiceCategoryDialog(item),
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