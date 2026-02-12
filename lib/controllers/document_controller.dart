import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../services/api_service.dart';
import '../models/document_type_model.dart';
import '../widgets/custom_center_dialog.dart';

class DocumentController extends GetxController {
  final ApiService _apiService = ApiService();

  // ----------------------------
  // Loading & master data
  // ----------------------------
  final isLoading = false.obs;
  final docTypes = <DocumentTypeModel>[].obs;

  // ----------------------------
  // Upload UI states
  // ----------------------------
  final uploadingDocIds = <String>{}.obs;
  final failedDocIds = <String>{}.obs;

  // ----------------------------
  // SERVER SOURCE OF TRUTH
  // docTypeId -> server document
  // ----------------------------
  final serverUploadedDocs = <String, Map<String, dynamic>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDocumentTypes();
  }

  // ----------------------------
  // Fetch document types
  // ----------------------------
  Future<void> fetchDocumentTypes() async {
    try {
      // NOTE: Ensure your ApiService returns List<DocumentTypeModel>
      // If your Service returns the wrapper object (DocumentTypeResponse), 
      // change this line to: (await _apiService.getDocumentTypes()).result;
      final types = await _apiService.getDocumentTypes();
      
      if (types.isNotEmpty) {
        // --- NEW UPDATE: Sort by Creation Time (Newest First) ---
        types.sort((a, b) {
          if (a.creationTime.isEmpty) return 1;
          if (b.creationTime.isEmpty) return -1;
          // Parse ISO8601 string to compare
          return DateTime.parse(b.creationTime).compareTo(DateTime.parse(a.creationTime));
        });
        // --------------------------------------------------------

        docTypes.value = types;
      }
    } catch (e) {
      debugPrint("❌ Failed to load document types: $e");
    }
  }

  // ----------------------------
  // Fetch already uploaded docs
  // ----------------------------
  Future<void> fetchUploadedDocuments(String spId) async {
    try {
      isLoading.value = true;

      // 1. CRITICAL: Ensure we have the master types before mapping!
      if (docTypes.isEmpty) {
        print("⏳ DocTypes empty, fetching master list first...");
        await fetchDocumentTypes();
      }

      final response = await _apiService.getServiceProviderDocuments(spId);
      
      // Clear old data
      serverUploadedDocs.clear();

      for (final doc in response) {
        final docTypeName = doc['docType']; // e.g., "Identity Document"

        if (docTypeName == null) continue;

        // 2. Match backend NAME with local docType
        final matchedType = docTypes.firstWhereOrNull(
          (e) => e.name.trim().toLowerCase() == docTypeName.toString().trim().toLowerCase(),
        );

        if (matchedType == null) {
          debugPrint("⚠️ No matching local docType found for API type: $docTypeName");
          continue;
        }

        // 3. Store match
        serverUploadedDocs[matchedType.id] = Map<String, dynamic>.from(doc);
      }

      print("✅ Mapped ${serverUploadedDocs.length} documents for UI.");
      serverUploadedDocs.refresh(); // Force UI update

    } catch (e) {
      debugPrint("❌ Fetch uploaded documents failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ----------------------------
  // Pick & upload document
  // ----------------------------
  Future<void> pickAndUpload({
    required String docTypeId,
    required String spId,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result == null) return;

      final file = result.files.first;

      if (kIsWeb && file.bytes == null) {
        _safeSnack("Error", "Browser could not read file data", error: true);
        return;
      }

      // 1. UPDATE UI: Clear previous error, show loading IMMEDIATELY
      failedDocIds.remove(docTypeId);
      uploadingDocIds.add(docTypeId);
      
      // Force UI to see the change
      failedDocIds.refresh(); 
      uploadingDocIds.refresh();

      // 2. Perform Request
      final success = await _apiService.uploadSpDocument(
        spId: spId,
        docTypeId: docTypeId,
        file: file,
      );

      // 3. Remove loading state
      uploadingDocIds.remove(docTypeId);
      uploadingDocIds.refresh(); 

      if (success) {
        if(Get.context != null) {
          CustomCenterDialog.show(
            Get.context!,
            title: "Success",
            message: "Document uploaded successfully",
            type: DialogType.success,
          );
        }
        
        // Only fetch list on success to prevent "flashing" the page on error
        await fetchUploadedDocuments(spId); 
      } else {
        // 4. Handle logical failure (API returned false)
        failedDocIds.add(docTypeId);
        failedDocIds.refresh(); 
        
        if(Get.context != null) {
          CustomCenterDialog.show(
            Get.context!,
            title: "Error",
            message: "Failed to upload. Please try again.",
            type: DialogType.error,
          );
        }
      }
    } catch (e) {
      // 5. Handle Exceptions
      uploadingDocIds.remove(docTypeId);
      failedDocIds.add(docTypeId);
      
      uploadingDocIds.refresh();
      failedDocIds.refresh(); 

      debugPrint("❌ Upload error: $e");

      // Specific error message for 404
      if (e.toString().contains("404")) {
        _safeSnack("API Error", "Server could not find this Provider (404).", error: true);
      } else {
        if(Get.context != null) {
          CustomCenterDialog.show(
            Get.context!,
            title: "Error",
            message: "Something went wrong.",
            type: DialogType.error,
          );
        }
      }
    }
  }

  Future<void> updateDocumentType(String id, String name) async {
    isLoading(true);
    bool success = await _apiService.updateDocumentType(id, name);
    if (success) {
      await fetchDocumentTypes(); // Refresh list (and re-sort)
      if(Get.context != null) {
        CustomCenterDialog.show(
          Get.context!,
          title: "Success",
          message: "Document type updated successfully",
          type: DialogType.success,
        );
      }
    } else {
      if(Get.context != null) {
        CustomCenterDialog.show(
          Get.context!,
          title: "Error",
          message: "Failed to update document type",
          type: DialogType.error,
        );
      }
    }
    isLoading(false);
  }

  Future<void> deleteDocumentType(String id, bool isActive) async {
    isLoading(true);
    bool success = await _apiService.deleteDocumentType(id, isActive);
    if (success) {
      await fetchDocumentTypes(); // Refresh list
      if(Get.context != null) {
        CustomCenterDialog.show(
          Get.context!,
          title: "Success",
          message: "Document type deleted successfully",
          type: DialogType.success,
        );
      }
    } else {
      if(Get.context != null) {
        CustomCenterDialog.show(
          Get.context!,
          title: "Error",
          message: "Failed to deleted document type",
          type: DialogType.error,
        );
      }
    }
    isLoading(false);
  }

  Future<bool> addDocumentType(String name) async {
    try {
      isLoading.value = true;
      final success = await _apiService.addDocumentType(name); 
      
      if (success) {
        await fetchDocumentTypes(); // Refresh list (will sort new item to top)
        if(Get.context != null) {
          CustomCenterDialog.show(
            Get.context!,
            title: "Success",
            message: "Document type added successfully",
            type: DialogType.success,
          );
        }
        return true;
      } else {
        if(Get.context != null) {
          CustomCenterDialog.show(
            Get.context!,
            title: "Error",
            message: "Failed to add document type",
            type: DialogType.error,
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint("❌ Add doc type error: $e");
      if(Get.context != null) {
        CustomCenterDialog.show(
          Get.context!,
          title: "Error",
          message: "Something went wrong",
          type: DialogType.error,
        );
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ----------------------------
  // UI helpers
  // ----------------------------
  bool isUploading(String docTypeId) => uploadingDocIds.contains(docTypeId);
  bool isFailed(String docTypeId) => failedDocIds.contains(docTypeId);
  bool isUploaded(String docTypeId) => serverUploadedDocs.containsKey(docTypeId);

  String uploadedFileName(String docTypeId) {
    final url = serverUploadedDocs[docTypeId]?['docUrl'];
    if (url == null) return 'File Uploaded';
    return url.toString().split('/').last;
  }

  String uploadedFileUrl(String docTypeId) =>
      serverUploadedDocs[docTypeId]?['docUrl'] ?? '';

  void _safeSnack(String title, String message, {bool error = false}) {
    if (Get.context == null) return;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: error ? Colors.red : Colors.green,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
    );
  }
}