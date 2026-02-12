import 'package:flutter/material.dart';
// Import your service, model, and custom dialog here
import '../services/api_service.dart'; 
import '../models/discount_model.dart';
import '../widgets/custom_center_dialog.dart'; 

class DiscountListScreen extends StatefulWidget {
  final VoidCallback? onEditDiscount;
  const DiscountListScreen({super.key, this.onEditDiscount});

  @override
  State<DiscountListScreen> createState() => _DiscountListScreenState();
}

class _DiscountListScreenState extends State<DiscountListScreen> {
  final ApiService _apiService = ApiService(); 
  
  String _selectedTab = 'All';
  bool _isLoading = true;
  List<DiscountModel> _discountList = [];

  @override
  void initState() {
    super.initState();
    _fetchDiscounts();
  }

  Future<void> _fetchDiscounts() async {
    setState(() => _isLoading = true);
    final list = await _apiService.getAllDiscounts();
    if (mounted) {
      setState(() {
        _discountList = list;
        _isLoading = false;
      });
    }
  }

  // --- DELETE ACTION ---
void _handleDelete(String id) {
    CustomCenterDialog.show(
      context,
      title: "Deactivate Discount", // Changed title to reflect action
      message: "Are you sure you want to deactivate this discount?",
      type: DialogType.info,
      onConfirm: () async {

        // Call API (assuming deleteServiceDiscount handles the soft delete on server)
        bool success = await _apiService.deleteServiceDiscount(id, true);

        if (success) {
          setState(() {
            // --- UPDATED LOGIC: FIND AND UPDATE INSTEAD OF REMOVE ---
            final index = _discountList.indexWhere((item) => item.id == id);
            if (index != -1) {
              final oldItem = _discountList[index];
              // Create a new instance with isActive = false
              _discountList[index] = DiscountModel(
                id: oldItem.id,
                serviceId: oldItem.serviceId,
                serviceName: oldItem.serviceName,
                discountPercentage: oldItem.discountPercentage,
                startDate: oldItem.startDate,
                endDate: oldItem.endDate,
                isActive: false, // <--- Mark as inactive
              );
            }
          });

          if (mounted) {
            CustomCenterDialog.show(
              context,
              title: "Success",
              message: "Discount deactivated successfully",
              type: DialogType.success,
            );
          }
        } else {
          // ... error handling
        }
      },
    );
  }
  Future<void> _toggleStatus(String id, bool newValue) async {
    // 1. Optimistic Update: Update UI immediately for better UX
    setState(() {
      final index = _discountList.indexWhere((item) => item.id == id);
      if (index != -1) {
        final oldItem = _discountList[index];
        _discountList[index] = DiscountModel(
          id: oldItem.id,
          serviceId: oldItem.serviceId,
          serviceName: oldItem.serviceName,
          discountPercentage: oldItem.discountPercentage,
          startDate: oldItem.startDate,
          endDate: oldItem.endDate,
          isActive: newValue, // Update UI with new state
        );
      }
    });

    // 2. Call API
    // Logic based on your request: 
    // To make Active (newValue = true) -> Pass 'false' to delete API.
    // To make Inactive (newValue = false) -> Pass 'true' to delete API.
    bool apiParam = !newValue; 
    
    bool success = await _apiService.deleteServiceDiscount(id, apiParam);

    // 3. Revert if API fails
    if (!success) {
      // Re-fetch data to sync with server state
      _fetchDiscounts(); 
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Discounts',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 24),

            // --- Main List Card ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // --- Header ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildTab('All'),
                            const SizedBox(width: 24),
                            _buildTab('Service Wise'),
                            const SizedBox(width: 24),
                            _buildTab('Category Wise'),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Total Discount: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text('${_discountList.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),

                  // --- Search Bar ---
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                const Icon(Icons.search, color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Search by Service Name',
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _fetchDiscounts,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEB5725),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            elevation: 0,
                          ),
                          child: const Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        // Download button (visual only)
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download, size: 16, color: Colors.black87),
                          label: const Row(
                            children: [
                              Text('Download', style: TextStyle(color: Colors.black87, fontSize: 13)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down, size: 16, color: Colors.black87)
                            ],
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        )
                      ],
                    ),
                  ),

                  // --- Table Header ---
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    child: Row(
                      children: [
                        _buildHeaderCell('SL', flex: 1),
                        _buildHeaderCell('SERVICE NAME', flex: 4),
                        _buildHeaderCell('DISCOUNT %', flex: 2),
                        _buildHeaderCell('VALID UNTIL', flex: 2),
                        _buildHeaderCell('STATUS', flex: 2),
                        _buildHeaderCell('ACTION', flex: 2, alignRight: true),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // --- Dynamic List ---
                  if (_isLoading)
                    const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFFEB5725)))
                  else if (_discountList.isEmpty)
                    const Padding(padding: EdgeInsets.all(40), child: Text("No discounts found."))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _discountList.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      itemBuilder: (ctx, index) {
                        final item = _discountList[index];
                        // Simple date substring to remove time
                        String validUntil = item.endDate.length > 10 
                            ? item.endDate.substring(0, 10) 
                            : item.endDate;
                        
                        return _buildRow(
                          sl: '${index + 1}',
                          title: item.serviceName,
                          discount: '${item.discountPercentage}%',
                          date: validUntil,
                          isActive: item.isActive,
                          onDelete: () => _handleDelete(item.id),
                          onStatusChanged: (val) => _toggleStatus(item.id, val),
                        );
                      },
                    ),

                  // --- Footer ---
                  if (!_isLoading && _discountList.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Showing 1 to ${_discountList.length} of ${_discountList.length} results', 
                              style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          Row(
                            children: [
                              _buildPaginationBtn(Icons.chevron_left),
                              const SizedBox(width: 8),
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEB5725).withOpacity(0.1),
                                  border: Border.all(color: const Color(0xFFEB5725)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('1', style: TextStyle(color: Color(0xFFEB5725), fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              _buildPaginationBtn(Icons.chevron_right),
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

  // --- Helper Widgets ---

  Widget _buildTab(String title) {
    bool isActive = _selectedTab == title;
    return InkWell(
      onTap: () => setState(() => _selectedTab = title),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: isActive
              ? const Border(bottom: BorderSide(color: Color(0xFFEB5725), width: 2))
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFFEB5725) : const Color(0xFF64748B),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1, bool alignRight = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRow({
    required String sl,
    required String title,
    required String discount,
    required String date,
    required bool isActive,
    required VoidCallback onDelete,
    required Function(bool) onStatusChanged, // <--- 1. Add Parameter
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(sl, style: const TextStyle(fontSize: 13, color: Colors.black87))),
          Expanded(flex: 4, child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87))),
          Expanded(flex: 2, child: Text(discount, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
          Expanded(flex: 2, child: Text(date, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Transform.scale(
                scale: 0.7,
                alignment: Alignment.centerLeft,
                child: Switch(
                  value: isActive,
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFFEB5725),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                  onChanged: onStatusChanged,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: widget.onEditDiscount, 
                  child: _buildActionIcon(Icons.edit_outlined, const Color(0xFFEB5725)),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onDelete,
                  child: _buildActionIcon(Icons.delete_outline, const Color(0xFFEF4444)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildPaginationBtn(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 16, color: Colors.grey),
    );
  }
}