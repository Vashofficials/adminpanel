import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ImagePreviewDialog extends StatelessWidget {
  final String? url;
  final Uint8List? bytes;
  final String title;

  const ImagePreviewDialog({
    super.key,
    this.url,
    this.bytes,
    required this.title,
  });

  /// Static method to show the dialog easily from any screen
  static void show(BuildContext context, {String? url, Uint8List? bytes, required String title}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8), // Dim the background
      builder: (context) => ImagePreviewDialog(url: url, bytes: bytes, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.grey[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
                // Image Body with Zoom Capability
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: _buildContent(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // 1. Show Local Bytes (for newly picked images)
    if (bytes != null) {
      return Image.memory(bytes!, fit: BoxFit.contain);
    }

    // 2. Show Network URL (for already uploaded images)
    if (url != null && url!.isNotEmpty) {
      if (url!.toLowerCase().endsWith('.svg')) {
        return SvgPicture.network(
          url!,
          fit: BoxFit.contain,
          placeholderBuilder: (ctx) => const CircularProgressIndicator(),
        );
      }
      return Image.network(
        url!,
        fit: BoxFit.contain,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
      );
    }

    // 3. Fallback
    return const Icon(Icons.image_not_supported, size: 100, color: Colors.grey);
  }
}