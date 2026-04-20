import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import '../controllers/refund_controller.dart';
import '../widgets/custom_center_dialog.dart';
// Assuming you will create a RefundController similar to your WithdrawController
// For now, I'll use a local mock list to show the UI in action.
class RefundRequestScreen extends StatefulWidget {
  const RefundRequestScreen({super.key});

  @override
  State<RefundRequestScreen> createState() => _RefundRequestScreenState();
}

class _RefundRequestScreenState extends State<RefundRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 1. USE THE REAL CONTROLLER
  final RefundController controller = Get.put(RefundController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'SUCCESS':
        return const Color(0xFF10B981); // Green
      case 'INITIATED':
        return const Color(0xFF6366F1); // Indigo
      case 'PENDING':
        return const Color(0xFF3B82F6); // Blue
      case 'DENIED':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  // Column Widths
  static const double colSL = 50;
  static const double colRef = 160;     
  static const double colCustomer = 200;
  static const double colBank = 180;
  static const double colNote = 200;
  static const double colAmount = 100;
  static const double colDate = 110;
  static const double colStatus = 110;
  static const double colAction = 120;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Obx(() {
        // 2. USE CONTROLLER LOADING STATE
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)));
        }

        // 3. FILTER FROM CONTROLLER LIST
        List<dynamic> filteredRequests = controller.refundList.where((req) {
          final status = req['status']?.toString().toUpperCase();
          switch (_tabController.index) {
            case 1: return status == 'PENDING';
            case 2: return status == 'INITIATED';
            case 3: return status == 'SUCCESS';
            case 4: return status == 'DENIED';
            default: return true;
          }
        }).toList();

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(controller.refundList.length),
                const SizedBox(height: 24),
                _buildTableContainer(filteredRequests),
              ],
            ),
          ),
        );
      }),
    );
  }

 Widget _buildHeader(int totalCount) {
    return Row(
      children: [
        const Text('Customer Refunds', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFF97316), borderRadius: BorderRadius.circular(20)),
          child: Text('$totalCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        const Spacer(),
        IconButton(
          // 4. ADD REFRESH ACTION
          onPressed: () => controller.fetchRefunds(),
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFFEF7822)),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: BorderSide(color: Colors.grey[300]!),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildTableContainer(List<dynamic> data) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabBarRow(data.length),
          _buildToolbar(),
          LayoutBuilder(
            builder: (context, constraints) {
              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTableHeader(),
                          ...data.asMap().entries.map((entry) => _buildTableRow(entry.value, entry.key + 1)),
                          if (data.isEmpty)
                            const SizedBox(height: 100, child: Center(child: Text("No refunds found"))),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarRow(int count) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF0F172A),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFFF97316),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Initiated'),
              Tab(text: 'Success'),
              Tab(text: 'Denied'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                children: [
                  const TextSpan(text: 'Filtered: '),
                  TextSpan(text: '$count', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 280, height: 48,
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(24)),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by Booking ID...',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
                child: const Text('Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Export CSV'),
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(
        children: const [
          SizedBox(width: colSL, child: _Th('SL')),
          SizedBox(width: colRef, child: _Th('REF / BOOKING ID')),
          SizedBox(width: colCustomer, child: _Th('CUSTOMER INFO')),
          SizedBox(width: colBank, child: _Th('REFUND TO')),
          SizedBox(width: colNote, child: _Th('REMARKS')),
          SizedBox(width: colAmount, child: _Th('AMOUNT')),
          SizedBox(width: colDate, child: _Th('REQUEST DATE')),
          SizedBox(width: colStatus, child: _Th('STATUS', alignCenter: true)),
          SizedBox(width: colAction, child: _Th('ACTION', alignCenter: true)),
        ],
      ),
    );
  }

Widget _buildTableRow(dynamic req, int sl) {
  // Mapping correct keys from your JSON response
  final String status = req['status']?.toString() ?? 'PENDING';
  final String bookingId = req['bookingId']?.toString() ?? 'N/A';
  final String refundId = req['id']?.toString() ?? 'N/A';
  
  // Logic for Full Name: Combining First, Middle, and Last name
  final String fName = req['customerFirstName']?.toString() ?? '';
  final String mName = req['customerMiddleName']?.toString() ?? '';
  final String lName = req['customerLastName']?.toString() ?? '';
  final String customerName = "$fName $mName $lName".trim().isEmpty 
      ? "Unknown" 
      : "$fName $mName $lName".replaceAll(RegExp(r'\s+'), ' ').trim();

  final String email = req['customerEmailId']?.toString() ?? 'No Email';
  final String mobileNo = req['customerMobile']?.toString() ?? 'No Mobile';
  final String bankName = req['bankName']?.toString() ?? 'N/A';
  final String accountNo = req['accountNo']?.toString() ?? 'XXXX';
  final String amount = req['amount']?.toString() ?? '0';
  
  // Note: Your JSON doesn't show a 'comment' field, adding safety
  final String comment = req['comment']?.toString() ?? '';
  
  // Date Formatting
  final String rawDate = req['requestDate']?.toString() ?? '';
  final String displayDate = rawDate.contains('T') 
      ? rawDate.split('T')[0] 
      : (rawDate.isEmpty ? 'N/A' : rawDate);

  final statusColor = _getStatusColor(status);

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
    ),
    child: Row(
      children: [
        // SL No
        SizedBox(width: colSL, child: Text('$sl', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        
        // Ref / Booking ID
      // Ref / Booking ID
SizedBox(
  width: colRef,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Booking ID
      Text(
        bookingId, 
        style: const TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 10, // Reduced from 11
          color: Color(0xFF0F172A),
        ),
      ),
      const SizedBox(height: 2),
      // Full UUID / Refund ID
      SelectableText(
        refundId, 
        style: const TextStyle(
          fontSize: 8, // Reduced from 9 to show full UUID
          color: Color(0xFF94A3B8),
          fontFamily: 'monospace', // Monospace helps with alignment of IDs
          letterSpacing: -0.2, // Tighter tracking to fit more characters
        ),
      ),
    ],
  ),
),
        
        // Customer Info
        SizedBox(
          width: colCustomer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB))),
              Text(email, style: const TextStyle(color: Color(0xFFF97316), fontSize: 11)),
              Text(mobileNo, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
            ],
          ),
        ),
        
        // Refund To (Bank)
        SizedBox(
          width: colBank,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(bankName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              Text('A/C: $accountNo', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
            ],
          ),
        ),
        
        // Remarks
        SizedBox(
          width: colNote,
          child: Text(
            comment.isEmpty ? 'No remarks' : comment, 
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, overflow: TextOverflow.ellipsis), 
            maxLines: 2,
          ),
        ),
        
        // Amount
        SizedBox(width: colAmount, child: Text("₹$amount", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF97316)))),
        
        // Request Date
        SizedBox(width: colDate, child: Text(displayDate, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
        
        // Status Badge
        SizedBox(
          width: colStatus,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status.toUpperCase(), 
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        
        // Action
        SizedBox(
          width: colAction,
          child: Center(
            child: (status.toUpperCase() == 'SUCCESS')
                ? const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)
                : ElevatedButton(
                    onPressed: () => _showRefundModal(req),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Update', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
          ),
        ),
      ],
    ),
  );
}
void _showRefundModal(Map<String, dynamic> request) {
  // Extracting Name info from API keys
  final String fName = request['customerFirstName']?.toString() ?? '';
  final String mName = request['customerMiddleName']?.toString() ?? '';
  final String lName = request['customerLastName']?.toString() ?? '';
  final String fullName = "$fName $mName $lName".replaceAll(RegExp(r'\s+'), ' ').trim();

  // Controllers for text fields
  final TextEditingController transactionController = TextEditingController();
  final TextEditingController remarkController = TextEditingController(text: request['comment']?.toString() ?? '');
  final TextEditingController dateController = TextEditingController(
    text: DateTime.now().toString().split(' ')[0], // Default to today
  );

  // Status mapping
  String selectedStatus = request['status']?.toString() ?? 'Initiated';
  final List<String> statusOptions = ['Pending', 'Initiated', 'Success', 'Denied'];

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 550,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top close button
                    Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
                        ),
                      ),
                    ),

                    // Icon Header (Reusing your UI helper)
                    _buildDialogHeaderIcon(), 
                    const SizedBox(height: 16),
                    const Text('Update Refund Status', 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                    const SizedBox(height: 24),

                    // Info Cards Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildModalInfoCard("Customer Details", [
                            fullName.isEmpty ? "Unknown" : fullName,
                            request['customerMobile']?.toString() ?? "No Mobile",
                            request['customerEmailId']?.toString() ?? "No Email",
                          ], Icons.person_outline),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModalInfoCard("Refund Bank Info", [
                            request['bankName']?.toString()?.toUpperCase() ?? "N/A",
                            "A/C: ${request['accountNo']?.toString() ?? 'XXXX'}",
                            "UPI: ${request['upiId']?.toString() ?? 'N/A'}",
                          ], Icons.account_balance_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Transaction No Field (Required for Success/Initiated)
                    _buildFieldLabel('Bank Transaction No / UTR *'),
                    TextField(
                      controller: transactionController,
                      decoration: _buildInputDecoration('Enter Reference Number'),
                    ),
                    const SizedBox(height: 20),

                    // Refund Date Field (Required)
                    _buildFieldLabel('Refund Date *'),
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => dateController.text = picked.toString().split(' ')[0]);
                        }
                      },
                      decoration: _buildInputDecoration('YYYY-MM-DD').copyWith(
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Status Selection
                    _buildFieldLabel('Select Refund Status'),
                    Wrap(
                      spacing: 10,
                      children: statusOptions.map((status) {
                        final bool isSelected = selectedStatus.toLowerCase() == status.toLowerCase();
                        return ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (val) => setDialogState(() => selectedStatus = status),
                          selectedColor: const Color(0xFFF97316).withOpacity(0.1),
                          checkmarkColor: const Color(0xFFF97316),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Remark Field
                    _buildFieldLabel('Admin Remark'),
                    TextField(
                      controller: remarkController,
                      maxLines: 2,
                      decoration: _buildInputDecoration('Add processing note...'),
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context), 
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF1F2937))),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Validation: Required fields for payment update
                            if (transactionController.text.isEmpty || dateController.text.isEmpty) {
                              CustomCenterDialog.show(
                                context,
                                title: "Required Fields",
                                message: "Please provide Transaction Number and Refund Date.",
                                type: DialogType.error,
                              );
                              return;
                            }
                            
                            Navigator.pop(context);
                            controller.updateRefundStatus(
                              request['id'], 
                              remark: remarkController.text.trim(),
                              transactionNo: transactionController.text.trim(),
                              refundedDate: dateController.text.trim(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Update Refund', 
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
  Widget _buildModalInfoCard(String title, List<String> lines, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 16), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          ...lines.map((line) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(line, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
          )),
        ],
      ),
    );
  }
}
// --- UI Helpers for Modals ---

Widget _buildFieldLabel(String label) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
          fontSize: 14,
        ),
      ),
    ),
  );
}

InputDecoration _buildInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
    ),
    contentPadding: const EdgeInsets.all(16),
  );
}

Widget _buildDialogHeaderIcon() {
  return Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.blue.withOpacity(0.1), width: 4),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        const CircularProgressIndicator(
          value: 1.0,
          strokeWidth: 4,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEAB308)),
        ),
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Color(0xFF22C55E),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 20),
        ),
      ],
    ),
  );
}

// Reusing your Table Header widget
class _Th extends StatelessWidget {
  final String text;
  final bool alignCenter;
  const _Th(this.text, {this.alignCenter = false});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: alignCenter ? TextAlign.center : TextAlign.left,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)));
  }
}