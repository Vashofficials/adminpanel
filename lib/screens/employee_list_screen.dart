import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import '../services/api_service.dart';

class EmployeeListScreen extends StatefulWidget {
  final VoidCallback? onAddEmployee;

  /// Called when user clicks "View Permissions" — passes the selected employee.
  /// DashboardScreen uses this to navigate to ModulePermissionScreen with pre-filled data.
  final void Function(EmployeeModel employee)? onViewPermissions;

  const EmployeeListScreen({
    super.key,
    this.onAddEmployee,
    this.onViewPermissions,
  });

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final ApiService _api = ApiService();

  List<EmployeeModel> _employees = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  final List<String> _tabs = ["All", "Active", "Inactive"];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEmployeeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployeeData() async {
    setState(() => _isLoading = true);
    final data = await _api.getActiveEmployees();
    setState(() {
      _employees = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchController.text.trim().toLowerCase();
    final List<EmployeeModel> filteredList = _employees.where((emp) {
      final matchTab = _selectedTabIndex == 1
          ? emp.isActive
          : _selectedTabIndex == 2
              ? !emp.isActive
              : true;
      final matchSearch = query.isEmpty ||
          emp.name.toLowerCase().contains(query) ||
          emp.userName.toLowerCase().contains(query);
      return matchTab && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 24),
                  _buildTabSection(),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 24),
                  _buildTableCard(filteredList),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Employee List",
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1D1F))),
        ElevatedButton.icon(
          onPressed: widget.onAddEmployee,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B00),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.add, size: 20),
          label: const Text("Add Employee"),
        ),
      ],
    );
  }

  Widget _buildTabSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          color: isSelected
                              ? const Color(0xFFFF6B00)
                              : Colors.transparent,
                          width: 2)),
                ),
                child: Text(_tabs[index],
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFFFF6B00)
                            : Colors.grey[600])),
              ),
            );
          }),
        ),
        Text("Total Employees: ${_employees.length}",
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTableCard(List<EmployeeModel> displayList) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          _buildSearchAndFilterBar(),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor:
                  MaterialStateProperty.all(Colors.grey.shade50),
              dataRowHeight: 70,
              columns: [
                _dataColumn("SL"),
                _dataColumn("EMPLOYEE NAME"),
                _dataColumn("USERNAME"),
                _dataColumn("MOBILE NO"),
                _dataColumn("STATUS"),
                _dataColumn("ACTION"),
              ],
              rows: List.generate(displayList.length, (index) {
                final emp = displayList[index];
                return DataRow(cells: [
                  DataCell(Text("${index + 1}")),
                  DataCell(Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emp.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(emp.emailId,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 11)),
                    ],
                  )),
                  DataCell(Text(emp.userName,
                      style: const TextStyle(fontSize: 13))),
                  DataCell(Text(emp.mobileNo,
                      style: const TextStyle(fontSize: 13))),
                  DataCell(_buildCustomSwitch(emp.isActive)),
                  DataCell(_buildActionMenu(emp)),
                ]);
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// 3-dot popup menu → "View Permissions" navigates to ModulePermissionScreen
  Widget _buildActionMenu(EmployeeModel emp) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      onSelected: (value) {
        if (value == 'view_permissions') {
          // ── Navigate to Assign Module Permissions with employee pre-filled ──
          widget.onViewPermissions?.call(emp);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view_permissions',
          child: Row(
            children: const [
              Icon(Icons.shield_outlined, size: 18, color: Color(0xFFFF6B00)),
              SizedBox(width: 10),
              Text("View Permissions",
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  DataColumn _dataColumn(String label) {
    return DataColumn(
        label: Text(label,
            style:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)));
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Search by name...",
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download),
            label: const Text("Download"),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSwitch(bool isActive) {
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: isActive,
        activeTrackColor: const Color(0xFFFF6B00),
        activeColor: Colors.white,
        thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
            (states) => states.contains(MaterialState.selected)
                ? const Icon(Icons.check, color: Color(0xFFFF6B00))
                : null),
        onChanged: (val) {},
      ),
    );
  }
}