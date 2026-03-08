import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

// --- CONSTANTS ---
const Color primaryOrange = Color(0xFFF97316);
const Color textDark = Color(0xFF1E293B);
const Color textGrey = Color(0xFF64748B);
const Color bgLight = Color(0xFFF1F5F9);
const Color borderGrey = Color(0xFFE2E8F0);

// --- REUSABLE WIDGETS ---

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader(this.title, {super.key});
  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13, letterSpacing: 0.5));
  }
}

class CustomLabel extends StatelessWidget {
  final String text;
  const CustomLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textDark));
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? prefix;
  final bool enabled;

  const CustomTextField({
    super.key, 
    required this.label, 
    required this.controller, 
    this.hint, 
    this.prefix, 
    this.enabled = true
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            filled: !enabled,
            fillColor: enabled ? Colors.white : bgLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: borderGrey)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: primaryOrange)),
          ),
        ),
      ],
    );
  }
}

class CustomDropdown extends StatelessWidget {
  final String label;
  final List<String> items;
  final RxString selectedValue;

  const CustomDropdown({super.key, required this.label, required this.items, required this.selectedValue});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomLabel(label),
        const SizedBox(height: 6),
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: borderGrey),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text("Select...", style: TextStyle(fontSize: 13, color: textGrey)),
              value: selectedValue.value.isEmpty ? null : selectedValue.value,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => selectedValue.value = val!,
            ),
          ),
        )),
      ],
    );
  }
}

class FileUploadBox extends StatelessWidget {
  // Accept Rx<PlatformFile?> instead of File
  final Rx<PlatformFile?> file; 
  final String type;
  final Function(String) onPick;
  final bool compact;

  const FileUploadBox({
    super.key,
    required this.file,
    required this.type,
    required this.onPick,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onPick(type),
      // Obx listens to changes and rebuilds immediately
      child: Obx(() {
        final f = file.value;
        bool hasFile = f != null;

        return Container(
          height: compact ? 80 : 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: hasFile
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImagePreview(f!),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, 
                         size: compact ? 24 : 40, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      compact ? "Select File" : "Click to Upload",
                      style: TextStyle(
                        color: Colors.grey[600], 
                        fontSize: compact ? 12 : 14
                      ),
                    ),
                  ],
                ),
        );
      }),
    );
  }

  Widget _buildImagePreview(PlatformFile file) {
    if (file.extension?.toLowerCase() == 'pdf') {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
            Text("PDF Selected", style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    // 🔥 WEB: Show image from Memory (Bytes)
    if (kIsWeb) {
      if (file.bytes != null) {
        return Image.memory(file.bytes!, fit: BoxFit.cover, width: double.infinity);
      }
      return const Center(child: Text("Loading..."));
    } 
    
    // 📱 MOBILE: Show image from Path
    else {
      if (file.path != null) {
        return Image.file(File(file.path!), fit: BoxFit.cover, width: double.infinity);
      }
      return const Center(child: Text("Error: No Path"));
    }
  }
}
