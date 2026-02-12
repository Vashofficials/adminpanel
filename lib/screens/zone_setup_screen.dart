import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/location_controller.dart';

class LocationManagementScreen extends StatelessWidget {
  final LocationController controller = Get.put(LocationController());

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController(); // 1. ADD THIS
    const Color primaryOrange = Color(0xFFF97316);
    const Color bgGrey = Color(0xFFF3F4F6);
    const Color textGrey = Color(0xFF4B5563);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: scrollController, // 2. ASSIGN IT HERE
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Location Management",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Manage service areas, geofences, and delivery zones.",
                      style: TextStyle(color: textGrey),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showJsonPayloadSidePanel(context),
                  icon: const Icon(Icons.code, size: 18),
                  label: const Text("JSON Payload"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade50,
                    foregroundColor: primaryOrange,
                    elevation: 0,
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),

            // --- 2. EDITOR SECTION (Map + Form) ---
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              height: 550,
              child: Row(
                children: [
                  // LEFT: MAP (65% width)
                  Expanded(
                    flex: 6,
                    child: Stack(
                      children: [
                        Obx(() {
                          Set<Polygon> polygons = {};
                          if (controller.polygonPoints.isNotEmpty) {
                            polygons.add(Polygon(
                              polygonId: const PolygonId("new_zone"),
                              points: controller.polygonPoints,
                              fillColor: primaryOrange.withOpacity(0.3),
                              strokeColor: primaryOrange,
                              strokeWidth: 2,
                            ));
                          }
                          return GoogleMap(
                            initialCameraPosition: const CameraPosition(
                              target: LatLng(26.8467, 80.9462),
                              zoom: 13,
                            ),
                            mapType: MapType.normal,
                            polygons: polygons,
                            markers: controller.mapMarkers.toSet(),
                            onTap: controller.addPolygonPoint,
                            onMapCreated: controller.onMapCreated,
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                          );
                        }),

                        // Floating Search Bar
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 10)
                              ],
                            ),
                            child: TextField(
                              controller: controller.searchCtrl,
                              decoration: const InputDecoration(
                                hintText: "Search Area by Name (e.g. Gomti Nagar)",
                                prefixIcon: Icon(Icons.search),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              onSubmitted: (val) => controller.searchAndMoveCamera(val),
                            ),
                          ),
                        ),

                        // Bottom Control Bar (Zoom +/-, Delete, Pin Info)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Row(
                            children: [
                              // Pin Count Badge
                              Obx(() => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.push_pin, size: 16, color: Colors.blue),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${controller.polygonPoints.length} points",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              )),
                              const Spacer(),
                              // Control Buttons
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                ),
                                child: Row(
                                  children: [
                                    // Zoom Out
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 20),
                                      onPressed: controller.zoomOut,
                                      tooltip: "Zoom Out",
                                    ),
                                    Container(
                                      width: 1,
                                      height: 24,
                                      color: Colors.grey.shade300,
                                    ),
                                    // Zoom In
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 20),
                                      onPressed: controller.zoomIn,
                                      tooltip: "Zoom In",
                                    ),
                                    Container(
                                      width: 1,
                                      height: 24,
                                      color: Colors.grey.shade300,
                                    ),
                                    // Delete Last Point
                                    Obx(() => IconButton(
                                      icon: const Icon(Icons.undo, size: 20),
                                      onPressed: controller.polygonPoints.isEmpty 
                                          ? null 
                                          : controller.undoLastPoint,
                                      tooltip: "Undo Last Point",
                                      color: controller.polygonPoints.isEmpty 
                                          ? Colors.grey 
                                          : Colors.orange,
                                    )),
                                    Container(
                                      width: 1,
                                      height: 24,
                                      color: Colors.grey.shade300,
                                    ),
                                    // Clear All
                                    Obx(() => IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20),
                                      onPressed: controller.polygonPoints.isEmpty 
                                          ? null 
                                          : controller.clearPolygon,
                                      tooltip: "Clear All Points",
                                      color: controller.polygonPoints.isEmpty 
                                          ? Colors.grey 
                                          : Colors.red,
                                    )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // RIGHT: FORM (35% width)
   // RIGHT: FORM (35% width)
