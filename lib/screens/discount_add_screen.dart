import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/data_models.dart'; 
import '../widgets/custom_center_dialog.dart'; 
import '../widgets/searchable_selection_sheet.dart'; // Ensure this path is correct

class AddDiscountScreen extends StatefulWidget {
  const AddDiscountScreen({super.key});

  @override
  State<AddDiscountScreen> createState() => _AddDiscountScreenState();
}

class _AddDiscountScreenState extends State<AddDiscountScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Data State
  List<CategoryModel> _categories = [];
  List<ServiceModel> _services = [];
  bool _isLoadingData = false;
  bool _isSubmitting = false;

  // Form State
  String _discountType = 'percentage'; 
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Selected Objects (for display in UI)
  CategoryModel? _selectedCategory;
  ServiceModel? _selectedService; 
  bool _isAllServicesSelected = false; // Flag for 'All Services' option

  // Controllers
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _minPurchaseController = TextEditingController();
  final _maxDiscountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // --- Data Loading ---
  Future<void> _loadCategories() async {
    setState(() => _isLoadingData = true);
    try {
      final data = await _api.getCategories();
      if (mounted) {
        setState(() {
          _categories = data;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
      print("Error loading categories: $e");
    }
  }

  Future<void> _loadServices(String categoryId) async {
    setState(() {
      _isLoadingData = true;
      _services = [];
      _selectedService = null;
      _isAllServicesSelected = false;
    });
    try {
      final data = await _api.getServices(categoryId: categoryId);
      if (mounted) {
        setState(() {
          _services = data;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
      print("Error loading services: $e");
    }
  }

  // --- Selection Logic ---
  void _openCategorySelection() {
    SearchableSelectionSheet.show(
      context,
      title: "Select Category",
      items: _categories.map((cat) => SelectionItem(
        id: cat.id, 
        title: cat.name,
        icon: Icons.category_outlined
      )).toList(),
      onItemSelected: (id) {
        final cat = _categories.firstWhere((c) => c.id == id);
        setState(() {
          _selectedCategory = cat;
        });
        _loadServices(cat.id);
      },
    );
  }

  void _openServiceSelection() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a category first")));
      return;
    }

    // Build list including "All Services" option
    List<SelectionItem> items = [];
    if (_services.isNotEmpty) {
      items.add(SelectionItem(
        id: 'all', 
        title: "All Services in ${_selectedCategory!.name}", 
        icon: Icons.done_all,
        subtitle: "Apply discount to all services"
      ));
    }
    items.addAll(_services.map((s) => SelectionItem(
      id: s.id, 
      title: s.name,
      subtitle: "Price: \$${s.price}",
      icon: Icons.design_services_outlined
    )));

    SearchableSelectionSheet.show(
      context,
      title: "Select Service",
      items: items,
      onItemSelected: (id) {
        setState(() {
          if (id == 'all') {
            _isAllServicesSelected = true;
            _selectedService = null;
          } else {
            _isAllServicesSelected = false;
            _selectedService = _services.firstWhere((s) => s.id == id);
          }
        });
      },
    );
  }

  // --- Submit Logic ---
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select start and end dates")));
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a category")));
      return;
    }

    // Determine target services
    List<ServiceModel> targetServices = [];
    if (_isAllServicesSelected) {
      targetServices = _services;
    } else if (_selectedService != null) {
      targetServices = [_selectedService!];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a service")));
      return;
    }

    setState(() => _isSubmitting = true);

    int successCount = 0;
    int failCount = 0;

    for (var service in targetServices) {
      double finalPercent = 0.0;
      double inputAmount = double.tryParse(_amountController.text) ?? 0.0;

      if (_discountType == 'fixed') {
        if (service.price > 0) {
          finalPercent = (inputAmount / service.price) * 100;
        } else {
          finalPercent = 0;
        }
      } else {
        finalPercent = inputAmount;
      }

      if (finalPercent > 100) finalPercent = 100;

      bool success = await _api.addServiceDiscount(
        serviceId: service.id,
        discountPercentage: finalPercent,
        startDate: _startDate!,
        endDate: _endDate!,
      );

      if (success) successCount++;
      else failCount++;
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (failCount == 0) {
        CustomCenterDialog.show(
          context,
          title: "Success",
          message: "Discount added to $successCount services successfully!",
          type: DialogType.success,
        );
        _resetForm();
      } else {
        CustomCenterDialog.show(
          context,
          title: "Partial Success",
          message: "Succeeded: $successCount, Failed: $failCount",
          type: DialogType.warning,
        );
      }
    }
  }

  void _resetForm() {
    _titleController.clear();
    _amountController.clear();
    _minPurchaseController.clear();
    _maxDiscountController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedService = null;
      _isAllServicesSelected = false;
      _services = [];
      _startDate = null;
      _endDate = null;
    });
  }

  // --- UI Helpers ---
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Custom Input Decoration for standard fields
  InputDecoration _buildInputDecoration({String? hintText, IconData? prefixIcon, String? prefixText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.grey, size: 20)
          : prefixText != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 14.0, bottom: 14.0),
                  child: Text(prefixText, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                )
              : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEB5725))),
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
      filled: true,
      fillColor: Colors.white,
    );
  }

  // Custom Selection Input (Looks like a TextField but is clickable)
  Widget _buildSelectionInput({
    required String label,
    required String placeholder,
    required VoidCallback onTap,
    required String? value,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired: true),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                if (isLoading) 
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                else 
                  Icon(Icons.arrow_drop_down_circle_outlined, color: Colors.grey.shade600, size: 20),
                
                const SizedBox(width: 10),
                
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: TextStyle(
                      fontSize: 14, 
                      color: value == null ? Colors.grey : Colors.black87
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        children: [if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
      ),
    );
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
            // Header
            const Text(
              'Add New Discount',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            const Text('Create a new discount campaign for services.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // Form Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    _buildLabel('Discount Title', isRequired: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: _buildInputDecoration(hintText: 'e.g. Summer Sale 2025', prefixIcon: Icons.title),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Category & Services Row
                    LayoutBuilder(builder: (context, constraints) {
                      bool isWide = constraints.maxWidth > 600;
                      return Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Selection
                          Expanded(
                            flex: isWide ? 1 : 0,
                            child: _buildSelectionInput(
                              label: "Select Category",
                              placeholder: "Choose a category...",
                              isLoading: _isLoadingData && _categories.isEmpty,
                              value: _selectedCategory?.name,
                              onTap: _openCategorySelection,
                            ),
                          ),
                          if (isWide) const SizedBox(width: 24) else const SizedBox(height: 20),
                          
                          // Service Selection
                          Expanded(
                            flex: isWide ? 1 : 0,
                            child: _buildSelectionInput(
                              label: "Select Services",
                              placeholder: "Choose Service",
                              isLoading: _isLoadingData && _services.isEmpty && _selectedCategory != null,
                              value: _isAllServicesSelected 
                                  ? "All Services in Category" 
                                  : _selectedService?.name,
                              onTap: _openServiceSelection,
                            ),
                          ),
                        ],
                      );
                    }),
                    
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Discount Type Radio
                    _buildLabel('Discount amount type', isRequired: true),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'percentage',
                          groupValue: _discountType,
                          activeColor: const Color(0xFFEB5725),
                          onChanged: (val) => setState(() => _discountType = val!),
                        ),
                        const Text('Percentage (%)'),
                        const SizedBox(width: 24),
                        Radio<String>(
                          value: 'fixed',
                          groupValue: _discountType,
                          activeColor: const Color(0xFFEB5725),
                          onChanged: (val) => setState(() => _discountType = val!),
                        ),
                        const Text('Fixed Amount'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Amount, Start, End Dates
                    LayoutBuilder(builder: (context, constraints) {
                      return Wrap(
                        spacing: 24,
                        runSpacing: 20,
                        children: [
                          SizedBox(
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(_discountType == 'percentage' ? 'Amount (%)' : 'Amount (Fixed)', isRequired: true),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: _buildInputDecoration(
                                    hintText: '0', 
                                    prefixText: _discountType == 'percentage' ? '% ' : '\$ '
                                  ),
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Start Date', isRequired: true),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _selectDate(context, true),
                                  child: AbsorbPointer(
                                    child: TextFormField(
                                      controller: TextEditingController(
                                        text: _startDate == null ? '' : DateFormat('MM/dd/yyyy').format(_startDate!),
                                      ),
                                      decoration: _buildInputDecoration(hintText: 'Select', prefixIcon: Icons.calendar_today),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('End Date', isRequired: true),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _selectDate(context, false),
                                  child: AbsorbPointer(
                                    child: TextFormField(
                                      controller: TextEditingController(
                                        text: _endDate == null ? '' : DateFormat('MM/dd/yyyy').format(_endDate!),
                                      ),
                                      decoration: _buildInputDecoration(hintText: 'Select', prefixIcon: Icons.calendar_today),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 30),

                    // Submit Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEB5725),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: _isSubmitting 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}