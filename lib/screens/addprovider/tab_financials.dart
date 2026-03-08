import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/add_provider_controller.dart';
import '../../models/bank_model.dart'; 
import 'common_widgets.dart'; 
import '../../widgets/searchable_selection_sheet.dart';

class TabFinancials extends GetView<AddProviderController> {
  const TabFinancials({super.key});

  @override
  Widget build(BuildContext context) {
    final bankingCtrl = controller.bankingController;

    return Obx(() {
      final existingDetails = bankingCtrl.providerBankDetails.value;

      // 🔄 LOGIC: Show Summary Grid OR Edit Form
      if (existingDetails != null) {
        return _buildProfessionalSummary(existingDetails);
      }

      return _buildEditForm(bankingCtrl);
    });
  }

  // ---------------------------------------------------------------------------
  // 🟢 VIEW 1: PROFESSIONAL SUMMARY (Grid of Small Cards)
  // ---------------------------------------------------------------------------
  Widget _buildProfessionalSummary(ProviderBankDetails details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER & ADD NEW BUTTON ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader("Active Bank Details"),
            if (!controller.isViewOnly.value)
              OutlinedButton.icon(
                onPressed: () {
                  // 🛑 RESET LOGIC: Clear data to show form again
                  controller.bankingController.providerBankDetails.value = null; 
                  controller.resetForms(); 
                  controller.clearBankingForms();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add New Bank"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue.shade200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              )
          ],
        ),
        const SizedBox(height: 16),

        // --- MAIN BANK CARD ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.account_balance, color: Colors.white.withOpacity(0.9), size: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text("VERIFIED", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                details.bankName ?? "Unknown Bank",
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                details.accountNo,
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, letterSpacing: 1.2),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // --- INFO GRID (Small Cards) ---
        LayoutBuilder(builder: (context, constraints) {
          // Calculate width for 2 columns
          double itemWidth = (constraints.maxWidth - 12) / 2; 
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildInfoTile(itemWidth, "Account Holder", details.accountHolderName, Icons.person),
              _buildInfoTile(itemWidth, "IFSC Code", details.ifscCode, Icons.pin),
              if (details.upiId != null && details.upiId!.isNotEmpty)
                 _buildInfoTile(itemWidth, "UPI ID", details.upiId!, Icons.qr_code),
              if (details.panNo != null)
                 _buildInfoTile(itemWidth, "PAN Number", details.panNo!, Icons.badge),
            ],
          );
        }),

        const SizedBox(height: 24),
        const SectionHeader("Documents"),
        const SizedBox(height: 12),

        // --- DOCUMENTS ROW ---
        Row(
          children: [
            Expanded(
              child: _DocumentCard(
                label: "Passbook",
                imageUrl: details.passbookUrl,
                icon: Icons.menu_book,
              ),
            ),
            if (details.isPanAvailable) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _DocumentCard(
                  label: "PAN Card",
                  imageUrl: details.panUrl,
                  icon: Icons.credit_card,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 🟠 VIEW 2: EDIT FORM (Standard Input)
  // ---------------------------------------------------------------------------
  Widget _buildEditForm(dynamic bankingCtrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader("Enter New Banking Details"),
        const SizedBox(height: 12),

        // --- UPDATED DROPDOWN LOGIC ---
        Obx(() {
          if (bankingCtrl.isLoading.value) {
            return const SizedBox(
              height: 50, 
              child: Center(child: LinearProgressIndicator())
            );
          }

          final selectedId = controller.selectedBankId.value;
          
          // --- FIX: Standard Loop to find bank (Avoids 'firstWhereOrNull' error) ---
          BankModel? selectedBank;
          if (selectedId != null) {
            for (var bank in bankingCtrl.bankList) {
              if (bank.id == selectedId) {
                selectedBank = bank;
                break;
              }
            }
          }
          // -----------------------------------------------------------------------

          final displayText = selectedBank != null ? selectedBank.name : "Select Bank";
          final isPlaceholder = selectedBank == null;
          final Color primaryOrange = const Color(0xFFF97316); 

          return AbsorbPointer(
            absorbing: controller.isViewOnly.value,
            child: InkWell(
              onTap: () {
                // Open Searchable Sheet
                SearchableSelectionSheet.show(
                  Get.context!,
                  title: "Select Bank",
                  primaryColor: primaryOrange,
                  items: bankingCtrl.bankList.map<SelectionItem>((bank) {
                    return SelectionItem(
                      id: bank.id,         
                      title: bank.name,    
                      icon: Icons.account_balance, 
                    );
                  }).toList(),
                  onItemSelected: (id) {
                    controller.selectedBankId.value = id;
                  },
                );
              },
              // Trigger Widget
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade500), 
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance, color: Colors.grey.shade600, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isPlaceholder)
                            Text("Select Bank", style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                            
                          Text(
                            displayText,
                            style: TextStyle(
                              color: isPlaceholder ? Colors.grey.shade600 : Colors.black87,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: CustomTextField(label: "Account Holder", controller: controller.accHolderCtrl, enabled: !controller.isViewOnly.value)),
            const SizedBox(width: 16),
            Expanded(child: CustomTextField(label: "Account Number", controller: controller.accNumberCtrl, enabled: !controller.isViewOnly.value)),
          ],
        ),

        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: CustomTextField(label: "IFSC Code", controller: controller.ifscCtrl, enabled: !controller.isViewOnly.value)),
            const SizedBox(width: 16),
            Expanded(child: CustomTextField(label: "UPI ID", controller: controller.upiCtrl, enabled: !controller.isViewOnly.value)),
          ],
        ),

        const SizedBox(height: 20),
        if (!controller.isViewOnly.value) ...[
          const CustomLabel("Upload Passbook Image *"),
          const SizedBox(height: 8),
          FileUploadBox(
            file: controller.passbookFile,
            type: 'passbook',
            onPick: controller.pickFile,
          ),

          const SizedBox(height: 24),
        ],
        Obx(() => AbsorbPointer(
          absorbing: controller.isViewOnly.value,
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("PAN Card Available", style: TextStyle(fontWeight: FontWeight.bold)),
            value: controller.isPanAvailable.value,
            activeColor: Colors.orange,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (val) => controller.isPanAvailable.value = val!,
          ),
        )),

        Obx(() {
          if (!controller.isPanAvailable.value) return const SizedBox();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              CustomTextField(label: "PAN Number", controller: controller.panNumberCtrl, enabled: !controller.isViewOnly.value),
              const SizedBox(height: 16),
              if (!controller.isViewOnly.value) ...[
                const CustomLabel("Upload PAN Image"),
                const SizedBox(height: 8),
                FileUploadBox(
                  compact: true,
                  file: controller.panCardFile,
                  type: 'pan',
                  onPick: controller.pickFile,
                ),
              ],
            ],
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 🛠️ HELPER WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildInfoTile(double width, String label, String value, IconData icon) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final IconData icon;

  const _DocumentCard({required this.label, required this.imageUrl, required this.icon});

  @override
  Widget build(BuildContext context) {
    bool hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: hasImage ? () => _showFullScreen(context, imageUrl!) : null,
      child: Container(
        height: 120, 
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                Image.network(imageUrl!, fit: BoxFit.cover)
              else
                Center(child: Icon(icon, size: 40, color: Colors.grey.shade300)),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.7)],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),

              Positioned(
                bottom: 10,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: TextStyle(color: hasImage ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                    if (hasImage)
                      const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreen(BuildContext context, String url) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
             InteractiveViewer(child: Image.network(url)),
             Padding(
               padding: const EdgeInsets.all(8.0),
               child: CircleAvatar(
                 backgroundColor: Colors.white,
                 child: IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
               ),
             )
          ],
        ),
      ),
    );
  }
}