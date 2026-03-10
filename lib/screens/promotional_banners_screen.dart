import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/data_models.dart';
import '../widgets/custom_center_dialog.dart';
import '../models/slider_banner_model.dart';
import '../widgets/image_preview_dialog.dart';

class PromotionalBannersScreen extends StatefulWidget {
  final VoidCallback? onUpdateBanner;
  const PromotionalBannersScreen({super.key, this.onUpdateBanner});

  @override
  State<PromotionalBannersScreen> createState() => _PromotionalBannersScreenState();
}

class _PromotionalBannersScreenState extends State<PromotionalBannersScreen> {
  final ApiService _api = ApiService();
  List<SliderBannerModel> _banners = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
    _loadCategories();
  }

  Future<void> _fetchBanners() async {
    setState(() => _isLoading = true);
    final data = await _api.getAllSliderBanners();
    setState(() {
      _banners = data;
      _isLoading = false;
    });
  }
  Future<void> _loadCategories() async {
    final cats = await _api.getCategories();
    setState(() => _categories = cats);
  }
  
  Future<void> _showUpdateDialog(BuildContext context, SliderBannerModel banner) async {
  final descCtrl = TextEditingController(text: banner.description);

  String? selectedCatId = banner.category.id;
  String? selectedServiceCatId = banner.serviceCategory.id;

  List<ServiceCategoryModel> localServiceCategories = [];

  Uint8List? newImageBytes;
  String? newImageName;

  bool isUpdating = false;

  // Load initial service categories
  localServiceCategories = await _api.getServiceCategories(selectedCatId!);

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// HEADER
                    Row(
                      children: const [
                        Icon(Icons.edit_note, color: Color(0xFFEB5725)),
                        SizedBox(width: 8),
                        Text(
                          "Update Banner",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 30),

                    /// CATEGORY
                    const Text("Category *", style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: selectedCatId,
                      items: _categories
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ))
                          .toList(),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onChanged: (val) async {
                        if (val == null) return;

                        setDialogState(() {
                          selectedCatId = val;
                          selectedServiceCatId = null;
                          localServiceCategories = [];
                        });

                        final services = await _api.getServiceCategories(val);

                        setDialogState(() {
                          localServiceCategories = services;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    /// SERVICE CATEGORY
                    const Text("Service Category *", style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: selectedServiceCatId,
                      items: localServiceCategories
                          .map((sc) => DropdownMenuItem(
                                value: sc.id,
                                child: Text(sc.name),
                              ))
                          .toList(),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedServiceCatId = val;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    /// DESCRIPTION
                    const Text("Description *", style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),

                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// IMAGE PICKER
                    const Text("Banner Image", style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),

                    GestureDetector(
                      onTap: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          withData: true,
                        );

                        if (result == null) return;

                        final file = result.files.first;

                        /// Size check
                        if (file.size > 1024 * 1024) {
                          CustomCenterDialog.show(
                            context,
                            title: "File Too Large",
                            message: "Please select an image under 1MB",
                            type: DialogType.error,
                          );
                          return;
                        }

                        setDialogState(() {
                          newImageBytes = file.bytes;
                          newImageName = file.name;
                        });
                      },
                      child: CustomPaint(
                        painter: DashedRectPainter(color: Colors.grey),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [

                                /// IMAGE PREVIEW
                                if (newImageBytes != null)
                                  Image.memory(
                                    newImageBytes!,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )
                                else
                                  Image.network(
                                    banner.bannerUrl,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image, size: 40, color: Colors.grey),
                                  ),

                                const SizedBox(height: 8),

                                Text(
                                  newImageName ?? "Click to change image",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// ACTION BUTTONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [

                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Cancel"),
                        ),

                        const SizedBox(width: 12),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEB5725),
                          ),
                          onPressed: isUpdating
                              ? null
                              : () async {

                                  /// Validation
                                  if (selectedCatId == null ||
                                      selectedServiceCatId == null ||
                                      descCtrl.text.trim().isEmpty) {
                                    CustomCenterDialog.show(
                                      context,
                                      title: "Required",
                                      message: "Please fill all fields",
                                      type: DialogType.required,
                                    );
                                    return;
                                  }

// Inside ElevatedButton onPressed:
setDialogState(() => isUpdating = true);

bool success = await _api.updateSliderBanner(
  bannerId: banner.id,
  categoryId: selectedCatId!,
  serviceCategoryId: selectedServiceCatId!,
  description: descCtrl.text.trim(),
  bannerBytes: newImageBytes,
  bannerName: newImageName,
);

setDialogState(() => isUpdating = false);
                                  if (success) {
                                    Navigator.pop(ctx);

                                    CustomCenterDialog.show(
                                      context,
                                      title: "Success",
                                      message: "Banner updated successfully",
                                      type: DialogType.success,
                                    );

                                    _fetchBanners();
                                  } else {
                                    CustomCenterDialog.show(
                                      context,
                                      title: "Error",
                                      message: "Failed to update banner",
                                      type: DialogType.error,
                                    );
                                  }
                                },
                          child: isUpdating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Update",
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ],
                    ),
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
void _showStatusSnackbar(String message, bool isError) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Text(message, style: const TextStyle(color: Colors.white)),
        ],
      ),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ),
  );
}

