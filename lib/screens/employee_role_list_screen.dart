import 'package:flutter/material.dart';

class EmployeeRoleListScreen extends StatefulWidget {
  final VoidCallback? onAddRole; 
  final VoidCallback? onEditRole; // <--- 1. Add this variable
  const EmployeeRoleListScreen({super.key, this.onAddRole, this.onEditRole});

  @override
  State<EmployeeRoleListScreen> createState() => _EmployeeRoleListScreenState();
}

class _EmployeeRoleListScreenState extends State<EmployeeRoleListScreen> {
  // ---------------------------------------------------------------------------
  // STATE & DATA
  // ---------------------------------------------------------------------------
  int _selectedTabIndex = 0; // 0: All, 1: Active, 2: Inactive
  final List<String> _tabs = ["All", "Active", "Inactive"];

  // Dummy Data matched to image_0519c1.jpg
  final List<Map<String, dynamic>> _roles = [
    {
      "sl": "1",
      "role": "Jr. Digital Marketer",
      "modules": "Dashboard, Booking Management, Promotion Management (Discounts, Coupons, Campaigns, Advertisements, Promotional Banners) Notification Ma...",
      "isActive": true,
    },
    {
      "sl": "2",
      "role": "Jr. Customer Executive",
      "modules": "Booking Management, Promotion Management (Discounts, Coupons, Campaigns, Advertisements, Promotional Banners) Notification Management (S...",
      "isActive": true,
    },
    {
      "sl": "3",
      "role": "Jr. Business Analysis",
      "modules": "Dashboard, Booking Management, Promotion Management (Discounts, Coupons, Campaigns, Advertisements, Promotional Banners) Notification Ma...",
      "isActive": true,
    },
    {
      "sl": "4",
      "role": "Super Admin",
      "modules": "Dashboard, Booking Management, Promotion Management (Discounts, Coupons, Campaigns, Advertisements, Promotional Banners) Notification Ma...",
      "isActive": true,
    },
    {
      "sl": "5",
      "role": "Senior Digital Marketer",
      "modules": "Dashboard, Booking Management, Promotion Management (Discounts, Coupons, Campaigns, Advertisements, Promotional Banners) Notification Ma...",
      "isActive": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC), // Light background
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER (Title + Add Button)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Employee Role List",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF202224),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (widget.onAddRole != null) {
                      widget.onAddRole!();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00), // Primary Orange
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text("Add Role", style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. TABS & COUNT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: List.generate(_tabs.length, (index) {
                    final isSelected = _selectedTabIndex == index;
                    return InkWell(
                      onTap: () => setState(() => _selectedTabIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 32),
                        padding: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected ? const Color(0xFFFF6B00) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          _tabs[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFFFF6B00) : Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                Text(
                  "Total Employee Roles: 7",
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: Colors.grey[700],
                    fontSize: 13
                  ),
                ),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            const SizedBox(height: 24),

            // 3. MAIN CARD (SEARCH + TABLE)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // A. Search Bar Area
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Search Input
                        Expanded(
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6FA), // Light input bg
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                Icon(Icons.search, color: Colors.grey[500], size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: "Search by role name",
                                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.only(bottom: 4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Search Button
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B00), // Orange
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            elevation: 0,
                          ),
                          child: const Text("Search"),
                        ),
                        const Spacer(),
                        // Download Button
                        OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Row(
                            children: [
                              Text("Download"),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down, size: 18)
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // B. The Table
                  SizedBox(
                    width: double.infinity,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.grey.shade200,
                        dataTableTheme: DataTableThemeData(
                          headingTextStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      child: DataTable(
                        horizontalMargin: 24,
                        columnSpacing: 30,
                        headingRowColor: MaterialStateProperty.all(Colors.transparent),
                        dataRowHeight: 75,
                        columns: const [
                          DataColumn(label: Text("SL")),
                          DataColumn(label: Text("ROLE NAME")),
                          DataColumn(label: Text("MODULES")),
                          DataColumn(label: Text("STATUS")),
                          DataColumn(label: Text("ACTION")),
                        ],
                        rows: _roles.map((data) {
                          return DataRow(cells: [
                            DataCell(Text(data['sl'], style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(data['role'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                            // Modules Column with ellipsis
                            DataCell(
                              Container(
                                width: 400, // Fixed width to force wrap/truncation
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  data['modules'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                                ),
                              ),
                            ),
                            // Custom Orange Toggle
                            DataCell(_buildCustomSwitch(data['isActive'])),
                            // Action Buttons
                            DataCell(Row(
                              children: [
                                // 2. WRAP EDIT BUTTON IN INKWELL AND CALL CALLBACK
                                InkWell(
                                  onTap: widget.onEditRole, 
                                  child: _buildActionButton(Icons.edit_outlined, const Color(0xFFFFCC99))
                                ), // Light orange border
                                const SizedBox(width: 8),
                                _buildActionButton(Icons.delete_outline, const Color(0xFFFFCDD2)), // Light red border
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // C. Footer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Showing 1 to 5 of 56 results", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        Row(
                          children: [
                            _paginationBtn("Previous", false),
                            const SizedBox(width: 8),
                            _paginationBtn("Next", true),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildActionButton(IconData icon, Color borderColor) {
    // Determine color based on icon type for the outline
    Color iconColor;
    if (icon == Icons.delete_outline) {
      iconColor = Colors.red.shade400;
    } else {
      iconColor = const Color(0xFFFF6B00); // Orange for edit
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Icon(icon, size: 16, color: iconColor),
    );
  }

  Widget _paginationBtn(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey[100],
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
    );
  }

  // Exact Match Switch: Orange Track, White Thumb, Checkmark inside
  Widget _buildCustomSwitch(bool isActive) {
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: isActive,
        activeColor: Colors.white, // Thumb color when active
        activeTrackColor: const Color(0xFFFF6B00), // Orange Track
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey[300],
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
        // This adds the checkmark icon inside the thumb
        thumbIcon: MaterialStateProperty.resolveWith<Icon?>((states) {
          if (states.contains(MaterialState.selected)) {
            return const Icon(Icons.check, color: Color(0xFFFF6B00), size: 16);
          }
          return null;
        }),
        onChanged: (val) {
          // Handle toggle
        },
      ),
    );
  }
}