Expanded(
  flex: 4,
  child: Container(
    // remove padding from here if you want the scrollbar at the edge, 
    // but keeping it here is fine for this layout.
    padding: const EdgeInsets.all(24), 
    color: Colors.white,
    child: Form(
      key: controller.formKey,
      // 1. WRAP COLUMN IN SINGLECHILDSCROLLVIEW
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => Text(
                  controller.isEditing.value ? "Edit Location" : "Define New Location",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )),
            const SizedBox(height: 8),
            const Text(
              "Use the map tools to draw a service area, then fill in the details below.",
              style: TextStyle(color: textGrey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _buildLabel("AREA NAME"),
            _buildStyledField(controller.areaNameCtrl, "e.g. Gomti Nagar Ext."),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("CITY"),
                      _buildStyledField(controller.cityCtrl, "Lucknow"),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("STATE"),
                      _buildStyledField(controller.stateCtrl, "Uttar Pradesh"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel("POST CODE"),
            _buildStyledField(controller.pinCodeCtrl, "226010"),
            const SizedBox(height: 16),
            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Ensure the polygon aligns with actual delivery capabilities.",
                      style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            
            // 2. CRITICAL: REPLACE Spacer() WITH FIXED SPACE
            // const Spacer(), // <--- OLD CAUSE OF CRASH
            const SizedBox(height: 24), 

            // Actions
            Obx(() => Column(
                  children: [
                    // 1. Cancel Banner (Only visible when editing)
                    if (controller.isEditing.value)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.edit, size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  "Editing Mode",
                                  style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: controller.cancelEdit,
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            )
                          ],
                        ),
                      ),

                    // 2. Main Action Button (Dynamic)
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton.icon(
                        icon: Icon(controller.isEditing.value ? Icons.update : Icons.save),
                        label: Text(controller.isEditing.value ? "Update Location" : "Save Location"),
                        style: ElevatedButton.styleFrom(
                          // Change color: Orange for Add, Blue for Update
                          backgroundColor: controller.isEditing.value
                              ? Colors.blue
                              : const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: controller.isLoading.value ? null : controller.submitLocation,
                      ),
                    ),
                  ],
                )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton(
                onPressed: controller.clearPolygon,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Clear Map", style: TextStyle(color: Colors.black87)),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- 3. LIST SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Existing Locations",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                // Search & Filter
                Row(
                  children: [
                    SizedBox(
                      width: 250,
                      height: 40,
                      child: TextField(
                        controller: controller.listSearchCtrl,
                        decoration: InputDecoration(
                          hintText: "Search locations...",
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                        onChanged: (val) => controller.filterLocations(val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list, size: 18),
                      label: const Text("Filter"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // DATA TABLE
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Padding(
                      padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
                }
                return DataTable(
                  headingRowColor: MaterialStateProperty.all(bgGrey),
                  columns: const [
                    DataColumn(label: Text("SL", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("AREA NAME", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("POST CODE", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("CITY", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("STATE", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("ACTION", style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: List.generate(controller.filteredLocationList.length, (index) {
                    final loc = controller.filteredLocationList[index];
                    return DataRow(cells: [
                      DataCell(Text("${index + 1}".padLeft(2, '0'))),
                      DataCell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(loc.areaName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Text("Geofence: Polygon",
                              style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      )),
                      DataCell(Text(loc.postCode ?? '-')),
                      DataCell(Text(loc.city ?? 'Lucknow')),
                      DataCell(Text(loc.state ?? 'Uttar Pradesh')),
                      DataCell(Row(
                        children: [
                          IconButton(
      icon: const Icon(Icons.edit, size: 18, color: Colors.orange),
      onPressed: () {
        // 1. Populate form and map
        controller.prepareEdit(loc);
        
        // 2. Scroll to top so user sees the form
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
    ),
                          IconButton(
      icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
      onPressed: () {
        // Ensure ID is not null before calling
        if (loc.id != null) {
          controller.deleteLocation(loc.id!);
        }
      },
    ),
                        ],
                      )),
                    ]);
                  }),
                );
              }),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  void _showJsonPayloadSidePanel(BuildContext context) {
    final payload = controller.generateJsonPayload();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "JSON Payload",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 8,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.35,
              height: MediaQuery.of(context).size.height,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withOpacity(0.1),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.code, color: Color(0xFFF97316), size: 24),
                            SizedBox(width: 12),
                            Text(
                              "JSON Payload",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  
                  // Description
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      "Current form data in JSON format. Empty fields are shown as null.",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  // JSON Content
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          payload,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: Color(0xFFD4D4D4),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Action Buttons
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.copy),
                            label: const Text("Copy to Clipboard"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF97316),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              controller.copyPayloadToClipboard();
                              Get.snackbar(
                                "Copied",
                                "JSON payload copied to clipboard",
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                                margin: const EdgeInsets.all(16),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text("Refresh"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _showJsonPayloadSidePanel(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim1,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildStyledField(TextEditingController ctrl, String hint) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.orange),
        ),
      ),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }
}