Future<void> _handleToggleBanner(String id, bool currentState) async {
  _showStatusSnackbar("Updating banner status...", false);

  // Send current state to flip it on the backend
  bool success = await _api.deleteSliderBanner(bannerId: id, isActive: currentState);
  
  if (success) {
    _showStatusSnackbar("Banner status updated successfully", false);
    _fetchBanners(); // Refresh the list
  } else {
    _showStatusSnackbar("Failed to change banner status", true);
  }
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
            _buildHeader(),
            const SizedBox(height: 24),
            BannerSetupCard(onSuccess: _fetchBanners),
            const SizedBox(height: 24),
            BannerListCard(
              banners: _banners,
              isLoading: _isLoading,
              onRefresh: _fetchBanners,
              onUpdate: (banner) => _showUpdateDialog(context, banner), // Updated this line
              onToggle: _handleToggleBanner, // 👈 Pass the handler here
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Sliding Banners',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        IconButton(onPressed: _fetchBanners, icon: const Icon(Icons.refresh, color: Colors.grey)),
      ],
    );
  }
}

// --- SETUP CARD WIDGET ---
class BannerSetupCard extends StatefulWidget {
  final VoidCallback onSuccess;
  const BannerSetupCard({super.key, required this.onSuccess});

  @override
  State<BannerSetupCard> createState() => _BannerSetupCardState();
}

class _BannerSetupCardState extends State<BannerSetupCard> {
  final ApiService _api = ApiService();
  final TextEditingController _descCtrl = TextEditingController();
  
  List<CategoryModel> _categories = [];
  List<ServiceCategoryModel> _serviceCategories = []; // 👈 New list
  
