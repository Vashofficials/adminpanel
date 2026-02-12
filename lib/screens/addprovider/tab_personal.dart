import 'dart:io'; // For FileImage (Mobile)
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/add_provider_controller.dart';
import 'common_widgets.dart';
import '../../widgets/searchable_selection_sheet.dart';

class TabPersonalDetails extends GetView<AddProviderController> {
  const TabPersonalDetails({super.key});

  @override
  Widget build(BuildContext context) {
    const Color borderGrey = Color(0xFFE0E0E0);
    const Color primaryOrange = Color(0xFFF97316);
    const Color textGrey = Color(0xFF757575);

    return Column(
      children: [
        // --- 1. SELECTION CARD ---
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.blue.shade50.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Start Application", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ElevatedButton.icon(
                    onPressed: () => _showOnboardDialog(context),
                    icon: const Icon(Icons.add_call, size: 18),
                    label: const Text("Start New Application"),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, foregroundColor: Colors.white, elevation: 0),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text("OR Resume Existing Application:", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // --- 2. PROVIDER SELECTOR ---
              Obx(() {
                 if (controller.providerListController.isLoading.value) return const LinearProgressIndicator();

                 final selectedProviderId = controller.selectedProviderId.value;
                 final selectedProvider = controller.providerListController.allProviders.firstWhereOrNull((p) => p.id == selectedProviderId);
                 
                 final displayText = selectedProvider != null 
                     ? "${selectedProvider.firstName} ${selectedProvider.lastName} (${selectedProvider.mobileNo})"
                     : "Select provider from list...";

                 return InkWell(
                   onTap: () {
                     SearchableSelectionSheet.show(
                       context,
                       title: "Select Provider",
                       primaryColor: primaryOrange,
                       items: controller.providerListController.allProviders.map((p) {
                         return SelectionItem(
                           id: p.id,
                           title: "${p.firstName} ${p.lastName}",
                           subtitle: p.mobileNo,
                           icon: Icons.person,
                         );
                       }).toList(),
                       onItemSelected: (id) {
                         controller.onSelectExistingProvider(id);
                       },
                     );
                   },
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(color: borderGrey),
                     ),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(displayText, style: TextStyle(color: selectedProviderId == null ? Colors.grey.shade600 : Colors.black87)),
                         const Icon(Icons.arrow_drop_down, color: Colors.grey),
                       ],
                     ),
                   ),
                 );
              }),
            ],
          ),
        ),

        // --- 2. FORM FIELDS ---
        Obx(() => controller.selectedProviderId.value == null 
          ? Container(
              height: 200, 
              alignment: Alignment.center, 
              child: const Text("Please select a provider above or start a new application.", style: TextStyle(color: textGrey))
            )
          : Column(
            children: [
               Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 3. PROFILE PICTURE UPLOAD ---
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => controller.pickProfileImage(),
                      child: Stack(
                        children: [
                          Container(
                            height: 140, 
                            decoration: BoxDecoration(
                              border: Border.all(color: borderGrey),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade50,
                              // Show Image logic
                              image: _buildProfileImageProvider(controller),
                            ),
                            alignment: Alignment.center,
                            child: _buildProfileChild(controller, textGrey),
                          ),
                          // Edit Icon Badge
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]
                              ),
                              child: const Icon(Icons.camera_alt, size: 16, color: primaryOrange),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // --- TEXT FIELDS ---
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: CustomTextField(label: "First Name *", controller: controller.firstNameCtrl)),
                            const SizedBox(width: 16),
                            Expanded(child: CustomTextField(label: "Last Name *", controller: controller.lastNameCtrl)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(label: "Middle Name", controller: controller.middleNameCtrl),
                        const SizedBox(height: 16),
                        CustomTextField(label: "Mobile Number", controller: controller.mobileCtrl, prefix: "+91 ", enabled: false),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: CustomTextField(label: "Email Address", controller: controller.emailCtrl)),
                  const SizedBox(width: 16),
                  Expanded(child: CustomTextField(label: "Aadhar Number *", controller: controller.aadharCtrl)),
                ],
              ),
              const SizedBox(height: 16),
              CustomDropdown(label: "Gender *", items: const ["Male", "Female", "Other"], selectedValue: controller.selectedGender),
            ],
          )
        ),
      ],
    );
  }

  // --- Helper: Determine Image Provider ---
  DecorationImage? _buildProfileImageProvider(AddProviderController controller) {
    if (controller.profileImageFile.value != null) {
      // 1. Show Newly Picked Local File
      if (kIsWeb) {
        return DecorationImage(
          image: MemoryImage(controller.profileImageFile.value!.bytes!),
          fit: BoxFit.cover,
        );
      } else {
        return DecorationImage(
          image: FileImage(File(controller.profileImageFile.value!.path!)),
          fit: BoxFit.cover,
        );
      }
    } else if (controller.profileImageUrl.value != null && controller.profileImageUrl.value!.isNotEmpty) {
      // 2. Show Existing Network URL
      return DecorationImage(
        image: NetworkImage(controller.profileImageUrl.value!), // Ensure valid URL
        fit: BoxFit.cover,
      );
    }
    // 3. No Image
    return null;
  }

  // --- Helper: Show Icon/Text if no image ---
  Widget? _buildProfileChild(AddProviderController controller, Color textGrey) {
    if (controller.profileImageFile.value != null || 
       (controller.profileImageUrl.value != null && controller.profileImageUrl.value!.isNotEmpty)) {
      return null; // Don't show child if image exists
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person, size: 40, color: textGrey.withOpacity(0.5)),
        const SizedBox(height: 8),
        Text("Upload\nPhoto", textAlign: TextAlign.center, style: TextStyle(color: textGrey, fontSize: 11)),
      ],
    );
  }

  void _showOnboardDialog(BuildContext context) {
    final TextEditingController mobileInput = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return AlertDialog(
          title: const Text("Onboard New Provider"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter the mobile number to register immediately."),
              const SizedBox(height: 16),
              TextField(
                controller: mobileInput,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(labelText: "Mobile Number", prefixText: "+91 ", border: OutlineInputBorder(), counterText: ""),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); 
                controller.quickOnboardProvider(mobileInput.text);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), foregroundColor: Colors.white),
              child: const Text("Onboard Now"),
            )
          ],
        );
      }
    );
  }
}