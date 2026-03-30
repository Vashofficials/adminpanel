import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/data_models.dart';
import '../widgets/custom_center_dialog.dart';

class ServiceTimingManagementScreen extends StatefulWidget {
  const ServiceTimingManagementScreen({super.key});

  @override
  State<ServiceTimingManagementScreen> createState() => _ServiceTimingManagementScreenState();
}

class _ServiceTimingManagementScreenState extends State<ServiceTimingManagementScreen> {
  final ApiService _api = ApiService();

  List<ServiceTimingModel> _serviceTimings = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  final TextEditingController _searchCtrl = TextEditingController();
  final Color _primaryOrange = const Color(0xFFEF7822);
  final Color _bgGrey = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _api.getCategories();
      final timings = await _api.getServiceTimings();
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _serviceTimings = timings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getCategoryName(String categoryId) {
    final cat = _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => CategoryModel(id: '', name: 'Unknown Category', isActive: false),
    );
    return cat.name;
  }

  void _showAddDialog() {
    String? selectedCategoryId;
    TimeOfDay? selectedStartTime;
    TimeOfDay? selectedEndTime;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            Future<void> pickTime(bool isStart) async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                setDialogState(() {
                  if (isStart) {
                    selectedStartTime = picked;
                  } else {
                    selectedEndTime = picked;
                  }
                });
              }
            }

            Future<void> submit() async {
              if (selectedCategoryId == null || selectedStartTime == null || selectedEndTime == null) {
                CustomCenterDialog.show(
                  context,
                  title: "Selection Required",
                  message: "Please select a category, start time, and end time.",
                  type: DialogType.required,
                );
                return;
              }

              setDialogState(() => isSubmitting = true);

              final startStr = '${selectedStartTime!.hour.toString().padLeft(2, '0')}:${selectedStartTime!.minute.toString().padLeft(2, '0')}';
              final endStr = '${selectedEndTime!.hour.toString().padLeft(2, '0')}:${selectedEndTime!.minute.toString().padLeft(2, '0')}';

              bool success = await _api.addServiceTiming(
                selectedCategoryId!,
                startStr,
                endStr,
              );

              if (!mounted) return;
              setDialogState(() => isSubmitting = false);

              if (success) {
                Navigator.pop(ctx);
                _loadData();
                CustomCenterDialog.show(
                  context,
                  title: "Success",
                  message: "Service timing added successfully",
                  type: DialogType.success,
                );
              } else {
                CustomCenterDialog.show(
                  context,
                  title: "Error",
                  message: "Failed to add service timing.",
                  type: DialogType.error,
                );
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.white,
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time_filled, color: _primaryOrange),
                        const SizedBox(width: 10),
                        const Text("Add Service Timing", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 30),
                    
                    const Text("Select Category", style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() => selectedCategoryId = val);
                      },
                      hint: const Text("Select Category"),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Start Time", style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => pickTime(true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    border: Border.all(color: Colors.grey[400]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(selectedStartTime != null 
                                          ? selectedStartTime!.format(context) 
                                          : "Select Time",
                                          style: TextStyle(color: selectedStartTime != null ? Colors.black87 : Colors.grey)
                                      ),
                                      const Icon(Icons.schedule, color: Colors.grey, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("End Time", style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => pickTime(false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    border: Border.all(color: Colors.grey[400]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(selectedEndTime != null 
                                          ? selectedEndTime!.format(context) 
                                          : "Select Time",
                                          style: TextStyle(color: selectedEndTime != null ? Colors.black87 : Colors.grey)
                                      ),
                                      const Icon(Icons.schedule, color: Colors.grey, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isSubmitting ? null : submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: isSubmitting 
                               ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                               : const Text("Add", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(ServiceTimingModel timing) {
    TimeOfDay parseTime(String t) {
      if (t.isEmpty) return const TimeOfDay(hour: 0, minute: 0);
      try {
        final parts = t.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) {
        return const TimeOfDay(hour: 0, minute: 0);
      }
    }

    TimeOfDay? selectedStartTime = parseTime(timing.startTime);
    TimeOfDay? selectedEndTime = parseTime(timing.endTime);
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            Future<void> pickTime(bool isStart) async {
              final picked = await showTimePicker(
                context: context,
                initialTime: isStart ? selectedStartTime! : selectedEndTime!,
              );
              if (picked != null) {
                setDialogState(() {
                  if (isStart) {
                    selectedStartTime = picked;
                  } else {
                    selectedEndTime = picked;
                  }
                });
              }
            }

            Future<void> submit() async {
              if (selectedStartTime == null || selectedEndTime == null) {
                CustomCenterDialog.show(
                  context,
                  title: "Selection Required",
                  message: "Please select start time and end time.",
                  type: DialogType.required,
                );
                return;
              }

              setDialogState(() => isSubmitting = true);

              final startStr = '${selectedStartTime!.hour.toString().padLeft(2, '0')}:${selectedStartTime!.minute.toString().padLeft(2, '0')}';
              final endStr = '${selectedEndTime!.hour.toString().padLeft(2, '0')}:${selectedEndTime!.minute.toString().padLeft(2, '0')}';

              bool success = await _api.updateServiceTiming(
                timing.serviceTimingId,
                startStr,
                endStr,
              );

              if (!mounted) return;
              setDialogState(() => isSubmitting = false);

              if (success) {
                Navigator.pop(ctx);
                _loadData();
                CustomCenterDialog.show(
                  context,
                  title: "Success",
                  message: "Service timing updated successfully",
                  type: DialogType.success,
                );
              } else {
                CustomCenterDialog.show(
                  context,
                  title: "Error",
                  message: "Failed to update service timing.",
                  type: DialogType.error,
                );
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.white,
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit, color: _primaryOrange),
                        const SizedBox(width: 10),
                        const Text("Edit Service Timing", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 30),
                    
                    const Text("Category", style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_getCategoryName(timing.categoryId), style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Start Time", style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => pickTime(true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    border: Border.all(color: Colors.grey[400]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(selectedStartTime != null 
                                          ? selectedStartTime!.format(context) 
                                          : "Select Time",
                                          style: TextStyle(color: selectedStartTime != null ? Colors.black87 : Colors.grey)
                                      ),
                                      const Icon(Icons.schedule, color: Colors.grey, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("End Time", style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => pickTime(false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    border: Border.all(color: Colors.grey[400]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(selectedEndTime != null 
                                          ? selectedEndTime!.format(context) 
                                          : "Select Time",
                                          style: TextStyle(color: selectedEndTime != null ? Colors.black87 : Colors.grey)
                                      ),
                                      const Icon(Icons.schedule, color: Colors.grey, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isSubmitting ? null : submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: isSubmitting 
                               ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                               : const Text("Save", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.toLowerCase();
    final filtered = _serviceTimings.where((timing) {
      final catName = _getCategoryName(timing.categoryId).toLowerCase();
      return catName.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: _bgGrey,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Head Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: _primaryOrange),
                      const SizedBox(width: 8),
                      const Text("Manage Service Time", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    label: const Text("Add New", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // List Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.list_alt, color: _primaryOrange),
                            const SizedBox(width: 8),
                            const Text("Service Timing List", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(
                          width: 250,
                          height: 40,
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (val) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: "Search by Category",
                              prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  _isLoading
                      ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            if (filtered.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40.0),
                                  child: Text("No service timings found.", style: TextStyle(color: Colors.grey, fontSize: 14)),
                                ),
                              );
                            }

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: DataTable(
                                    horizontalMargin: 24,
                                    columnSpacing: 20,
                                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF9F9F9)),
                                    columns: [
                                      DataColumn(label: Text("SL", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                                      DataColumn(label: Text("CATEGORY NAME", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                                      DataColumn(label: Text("START TIME", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                                      DataColumn(label: Text("END TIME", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                                      DataColumn(label: Text("ACTION", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                                    ],
                                    rows: List<DataRow>.generate(filtered.length, (index) {
                                      final timing = filtered[index];
                                      return DataRow(
                                        cells: [
                                          DataCell(Text("${index + 1}")),
                                          DataCell(Text(_getCategoryName(timing.categoryId), style: const TextStyle(fontWeight: FontWeight.w500))),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(12)),
                                              child: Text(timing.startTime, style: const TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.bold, fontSize: 12)),
                                            )
                                          ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(color: const Color(0xFFFFEDD5), borderRadius: BorderRadius.circular(12)),
                                              child: Text(timing.endTime, style: const TextStyle(color: Color(0xFFC2410C), fontWeight: FontWeight.bold, fontSize: 12)),
                                            )
                                          ),
                                          DataCell(
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                              onPressed: () => _showEditDialog(timing),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
