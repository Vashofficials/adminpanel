import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui'; // For PointerDeviceKind
import '../controllers/provider_controller.dart';
// 1. IMPORT THE ADD PROVIDER CONTROLLER
import '../controllers/add_provider_controller.dart'; 
// Import your AddProviderScreen if you use direct navigation fallback
import 'provider_add_screen.dart'; 

class ProviderListScreen extends StatelessWidget {
  final ProviderController controller = Get.put(ProviderController());
  
  // 2. Add a callback to handle navigation request to the parent/dashboard
  final Function(String)? onNav;

  // Constructor
  ProviderListScreen({Key? key, this.onNav}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFF97316);
    const Color textDark = Color(0xFF1E293B);
    const Color textGrey = Color(0xFF64748B);
    const Color bgLight = Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... [HEADER AND FILTER CODE REMAINS EXACTLY THE SAME] ...
            const Text("Service Providers Dashboard", 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)
            ),
            const SizedBox(height: 4),
            const Text("Manage your team and monitor their status across Lucknow", 
              style: TextStyle(color: textGrey)
            ),
            const SizedBox(height: 24),

            // --- FILTER BAR ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterField(
                      label: "LOCATION", value: "Lucknow", icon: Icons.lock_outline, isLocked: true
                    )
                  ),
                  const SizedBox(width: 16),
                  // Expanded(
                  //   child: _buildFilterField(
                  //     label: "JOIN DATE", value: "Select date range", icon: Icons.calendar_today_outlined
                  //   )
                  // ),
                  // const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("SEARCH PROVIDER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Container(
                          height: 42,
                          child: TextField(
                            onChanged: (val) {
                               controller.searchText.value = val;
                            },
                            decoration: InputDecoration(
                              hintText: "Search name or number",
                              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                              prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade200)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade200)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFF97316))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: controller.fetchProviders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text("Refresh", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- CATEGORY FILTER CHIPS ---
            Obx(() {
              final categories = controller.availableCategories;
              if (categories.length <= 1) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        const Text(
                          'Filter by Category:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final isSelected = controller.selectedCategory.value == cat;
                        return GestureDetector(
                          onTap: () => controller.selectedCategory.value = cat,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryOrange : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? primaryOrange : const Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                ? [BoxShadow(color: primaryOrange.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))]
                                : [],
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF374151),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            }),

            // --- MAIN TABLE CARD ---
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  // ... [TABS AND SEARCH CODE REMAINS EXACTLY THE SAME] ...
                  // (Skipping upper UI code for brevity, logic change is below in DataRow)
                  
                  // DATA TABLE
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: primaryOrange)));
                    }
                    
                    if (controller.providerList.isEmpty) {
                      return const Padding(padding: EdgeInsets.all(40), child: Center(child: Text("No providers found")));
                    }

                    return ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: { PointerDeviceKind.touch, PointerDeviceKind.mouse },
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 100),
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                            columnSpacing: 24,
                            dataRowHeight: 72,
                            horizontalMargin: 20,
                            columns: const [
                              DataColumn(label: Text("SL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textGrey))),
                              DataColumn(label: Text("PROVIDER NAME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textGrey))),
                              DataColumn(label: Text("CATEGORY MAPPED", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textGrey))),
                              DataColumn(label: Text("CONTACT DETAILS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textGrey))),
                              DataColumn(label: Text("LOCATION & ADDRESS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textGrey))),
                              DataColumn(label: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textGrey))),
                              DataColumn(label: Text("ONBOARDING", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textGrey))),
                              DataColumn(label: Text("ACTIONS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textGrey))),
                            ],
                            rows: List.generate(controller.providerList.length, (index) {
                              final provider = controller.providerList[index];
                              return DataRow(cells: [
                                DataCell(Text("${index + 1}", style: const TextStyle(color: textGrey, fontWeight: FontWeight.w500))),
                                
                                // Name & Avatar
                                DataCell(InkWell(
                                  onTap: () {
                                    // Navigate to provider details (uses same view/edit screen)
                                    AddProviderController addCtrl = Get.put(AddProviderController());
                                    addCtrl.isViewOnly.value = true; // <-- NEW
                                    addCtrl.currentStep.value = 0;
                                    addCtrl.onSelectExistingProvider(provider.id);
                                    if (onNav != null) {
                                      onNav!('provider/add'); 
                                    } else {
                                      Get.to(() => AddProviderScreen());
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: _getAvatarColor(index),
                                        backgroundImage: (provider.imageUrl != null && provider.imageUrl!.isNotEmpty)
                                            ? NetworkImage(provider.imageUrl!)
                                            : null,
                                        onBackgroundImageError: (provider.imageUrl != null && provider.imageUrl!.isNotEmpty)
                                            ? (_, __) {} 
                                            : null,
                                        child: (provider.imageUrl == null || provider.imageUrl!.isEmpty)
                                            ? Text(
                                                provider.firstName.isNotEmpty ? provider.firstName[0].toUpperCase() : "?",
                                                style: TextStyle(color: _getAvatarTextColor(index), fontSize: 12, fontWeight: FontWeight.bold),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(provider.fullName, style: const TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 13)),
                                          SizedBox(
                                            width: 80,
                                            child: Text("ID: ...${provider.id.substring(0, 5)}", overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: textGrey))
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )),

                                // Category Mapped
                                DataCell(Obx(() {
                                  final cat = controller.providerCategoriesMap[provider.id];
                                  if (cat == null) {
                                    return const SizedBox(
                                      width: 16, height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: primaryOrange)
                                    );
                                  }
                                  return Text(cat, style: const TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 12));
                                })),

                                // Contact
                                DataCell(Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(provider.emailId ?? "No Email", style: const TextStyle(fontSize: 12, color: textGrey)),
                                    Text(provider.mobileNo, style: const TextStyle(fontSize: 12, color: textGrey)),
                                  ],
                                )),

                                // Location
                                DataCell(Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(provider.fullAddress, style: const TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 13)),
                                    if(provider.zipCode != null)
                                      Text("Pin: ${provider.zipCode}", style: const TextStyle(fontSize: 11, color: textGrey)),
                                  ],
                                )),

                                // Status
                            // Status DataCell
DataCell(
  Obx(() {
    // We access the provider through the controller list to ensure reactivity
    final provider = controller.providerList[index];
    
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        // 1. Point to the correct status field (Active = true, Inactive = false)
        value: provider.isActive, 
        activeColor: Colors.white,
        activeTrackColor: primaryOrange,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.shade300,
        // 2. Call the handler that manages the Confirmation Dialog and flipped API logic
        onChanged: (bool val) => controller.handleToggleStatus(context, index, val),
      ),
    );
  }),
),
                                // Onboarding Badge
                                DataCell(_buildStatusBadge(provider.onboardingStatus)),

                                // --- 3. UPDATED ACTIONS ---
                                DataCell(Row(
                                  children: [
                                    // View Button
                                    _buildActionBtn(Icons.remove_red_eye_outlined, Colors.blue, () {
                                      AddProviderController addCtrl = Get.put(AddProviderController());
                                      addCtrl.isViewOnly.value = true;
                                      addCtrl.currentStep.value = 0;
                                      addCtrl.onSelectExistingProvider(provider.id);
                                      if (onNav != null) {
                                        onNav!('provider/add'); 
                                      } else {
                                        Get.to(() => AddProviderScreen());
                                      }
                                    }),
                                    const SizedBox(width: 8),
                                    // Edit Button
                                    _buildActionBtn(Icons.edit_outlined, Colors.orange, () {
                                      AddProviderController addCtrl = Get.put(AddProviderController());
                                      addCtrl.isViewOnly.value = false;
                                      addCtrl.currentStep.value = 0;
                                      addCtrl.onSelectExistingProvider(provider.id);
                                      if (onNav != null) {
                                        onNav!('provider/add'); 
                                      } else {
                                        Get.to(() => AddProviderScreen());
                                      }
                                    }),
                                  ],
                                )),
                              ]);
                            }),
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... [WIDGET BUILDERS AND HELPERS REMAIN SAME] ...
  Widget _buildFilterField({required String label, required String value, required IconData icon, bool isLocked = false}) {
     // ... (Keep existing code)
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(6),
            color: isLocked ? const Color(0xFFF8FAFC) : Colors.white, 
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: TextStyle(fontSize: 13, color: isLocked ? Colors.grey : Colors.black87)),
              Icon(icon, size: 16, color: isLocked ? Colors.grey.shade400 : Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    // ... (Keep existing code)
    Color bg, text;
    switch (status) {
      case 'Approved': bg = const Color(0xFFDCFCE7); text = const Color(0xFF166534); break;
      case 'Pending Docs': bg = const Color(0xFFFFEDD5); text = const Color(0xFF9A3412); break;
      default: bg = const Color(0xFFFEF9C3); text = const Color(0xFF854D0E); 
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap) {
    // ... (Keep existing code)
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Color _getAvatarColor(int index) {
     final colors = [Colors.blue.shade50, Colors.purple.shade50, Colors.green.shade50, Colors.orange.shade50, Colors.pink.shade50];
    return colors[index % colors.length];
  }

  Color _getAvatarTextColor(int index) {
     final colors = [Colors.blue.shade700, Colors.purple.shade700, Colors.green.shade700, Colors.orange.shade700, Colors.pink.shade700];
    return colors[index % colors.length];
  }
}