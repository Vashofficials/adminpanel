import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WithdrawRequestScreen extends StatefulWidget {
  const WithdrawRequestScreen({super.key});

  @override
  State<WithdrawRequestScreen> createState() => _WithdrawRequestScreenState();
}

class _WithdrawRequestScreenState extends State<WithdrawRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Dummy data for the table
  final List<Map<String, dynamic>> _dummyRequests = [
    {
      'id': 1,
      'providerName': 'Rajesh Kumar',
      'email': 'rajesh.k@gmail.com',
      'phone': '+91 98765 43210',
      'totalEarning': '₹ 45,000',
      'totalSettlement': '₹ 38,000',
      'pendingSettlement': '₹ 7,000',
      'adminNote': 'Your request approved successfully. Please...',
      'totalBookings': 45,
      'totalServices': 12,
      'requestTime': '05-Mar-23\n00:58AM',
      'status': 'Approved',
    },
    {
      'id': 2,
      'providerName': 'Amit Singh',
      'email': 'amit.singh@yahoo.com',
      'phone': '+91 87654 32109',
      'totalEarning': '₹ 12,500',
      'totalSettlement': '₹ 12,500',
      'pendingSettlement': '₹ 0',
      'adminNote': 'Withdraw Settled successfully.',
      'totalBookings': 30,
      'totalServices': 8,
      'requestTime': '05-Mar-23\n00:58AM',
      'status': 'Settled',
    },
    {
      'id': 3,
      'providerName': 'Priya Sharma',
      'email': 'priya.sharma@gmail.com',
      'phone': '+91 76543 21098',
      'totalEarning': '₹ 89,200',
      'totalSettlement': '₹ 80,000',
      'pendingSettlement': '₹ 9,200',
      'adminNote': 'Not Provided Yet',
      'totalBookings': 15,
      'totalServices': 5,
      'requestTime': '23-Jan-23\n02:52AM',
      'status': 'Pending',
    },
    {
      'id': 4,
      'providerName': 'Vijay Verma',
      'email': 'vijay.v@outlook.com',
      'phone': '+91 99887 76655',
      'totalEarning': '₹ 8,400',
      'totalSettlement': '₹ 5,000',
      'pendingSettlement': '₹ 3,400',
      'adminNote': 'Rejected due to incomplete bank details.',
      'totalBookings': 60,
      'totalServices': 20,
      'requestTime': '23-Jan-23\n02:50AM',
      'status': 'Denied',
    },
    {
      'id': 5,
      'providerName': 'Anjali Gupta',
      'email': 'anjali.g@gmail.com',
      'phone': '+91 90123 45678',
      'totalEarning': '₹ 32,150',
      'totalSettlement': '₹ 20,000',
      'pendingSettlement': '₹ 12,150',
      'adminNote': 'Withdraw Settled successfully.',
      'totalBookings': 25,
      'totalServices': 7,
      'requestTime': '20-Jan-23\n04:15PM',
      'status': 'Settled',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper method to determine status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
      case 'Settled':
        return const Color(0xFF10B981); // Emerald (Green)
      case 'Pending':
        return const Color(0xFF3B82F6); // Blue
      case 'Denied':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  // Modal dialog exactly matching the second screenshot
  void _showSettleModal(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500,
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
                      // Outer dotted ring simulation
                      const CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEAB308)), // Yellow ring
                      ),
                      // Inner checkmark
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E), // Green
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                const Text(
                  'Settled this request ?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937), // Gray-800
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
                          color: const Color(0xFFF8FAFC), // Very light slate
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
                              request['providerName'],
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2563EB), fontSize: 14), // Blue name
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: const [
                                Icon(Icons.phone_iphone_rounded, size: 16, color: Color(0xFF64748B)),
                                SizedBox(width: 8),
                                Text('29****', style: TextStyle(color: Color(0xFF475569), fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Icon(Icons.map_outlined, size: 16, color: Color(0xFF64748B)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text('Minima quasi et et i', style: TextStyle(color: Color(0xFF475569), fontSize: 13)),
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
                          children: const [
                            Text(
                              'Withdraw Bank details',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'SBI Bank',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B), fontSize: 13),
                            ),
                            Text(
                              '76435363465',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.credit_card, size: 14, color: Color(0xFF64748B)),
                                SizedBox(width: 4),
                                Text('IFSC: IFSC654534', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.qr_code, size: 14, color: Color(0xFF64748B)),
                                SizedBox(width: 4),
                                Text('UPI: 675755@oksbi', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Note TextField
                TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Note',
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
                        backgroundColor: const Color(0xFFF3F4F6), // Gray 100
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316), // Primary Orange
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Yes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredRequests;
    switch (_tabController.index) {
      case 1:
        filteredRequests = _dummyRequests.where((r) => r['status'] == 'Pending').toList();
        break;
      case 2:
        filteredRequests = _dummyRequests.where((r) => r['status'] == 'Approved').toList();
        break;
      case 3:
        filteredRequests = _dummyRequests.where((r) => r['status'] == 'Denied').toList();
        break;
      case 4:
        filteredRequests = _dummyRequests.where((r) => r['status'] == 'Settled').toList();
        break;
      case 0:
      default:
        filteredRequests = _dummyRequests;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate-100
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Withdraw Requests',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444), // Red badge
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '14', // Total withdraws count matches screenshot
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- TAB BAR AND CONTENT AREA ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tabs row
                  Container(
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          labelColor: const Color(0xFF0F172A),
                          unselectedLabelColor: const Color(0xFF64748B),
                          indicatorColor: const Color(0xFFF97316), // Primary Orange
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(text: 'All'),
                            Tab(text: 'Pending'),
                            Tab(text: 'Approved'),
                            Tab(text: 'Denied'),
                            Tab(text: 'Settled'),
                          ],
                        ),
                        // Right side 'Total withdraw' text
                        Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                              children: [
                                TextSpan(text: 'Total withdraw: '),
                                TextSpan(text: '14', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions Toolbar (Search & Buttons)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Search Input
                        Row(
                          children: [
                            Container(
                              width: 280,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9), // Light background for search
                                borderRadius: BorderRadius.circular(24), // Pill shape
                              ),
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Search by provider',
                                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
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
                                backgroundColor: const Color(0xFFF97316), // Primary Orange
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                              ),
                              child: const Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),

                        // Action Buttons
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: const Text('Download'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Adjusted padding to match height
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Table View wrapped in SingleChildScrollView for horizontal scroll if needed
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 320), // Ensure it spans but can scroll
                      child: Column(
                        children: [
                          // TH
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                            child: Row(
                              children: const [
                                SizedBox(width: 50, child: _Th('SL')),
                                SizedBox(width: 240, child: _Th('PROVIDER NAME')),
                                SizedBox(width: 280, child: _Th('ADMIN NOTE')),
                                SizedBox(width: 130, child: _Th('AMOUNT')),
                                SizedBox(width: 150, child: _Th('REQUEST')),
                                SizedBox(width: 120, child: _Th('STATUS', alignCenter: true)),
                                SizedBox(width: 160, child: _Th('ACTION', alignCenter: true)),
                              ],
                            ),
                          ),

                          // TABLE ROWS
                          ...filteredRequests.map((req) {
                            final statusColor = _getStatusColor(req['status']);
                            final isPending = req['status'] == 'Pending';
                            final isSettled = req['status'] == 'Settled';

                            return Container(
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center, // Vertically center the row contents
                                children: [
                                  // SizedBox(
                                  //   width: 40,
                                  //   child: Row(
                                  //     children: [
                                  //       // Checkbox simulation
                                  //       Container(
                                  //         width: 16,
                                  SizedBox(
                                    width: 50,
                                    child: Text('${req['id']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
                                  ),
                                  
                                  // Provider Name
                                  SizedBox(
                                    width: 240,
                                    child: InkWell(
                                      onTap: () {
                                        // TODO: Real navigation to Provider View
                                        Get.snackbar('Navigate', 'Viewing details for ${req['providerName']}');
                                      },
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            req['providerName'],
                                            style: const TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.w600, fontSize: 13, decoration: TextDecoration.underline), // Highlight Tapable
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'ID: P-${202300 + (req['id'] as int)}',
                                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  // Admin Note
                                  SizedBox(
                                    width: 280,
                                    child: req['adminNote'] == 'Not Provided Yet'
                                        ? Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF), // Blue 50
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text('Not Provided Yet', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w600)),
                                            ),
                                          )
                                        : Text(
                                            req['adminNote'],
                                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                  ),

                                  // Amount
                                  SizedBox(
                                    width: 130,
                                    child: Text(
                                      req['pendingSettlement'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFF97316)),
                                    ),
                                  ),

                                  // Request Date/Time
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      req['requestTime'],
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                    ),
                                  ),

                                  // Status Badge
                                  SizedBox(
                                    width: 120,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          req['status'],
                                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Action
                                  SizedBox(
                                    width: 160,
                                    child: Center(
                                      child: isSettled
                                          ? const Text('Already Settled', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 13))
                                          : isPending
                                              // Pending Actions (Close & Check)
                                              ? Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    InkWell(
                                                      onTap: () {},
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          border: Border.all(color: const Color(0xFFEF4444)),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: const Icon(Icons.close, color: Color(0xFFEF4444), size: 16),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    InkWell(
                                                      onTap: () {},
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          border: Border.all(color: const Color(0xFF10B981)),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: const Icon(Icons.check, color: Color(0xFF10B981), size: 16),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              // Settle Button
                                              : ElevatedButton(
                                                  onPressed: () => _showSettleModal(req),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF10B981), // Emerald
                                                    elevation: 0,
                                                    minimumSize: const Size(80, 36),
                                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                  ),
                                                  child: const Text('Settle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                                ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
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

class _Th extends StatelessWidget {
  final String text;
  final bool alignCenter;
  const _Th(this.text, {this.alignCenter = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignCenter ? TextAlign.center : TextAlign.left,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B), // Slate 800
      ),
    );
  }
}
