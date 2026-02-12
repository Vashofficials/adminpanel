import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../controllers/document_controller.dart';
import '../controllers/banking_controller.dart';
import '../widgets/custom_center_dialog.dart';

class MasterSetupScreen extends StatelessWidget {
  const MasterSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text("Master Setup", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.black87),
          bottom: const TabBar(
            labelColor: Color(0xFFF97316),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFF97316),
            tabs: [
              Tab(text: "Document Types", icon: Icon(Icons.description_outlined)),
              Tab(text: "Banks", icon: Icon(Icons.account_balance_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DocumentTypesTab(),
            _BanksTab(),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 📄 TAB 1: DOCUMENT TYPES (With Edit & Delete)
// -----------------------------------------------------------------------------
class _DocumentTypesTab extends StatelessWidget {
  const _DocumentTypesTab();

  @override
  Widget build(BuildContext context) {
    final DocumentController controller = Get.put(DocumentController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF97316),
        icon: const Icon(Icons.add),
        label: const Text("Add Document Type"),
        onPressed: () => _showDocDialog(context, controller, isEdit: false),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.docTypes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.docTypes.isEmpty) {
          return _buildEmptyState("No document types found.");
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.docTypes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, index) {
            final doc = controller.docTypes[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.folder_shared, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          "ID: ${doc.id}",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  // Edit Button
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueGrey),
                    onPressed: () => _showDocDialog(context, controller, isEdit: true, docItem: doc),
                  ),
                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, "Delete Document Type?", () async {
                      await controller.deleteDocumentType(doc.id, doc.isActive);
                    }),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  void _showDocDialog(BuildContext context, DocumentController controller, {required bool isEdit, dynamic docItem}) {
    final textCtrl = TextEditingController(text: isEdit ? docItem.name : "");
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.description, size: 30, color: Color(0xFFF97316)),
                const SizedBox(height: 20),
                Text(
                  isEdit ? "Update Document Type" : "New Document Type",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: textCtrl,
                  decoration: const InputDecoration(
                    labelText: "Document Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (textCtrl.text.trim().isNotEmpty) {
                            Navigator.pop(context);
                            if (isEdit) {
                              await controller.updateDocumentType(docItem.id, textCtrl.text.trim());
                            } else {
                              await controller.addDocumentType(textCtrl.text.trim());
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                        child: Text(isEdit ? "Update" : "Add", style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🏦 TAB 2: BANKS (With Edit & Delete)
// -----------------------------------------------------------------------------
class _BanksTab extends StatelessWidget {
  const _BanksTab();

  @override
  Widget build(BuildContext context) {
    final BankingController controller = Get.put(BankingController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF97316),
        icon: const Icon(Icons.add),
        label: const Text("Add Bank"),
        onPressed: () => _showBankDialog(context, controller, isEdit: false),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.bankList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.bankList.isEmpty) {
          return _buildEmptyState("No banks available.");
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.bankList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, index) {
            final bank = controller.bankList[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                      image: (bank.imgLink != null && bank.imgLink!.isNotEmpty) 
                        ? DecorationImage(image: NetworkImage(bank.imgLink!), fit: BoxFit.contain)
                        : null
                    ),
                    child: (bank.imgLink == null || bank.imgLink!.isEmpty)
                      ? const Icon(Icons.account_balance, color: Colors.grey)
                      : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(bank.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  // Edit Button
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueGrey),
                    onPressed: () => _showBankDialog(context, controller, isEdit: true, bankItem: bank),
                  ),
                  // Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, "Delete Bank?", () async {
                      await controller.deleteBank(bank.id, bank.isActive);
                    }),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  void _showBankDialog(BuildContext context, BankingController controller, {required bool isEdit, dynamic bankItem}) {
    final textCtrl = TextEditingController(text: isEdit ? bankItem.name : "");
    PlatformFile? pickedLogo;
    RxString fileName = "No file selected".obs;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance, size: 30, color: Color(0xFFF97316)),
                const SizedBox(height: 20),
                Text(
                  isEdit ? "Update Bank" : "Add New Bank",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: textCtrl,
                  decoration: const InputDecoration(
                    labelText: "Bank Name",
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(type: FileType.image);
                    if (result != null) {
                      pickedLogo = result.files.first;
                      fileName.value = pickedLogo!.name;
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.upload_file, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Obx(() => Text(
                            fileName.value, 
                            style: TextStyle(color: fileName.value.startsWith("No file") ? Colors.grey : Colors.black87),
                            overflow: TextOverflow.ellipsis
                          )),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (textCtrl.text.trim().isEmpty) return;
                          
                          // For update, file is mandatory per original request if not changing
                          // If changing, handle null appropriately based on API
                          if (pickedLogo == null) {
                             Get.snackbar("Required", "Please select a file", backgroundColor: Colors.orange, colorText: Colors.white);
                             return;
                          }

                          Navigator.pop(context);
                          if (isEdit) {
                            await controller.updateBank(bankItem.id, textCtrl.text.trim(), pickedLogo!);
                          } else {
                            await controller.addBank(textCtrl.text.trim(), pickedLogo);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                        child: Text(isEdit ? "Update" : "Save", style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🛠️ HELPER WIDGETS & FUNCTIONS
// -----------------------------------------------------------------------------
Widget _buildEmptyState(String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
      ],
    ),
  );
}

void _confirmDelete(BuildContext context, String title, VoidCallback onConfirm) {
  // Use CustomCenterDialog instead of standard AlertDialog
  CustomCenterDialog.show(
    context,
    title: title,
    message: "Are you sure you want to delete this item? This action cannot be undone.",
    type: DialogType.warning, // Orange warning style
    confirmText: "Delete",
    cancelText: "Cancel",
    onConfirm: () {
      // 2. Execute the delete logic
      onConfirm(); 
    },
  );
}
