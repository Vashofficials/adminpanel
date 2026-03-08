import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/add_provider_controller.dart';

class TabDocuments extends StatefulWidget {
  const TabDocuments({super.key});

  @override
  State<TabDocuments> createState() => _TabDocumentsState();
}

class _TabDocumentsState extends State<TabDocuments> {
  final AddProviderController controller = Get.find<AddProviderController>();

  @override
  void initState() {
    super.initState();
    // Safety check: fetch again when tab opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.currentSpId != null) {
        controller.documentController.fetchUploadedDocuments(controller.currentSpId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final docCtrl = controller.documentController;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("REQUIRED DOCUMENTS", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Please upload the following documents for verification.",
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 16),

        Obx(() {
          // -----------------------------------------------------------
          // FIX: FORCE REACTIVITY
          // We read these values here so Obx KNOWS it must rebuild
          // whenever these change, regardless of the ListView builder.
          // -----------------------------------------------------------
          final _ = docCtrl.uploadingDocIds.length;
          final __ = docCtrl.failedDocIds.length;
          final ___ = docCtrl.serverUploadedDocs.length;

          if (docCtrl.isLoading.value) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ));
          }

          if (docCtrl.docTypes.isEmpty) {
            return Center(
              child: Column(
                children: [
                  const Text("No document types found."),
                  TextButton(
                    onPressed: () => docCtrl.fetchDocumentTypes(), 
                    child: const Text("Retry Loading Types")
                  )
                ],
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docCtrl.docTypes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final docType = docCtrl.docTypes[index];
              
              final isUploading = docCtrl.isUploading(docType.id);
              final isUploaded = docCtrl.isUploaded(docType.id);
              final isFailed = docCtrl.isFailed(docType.id);
              final uploadedFileName = docCtrl.uploadedFileName(docType.id);
              final uploadedFileUrl = docCtrl.uploadedFileUrl(docType.id);

              Color borderColor = Colors.grey.shade300;
              if (isUploaded) borderColor = Colors.green;
              if (isFailed) borderColor = Colors.red;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      height: 40, width: 40,
                      decoration: BoxDecoration(
                        color: isUploaded ? Colors.green.shade50 : isFailed ? Colors.red.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isUploading
                          ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(
                              isUploaded ? Icons.check_circle : isFailed ? Icons.error_outline : Icons.description,
                              color: isUploaded ? Colors.green : isFailed ? Colors.red : Colors.blue,
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(docType.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          if (isUploaded)
                            Text("Uploaded", style: const TextStyle(fontSize: 11, color: Colors.green))
                          else if (isUploading)
                            const Text("Uploading...", style: TextStyle(fontSize: 11, color: Colors.orange))
                          else if (isFailed)
                            const Text("Upload failed", style: TextStyle(fontSize: 11, color: Colors.red))
                          else
                            const Text("Pending", style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    // Action
                    if (isUploaded)
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () => _openPreview(uploadedFileUrl),
                      )
                    else if (!isUploading && !controller.isViewOnly.value)
                      ElevatedButton(
                        onPressed: () {
                          if (controller.currentSpId == null) {
                            Get.snackbar("Error", "Complete Personal Details first.");
                            return;
                          }
                          docCtrl.pickAndUpload(docTypeId: docType.id, spId: controller.currentSpId!);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFailed ? Colors.red.shade50 : Colors.blue.shade50,
                          foregroundColor: isFailed ? Colors.red : Colors.blue,
                          elevation: 0,
                          minimumSize: const Size(70, 32),
                        ),
                        child: Text(isFailed ? "Retry" : "Upload"),
                      ),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }

  void _openPreview(String url) {
    if (url.isEmpty) return;

    // 1. Encode spaces (%20) and parentheses (%28, %29)
    String finalUrl = url.trim();
    finalUrl = Uri.encodeFull(finalUrl);
    finalUrl = finalUrl.replaceAll('(', '%28').replaceAll(')', '%29');

    debugPrint("🔍 Opening Preview: $finalUrl");

    final bool isPdf = finalUrl.toLowerCase().contains('.pdf');

    // 2. Use showDialog to prevent "Unexpected null value" context errors
    showDialog(
      context: context, 
      builder: (BuildContext ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            height: 600,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 12.0),
                        child: Text("Document Preview",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Content
                Expanded(
                  child: isPdf
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text("This is a PDF document.",
                                style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SelectableText(
                                "URL: $finalUrl",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 10),
                              ),
                            ),
                          ],
                        )
                      : InteractiveViewer(
                          panEnabled: true,
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Image.network(
                            finalUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.broken_image,
                                        size: 50, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text("Could not load image",
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}