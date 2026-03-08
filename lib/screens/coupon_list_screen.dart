import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/coupon_model.dart';
import '../widgets/custom_center_dialog.dart';
import 'package:intl/intl.dart';

class CouponListScreen extends StatefulWidget {
  final Function()? onEditCoupon;
  const CouponListScreen({super.key, this.onEditCoupon});

  @override
  State<CouponListScreen> createState() => _CouponListScreenState();
}

class _CouponListScreenState extends State<CouponListScreen> {
  final ApiService _api = ApiService();
  List<CouponModel> _allCoupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getAllCoupons();
      debugPrint("📡 Fetched ${data.length} coupons from API");
      
      setState(() {
        _allCoupons = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ UI Error fetching coupons: $e");
      setState(() => _isLoading = false);
    }
  }
Future<void> _showUpdateCouponDialog(BuildContext context, CouponModel coupon) async {
  final codeCtrl = TextEditingController(text: coupon.couponCode);
  final amountCtrl = TextEditingController(text: coupon.discountType == 'PERCENTAGE' 
      ? coupon.discountPercentage.toString() 
      : coupon.amount.toString());
  final minPurchaseCtrl = TextEditingController(text: coupon.minPurchaseAmount.toString());
  final limitCtrl = TextEditingController(text: coupon.sameUserLimit.toString());

  String selectedDiscountType = coupon.discountType;
  DateTime startDate = coupon.startDate;
  DateTime endDate = coupon.endDate;
  bool isUpdating = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 550,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// HEADER
                    Row(
                      children: const [
                        Icon(Icons.edit_calendar, color: Color(0xFFEB5725)),
                        SizedBox(width: 8),
                        Text("Update Coupon Details",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 30),

                    Row(
                      children: [
                        Expanded(child: _buildPopupLabelField("Coupon Code", codeCtrl)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPopupLabelField("Limit per User", limitCtrl, isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    /// DISCOUNT TYPE
                    const Text("Discount Type", style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'PERCENTAGE',
                          groupValue: selectedDiscountType,
                          activeColor: const Color(0xFFEB5725),
                          onChanged: (val) => setDialogState(() => selectedDiscountType = val!),
                        ),
                        const Text("Percentage"),
                        const SizedBox(width: 12),
                        Radio<String>(
                          value: 'FIXED',
                          groupValue: selectedDiscountType,
                          activeColor: const Color(0xFFEB5725),
                          onChanged: (val) => setDialogState(() => selectedDiscountType = val!),
                        ),
                        const Text("Fixed Amount"),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: _buildPopupLabelField(selectedDiscountType == 'PERCENTAGE' ? "Percent %" : "Amount ₹", amountCtrl, isNumber: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPopupLabelField("Min Purchase ₹", minPurchaseCtrl, isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    /// DATES
                    Row(
                      children: [
                        Expanded(child: _buildPopupDatePicker("Start Date", startDate, (d) => setDialogState(() => startDate = d))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPopupDatePicker("End Date", endDate, (d) => setDialogState(() => endDate = d))),
                      ],
                    ),

                    const SizedBox(height: 30),

                    /// ACTION BUTTONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEB5725),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: isUpdating ? null : () async {
                            setDialogState(() => isUpdating = true);
                            
                            // PLACEHOLDER: Call your update API here
                            debugPrint("Updating Coupon ID: ${coupon.id}");
                            await Future.delayed(const Duration(seconds: 1)); // Simulate API
                            
                            setDialogState(() => isUpdating = false);
                            Navigator.pop(ctx);
                            _fetchCoupons(); // Refresh the list
                          },
                          child: isUpdating 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Update Coupon", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// --- Internal Helpers for the Dialog ---

Widget _buildPopupLabelField(String label, TextEditingController ctrl, {bool isNumber = false}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF64748B), fontSize: 12)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ],
  );
}

Widget _buildPopupDatePicker(String label, DateTime date, Function(DateTime) onPick) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF64748B), fontSize: 12)),
      const SizedBox(height: 6),
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null) onPick(picked);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(DateFormat('yyyy-MM-dd').format(date)),
            ],
          ),
        ),
      ),
    ],
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF8F9FC),
    body: _isLoading 
      ? const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFEB5725),
            strokeWidth: 3,
          ),
        )
      : SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                ),
                child: _allCoupons.isEmpty 
                  ? _buildEmptyState("No coupons found in database.")
                  : _buildTable(),
              ),
            ],
          ),
        ),
  );
}

  Widget _buildEmptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Column(
      children: [
        _buildTableHeader(),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _allCoupons.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) => _buildRow(index + 1, _allCoupons[index]),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      child: Row(
        children: [
          _buildCell('SL', 1),
          _buildCell('COUPON INFO', 4),
          _buildCell('TYPE', 3),
          _buildCell('DISCOUNT', 3),
          _buildCell('MIN BUY', 2),
          _buildCell('STATUS', 2, align: TextAlign.center),
          _buildCell('ACTION', 2, align: TextAlign.right),
        ],
      ),
    );
  }

  Widget _buildRow(int sl, CouponModel coupon) {
    // Dynamic Subtitle based on API response
    String subTitle = "Default Coupon";
    if (coupon.service != null) {
      subTitle = "Service: ${coupon.service!.name}";
    } else if (coupon.category != null) {
      subTitle = "Category: ${coupon.category!.name}";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          _buildCell(sl.toString(), 1),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.couponCode,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  subTitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildCell(coupon.couponType, 3),
          _buildCell(
            coupon.discountType == 'PERCENTAGE'
                ? "${coupon.discountPercentage}% OFF"
                : "₹${coupon.amount} OFF",
            3,
            color: Colors.green.shade700,
          ),
          _buildCell("₹${coupon.minPurchaseAmount.toStringAsFixed(0)}", 2),
          Expanded(
            flex: 2,
            child: Center(
              child: Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: coupon.isActive,
                  activeTrackColor: const Color(0xFFEB5725),
                  activeColor: Colors.white,
                  onChanged: (v) {
                    // Logic for status toggle
                  },
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
_buildActionBtn(Icons.edit_outlined, Colors.blue, () => _showUpdateCouponDialog(context, coupon)),
                const SizedBox(width: 8),
                _buildActionBtn(Icons.delete_outline, Colors.red, () {
                  CustomCenterDialog.show(
                    context,
                    title: "Delete Coupon",
                    message: "Are you sure you want to delete ${coupon.couponCode}?",
                    type: DialogType.warning,
                    onConfirm: () {
                      // Logic for deletion
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(String text, int flex, {TextAlign align = TextAlign.left, Color? color}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 13,
          color: color ?? const Color(0xFF64748B),
          fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Coupons',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_allCoupons.length} total coupons found',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _fetchCoupons,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text("Refresh"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
          ),
        ),
      ],
    );
  }
}