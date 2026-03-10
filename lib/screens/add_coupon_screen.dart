import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/data_models.dart';
import '../widgets/custom_center_dialog.dart';

class AddCouponScreen extends StatefulWidget {
  const AddCouponScreen({super.key});

  @override
  State<AddCouponScreen> createState() => _AddCouponScreenState();
}

class _AddCouponScreenState extends State<AddCouponScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Data Lists
  List<CategoryModel> _categories = [];
  List<ServiceModel> _services = [];

  // Selections
  String? _selectedCatId;
  final List<ServiceModel> _selectedServiceObjects = []; 

  // Form State
  String _discountType = 'PERCENTAGE';
  DateTime? _startDate = DateTime.now();
  DateTime? _endDate = DateTime.now().add(const Duration(days: 7));

  // Controllers
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  final _minPurchaseController = TextEditingController();
  final _limitUserController = TextEditingController(); // Hint only, no default "1"

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // --- Logic & Data Fetching ---

  Future<void> _loadCategories() async {
    final data = await _api.getCategories();
    setState(() => _categories = data);
  }

Future<void> _loadServices(String catId) async {
    setState(() {
      _selectedCatId = catId;
      // We no longer need to fetch services for the coupon payload
    });
  }

 Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  if (_selectedCatId == null) {
      CustomCenterDialog.show(context, 
        title: "Selection Required", 
        message: "Please select a category.", 
        type: DialogType.required
      );
      return;
    }

    setState(() => _isSubmitting = true);

    bool success = await _api.addCoupon(
      categoryId: _selectedCatId!, // Directly passing the ID string
      couponType: "PROMO",
      couponCode: _codeController.text.trim().toUpperCase(),
      discountType: _discountType,
      startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
      amount: _discountType == 'FIXED' ? (double.tryParse(_amountController.text) ?? 0) : 0,
      discountPercentage: _discountType == 'PERCENTAGE' ? (double.tryParse(_amountController.text) ?? 0) : 0,
      minPurchaseAmount: double.tryParse(_minPurchaseController.text) ?? 0,
      sameUserLimit: int.tryParse(_limitUserController.text) ?? 1,
    );

    setState(() => _isSubmitting = false);
  
  if (success) {
    CustomCenterDialog.show(context, title: "Success", message: "Coupon created successfully!", type: DialogType.success);
    _resetForm();
  } else {
    CustomCenterDialog.show(context, title: "Error", message: "Server rejected the request. Please check the console.", type: DialogType.error);
  }
}

  void _resetForm() {
    _formKey.currentState?.reset();
    _codeController.clear();
    _amountController.clear();
    _minPurchaseController.clear();
    _limitUserController.clear();
    setState(() {
      _selectedServiceObjects.clear();
      _selectedCatId = null;
      _services = [];
    });
  }

  // --- Service Picker Dialog ---

  void _openServicePicker() {
    if (_selectedCatId == null) {
      CustomCenterDialog.show(context, title: "Category Needed", message: "Select a category first to see available services.", type: DialogType.info);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Select Services (${_services.length})"),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: SizedBox(
              width: 450,
              height: 400,
              child: _services.isEmpty 
                ? const Center(child: CircularProgressIndicator()) 
                : ListView.separated(
                    itemCount: _services.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      final isPicked = _selectedServiceObjects.any((s) => s.id == service.id);
                      return CheckboxListTile(
                        activeColor: const Color(0xFFEB5725),
                        title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text("Price: ₹${service.price}", style: const TextStyle(color: Colors.grey)),
                        value: isPicked,
                        onChanged: (val) {
                          setState(() { 
                            val == true 
                                ? _selectedServiceObjects.add(service) 
                                : _selectedServiceObjects.removeWhere((s) => s.id == service.id);
                          });
                          setDialogState(() {}); 
                        },
                      );
                    },
                  ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Confirm Selection", style: TextStyle(color: Color(0xFFEB5725), fontWeight: FontWeight.bold))),
            ],
          );
        },
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
            _buildHeader(),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    _buildRow([
                      _buildField("Coupon Code", TextFormField(controller: _codeController, decoration: _buildDecoration("e.g. RELAX20"))),
                      _buildField("Usage Limit", TextFormField(controller: _limitUserController, keyboardType: TextInputType.number, decoration: _buildDecoration("Max uses per customer", isHintOnly: true))),
                    ]),
                    const SizedBox(height: 24),
                    _buildRow([
                      _buildField("Select Category", DropdownButtonFormField<String>(
                        value: _selectedCatId,
                        items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (val) => _loadServices(val!),
                        decoration: _buildDecoration("Choose Category"),
                      )),
                    ]),
                    const Divider(height: 64),
                    _buildDiscountSection(),
                    const SizedBox(height: 24),
                    _buildRow([
                      _buildField("Start Date", _dateTile(true)),
                      _buildField("End Date", _dateTile(false)),
                    ]),
                    const SizedBox(height: 48),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Component Helpers ---

  Widget _buildField(String label, Widget child) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _buildServiceDisplayField() {
    return _buildField(
      "Selected Services (${_selectedServiceObjects.length})",
      GestureDetector(
        onTap: _openServicePicker,
        child: CustomPaint(
          painter: DashedBorderPainter(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedServiceObjects.isEmpty 
                      ? "Tap to select services" 
                      : _selectedServiceObjects.map((s) => s.name).join(", "),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _selectedServiceObjects.isEmpty ? Colors.grey : Colors.black87, fontSize: 14),
                  ),
                ),
                const Icon(Icons.add_box_outlined, size: 22, color: Color(0xFFEB5725)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Discount Type", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              Row(
                children: [
                  Radio<String>(value: 'PERCENTAGE', groupValue: _discountType, activeColor: const Color(0xFFEB5725), onChanged: (v) => setState(() => _discountType = v!)),
                  const Text("Percentage"),
                  const SizedBox(width: 12),
                  Radio<String>(value: 'FIXED', groupValue: _discountType, activeColor: const Color(0xFFEB5725), onChanged: (v) => setState(() => _discountType = v!)),
                  const Text("Fixed Amount"),
                ],
              ),
            ],
          ),
        ),
        _buildField(_discountType == 'PERCENTAGE' ? "Percent %" : "Amount ₹", TextFormField(controller: _amountController, decoration: _buildDecoration("0"))),
        const SizedBox(width: 24),
        _buildField("Min Purchase ₹", TextFormField(controller: _minPurchaseController, decoration: _buildDecoration("0"))),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: _resetForm, child: const Text("Reset All", style: TextStyle(color: Colors.grey))),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEB5725),
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: _isSubmitting 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("Create Coupon", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  InputDecoration _buildDecoration(String hint, {bool isHintOnly = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w400),
      filled: true,
      fillColor: const Color(0xFFF8F9FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFEB5725), width: 1.5)),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Add New Coupon', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        SizedBox(height: 4),
        Text('Target your campaign to specific services.', style: TextStyle(color: Colors.blueGrey)),
      ],
    );
  }

  Widget _dateTile(bool isStart) {
    final date = isStart ? _startDate : _endDate;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: date!, firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (picked != null) setState(() => isStart ? _startDate = picked : _endDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFFF8F9FC), border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [const Icon(Icons.calendar_month_outlined, size: 18, color: Colors.grey), const SizedBox(width: 12), Text(DateFormat('yyyy-MM-dd').format(date!))]),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 3, startX = 0;
    final paint = Paint()
      ..color = const Color(0xFFEB5725).withOpacity(0.5) 
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    var path = Path();
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)));

    for (var pathMetric in path.computeMetrics()) {
      while (startX < pathMetric.length) {
        canvas.drawPath(pathMetric.extractPath(startX, startX + dashWidth), paint);
        startX += dashWidth + dashSpace;
      }
      startX = 0;
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}