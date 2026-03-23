import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/withdraw_controller.dart';
import '../widgets/custom_center_dialog.dart';
import 'package:flutter/gestures.dart';

class WithdrawRequestScreen extends StatefulWidget {
  const WithdrawRequestScreen({super.key});

  @override
  State<WithdrawRequestScreen> createState() => _WithdrawRequestScreenState();
}

class _WithdrawRequestScreenState extends State<WithdrawRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WithdrawController controller = Get.put(WithdrawController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
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
      case 'APPROVED':
      case 'SETTLED':
        return const Color(0xFF10B981); // Green
      case 'PENDING':
        return const Color(0xFF3B82F6); // Blue
      case 'DENIED':
      case 'FAILED':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  // Adjusted column widths to fit all required data comfortably
  static const double colSL = 50;
  static const double colRef = 160;     // Reference ID (UUID)
  static const double colProvider = 200;
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
        if (controller.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF97316)));
        }

        List<dynamic> filteredRequests = controller.withdrawList.where((req) {
          final status = req['status']?.toString().toUpperCase();
          switch (_tabController.index) {
            case 1: return status == 'PENDING';
            case 2: return status == 'SUCCESS' || status == 'APPROVED';
            case 3: return status == 'DENIED';
            case 4: return status == 'SETTLED';
            default: return true;
          }
        }).toList();

        // --- UPDATED: Wrap with ScrollConfiguration and add ClampingScrollPhysics ---
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(), // Removes bouncy extra space
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(controller.withdrawList.length),
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
        const Text('Withdraw Requests',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A))),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(20)),
          child: Text('$totalCount',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
        const Spacer(), // Pushes the refresh icon to the far right
        IconButton(
          onPressed: () => controller.fetchRequests(),
          icon: const Icon(Icons.refresh_rounded,  color: const Color(0xFFEF7822)),
          tooltip: 'Refresh Data',
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
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
          ]),
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
                    // --- THE FIX: ADD INTRINSIC WIDTH HERE ---
                    child: IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch, 
                        children: [
                          _buildTableHeader(),
                          ...data.asMap().entries.map(
                              (entry) => _buildTableRow(entry.value, entry.key + 1)),
                          if (data.isEmpty)
                            const SizedBox(
                              height: 100,
                              child: Center(child: Text("No data found")),
                            ),
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
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF0F172A),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFFF97316),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Denied'),
              Tab(text: 'Settled')
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                children: [
                  const TextSpan(text: 'Filtered count: '),
                  TextSpan(
                      text: '$count',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A))),
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
                width: 280,
                height: 48,
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24)),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by provider',
                    hintStyle:
                        TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon:
                        Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 16)),
                child: const Text('Search',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download'),
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(
        children: const [
          SizedBox(width: colSL, child: _Th('SL')),
          SizedBox(width: colRef, child: _Th('REFERENCE ID')),
          SizedBox(width: colProvider, child: _Th('PROVIDER INFO')),
          SizedBox(width: colBank, child: _Th('BANK DETAILS')),
          SizedBox(width: colNote, child: _Th('ADMIN NOTE')),
          SizedBox(width: colAmount, child: _Th('AMOUNT')),
          SizedBox(width: colDate, child: _Th('DATE')),
          SizedBox(width: colStatus, child: _Th('STATUS', alignCenter: true)),
          SizedBox(width: colAction, child: _Th('ACTION', alignCenter: true)),
        ],
      ),
    );
  }

  Widget _buildTableRow(dynamic req, int sl) {
    final status = req['status'] ?? 'Pending';
    final statusColor = _getStatusColor(status);

    final String reference = req['id'] ?? 'N/A';
    final String providerName = req['providerName'] ?? 'Unknown';
    final String email = req['email'] ?? 'N/A';
    final String mobile = req['mobileNo'] ?? 'N/A';

    final String bankName = req['bankName'] ?? 'N/A';
    final String accountNo = req['accountNo'] ?? 'N/A';
    final String upiId = req['upiId'] ?? 'N/A';

    final String adminNote = req['comment'] ?? 'Not Provided Yet';
    final String date = req['requestDate']?.toString().split('T')[0] ?? 'N/A';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          // SL No
          SizedBox(
              width: colSL,
              child: Text('$sl',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13))),

          // Reference ID (Full UUID)
          SizedBox(
            width: colRef,
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: SelectableText(
                reference,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                    height: 1.3),
              ),
            ),
          ),

          // Provider Info
          SizedBox(
            width: colProvider,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(providerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF2563EB))),
                const SizedBox(height: 2),
                Text(email,
                    style: const TextStyle(
                        color: Color(0xFFF97316), fontSize: 11)),
                Text('Mob: $mobile',
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 11)),
              ],
            ),
          ),

          // Bank Details
          SizedBox(
            width: colBank,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(bankName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 2),
                Text('A/C: $accountNo',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF475569))),
                Text('UPI: $upiId',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),

          // Admin Note
          SizedBox(
            width: colNote,
            child: adminNote == 'Not Provided Yet' || adminNote.isEmpty
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Not Provided Yet',
                          style: TextStyle(
                              color: Color(0xFF3B82F6),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  )
                : Text(
                    adminNote,
                    style:
                        const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),

          // Amount
          SizedBox(
              width: colAmount,
              child: Text("₹${req['amount'] ?? '0'}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFFF97316)))),

          // Date
          SizedBox(
              width: colDate,
              child: Text(date,
                  style:
                      const TextStyle(color: Color(0xFF64748B), fontSize: 12))),

          // Status Badge
          SizedBox(
            width: colStatus,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),

          // Action
          SizedBox(
            width: colAction,
            child: Center(
              child: (status == 'SUCCESS' || status == 'SETTLED')
                  ? const Text('Already Settled',
                      style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                          fontSize: 12))
                  : ElevatedButton(
                      onPressed: () => _showSettleModal(req),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          elevation: 0,
                          minimumSize: const Size(80, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20))),
                      child: const Text('Settle',
                          style: TextStyle(color: Colors.white, fontSize: 11))),
            ),
          ),
        ],
      ),
    );
  }

  // Updated Modal to match static UI but populated with dynamic Data
  // Updated Modal to include dynamic status chips
  void _showSettleModal(Map<String, dynamic> request) {
    final String providerName = request['providerName'] ?? 'Unknown';
    final String mobile = request['mobileNo'] ?? 'N/A';
    final String email = request['email'] ?? 'N/A';
    final String bankName = request['bankName'] ?? 'Unknown Bank';
    final String accountNo = request['accountNo'] ?? 'N/A';
    final String upiId = request['upiId'] ?? 'N/A';

    // Default selection when the modal opens
    String selectedStatus = 'Settled'; 
    final List<String> statusOptions = ['Pending', 'Approved', 'Denied', 'Settled'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // StatefulBuilder allows us to call setState just for this dialog
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
                    // Top close button
                    Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
                        ),
                      ),
                    ),

                    // Icon Header
                    Container(
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
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Update Request Status', // Updated title
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info Cards Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Provider Information Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Provider Information',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  providerName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2563EB), fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_iphone_rounded, size: 16, color: Color(0xFF64748B)),
                                    const SizedBox(width: 8),
                                    Text(mobile, style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.email_outlined, size: 16, color: Color(0xFF64748B)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(email, style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Withdraw Method Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Withdraw Bank details',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  bankName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B), fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.credit_card, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text('A/C: $accountNo', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.qr_code, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text('UPI: $upiId', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- NEW: Status Selection Chips ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Action Status',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12.0,
                            runSpacing: 12.0,
                            children: statusOptions.map((status) {
                              final bool isSelected = selectedStatus == status;
                              return ChoiceChip(
                                label: Text(status),
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  if (selected) {
                                    // Update state ONLY inside the dialog
                                    setDialogState(() => selectedStatus = status);
                                  }
                                },
                                selectedColor: const Color(0xFFF97316).withOpacity(0.1),
                                checkmarkColor: const Color(0xFFF97316),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFFF97316) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected ? const Color(0xFFF97316) : const Color(0xFF64748B),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Note TextField
                    TextField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Admin Note (Required)',
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F4F6),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 16),
                   ElevatedButton(
  onPressed: () {
    // 1. Close the Settle Modal
    Navigator.of(context).pop();
    
    // 2. Format the status for the API
    String apiStatus = selectedStatus;
    if (apiStatus == 'Settled') {
      apiStatus = 'SUCCESS'; 
    } else {
      apiStatus = apiStatus.toUpperCase();
    }

    // 3. Just call the controller! It handles the loading, refreshing, and popups now.
    controller.updateStatus(request['id'], apiStatus);
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFF97316),
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  child: const Text('Update Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
}

class _Th extends StatelessWidget {
  final String text;
  final bool alignCenter;
  const _Th(this.text, {this.alignCenter = false});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: alignCenter ? TextAlign.center : TextAlign.left,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B)));
  }
}