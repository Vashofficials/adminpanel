import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; 
import '../services/api_service.dart';
import '../models/data_models.dart';
import '../widgets/custom_center_dialog.dart';

class ServiceScreen extends StatefulWidget {
  final VoidCallback? onAddService;

  const ServiceScreen({super.key, this.onAddService});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  
  // Data
  List<ServiceModel> _services = [];
  List<CategoryModel> _categories = [];
  final Map<String, String> _serviceCategoryMap = {}; 

  bool _isLoading = true;
  String? _selectedFilterCategoryId; 
  
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  final Color _primaryOrange = const Color(0xFFEF7822);
  final Color _bgGrey = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Add listener to search controller to trigger rebuilds on typing
    _searchCtrl.addListener(_onSearchChanged);
    
    _loadAllData(); 
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.removeListener(_onSearchChanged); // Clean up listener
    _searchCtrl.dispose();
    super.dispose();
  }

  // Trigger rebuild when user types
  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final cats = await _api.getCategories();
      List<Future<List<ServiceModel>>> futures = [];
      for (var cat in cats) {
        futures.add(_api.getServices(categoryId: cat.id));
      }

      final results = await Future.wait(futures);
      
      List<ServiceModel> allServices = [];
      Map<String, String> tempMap = {};

      for (int i = 0; i < cats.length; i++) {
        var catName = cats[i].name;
        var categoryServices = results[i];
        
        for (var service in categoryServices) {
          allServices.add(service);
          tempMap[service.id] = catName; 
        }
      }

      if (mounted) {
        setState(() {
          _categories = cats;
          _services = allServices;
          _serviceCategoryMap.addAll(tempMap);
          _selectedFilterCategoryId = null; 
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading all data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategoryServices(String categoryId) async {
    setState(() => _isLoading = true);
    try {
      final svcs = await _api.getServices(categoryId: categoryId);
      String catName = _categories.firstWhere((c) => c.id == categoryId).name;
      for (var s in svcs) {
        _serviceCategoryMap[s.id] = catName;
      }

      if (mounted) {
        setState(() {
          _services = svcs;
          _selectedFilterCategoryId = categoryId;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading category services: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(ServiceModel service) async {
    setState(() => _isLoading = true);
    
    // Calculate the NEW status (flip the current one)
    bool targetStatus = !service.isActive;

    bool success = await _api.deleteService(service.id, isActive: targetStatus);

    if (success) {
      await _loadAllData(); // Reload to see changes
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Service ${targetStatus ? 'Activated' : 'Deactivated'} successfully"),
            backgroundColor: targetStatus ? Colors.green : Colors.grey,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update status")));
      }
    }
  }

  // --- Delete Logic (Explicitly Deactivates) ---
void _confirmDelete(ServiceModel service) {
    CustomCenterDialog.show(
      context,
      title: "Delete Service",
      message: "Are you sure you want to remove '${service.name}'?",
      type: DialogType.warning,
      confirmText: "Delete",
      cancelText: "Cancel",
      onConfirm: () async {
        // ❌ REMOVED: Navigator.pop(context); (Caused the white screen/double pop)
        
        // 1. Show Loading
        setState(() => _isLoading = true);

        // 2. Call API (Explicitly Deactivate)
        bool success = await _api.deleteService(service.id, isActive: false);

        // 3. Handle Result
        if (success) {
          await _loadAllData(); // Refresh list
          if (mounted) {
             CustomCenterDialog.show(
               context, 
               title: "Success", 
               message: "Service deleted successfully.", 
               type: DialogType.success
             );
          }
        } else {
          setState(() => _isLoading = false);
          if (mounted) {
            CustomCenterDialog.show(
              context, 
              title: "Error", 
              message: "Failed to delete service.", 
              type: DialogType.error
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- SEARCH FILTER LOGIC ---
    final searchText = _searchCtrl.text.trim().toLowerCase();
    
    final filteredServices = _services.where((s) {
      final name = s.name.toLowerCase();
      // Returns true if name contains the search text (or if search is empty)
      return name.contains(searchText);
    }).toList();

    return Scaffold(
      backgroundColor: _bgGrey,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Service List", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("Manage your services, track status, and update details.", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
                      // Shows count of FILTERED results
                      child: Text("Total Services: ${filteredServices.length}", style: TextStyle(color: _primaryOrange, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 15),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (widget.onAddService != null) widget.onAddService!(); 
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Add Service"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),

            // 2. Filter Bar
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
              child: Row(
                children: [
                  Icon(Icons.filter_list_alt, color: _primaryOrange, size: 22), 
                  const SizedBox(width: 15),
                  
                  // ENHANCED DROPDOWN
                  Expanded(
                    child: Container(
                      height: 40, 
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedFilterCategoryId == null ? Colors.grey[300]! : _primaryOrange.withOpacity(0.5)
                        )
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedFilterCategoryId,
                          icon: Icon(Icons.keyboard_arrow_down, color: _primaryOrange), 
                          isExpanded: true, 
                          style: const TextStyle(color: Colors.black87, fontSize: 14),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Row(
                                children: [
                                  if (_selectedFilterCategoryId == null) 
                                    Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: _primaryOrange, shape: BoxShape.circle)),
                                  const Text("All Categories", style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            ..._categories.map((cat) {
                              bool isSelected = _selectedFilterCategoryId == cat.id;
                              return DropdownMenuItem<String?>(
                                value: cat.id,
                                child: Text(
                                  cat.name, 
                                  style: TextStyle(
                                    color: isSelected ? _primaryOrange : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal
                                  )
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            // Clear search when switching categories for better UX
                            _searchCtrl.clear();
                            if (val == null) {
                              _loadAllData(); 
                            } else {
                              _loadCategoryServices(val); 
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 15),

                  // Search Box
                  Container(
                    width: 300,
                    height: 40,
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.transparent)),
                    child: TextField(
                      controller: _searchCtrl,
                      textAlignVertical: TextAlignVertical.center, 
                      decoration: const InputDecoration(
                        hintText: "Search services...",
                        prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(bottom: 8), 
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Table - FULL WIDTH IMPLEMENTATION
            Container(
              width: double.infinity, 
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: _isLoading 
                ? SizedBox(
                    height: 400,
                    child: Center(
                      child: CircularProgressIndicator(color: _primaryOrange),
                    ),
                  )
                // Check if filtered list is empty (could be because of search OR no data)
                : filteredServices.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(50), 
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 10),
                            Text(
                              _searchCtrl.text.isEmpty ? "No services found." : "No results for \"${_searchCtrl.text}\"",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        )
                      )
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              horizontalMargin: 24,
                              columnSpacing: 30, 
                              headingRowColor: MaterialStateProperty.all(const Color(0xFFF9F9F9)),
                              columns: [
                                DataColumn(label: Text("SL", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text("IMAGE", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text("NAME", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text("CATEGORY", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text("PRICE", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text("STATUS", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text("ACTION", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12))),
                              ],
                              // Use 'filteredServices' here instead of '_services'
                              rows: List<DataRow>.generate(filteredServices.length, (index) {
                                final svc = filteredServices[index];
                                String catName = _serviceCategoryMap[svc.id] ?? "Unknown";

                                return DataRow(
                                  cells: [
                                    DataCell(Text("${index + 1}")),
                                    
                                    // IMAGE
                                    DataCell(Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: _buildImage(svc.imgLink),
                                    )),
                                    
                                    // NAME
                                    DataCell(Text(svc.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                                    
                                    // CATEGORY
                                    DataCell(Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                                      child: Text(catName, style: TextStyle(color: Colors.blue[800], fontSize: 12)), 
                                    )),
                                    
                                    // PRICE
                                    DataCell(Text("₹ ${svc.price.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold))),
                                    
                                    // STATUS
DataCell(Switch(
                                    value: svc.isActive, 
                                    activeColor: _primaryOrange, 
                                    // Calls toggle to flip the status
                                    onChanged: (val) => _toggleStatus(svc),
                                  )),                                    
                                    // ACTION
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(8)
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min, 
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18), 
                                              onPressed: () {},
                                              constraints: const BoxConstraints(), 
                                              padding: const EdgeInsets.all(8),
                                            ),
                                            Container(width: 1, height: 20, color: Colors.grey[300]), 
                                            IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), 
                                          onPressed: () => _confirmDelete(svc),
                                        ),
                                          ],
                                        ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) return const Icon(Icons.broken_image, size: 24, color: Colors.grey);
    
    return SizedBox(
       height: 40,
       width: 40, 
       child: AspectRatio(
         aspectRatio: 1, 
         child: (url.toLowerCase().endsWith('.svg')) 
           ? SvgPicture.network(
               url, 
               fit: BoxFit.contain,
               placeholderBuilder: (_) => const Center(child: Padding(
                 padding: EdgeInsets.all(8.0),
                 child: CircularProgressIndicator(strokeWidth: 2),
               )),
             )
           : Image.network(
               url, 
               fit: BoxFit.contain,
               errorBuilder: (_,__,___) => const Icon(Icons.broken_image, size: 24, color: Colors.grey)
             ),
       ),
    );
  }
}