import 'dart:io'; 
import 'dart:ui' as ui; 

import 'package:file_picker/file_picker.dart'; 
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';

class UpdatePromotionalBannerScreen extends StatefulWidget {
  const UpdatePromotionalBannerScreen({super.key});

  @override
  State<UpdatePromotionalBannerScreen> createState() => _UpdatePromotionalBannerScreenState();
}

class _UpdatePromotionalBannerScreenState extends State<UpdatePromotionalBannerScreen> {
  // --- Controllers & State ---
  final TextEditingController _titleController = TextEditingController();
  String? _selectedCategory;
  
  // Image State
  PlatformFile? _newPickedFile; // For new upload
  bool _hasExistingImage = true; // Simulating that we are editing an existing record

  @override
  void initState() {
    super.initState();
    // 1. Simulate fetching existing data
    _titleController.text = "Laptop Repair service";
    _selectedCategory = "cat2"; // Matching 'Repair' in dropdown
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // --- Image Picker Logic ---
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _newPickedFile = result.files.first;
      });
    }
  }

  void _clearNewFile() {
    setState(() {
      _newPickedFile = null;
      // Note: We don't set _hasExistingImage to false here, 
      // because clearing a new upload should revert to showing the old image.
    });
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
            // --- Screen Header ---
            const Text(
              'Update Banner',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),

            // --- Main Update Card ---
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
                  
                  // Responsive Layout (Row on Desktop, Col on Mobile)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isWide = constraints.maxWidth > 800;
                      return isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildLeftForm()),
                                const SizedBox(width: 40),
                                Expanded(child: _buildRightUpload()),
                              ],
                            )
                          : Column(
                              children: [
                                _buildLeftForm(),
                                const SizedBox(height: 30),
                                _buildRightUpload(),
                              ],
                            );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // --- Action Buttons ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Cancel Button
                      OutlinedButton(
                        onPressed: () {
                          // Handle Navigation Back
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700)),
                      ),
                      const SizedBox(width: 16),
                      
                      // Update Button
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Implement Update Logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Banner Updated Successfully")),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEB5725),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        child: const Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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

  // --- Form Section ---
  Widget _buildLeftForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Input
        _buildLabel('Title', isRequired: true),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Enter banner title',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: const Icon(Icons.title, size: 20, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEB5725)),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
        const SizedBox(height: 20),

        // Select Category
        _buildLabel('Select Category', isRequired: true),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              hint: const Text('Select Category', style: TextStyle(fontSize: 14, color: Colors.grey)),
              items: const [
                 DropdownMenuItem(value: 'cat1', child: Text('Cleaning')),
                 DropdownMenuItem(value: 'cat2', child: Text('Repair')),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // --- Image Upload Section ---
  Widget _buildRightUpload() {
    return Column(
      children: [
        const Align(
          alignment: Alignment.center,
          child: Text('Update cover image', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        ),
        const SizedBox(height: 12),
        
        // CLICKABLE UPLOAD ZONE
        GestureDetector(
          onTap: _pickFile,
          child: CustomPaint(
            painter: DashedRectPainter(color: Colors.grey.shade400, strokeWidth: 1.5, gap: 5.0),
            child: Container(
              height: 180,
              width: double.infinity,
              alignment: Alignment.center,
              child: _determineImageContent(),
            ),
          ),
        ),
      ],
    );
  }

  // --- Logic to decide what image to show ---
  Widget _determineImageContent() {
    // 1. If user picked a NEW file, show that
    if (_newPickedFile != null) {
      return Stack(
        children: [
          SizedBox.expand(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _getNewImageWidget(),
            ),
          ),
          Positioned(
            top: 8, right: 8,
            child: InkWell(
              onTap: _clearNewFile,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.undo, color: Color(0xFFEB5725), size: 20),
              ),
            ),
          )
        ],
      );
    }
    
    // 2. If no new file, but we have an EXISTING image, show that
    else if (_hasExistingImage) {
      return Stack(
        children: [
          SizedBox.expand(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                // In real app: Image.network(existingUrl)
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.image, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("Current Saved Image", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ), 
              ),
            ),
          ),
          Positioned(
            bottom: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
              child: const Text("Tap to change", style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          )
        ],
      );
    }

    // 3. Fallback (Shouldn't happen in update, but good for safety)
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        const Text('Upload New File', style: TextStyle(color: Color(0xFFEB5725), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _getNewImageWidget() {
    if (kIsWeb) {
      if (_newPickedFile!.bytes != null) {
        return Image.memory(_newPickedFile!.bytes!, fit: BoxFit.cover);
      }
      return const Center(child: Text("Error loading web image"));
    } else {
      if (_newPickedFile!.path != null) {
        return Image.file(File(_newPickedFile!.path!), fit: BoxFit.cover);
      }
      return const Center(child: Text("Error loading image path"));
    }
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        children: [
          if (isRequired)
            const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}

// =============================================================================
// HELPER: DASHED BORDER PAINTER (Included so the file is standalone)
// =============================================================================

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
    path.moveTo(x + 10, y);
    path.lineTo(w - 10, y);
    path.quadraticBezierTo(w, y, w, y + 10);
    path.lineTo(w, h - 10);
    path.quadraticBezierTo(w, h, w - 10, h);
    path.lineTo(x + 10, h);
    path.quadraticBezierTo(x, h, x, h - 10);
    path.lineTo(x, y + 10);
    path.quadraticBezierTo(x, y, x + 10, y);

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