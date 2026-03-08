import 'package:flutter/material.dart';

enum DialogType { success, error, warning, info, required }

class CustomCenterDialog extends StatelessWidget {
  final String title;
  final String message;
  final DialogType type;
  final VoidCallback? onConfirm;
  final String confirmText;
  final String cancelText;

  const CustomCenterDialog({
    Key? key,
    required this.title,
    required this.message,
    this.type = DialogType.info,
    this.onConfirm,
    this.confirmText = "Okay",
    this.cancelText = "Cancel",
  }) : super(key: key);

  // --- FIX IS HERE ---
  // Added confirmText and cancelText arguments to this method
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    DialogType type = DialogType.info,
    VoidCallback? onConfirm,
    String? confirmText, // Optional override
    String? cancelText,  // Optional override
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomCenterDialog(
        title: title,
        message: message,
        type: type,
        onConfirm: onConfirm,
        // Logic: Use passed text -> If null, check onConfirm -> Default fallback
        confirmText: confirmText ?? (onConfirm != null ? "Yes" : "Okay"),
        cancelText: cancelText ?? "Cancel",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      elevation: 5,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIcon(),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      if (onConfirm != null) ...[
                        Expanded(
                          child: SizedBox(
                            height: 45,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide.none,
                                backgroundColor: Colors.grey.shade200,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                cancelText,
                                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton(
                            onPressed: () {
                              if (onConfirm != null) onConfirm!();
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getMainColor(),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              confirmText,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMainColor() {
    switch (type) {
      case DialogType.success: return Colors.green;
      case DialogType.error: return Colors.red;
      case DialogType.required: return Colors.orange;
      case DialogType.warning: return const Color(0xFF536DFE);
      case DialogType.info: return const Color(0xFF536DFE);
    }
  }

  Widget _buildIcon() {
    IconData iconData;
    Color color;

    switch (type) {
      case DialogType.success:
        iconData = Icons.check;
        color = Colors.green;
        break;
      case DialogType.error:
        iconData = Icons.close;
        color = Colors.red;
        break;
      case DialogType.required:
        iconData = Icons.warning_amber_rounded;
        color = Colors.orange;
        break;
      case DialogType.warning:
        iconData = Icons.priority_high;
        color = Colors.orange.shade300;
        break;
      default:
        iconData = Icons.info_outline;
        color = const Color(0xFF536DFE);
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 3),
      ),
      child: Center(
        child: Icon(iconData, size: 40, color: color),
      ),
    );
  }
}