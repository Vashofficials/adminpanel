import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';

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
  
  // Replace with: final RefundController controller = Get.put(RefundController());
  final RxBool isLoading = false.obs;
  final RxList<dynamic> refundList = [
    {
      "id": "REF-UUID-12345",
      "bookingId": "BK-9901",
      "customerName": "Himanshu Shukla",
      "email": "himanshu@example.com",
      "mobileNo": "+91 9876543210",
      "bankName": "HDFC Bank",
      "accountNo": "XXXXXX4521",
      "upiId": "himanshu@okaxis",
      "amount": "1,500.00",
      "requestDate": "2026-04-03T10:00:00",
      "status": "PENDING",
      "comment": ""
    },
    {
      "id": "REF-UUID-67890",
      "bookingId": "BK-8822",
      "customerName": "Chunmun",
      "email": "chunmun@example.com",
      "mobileNo": "+91 9988776655",
      "bankName": "ICICI Bank",
      "accountNo": "XXXXXX9900",
      "upiId": "chunmun@upi",
      "amount": "2,450.00",
      "requestDate": "2026-03-22T14:20:00",
      "status": "INITIATED",
      "comment": "Processing with Gateway"
    }
  ].obs;

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
        if (isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)));
        }

        List<dynamic> filteredRequests = refundList.where((req) {
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
                _buildHeader(refundList.length),
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
        const Text('Customer Refunds',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFF97316), borderRadius: BorderRadius.circular(20)),
          child: Text('$totalCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {}, // controller.fetchRefunds(),
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
    final statusColor = _getStatusColor(req['status']);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          SizedBox(width: colSL, child: Text('$sl', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          SizedBox(
            width: colRef,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req['bookingId'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                Text(req['id'], style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          SizedBox(
            width: colCustomer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req['customerName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB))),
                Text(req['email'], style: const TextStyle(color: Color(0xFFF97316), fontSize: 11)),
                Text(req['mobileNo'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              ],
            ),
          ),
          SizedBox(
            width: colBank,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req['bankName'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                Text('A/C: ${req['accountNo']}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
              ],
            ),
          ),
          SizedBox(
            width: colNote,
            child: Text(req['comment'].isEmpty ? 'No remarks' : req['comment'], 
                 style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, overflow: TextOverflow.ellipsis), maxLines: 2),
          ),
          SizedBox(width: colAmount, child: Text("₹${req['amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF97316)))),
          SizedBox(width: colDate, child: Text(req['requestDate'].split('T')[0], style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
          SizedBox(
            width: colStatus,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(req['status'], style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          SizedBox(
            width: colAction,
            child: Center(
              child: (req['status'] == 'SUCCESS')
                  ? const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)
                  : ElevatedButton(
                      onPressed: () => _showRefundModal(req),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                      child: const Text('Update', style: TextStyle(color: Colors.white, fontSize: 11))),
            ),
          ),
        ],
      ),
    );
  }

  void _showRefundModal(Map<String, dynamic> request) {
    String selectedStatus = request['status']; 
    final List<String> statusOptions = ['Pending', 'Initiated', 'Success', 'Denied'];
    final TextEditingController commentController = TextEditingController(text: request['comment']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 550,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ),
                    const Text('Update Refund Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        // Customer Card
                        Expanded(
                          child: _buildModalInfoCard("Customer Details", [
                            request['customerName'],
                            request['mobileNo'],
                            request['email'],
                          ], Icons.person_outline),
                        ),
                        const SizedBox(width: 16),
                        // Bank Card
                        Expanded(
                          child: _buildModalInfoCard("Refund Bank Info", [
                            request['bankName'],
                            "A/C: ${request['accountNo']}",
                            "UPI: ${request['upiId']}",
                          ], Icons.account_balance_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Status Selection
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 10,
                        children: statusOptions.map((status) {
                          final bool isSelected = selectedStatus == status;
                          return ChoiceChip(
                            label: Text(status),
                            selected: isSelected,
                            onSelected: (val) => setDialogState(() => selectedStatus = status),
                            selectedColor: const Color(0xFFF97316).withOpacity(0.1),
                            checkmarkColor: const Color(0xFFF97316),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add processing note or reason for denial...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Discard')),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            // Logic: update list or call API
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                          child: const Text('Update Refund', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
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