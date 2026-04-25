import 'package:flutter/material.dart';
import '../models/module_model.dart';
import '../services/api_service.dart';
import '../widgets/custom_center_dialog.dart';

class EmployeeRoleListScreen extends StatefulWidget {
  final VoidCallback? onAddRole;
  final VoidCallback? onEditRole;
  const EmployeeRoleListScreen({super.key, this.onAddRole, this.onEditRole});

  @override
  State<EmployeeRoleListScreen> createState() => _EmployeeRoleListScreenState();
}

class _EmployeeRoleListScreenState extends State<EmployeeRoleListScreen> {
  final ApiService _api = ApiService();

  // Module Form State
  final TextEditingController _moduleNameCtrl = TextEditingController();
  final TextEditingController _moduleIdCtrl = TextEditingController();
  bool _isAddingModule = false;

  // List State
  List<ModuleModel> _modules = [];
  bool _isLoadingModules = true;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    setState(() => _isLoadingModules = true);
    final data = await _api.fetchModules();
    setState(() {
      _modules = data;
      _isLoadingModules = false;
    });
  }

  Future<void> _submitModule() async {
    if (_moduleNameCtrl.text.isEmpty || _moduleIdCtrl.text.isEmpty) {
      CustomCenterDialog.show(context,
          title: "Required",
          message: "Please fill all fields",
          type: DialogType.required);
      return;
    }

    setState(() => _isAddingModule = true);
    bool success =
        await _api.addModule(_moduleNameCtrl.text, _moduleIdCtrl.text);

    if (mounted) {
      setState(() => _isAddingModule = false);
      if (success) {
        CustomCenterDialog.show(context,
            title: "Success",
            message: "Module added successfully",
            type: DialogType.success);
        _moduleNameCtrl.clear();
        _moduleIdCtrl.clear();
        _loadModules();
      } else {
        CustomCenterDialog.show(context,
            title: "Error",
            message: "Failed to add module",
            type: DialogType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildModuleSetupCard(),
            const SizedBox(height: 24),
            _buildModuleTableCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleSetupCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Module Setup",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                  child: _buildTextField(
                      "Module Name", _moduleNameCtrl, "e.g. Booking Management")),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildTextField("Identifier", _moduleIdCtrl,
                      "e.g. booking_management")),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _isAddingModule ? null : _submitModule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isAddingModule
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("Add Module",
                        style: TextStyle(color: Colors.white)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildModuleTableCard() {
    return Container(
      width: double.infinity, // Force card to full width
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text("Module List",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          _isLoadingModules
              ? const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF6B00))))
              : LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(const Color(0xFFF9F9F9)),
                        dataRowMaxHeight: 70, // Slightly taller rows for better breathing room
                        horizontalMargin: 20,
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text("SL", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("MODULE NAME", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("IDENTIFIER", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("ACTION", style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: List.generate(_modules.length, (index) {
                          final m = _modules[index];
                          return DataRow(cells: [
                            DataCell(Text("${index + 1}")),
                            DataCell(Text(m.moduleName,
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF202224)))),
                            DataCell(Text(m.moduleIdentifier,
                                style: TextStyle(color: Colors.grey.shade600))),
                            DataCell(_buildCustomSwitch(m.isActive)),
                            DataCell(Row(
                              children: [
                                _buildActionButton(Icons.edit_outlined, const Color(0xFFFFCC99)),
                                const SizedBox(width: 8),
                                _buildActionButton(Icons.delete_outline, const Color(0xFFFFCDD2)),
                              ],
                            )),
                          ]);
                        }),
                      ),
                    ),
                  );
                }),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF5F6FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, Color borderColor) {
    Color iconColor = icon == Icons.delete_outline
        ? Colors.red.shade400
        : const Color(0xFFFF6B00);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Icon(icon, size: 18, color: iconColor),
    );
  }

  Widget _buildCustomSwitch(bool isActive) {
    return Transform.scale(
      scale: 0.8, // Make the switch look more modern and proportional
      child: Switch(
        value: isActive,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFFFF6B00),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.shade300,
        onChanged: (val) {
          // Toggle logic here
        },
      ),
    );
  }
}