import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/add_provider_controller.dart';
import 'common_widgets.dart';

class TabServices extends GetView<AddProviderController> {
  const TabServices({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFF97316);
    const Color borderGrey = Color(0xFFE0E0E0);
    const Color textDark = Color(0xFF212121);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader("Service Mapping"),
          const SizedBox(height: 8),
          const Text(
            "Tap a service to Activate/Deactivate. Orange indicates active services.",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          
          Obx(() {
            // 1. Loading Check
            if (controller.categories.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20), 
                child: Center(child: Text("Loading available services..."))
              );
            }

            // 2. Create a fast Lookup Map for current status
            // Key: Service Name (since API maps by name), Value: isActive status
            // If a service is missing from this map, it means it is NOT mapped (effectively inactive).
            final Map<String, bool> activeStatusMap = {
              for (var item in controller.mappedServicesList) 
                item.service: item.isActive
            };

            // 3. Build the Unified List
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.categories.length,
              itemBuilder: (ctx, i) {
                final cat = controller.categories[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderGrey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ExpansionTile(
                    shape: const Border(),
                    initiallyExpanded: i == 0, // Expand first one by default for better UX
                    title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                    children: [
                      Obx(() {
                        final services = controller.serviceMap[cat.id] ?? [];
                        
                        if (services.isEmpty) {
                          return const Padding(padding: EdgeInsets.all(16), child: Text("No services available"));
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            spacing: 10, runSpacing: 10,
                            children: services.map((srv) {
                              
                              // Check if this service is currently active for this provider
                              final bool isActive = activeStatusMap[srv.name] ?? false;
                              
                              return FilterChip(
                                label: Text(
                                  srv.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    // Visual Feedback: White text if Active, Black if Inactive
                                    color: isActive ? Colors.white : Colors.black87,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                
                                // --- STATE LOGIC ---
                                selected: isActive,
                                showCheckmark: false, // Cleaner look without checkmark
                                
                                // --- STYLING ---
                                selectedColor: primaryOrange, // Active Color
                                backgroundColor: Colors.grey.shade100, // Inactive Color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isActive ? Colors.transparent : Colors.grey.shade300
                                  )
                                ),

                                // --- ACTION ---
                                onSelected: (_) {
                                  // Simplified Interaction: Just toggle.
                                  // The controller handles:
                                  // 1. If New -> Map It
                                  // 2. If Active -> Deactivate (Delete true)
                                  // 3. If Inactive -> Activate (Delete false)
                                  controller.toggleService(cat.id, srv.id, srv.name);
                                },
                              );
                            }).toList(),
                          ),
                        );
                      })
                    ],
                  ),
                );
              },
            );
          }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}