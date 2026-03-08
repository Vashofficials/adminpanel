import 'package:flutter/material.dart';

class EmployeeListScreen extends StatefulWidget {
  final VoidCallback? onAddEmployee;
  const EmployeeListScreen({super.key, this.onAddEmployee});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> with SingleTickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // STATE & DATA
  // ---------------------------------------------------------------------------
  int _selectedTabIndex = 0; // 0: All, 1: Active, 2: Inactive
  final List<String> _tabs = ["All", "Active", "Inactive"];

  final List<Map<String, dynamic>> _employees = [
    {
      "sl": "1",
      "name": "Rajesh Kumar",
      "email": "rajesh.k@chayankaro.in",
      "id": "d9d6e8b8-55b0...",
      "role": "Assistant Admin",
      "permissions": "Dashboard, Booking Management, Promotion Management (Discounts,...",
      "isActive": true,
    },
    {
      "sl": "2",
      "name": "Anjali Singh",
      "email": "anjali.singh@chayankaro.in",
      "id": "1d67fad5-5d95...",
      "role": "Senior Digital Marketer",
      "permissions": "Dashboard, Booking Management, Promotion Management (Discounts,...",
      "isActive": true,
    },
    {
      "sl": "3",
      "name": "Vikram Malhotra",
      "email": "vikram.m@chayankaro.in",
      "id": "adf62b5b-0a74...",
      "role": "Jr. Business Analyst",
      "permissions": "Dashboard, Booking Management, Promotion Management (Discounts,...",
      "isActive": true,
    },
    {
      "sl": "4",
      "name": "Sneha Gupta",
      "email": "sneha.gupta@chayankaro.in",
      "id": "f5f6d789-b42b...",
      "role": "Senior Customer Executive",
      "permissions": "Booking Management, Promotion Management (Discounts, Coupons,...",
      "isActive": false, // Inactive example
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // Light grey background
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Employee List",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1D1F),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: widget.onAddEmployee,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00), // Orange
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text("Add Employee", style: TextStyle(fontWeight: FontWeight.w600)),
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
                        margin: const EdgeInsets.only(right: 24),
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
                  "Total Employees: ${_employees.length}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 24),

            // 3. MAIN CARD (SEARCH + TABLE)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // A. Search and Filter Bar
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                const Icon(Icons.search, color: Colors.grey),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: "Search here",
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.only(bottom: 4),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.all(4),
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6B00),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                    ),
                                    child: const Text("Search"),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[800],
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 20),
                          label: const Text("Download"),
                        ),
                      ],
                    ),
                  ),

                  // B. Data Table
                  SizedBox(
                    width: double.infinity,
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.grey.shade200),
                      child: DataTable(
                        horizontalMargin: 20,
                        columnSpacing: 24,
                        headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                        dataRowHeight: 85, // Taller rows for multi-line content
                        columns: [
                          DataColumn(label: _buildHeader("SL")),
                          DataColumn(label: _buildHeader("EMPLOYEE NAME")),
                          DataColumn(label: _buildHeader("EMPLOYEE ID")),
                          DataColumn(label: _buildHeader("ROLE")),
                          DataColumn(label: _buildHeader("PERMISSION")),
                          DataColumn(label: _buildHeader("STATUS")),
                          DataColumn(label: _buildHeader("ACTION")),
                        ],
                        rows: _employees.map((data) {
                          return DataRow(cells: [
                            DataCell(Text(data['sl'], style: const TextStyle(fontWeight: FontWeight.w500))),
                            // Name & Email
                            DataCell(Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(data['email'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            )),
                            // ID
                            DataCell(Text(data['id'], style: TextStyle(color: Colors.grey[600], fontSize: 13))),
                            // Role
                            DataCell(Text(data['role'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                            // Permission with 'Edit/Delete' text
                            DataCell(Container(
                              width: 250, // Limit width to force wrap if needed
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['permissions'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey[800], fontSize: 12, height: 1.3),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Edit/Delete/Export",
                                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                  ),
                                ],
                              ),
                            )),
                            // Status Toggle
                            DataCell(_buildCustomSwitch(data['isActive'])),
                            // Action Menu
                            DataCell(IconButton(
                              icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                              onPressed: () {},
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // C. Pagination Footer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Showing 1 to ${_employees.length} of 4 results", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        Row(
                          children: [
                            _paginationBtn("Previous"),
                            const SizedBox(width: 8),
                            _paginationBtn("Next"),
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

  // Helper for Table Headers
  Widget _buildHeader(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[600], letterSpacing: 0.5),
    );
  }

  // Helper for Pagination Buttons
  Widget _paginationBtn(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
    );
  }

  // Custom Switch to match the image (Orange with Tick inside thumb)
  Widget _buildCustomSwitch(bool isActive) {
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: isActive,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFFFF6B00),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey[300],
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
        thumbIcon: MaterialStateProperty.resolveWith<Icon?>((states) {
          if (states.contains(MaterialState.selected)) {
            return const Icon(Icons.check, color: Color(0xFFFF6B00));
          }
          return null;
        }),
        onChanged: (val) {
          // In a real app, update state here
        },
      ),
    );
  }
}