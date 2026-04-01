import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';

import '../../controllers/add_provider_controller.dart';
import '../../models/location_model.dart';
import '../../widgets/searchable_selection_sheet.dart';
import '../../widgets/custom_center_dialog.dart';
import 'common_widgets.dart';

class TabLocationMap extends GetView<AddProviderController> {
  const TabLocationMap({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFF97316);

    // Lazy load master list
    if (controller.locationController.locationList.isEmpty) {
      Future.microtask(() => controller.locationController.fetchLocations());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader("MAP PROVIDER LOCATION"),
          const SizedBox(height: 8),
          const Text(
            "Select an operating area to assign to this provider.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // --- 1. INPUT FIELD (Dropdown - Adds NEW Mapping) ---
          if (!controller.isViewOnly.value)
            Obx(() {
              if (controller.locationController.isLoading.value) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ));
              }

              final selectedLoc = controller.selectedLocation.value;
              final isPlaceholder = selectedLoc == null;

              String displayText = "Choose an Area to Add";
              if (selectedLoc != null) {
                displayText = selectedLoc.areaName;
                if (selectedLoc.city != null && selectedLoc.city!.isNotEmpty) {
                  displayText += " (${selectedLoc.city})";
                }
              }

              return InkWell(
                onTap: () {
                  // Get IDs that are ALREADY mapped
                  final mappedIds = controller
                      .locationController.providerLocationList
                      .map((e) => e.areaId?.toString())
                      .whereType<String>()
                      .toSet();

                  SearchableSelectionSheet.show(
                    context,
                    title: "Select Operating Area",
                    primaryColor: primaryOrange,
                    items:
                        controller.locationController.locationList.map((loc) {
                      final isMapped =
                          mappedIds.contains(loc.areaId?.toString() ?? loc.id);
                      return SelectionItem(
                        id: loc.areaId?.toString() ?? loc.id ?? "unknown",
                        title: loc.areaName,
                        subtitle:
                            isMapped ? "⚠️ Already Assigned" : (loc.city ?? ""),
                        icon:
                            isMapped ? Icons.lock_outline : Icons.map_outlined,
                      );
                    }).toList(),
                    isMultiSelect: true,
                    onMultiItemSelected: (selectedIds) {
                      final newIds = selectedIds
                          .where((id) => !mappedIds.contains(id))
                          .toList();
                      if (newIds.isEmpty) {
                        if (selectedIds.isNotEmpty) {
                          CustomCenterDialog.show(
                            context,
                            title: "Location Assigned",
                            message:
                                "Selected locations are already in the list below. You can toggle their status there.",
                            type: DialogType.info,
                          );
                        }
                        return;
                      }

                      final locs = controller.locationController.locationList
                          .where((l) =>
                              newIds.contains(l.areaId?.toString() ?? l.id))
                          .toList();

                      if (locs.isNotEmpty) {
                        controller.addMultipleLocationsFromDropdown(locs);
                      }
                    },
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_location_alt_outlined,
                          color: Colors.grey.shade600, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isPlaceholder)
                              Text("Select New Area",
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade700)),
                            Text(
                              displayText,
                              style: TextStyle(
                                color: isPlaceholder
                                    ? Colors.grey.shade600
                                    : Colors.black87,
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
              );
            }),

          if (!controller.isViewOnly.value) const SizedBox(height: 30),
          if (!controller.isViewOnly.value) const Divider(),

          // --- 3. LIST OF ASSIGNED LOCATIONS (With Toggle) ---
          const SizedBox(height: 10),
          const Text("Currently Assigned Areas",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (!controller.isViewOnly.value)
            const Text("Tap lock icon to deactivate/remove access.",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),

          Obx(() {
            if (controller.locationController.isProviderMapLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final assignedList =
                controller.locationController.providerLocationList;

            if (assignedList.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text("No areas assigned yet.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assignedList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final mappedLoc = assignedList[index];
                final bool isActive = mappedLoc
                    .isActive; // Ensure your model has this field (non-final)

                return Container(
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isActive
                            ? Colors.grey.shade300
                            : Colors.grey.shade200),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ]
                        : null,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive
                          ? Colors.green.shade50
                          : Colors.grey.shade300,
                      child: Icon(isActive ? Icons.check_circle : Icons.cancel,
                          color: isActive ? Colors.green : Colors.grey,
                          size: 20),
                    ),
                    title: Text(mappedLoc.areaName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.black87 : Colors.grey,
                          decoration:
                              isActive ? null : TextDecoration.lineThrough,
                        )),
                    subtitle: Text(
                        isActive
                            ? "Active Coverage"
                            : "Inactive (Access Revoked)",
                        style: TextStyle(
                            fontSize: 12,
                            color: isActive ? Colors.green : Colors.red)),

                    // --- TOGGLE BUTTON ---
                    trailing: controller.isViewOnly.value
                        ? null
                        : IconButton(
                            icon: Icon(
                              isActive
                                  ? Icons.lock_open
                                  : Icons
                                      .lock_outline, // Open = Active, Locked = Revoked/Deleted
                              color: isActive ? Colors.green : Colors.grey,
                            ),
                            tooltip: isActive ? "Deactivate" : "Reactivate",
                            onPressed: () {
                              // Call the toggle function
                              controller.toggleLocationStatus(mappedLoc);
                            },
                          ),
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

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 80,
              child: Text("$label:",
                  style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(
              child: Text(value ?? "N/A",
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}
