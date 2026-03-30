import 'package:flutter/material.dart';

// --- THEME COLORS ---
const Color _orange = Color(0xFFF97316);      // Primary Action Color
const Color _orangeLight = Color(0xFFFFF7ED); // Light Orange for Backgrounds
const Color _bg = Color(0xFFF7F9FC);          // App Background
const Color _panelBg = Colors.white;          // Panel Background
const Color _border = Color(0xFFE5E7EB);      // Divider/Border Color
const Color _textDark = Color(0xFF1F2937);    // Primary Text
const Color _muted = Color(0xFF6B7280);       // Subtext / Icons

class _ReferralScreenBase extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ReferralScreenBase({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            color: Colors.white,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: _muted),
                ),
              ],
            ),
          ),
          
          // 2. Page Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class PendingRewardsScreen extends StatelessWidget {
  final ValueChanged<String>? onNav;
  const PendingRewardsScreen({super.key, this.onNav});

  @override
  Widget build(BuildContext context) {
    return _ReferralScreenBase(
      title: "Pending Rewards",
      subtitle: "Review and process referral rewards triggered by new customers.",
      child: _PendingRewardsTab(),
    );
  }
}

class PaidCommissionsScreen extends StatelessWidget {
  final ValueChanged<String>? onNav;
  const PaidCommissionsScreen({super.key, this.onNav});

  @override
  Widget build(BuildContext context) {
    return _ReferralScreenBase(
      title: "Paid Commissions",
      subtitle: "View historical paid cash commissions assigned to referrers.",
      child: _PaidCommissionsTab(),
    );
  }
}

class IssuedCouponsScreen extends StatelessWidget {
  final ValueChanged<String>? onNav;
  const IssuedCouponsScreen({super.key, this.onNav});

  @override
  Widget build(BuildContext context) {
    return _ReferralScreenBase(
      title: "Issued Coupons",
      subtitle: "View promotional coupons distributed as referral rewards.",
      child: _IssuedCouponsTab(),
    );
  }
}