  String? _selectedCatId;
  String? _selectedServiceCatId; // 👈 New selection ID
  PlatformFile? _pickedFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _api.getCategories();
    setState(() => _categories = cats);
  }

  // 👈 New method to fetch sub-categories
  Future<void> _loadServiceCategories(String categoryId) async {
    setState(() {
      _selectedServiceCatId = null; // Reset sub-selection
      _serviceCategories = [];
    });
    try {
      final services = await _api.getServiceCategories(categoryId);
      setState(() => _serviceCategories = services);
    } catch (e) {
      debugPrint("Error loading services: $e");
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null) {
      final file = result.files.first;
      double sizeInMb = file.size / (1024 * 1024);
      if (sizeInMb > 1.0) {
        CustomCenterDialog.show(context, title: "File Too Large", message: "Image must be under 1 MB.", type: DialogType.error);
        return;
      }
      setState(() => _pickedFile = file);
    }
  }

  Future<void> _submit() async {
if (_pickedFile == null || _selectedCatId == null || _selectedServiceCatId == null || _descCtrl.text.isEmpty) {
        CustomCenterDialog.show(context, title: "Required", message: "Image, Category,Service Category,and Description are required", type: DialogType.required);
      return;
    }

    setState(() => _isSubmitting = true);
    bool success = await _api.addSliderBanner(
      categoryId: _selectedCatId!,
      serviceCategoryId: _selectedServiceCatId!, // 👈 Pass the selected ID
      description: _descCtrl.text,
      bannerBytes: _pickedFile!.bytes!,
      bannerName: _pickedFile!.name,
    );
    setState(() => _isSubmitting = false);

    if (success) {
      CustomCenterDialog.show(context, title: "Success", message: "Banner added successfully!", type: DialogType.success);
      _clearForm();
      widget.onSuccess();
    } else {
      CustomCenterDialog.show(context, title: "Error", message: "Failed to upload banner", type: DialogType.error);
    }
  }

  void _clearForm() {
  setState(() {
    _pickedFile = null;
    _selectedCatId = null;
    _selectedServiceCatId = null; // 👈 Clear sub-id
    _serviceCategories = [];     // 👈 Clear sub-list
    _descCtrl.clear();
  });
}

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Banner Setup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            bool isWide = constraints.maxWidth > 800;
            return isWide 
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _buildForm()),
                  const SizedBox(width: 40),
                  Expanded(child: _buildUploadArea()),
                ])
              : Column(children: [_buildForm(), const SizedBox(height: 20), _buildUploadArea()]);
          }),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlinedButton(onPressed: _clearForm, child: const Text("Reset")),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEB5725)),
              child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit", style: TextStyle(color: Colors.white)),
            )
          ])
        ],
      ),
    );
  }

  Widget _buildForm() {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text("Select Category *", style: TextStyle(fontWeight: FontWeight.w500)),
    const SizedBox(height: 8),
    DropdownButtonFormField<String>(
      value: _selectedCatId,
      items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedCatId = val);
          _loadServiceCategories(val); // 👈 Load the next dropdown
        }
      },
      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
    ),
    
    const SizedBox(height: 15),

    // 👈 NEW: Service Category Dropdown
    const Text("Select Service Category *", style: TextStyle(fontWeight: FontWeight.w500)),
    const SizedBox(height: 8),
    DropdownButtonFormField<String>(
      value: _selectedServiceCatId,
      disabledHint: const Text("Select Category first"),
      items: _serviceCategories.map((sc) => DropdownMenuItem(value: sc.id, child: Text(sc.name))).toList(),
      onChanged: _selectedCatId == null ? null : (val) => setState(() => _selectedServiceCatId = val),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        filled: _selectedCatId == null,
        fillColor: _selectedCatId == null ? Colors.grey[100] : Colors.transparent,
      ),
    ),

    const SizedBox(height: 15),
    const Text("Description *", style: TextStyle(fontWeight: FontWeight.w500)),
    const SizedBox(height: 8),
    TextField(
      controller: _descCtrl, 
      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Enter banner info", contentPadding: EdgeInsets.symmetric(horizontal: 12))
    ),
  ]);
}
  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _pickFile,
      child: CustomPaint(
        painter: DashedRectPainter(color: Colors.grey),
        child: Container(
          height: 150, width: double.infinity,
          child: _pickedFile != null 
            ? Image.memory(_pickedFile!.bytes!, fit: BoxFit.cover)
            : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_upload), Text("Upload Banner (Max 1MB)")]),
        ),
      ),
    );
  }
}

// --- LIST CARD WIDGET ---
class BannerListCard extends StatelessWidget {
  final List<SliderBannerModel> banners;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(SliderBannerModel) onUpdate;
  final Function(String, bool) onToggle; // 👈 Add this line

  const BannerListCard({
    super.key, 
    required this.banners, 
    required this.isLoading, 
    required this.onRefresh,
    required this.onUpdate,
    required this.onToggle, // 👈 Add this line
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        const ListTile(title: Text("Banner List", style: TextStyle(fontWeight: FontWeight.bold))),
        const Divider(),
        if (isLoading) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
        if (!isLoading && banners.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text("No banners found.")),
        ...banners.map((banner) => _buildRow(context, banner)),
      ]),
    );
  }

  Widget _buildRow(BuildContext context, SliderBannerModel banner) {
    return Column(
      children: [
        ListTile(
          leading: GestureDetector(
            onTap: () => ImagePreviewDialog.show(context, url: banner.bannerUrl, title: "Banner Preview"),
            child: Container(
              width: 80, height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  banner.bannerUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.red),
                ),
              ),
            ),
          ),
          title: Text(banner.description, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text("${banner.category.name} > ${banner.serviceCategory.name}"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                onPressed: () => onUpdate(banner),
              ),
              const SizedBox(width: 8),
              // THE TOGGLE SWITCH
              Switch(
                value: banner.isActive,
                activeColor: const Color(0xFFEB5725),
                onChanged: (bool newValue) {
                  onToggle(banner.id, banner.isActive); // Trigger the API call
                },
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double gap;

  DashedRectPainter({this.strokeWidth = 1.0, this.color = Colors.grey, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    Paint dashedPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double x = 0;
    double y = 0;
    double w = size.width;
    double h = size.height;

    Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(12)));

    Path dashPath = Path();
    for (ui.PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += (gap * 2);
      }
    }
    canvas.drawPath(dashPath, dashedPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}