import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import '../models/module_model.dart';
import '../services/api_service.dart';
import '../widgets/searchable_selection_sheet.dart';
import '../widgets/custom_center_dialog.dart';

class ModulePermissionScreen extends StatefulWidget {
  /// When provided, the screen opens pre-loaded with this employee's
  /// existing permissions already fetched and checked.
  final EmployeeModel? preSelectedEmployee;

  const ModulePermissionScreen({super.key, this.preSelectedEmployee});

  @override
  State<ModulePermissionScreen> createState() => _ModulePermissionScreenState();
}

class _ModulePermissionScreenState extends State<ModulePermissionScreen> {
  final ApiService _api = ApiService();

  // Selection State
  EmployeeModel? _selectedEmployee;
  final List<String> _selectedModuleIds = [];

  // Data Lists
  List<ModuleModel> _allModules = [];
  List<EmployeeModel> _allEmployees = [];

  // Loading States
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingPermissions = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _api.fetchModules(),
      _api.getActiveEmployees(),
    ]);
    if (!mounted) return;
    setState(() {
      _allModules = results[0] as List<ModuleModel>;
      _allEmployees = results[1] as List<EmployeeModel>;
      _isLoading = false;
    });

    // If navigated from Employee List with a pre-selected employee,
    // auto-load their permissions immediately after modules are ready.
    if (widget.preSelectedEmployee != null) {
      _selectedEmployee = widget.preSelectedEmployee;
      _loadEmployeePermissions(_selectedEmployee!.id);
    }
  }

  /// Calls GET /admin/getAdminUserPermission?adminUserId=...
  /// and pre-checks modules that are currently active for this user.
  Future<void> _loadEmployeePermissions(String adminUserId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingPermissions = true;
      _selectedModuleIds.clear();
    });

    try {
      final permissions = await _api.getAdminUserPermission(adminUserId);

      final activeIdentifiers = permissions
          .where((p) => p.isActive)
          .map((p) => p.moduleIdentifier)
          .toSet();

      final matchedIds = _allModules
          .where((m) => activeIdentifiers.contains(m.moduleIdentifier))
          .map((m) => m.id)
          .toList();

      if (mounted) {
        setState(() {
          _selectedModuleIds.addAll(matchedIds);
          _isLoadingPermissions = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPermissions = false);
      debugPrint("Error loading employee permissions: $e");
    }
  }

  void _openEmployeeSelector() {
    final selectionItems = _allEmployees
        .map((e) => SelectionItem(
              id: e.id,
              title: e.name,
              subtitle: e.userName,
              icon: Icons.person_search,
            ))
        .toList();

    SearchableSelectionSheet.show(
      context,
      title: "Select Employee",
      items: selectionItems,
      primaryColor: const Color(0xFFFF6B00),
      onItemSelected: (id) {
        final employee = _allEmployees.firstWhere((e) => e.id == id);
        setState(() => _selectedEmployee = employee);
        _loadEmployeePermissions(employee.id);
      },
    );
  }

  Future<void> _savePermissions() async {
    if (_selectedEmployee == null) {
      CustomCenterDialog.show(context,
          title: "Selection Required",
          message: "Please select an employee first.",
          type: DialogType.required);
      return;
    }

    setState(() => _isSaving = true);
    bool success = await _api.addAdminPermission(
      userId: _selectedEmployee!.id,
      moduleIds: _selectedModuleIds,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        CustomCenterDialog.show(context,
            title: "Success",
            message: "Permissions updated for ${_selectedEmployee!.name}",
            type: DialogType.success);
      } else {
        CustomCenterDialog.show(context,
            title: "Error",
            message: "Failed to update permissions",
            type: DialogType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text("Assign Module Permissions",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Employee Selector Card
                  _buildEmployeeSelector(),
                  const SizedBox(height: 24),

                  // 2. Module List Header
                  Row(
                    children: [
                      const Text("Select Accessible Modules",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      if (_isLoadingPermissions) ...[
                        const SizedBox(width: 12),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFFF6B00)),
                        ),
                        const SizedBox(width: 8),
                        Text("Loading permissions...",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. Module Checklist
                  Expanded(child: _buildModuleChecklist()),

                  // 4. Save Button
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildEmployeeSelector() {
    // If pre-selected via navigation, make the card non-tappable (read-only header)
    // unless the user wants to change it by tapping.
    return InkWell(
      onTap: _openEmployeeSelector,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFFFF2E1),
              child: Icon(Icons.badge, color: Color(0xFFFF6B00)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedEmployee?.name ?? "Click to select Employee",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    _selectedEmployee?.userName ??
                        "Select the user to assign modules",
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down_circle_outlined,
                color: Color(0xFFFF6B00)),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleChecklist() {
    if (_isLoadingPermissions) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        itemCount: _allModules.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final module = _allModules[index];
          final isSelected = _selectedModuleIds.contains(module.id);

          return CheckboxListTile(
            activeColor: const Color(0xFFFF6B00),
            title: Text(module.moduleName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(module.moduleIdentifier,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            value: isSelected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedModuleIds.add(module.id);
                } else {
                  _selectedModuleIds.remove(module.id);
                }
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24),
      child: ElevatedButton(
        onPressed: (_isSaving || _isLoadingPermissions) ? null : _savePermissions,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B00),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Save Permissions",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}