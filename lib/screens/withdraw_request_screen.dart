import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/withdraw_controller.dart';

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
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Approved':
      case 'Settled':
        return const Color(0xFF10B981);
      case 'Pending':
        return const Color(0xFF3B82F6);
      case 'Denied':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  // Column Width Constants to ensure perfect alignment
  static const double colSL = 50;
  static const double colProvider = 250;
  static const double colRef = 150;
  static const double colNote = 200;
  static const double colAmount = 120;
  static const double colDate = 130;
  static const double colStatus = 120;
  static const double colAction = 150;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)));
        }

        List<dynamic> filteredRequests = controller.withdrawList.where((req) {
          final status = req['status'];
          switch (_tabController.index) {
            case 1: return status == 'Pending';
            case 2: return status == 'Approved';
            case 3: return status == 'Denied';
            case 4: return status == 'Settled';
            default: return true;
          }
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(controller.withdrawList.length),
              const SizedBox(height: 24),
              _buildTableContainer(filteredRequests),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(int totalCount) {
    return Row(
      children: [
        const Text('Withdraw Requests',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(20)),
          child: Text('$totalCount',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        IconButton(
          onPressed: () {
            controller.fetchRequests(); // Re-hits the API
            Get.snackbar(
              'Refreshing', 
              'Fetching latest data...',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 1),
              backgroundColor: const Color(0xFF0F172A).withOpacity(0.8),
              colorText: Colors.white,
            );
          },
          icon: const Icon(
            Icons.refresh_rounded,
            color: Color(0xFF64748B), // Slate color to match your UI
          ),
          tooltip: 'Refresh Data',
          splashRadius: 24,
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
          // The horizontal scroll only applies to the table content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTableHeader(),
                ...data.asMap().entries.map((entry) => _buildTableRow(entry.value, entry.key + 1)),
                if (data.isEmpty)
                  const SizedBox(
                    width: colSL + colProvider + colRef + colNote + colAmount + colDate + colStatus + colAction + 48,
                    height: 100,
                    child: Center(child: Text("No data found")),
                  ),
              ],
            ),
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
            indicatorWeight: 3,
            tabs: const [Tab(text: 'All'), Tab(text: 'Pending'), Tab(text: 'Approved'), Tab(text: 'Denied'), Tab(text: 'Settled')],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                children: [
                  const TextSpan(text: 'Filtered count: '),
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
                width: 280,
                height: 48,
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(24)),
                child: const TextField(
                  decoration: InputDecoration(
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
                    backgroundColor: const Color(0xFFF97316),
                    shape: const StadiumBorder(),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
                child: const Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: const BoxDecoration(
          color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(
        children: const [
          SizedBox(width: colSL, child: _Th('SL')),
          SizedBox(width: colProvider, child: _Th('PROVIDER NAME')),
          SizedBox(width: colRef, child: _Th('REFERENCE')),
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
    final String adminNote = (req['comments'] == null || req['comments'].toString().isEmpty) ? "N/A" : req['comments'].toString();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          SizedBox(width: colSL, child: Text('$sl', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          SizedBox(
            width: colProvider,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req['serviceProvider']['emailId'] ?? 'N/A',
                    style: const TextStyle(
                        color: Color(0xFFF97316),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        decoration: TextDecoration.underline)),
                Text('Mob: ${req['serviceProvider']['mobileNo']}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              ],
            ),
          ),
          SizedBox(width: colRef, child: Text(req['referenceNumber'] ?? "N/A", style: const TextStyle(fontSize: 13))),
          SizedBox(
            width: colNote,
            child: Text(adminNote,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: adminNote == "N/A" ? Colors.grey : const Color(0xFF0F172A),
                    fontSize: 12,
                    fontStyle: adminNote == "N/A" ? FontStyle.italic : FontStyle.normal)),
          ),
          SizedBox(width: colAmount, child: Text("₹ ${req['amount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFF97316)))),
          SizedBox(width: colDate, child: Text(req['requestDate'].toString().split('T')[0], style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
          SizedBox(
            width: colStatus,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          SizedBox(
            width: colAction,
            child: Center(
              child: status == 'Settled'
                  ? const Text('Already Settled', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 13))
                  : ElevatedButton(
                      onPressed: () => _showSettleModal(req),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981), shape: const StadiumBorder(), elevation: 0),
                      child: const Text('Settle', style: TextStyle(color: Colors.white, fontSize: 12))),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettleModal(Map<String, dynamic> request) {
    // Keep your existing modal logic here, but ensure it uses Get.back() for consistency
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Settle Request"),
              content: Text("Confirm settlement for ${request['serviceProvider']['emailId']}?"),
              actions: [
                TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () {
                      controller.updateStatus(request['id'], "Settled");
                      Get.back();
                    },
                    child: const Text("Confirm"))
              ],
            ));
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
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)));
  }
}