// -----------------------------------------------------------------------------
// PENDING REWARDS TAB
// -----------------------------------------------------------------------------
class _PendingRewardsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _buildFilterBar(),
          const Divider(height: 1, color: _border),
          _buildTableHeader(['CUSTOMER B (BUYER)', 'ORDER DETAILS', 'REFERRER (CUSTOMER A)', 'COMPLETION DATE', 'STATUS', 'ACTIONS']),
          Expanded(
            child: ListView.separated(
              itemCount: 4,
              separatorBuilder: (context, index) => const Divider(height: 1, color: _border),
              itemBuilder: (context, index) {
                return _buildRow(
                  customerB: "Rahul Jaiswal\nrahul.j@example.com",
                  orderDetails: "₹1,250.00\nID: #ORD-98211",
                  customerA: "Amit Sharma",
                  date: "Oct 24, 2026\n14:22 PM",
                  status: "NEEDS REVIEW",
                  onAction: () => _showProcessRewardDialog(context),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _showProcessRewardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 800,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Reward Fulfillment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
                    IconButton(icon: const Icon(Icons.close, color: _muted), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Process action for Referral Trigger. Please choose an option below to fulfill Customer A's reward based on Customer B's first successful order.", style: TextStyle(color: _muted, fontSize: 13)),
                const SizedBox(height: 24),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildRewardOption1()),
                    const SizedBox(width: 24),
                    Expanded(child: _buildRewardOption2()),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildRewardOption1() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("1. Direct Bank Commission", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 8),
          const Text("Process a direct cash incentive to the referrer's verified bank account or UPI.", style: TextStyle(fontSize: 12, color: _muted)),
          const SizedBox(height: 20),
          const Text("COMMISSION PERCENTAGE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _muted)),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              suffixText: "%",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            controller: TextEditingController(text: "10"),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(6)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("CALCULATED REWARD", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _muted)),
                SizedBox(height: 4),
                Text("₹125.00", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: _orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
              child: const Text("Mark as Paid via UPI/Bank", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRewardOption2() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("2. Specific Coupon Code", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 8),
          const Text("Issue a one-time promotional code that the referrer can apply on their next purchase.", style: TextStyle(fontSize: 12, color: _muted)),
          const SizedBox(height: 20),
          const Text("PROMOTION CODE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _muted)),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            controller: TextEditingController(text: "FLAT200"),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(6)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("BENEFIT TO USER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _muted)),
                SizedBox(height: 4),
                Text("₹200.00 off next order", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: _orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
              child: const Text("Assign Coupon Code", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PAID COMMISSIONS TAB
// -----------------------------------------------------------------------------
class _PaidCommissionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _buildFilterBar(),
          const Divider(height: 1, color: _border),
          _buildTableHeader(['DATE', 'REFERRER (CUSTOMER A)', 'REWARD TYPE', 'AMOUNT PAID', 'STATUS', 'TRIGGER ORDER', '']),
          Expanded(
            child: ListView.separated(
              itemCount: 4,
              separatorBuilder: (context, index) => const Divider(height: 1, color: _border),
              itemBuilder: (context, index) {
                return _buildRow(
                  customerB: "Oct 24, 2026\n14:32 PM",
                  orderDetails: "Alex Morgan\nalex.m@example.com",
                  customerA: "Bank Commission",
                  date: "₹150.00",
                  status: "PAID",
                  isPaid: true,
                  actionText: "#ORD-90210",
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ISSUED COUPONS TAB
// -----------------------------------------------------------------------------
class _IssuedCouponsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _buildFilterBar(),
          const Divider(height: 1, color: _border),
          _buildTableHeader(['DATE', 'REFERRER (CUSTOMER A)', 'REWARD TYPE', 'COUPON CODE', 'STATUS', 'TRIGGER ORDER', '']),
          Expanded(
            child: ListView.separated(
              itemCount: 4,
              separatorBuilder: (context, index) => const Divider(height: 1, color: _border),
              itemBuilder: (context, index) {
                return _buildRow(
                  customerB: "Oct 23, 2026\n09:15 AM",
                  orderDetails: "Sarah Chen\ns.chen@corp.com",
                  customerA: "Promo Coupon",
                  date: "REF-SAVE-20",
                  status: "ISSUED",
                  isPaid: true,
                  actionText: "#ORD-88722",
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SHARED WIDGETS
// -----------------------------------------------------------------------------

Widget _buildFilterBar() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 300,
          height: 40,
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search triggers, orders, or referrers...",
              hintStyle: const TextStyle(fontSize: 13, color: _muted),
              prefixIcon: const Icon(Icons.search, size: 18, color: _muted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: _border)),
            ),
          ),
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_list, size: 16, color: _textDark),
              label: const Text("Filter", style: TextStyle(color: _textDark)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: _border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
            ),
          ],
        )
      ],
    ),
  );
}

Widget _buildTableHeader(List<String> columns) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    color: _orangeLight,
    child: Row(
      children: columns.map((col) => Expanded(
        flex: col == 'STATUS' || col == 'ACTIONS' || col == '' ? 1 : 2,
        child: Text(col, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _muted, letterSpacing: 0.5)),
      )).toList(),
    ),
  );
}

Widget _buildRow({
  required String customerB, 
  required String orderDetails, 
  required String customerA, 
  required String date, 
  required String status,
  VoidCallback? onAction,
  bool isPaid = false,
  String? actionText,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    child: Row(
      children: [
        // Col 1
        Expanded(flex: 2, child: _multilineText(customerB)),
        // Col 2
        Expanded(flex: 2, child: _multilineText(orderDetails)),
        // Col 3
        Expanded(flex: 2, child: _multilineText(customerA)),
        // Col 4
        Expanded(flex: 2, child: _multilineText(date)),
        // Col 5
        Expanded(
          flex: 1, 
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'PAID' || status == 'ISSUED' ? const Color(0xFFD1FAE5) : _orangeLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: status == 'PAID' || status == 'ISSUED' ? const Color(0xFF059669) : _orange)),
            ),
          ),
        ),
        // Col 6
        Expanded(
          flex: 1, 
          child: Align(
            alignment: Alignment.centerLeft,
            child: isPaid 
              ? Text(actionText ?? "", style: const TextStyle(fontWeight: FontWeight.w600, color: _textDark))
              : ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  child: const Text("Process", style: TextStyle(fontSize: 12)),
                ),
          ),
        ),
      ],
    ),
  );
}

Widget _multilineText(String text) {
  final parts = text.split('\n');
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(parts[0], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
      if (parts.length > 1) ...[
        const SizedBox(height: 4),
        Text(parts[1], style: const TextStyle(fontSize: 12, color: _muted)),
      ]
    ],
  );
}
