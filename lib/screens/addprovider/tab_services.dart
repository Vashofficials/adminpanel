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
            "Select individual services or use the checkbox to select all services in a category.",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          Obx(() {
            // 1. Loading Check
            if (controller.categories.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text("Loading available services...")),
              );
            }

            // 2. Build the category list
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
                    initiallyExpanded: i == 0,

                    // ── CATEGORY HEADER ──────────────────────────────────
                    title: Obx(() {
                      final services = controller.serviceMap[cat.id] ?? [];
                      final allSelected =
                          controller.isAllServicesSelectedForCategory(cat.id);
                      final selectedCount = services
                          .where((s) =>
                              controller.localServiceStatus[s.name] == true)
                          .length;

                      return Row(
                        children: [
                          // "Select All" checkbox
                          GestureDetector(
                            onTap: controller.isViewOnly.value
                                ? null
                                : () => controller
                                    .toggleAllServicesForCategory(cat.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color:
                                    allSelected ? primaryOrange : Colors.white,
                                border: Border.all(
                                  color: allSelected
                                      ? primaryOrange
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: allSelected
                                  ? const Icon(Icons.check,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                          ),

                          // Category name
                          Expanded(
                            child: Text(
                              cat.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ),

                          // Selected count badge
                          if (selectedCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: primaryOrange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "$selectedCount selected",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: primaryOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      );
                    }),

                    // ── SERVICE CHIPS ─────────────────────────────────────
                    children: [
                      Obx(() {
                        final services = controller.serviceMap[cat.id] ?? [];
                        final activeStatusMap = controller.localServiceStatus;

                        if (services.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text("No services available"),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: services.map((srv) {
                              final bool isActive =
                                  activeStatusMap[srv.name] ?? false;

                              return FilterChip(
                                label: Text(
                                  srv.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                selected: isActive,
                                showCheckmark: true,
                                checkmarkColor: Colors.white,
                                selectedColor: primaryOrange,
                                backgroundColor: Colors.grey.shade100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isActive
                                        ? Colors.transparent
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                onSelected: (_) {
                                  if (!controller.isViewOnly.value) {
                                    controller.toggleServiceLocal(
                                      cat.id,
                                      srv.id,
                                      srv.name,
                                    );
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        );
                      }),
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
