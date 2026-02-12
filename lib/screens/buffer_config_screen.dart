import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../repositories/buffer_repository.dart';
import '../models/buffer_time_model.dart';
import '../widgets/custom_center_dialog.dart';

class BufferConfigScreen extends StatefulWidget {
  const BufferConfigScreen({super.key});

  @override
  State<BufferConfigScreen> createState() => _BufferConfigScreenState();
}

class _BufferConfigScreenState extends State<BufferConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final BufferRepository _bufferRepo = BufferRepository();
  
  // Controllers
  final TextEditingController _distFromController = TextEditingController();
  final TextEditingController _distToController = TextEditingController();
  final TextEditingController _bufferBeforeController = TextEditingController();
  final TextEditingController _bufferAfterController = TextEditingController();

  bool _isSaving = false;
  bool _isLoadingList = true;
  List<BufferTimeModel> _bufferList = [];

  // EDIT STATE
  String? _editingId; // If null, we are adding. If set, we are updating.

  @override
  void initState() {
    super.initState();
    _fetchBufferList();
  }

  // --- DATA LOADING ---
  Future<void> _fetchBufferList() async {
    setState(() => _isLoadingList = true);
    final list = await _bufferRepo.getBufferList();
    if (mounted) {
      setState(() {
        _bufferList = list;
        _isLoadingList = false;
      });
    }
  }

  // --- SAVE / UPDATE ACTION ---
  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    bool success;
    
    // LOGIC SPLIT: Add vs Update
    if (_editingId == null) {
      // Create New
      success = await _bufferRepo.saveBufferSettings(
        distanceFrom: int.parse(_distFromController.text),
        distanceTo: int.parse(_distToController.text),
        bufferBefore: int.parse(_bufferBeforeController.text),
        bufferAfter: int.parse(_bufferAfterController.text),
      );
    } else {
      // Update Existing
      success = await _bufferRepo.updateBufferSettings(
        bufferTimeId: _editingId!,
        distanceFrom: int.parse(_distFromController.text),
        distanceTo: int.parse(_distToController.text),
        bufferBefore: int.parse(_bufferBeforeController.text),
        bufferAfter: int.parse(_bufferAfterController.text),
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      CustomCenterDialog.show(
        context,
        title: "Success",
        message: _editingId == null 
            ? "Buffer added successfully!" 
            : "Buffer updated successfully!",
        type: DialogType.success,
      );
      _clearFields();
      _fetchBufferList(); // Refresh list
    } else {
      CustomCenterDialog.show(
        context,
        title: "Error",
        message: "Failed to save. Please try again.",
        type: DialogType.error,
      );
    }
  }
