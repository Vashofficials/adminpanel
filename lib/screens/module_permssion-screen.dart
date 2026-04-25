import 'package:flutter/material.dart';
import '../models/employee_model.dart'; // Ensure ModuleModel & EmployeeModel are here
import '../models/module_model.dart';
import '../services/api_service.dart';
import '../widgets/searchable_selection_sheet.dart';
import '../widgets/custom_center_dialog.dart';

class ModulePermissionScreen extends StatefulWidget {
  const ModulePermissionScreen({super.key});

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
  bool _isLoading = true;
  bool _isSaving = false;

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
    setState(() {
      _allModules = results[0] as List<ModuleModel>;
      _allEmployees = results[1] as List<EmployeeModel>;
      _isLoading = false;
    });
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
        setState(() {
          _selectedEmployee = _allEmployees.firstWhere((e) => e.id == id);
        });
      },
    );
  }

  Future<void> _savePermissions() async {
    if (_selectedEmployee == null || _selectedModuleIds.isEmpty) {
      CustomCenterDialog.show(context,
          title: "Selection Required",
          message: "Please select an employee and at least one module.",
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
            title: "Error", message: "Failed to update permissions", type: DialogType.error);
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
                  const Text("Select Accessible Modules",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // 3. Module Checklist
                  Expanded(child: _buildModuleChecklist()),

                  // 4. Action Button
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildEmployeeSelector() {
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
                  Text(_selectedEmployee?.name ?? "Click to select Employee",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(_selectedEmployee?.userName ?? "Select the user to assign modules",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down_circle_outlined, color: Color(0xFFFF6B00)),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleChecklist() {
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
        onPressed: _isSaving ? null : _savePermissions,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B00),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Save Permissions",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}