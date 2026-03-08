import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/add_provider_controller.dart';

// Import your components
// Ensure these files exist and are named correctly in your folder
import './addprovider/tab_personal.dart';
import './addprovider/common_widgets.dart';
import './addprovider/tab_address.dart';
import './addprovider/tab_services.dart';
import './addprovider/tab_financials.dart';
import './addprovider/tab_documents.dart';
import './addprovider/tab_location.dart';

class AddProviderScreen extends StatelessWidget {
  final AddProviderController controller = Get.put(AddProviderController());
  
  final VoidCallback? onBack; 

  AddProviderScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight, // Defined in common_widgets.dart
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: onBack ?? () => Get.back(),
        ),
        title: Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(controller.isViewOnly.value ? "Provider Details" : "Add/Edit Provider", style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(controller.isViewOnly.value ? "Viewing provider information" : "Onboard new or update existing", style: const TextStyle(color: textGrey, fontSize: 12)),
          ],
        )),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildCustomStepper(context), 
        ),
      ),

      // --- BODY ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(8), 
            border: Border.all(color: borderGrey)
          ),
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            switch (controller.currentStep.value) {
              // FIX: Removed 'const' keyword here
              case 0: return TabPersonalDetails();
              case 1: return TabAddress();
              case 2: return TabLocationMap();
              case 3: return TabServices(); 
              case 4: return TabFinancials();
              case 5: return TabDocuments();
              default: return TabPersonalDetails();
            }
          }),
        ),
      ),
      
      // --- BOTTOM NAVIGATION ---
      bottomNavigationBar: Obx(() {
        if (controller.isViewOnly.value) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: borderGrey))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               controller.currentStep.value > 0 
                 ? OutlinedButton(onPressed: controller.prevStep, child: const Text("Back"))
                 : const SizedBox.shrink(),
               
               ElevatedButton(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: primaryOrange, 
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
                 ),
                 onPressed: controller.isLoading.value ? null : controller.nextStep,
                 child: controller.isLoading.value 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(controller.currentStep.value == 4 ? "Finish" : "Next"),
               ),
            ],
          ),
        );
      }),
    );
  }

  // --- STEPPER ---
  Widget _buildCustomStepper(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 800;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryOrange, width: 2)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          _buildStepTab(0, "Personal", Icons.person_outline, isWideScreen),
          _buildStepTab(1, "Address", Icons.location_on_outlined, isWideScreen),
          _buildStepTab(2, "Location", Icons.map_outlined, isWideScreen),
          _buildStepTab(3, "Services", Icons.work_outline, isWideScreen),
          _buildStepTab(4, "Financials", Icons.account_balance_wallet_outlined, isWideScreen),
          _buildStepTab(5, "Docs", Icons.description_outlined, isWideScreen),
        ],
      ),
    );
  }

  Widget _buildStepTab(int index, String label, IconData icon, bool isWideScreen) {
    return Expanded(
      child: Obx(() {
        bool isActive = controller.currentStep.value == index;
        return InkWell(
          onTap: () => controller.setStep(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: isActive 
                ? const Border(bottom: BorderSide(color: primaryOrange, width: 3)) 
                : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: isActive ? primaryOrange : textGrey),
                if(isActive || isWideScreen) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(label, 
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive ? primaryOrange : textGrey,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13
                      )
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      }),
    );
  }
}