void _onDeleteClick(String id) {
    CustomCenterDialog.show(
      context,
      title: "Delete Rule",
      message: "Are you sure you want to delete this buffer configuration?",
      type: DialogType.info,
      onConfirm: () async {
        // 1. Close the confirmation dialog

        // 2. Call API
        bool success = await _bufferRepo.deleteBufferSettings(id);

        if (success) {
          // 3. Clear form if we deleted the item currently being edited
          if (_editingId == id) {
            _clearFields();
          }

          // 4. Show Success Dialog
          if (mounted) {
            CustomCenterDialog.show(
              context,
              title: "Success",
              message: "Buffer rule deleted successfully",
              type: DialogType.success,
            );
          }

          // 5. RELOAD FROM SERVER (Get real data instead of local remove)
          _fetchBufferList(); 
          
        } else {
          if (mounted) {
            CustomCenterDialog.show(
              context,
              title: "Error",
              message: "Failed to delete rule",
              type: DialogType.error,
            );
          }
        }
      },
    );
  }
  Future<void> _handleStatusToggle(String id, bool newValue) async {
    // 1. Optimistic Update (Update UI immediately)
    setState(() {
      final index = _bufferList.indexWhere((item) => item.id == id);
      if (index != -1) {
        final old = _bufferList[index];
        _bufferList[index] = BufferTimeModel(
          id: old.id,
          distanceFrom: old.distanceFrom,
          distanceTo: old.distanceTo,
          bufferBefore: old.bufferBefore,
          bufferAfter: old.bufferAfter,
          isActive: newValue, // <--- Update Status
          //creationTime: old.creationTime, // Ensure this exists in your model
        );
      }
    });

    // 2. Call API
    bool success = await _bufferRepo.toggleStatus(id, newValue);

    // 3. Revert if failed
    if (!success) {
      _fetchBufferList(); // Refresh data to server state
      if (mounted) {
        CustomCenterDialog.show(
          context,
          title: "Error",
          message: "Failed to update status",
          type: DialogType.error,
        );
      }
    }
  }
  // --- EDIT ACTION ---
  void _onEditClick(BufferTimeModel item) {
    setState(() {
      _editingId = item.id; // Store ID to know we are editing
      _distFromController.text = item.distanceFrom.toString();
      _distToController.text = item.distanceTo.toString();
      _bufferBeforeController.text = item.bufferBefore.toString();
      _bufferAfterController.text = item.bufferAfter.toString();
    });
  }

  void _clearFields() {
    setState(() {
      _editingId = null; // Reset to "Add Mode"
      _distFromController.clear();
      _distToController.clear();
      _bufferBeforeController.clear();
      _bufferAfterController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = _editingId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Buffer Management", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -----------------------
          // LEFT: FORM SECTION
          // -----------------------
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? "Edit Configuration" : "Add New Configuration", 
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        if (isEditing) 
                          TextButton.icon(
                            onPressed: _clearFields,
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text("Cancel Edit"),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                          )
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel("Distance Range (km)"),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildInputField(_distFromController, "From (0)", Icons.near_me)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildInputField(_distToController, "To (5)", Icons.place)),
                            ],
                          ),
                          
                          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),
                          
                          _buildSectionLabel("Time Buffer (minutes)"),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildInputField(_bufferBeforeController, "Before Job", Icons.history)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildInputField(_bufferAfterController, "After Job", Icons.update)),
                            ],
                          ),

                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveConfiguration,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF97316),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _isSaving 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    isEditing ? "Update Rule" : "Save Rule", 
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // -----------------------
          // RIGHT: LIST SECTION
          // -----------------------
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.shade200))),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Active Configurations", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(onPressed: _fetchBufferList, icon: const Icon(Icons.refresh, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoadingList 
                      ? const Center(child: CircularProgressIndicator())
                      : _bufferList.isEmpty 
                        ? Center(child: Text("No configurations found", style: TextStyle(color: Colors.grey.shade500)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            itemCount: _bufferList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, index) => _buildBufferCard(_bufferList[index]),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildBufferCard(BufferTimeModel item) {
    bool isSelected = item.id == _editingId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? Colors.orange : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.route, color: Color(0xFFF97316)),
          ),
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${item.distanceFrom} - ${item.distanceTo} km", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _iconText(Icons.history, "${item.bufferBefore} min before"),
                    const SizedBox(width: 12),
                    _iconText(Icons.update, "${item.bufferAfter} min after"),
                  ],
                )
              ],
            ),
          ),
          // --- NEW: Toggle Switch ---
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: item.isActive, 
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFFF97316),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
              onChanged: (val) => _handleStatusToggle(item.id, val),
            ),
          ),
          const SizedBox(width: 8),
          // --------------------------
          
          // Edit Button
          IconButton(
            icon: Icon(Icons.edit, color: isSelected ? Colors.orange : Colors.grey),
            onPressed: () => _onEditClick(item),
            tooltip: "Edit this rule",
          ),
          IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _onDeleteClick(item.id),
                tooltip: "Delete",
              ),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)));
  }

  Widget _buildInputField(TextEditingController ctrl, String hint, IconData icon) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, size: 18, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
    );
  }
}