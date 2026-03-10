import 'dart:math';
import 'package:flutter/material.dart';

class TransactionReportScreen extends StatelessWidget {
  const TransactionReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Main Background Color
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate-100
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER SECTION
            const _HeaderSection(),
            const SizedBox(height: 24),


            // 3. FILTERS SECTION
            const _FiltersSection(),
            const SizedBox(height: 24),

            // 4. DATA TABLE SECTION
            const _DataTableSection(),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. HEADER SECTION
// -----------------------------------------------------------------------------
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Provider Earn Report',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Manage financial movements and view Lucknow region insights.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED), // Orange-50
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Color(0xFFF97316)), // Orange-500
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'TOTAL TRANSACTIONS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '352',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}



// -----------------------------------------------------------------------------
// 3. FILTERS SECTION
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// 3. FILTERS SECTION (UPDATED)
// -----------------------------------------------------------------------------
class _FiltersSection extends StatelessWidget {
  const _FiltersSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.filter_alt_outlined,
                  size: 20, color: Color(0xFFF97316)),
              SizedBox(width: 8),
              Text('Provider Earn Filters',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive grid for inputs
              final width = constraints.maxWidth;
              final isSmall = width < 800;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.end, // Helps alignment
                children: [
                  _FilterInput(
                      label: 'Start Date',
                      hint: 'mm/dd/yyyy',
                      width: isSmall ? width : 180,
                      icon: Icons.calendar_today_outlined),
                  _FilterInput(
                      label: 'End Date',
                      hint: 'mm/dd/yyyy',
                      width: isSmall ? width : 180,
                      icon: Icons.calendar_today_outlined),
                  _FilterInput(
                      label: 'Sort By',
                      hint: 'Newest First',
                      width: isSmall ? width : 200,
                      isDropdown: true),
                  _FilterInput(
                      label: 'Choose First',
                      hint: '10 Records',
                      width: isSmall ? width : 150,
                      isDropdown: true),
                  
                  // --- FIXED BUTTON SECTION ---
                  SizedBox(
                    width: isSmall ? width : 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Invisible Label to match the height of other labels
                        const Text(
                          '', 
                          style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.w600
                          ),
                        ),
                        // 2. Exact same spacing as _FilterInput
                        const SizedBox(height: 6),
                        // 3. Button with exact same height as Input fields (46)
                        SizedBox(
                          width: double.infinity,
                          height: 46, 
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF97316),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: const Text('Apply Filter',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ----------------------------
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
class _FilterInput extends StatelessWidget {
  final String label;
  final String hint;
  final double width;
  final IconData? icon;
  final bool isDropdown;

  const _FilterInput({
    required this.label,
    required this.hint,
    required this.width,
    this.icon,
    this.isDropdown = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(hint,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A))),
                Icon(
                  isDropdown
                      ? Icons.keyboard_arrow_down_rounded
                      : (icon ?? Icons.calendar_month),
                  size: 18,
                  color: const Color(0xFF94A3B8),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. DATA TABLE SECTION
// -----------------------------------------------------------------------------
class _DataTableSection extends StatelessWidget {
  const _DataTableSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.search,
                            size: 20, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Search by Provider Name...',
                              style: TextStyle(color: Color(0xFF94A3B8))),
                        ),
                        Container(
                          margin: const EdgeInsets.all(2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Search',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download CSV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                  ),
                ),
              ],
            ),
          ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFFFF7ED),
            child: Row(
              children: const [
                SizedBox(width: 40, child: _Th('SL')),
                Expanded(flex: 1, child: _Th('PROVIDER INFO')),
                Expanded(flex: 1, child: _Th('TOTAL EARN', alignRight: true)),
              ],
            ),
          ),

          // Table Rows
          const _Tr(
            sl: '01',
            providerInfo: 'Ellison Trading',
            providerSub: 'Account payable',
            totalEarn: '₹17,909.89',
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const _Tr(
            sl: '02',
            providerInfo: 'Ellison Cardenas',
            providerSub: 'Account receivable',
            totalEarn: '₹21,839.69',
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const _Tr(
            sl: '03',
            providerInfo: 'John Roy',
            providerSub: 'Account receivable',
            totalEarn: '₹21,829.69',
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const _Tr(
            sl: '04',
            providerInfo: 'Ellison Cardenas',
            providerSub: '',
            totalEarn: '₹72,010.15',
          ),

          // Pagination
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    children: [
                      TextSpan(text: 'Showing '),
                      TextSpan(
                          text: '1 to 4',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      TextSpan(text: ' of '),
                      TextSpan(
                          text: '352',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      TextSpan(text: ' Entries'),
                    ],
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Prev',
                          style: TextStyle(color: Color(0xFF64748B))),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Next',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Th extends StatelessWidget {
  final String text;
  final bool alignRight;
  const _Th(this.text, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF7C2D12), // Dark Brown/Orange
        letterSpacing: 0.5,
      ),
    );
  }
}

class _Tr extends StatelessWidget {
  final String sl;
  final String providerInfo;
  final String providerSub;
  final String totalEarn;

  const _Tr({
    required this.sl,
    required this.providerInfo,
    required this.providerSub,
    required this.totalEarn,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
              width: 40,
              child: Text(sl,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(providerInfo,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B))),
                if (providerSub.isNotEmpty)
                  Text(providerSub,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(totalEarn,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }
}