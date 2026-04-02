import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/transaction_report_controller.dart';

class TransactionReportScreen extends StatelessWidget {
  const TransactionReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TransactionReportController());

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
    final controller = Get.find<TransactionReportController>();

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
                'Manage financial movements and view provider earning insights.',
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
                children: [
                  const Text(
                    'Total Provider Earning',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Obx(() => Text(
                    '₹${NumberFormat('#,##,###.##').format(controller.totalProviderEarning)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  )),
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
          Obx(() {
            final controller = Get.find<TransactionReportController>();
            final isSmall = MediaQuery.of(context).size.width < 800;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                _FilterInput(
                  label: 'Start Date',
                  hint: DateFormat('MM/dd/yyyy').format(controller.fromDate.value),
                  width: isSmall ? double.infinity : 180,
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _selectDate(context, controller.fromDate),
                ),
                _FilterInput(
                  label: 'End Date',
                  hint: DateFormat('MM/dd/yyyy').format(controller.toDate.value),
                  width: isSmall ? double.infinity : 180,
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _selectDate(context, controller.toDate),
                ),
                
                // --- APPLY FILTER BUTTON ---
                SizedBox(
                  width: isSmall ? double.infinity : 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => controller.fetchReport(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: controller.isLoading.value 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Apply Filter',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, Rx<DateTime> date) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF97316),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      date.value = picked;
    }
  }
}

class _FilterInput extends StatelessWidget {
  final String label;
  final String hint;
  final double width;
  final IconData? icon;
  final bool isDropdown;
  final VoidCallback? onTap;

  const _FilterInput({
    required this.label,
    required this.hint,
    required this.width,
    this.icon,
    this.isDropdown = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
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
                        Expanded(
                          child: TextField(
                            onChanged: (v) => Get.find<TransactionReportController>().searchText.value = v,
                            decoration: const InputDecoration(
                              hintText: 'Search by Provider Name...',
                              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {},
                          child: Container(
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
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => Get.find<TransactionReportController>().exportToCSV(),
                  icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                  label: const Text('Download CSV', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
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
          Obx(() {
            final controller = Get.find<TransactionReportController>();
            if (controller.isLoading.value) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Color(0xFFF97316))));
            }
            if (controller.filteredList.isEmpty) {
              return const SizedBox(height: 200, child: Center(child: Text("No data found for selected period.")));
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.filteredList.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final item = controller.filteredList[index];
                return _Tr(
                  sl: (index + 1).toString().padLeft(2, '0'),
                  providerInfo: item.providerName,
                  providerSub: 'ID: ${item.providerId.substring(0, 8)}...',
                  totalEarn: '₹${NumberFormat('#,##,###.##').format(item.totalPayment)}',
                );
              },
            );
          }),

          // Pagination
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() {
                  final controller = Get.find<TransactionReportController>();
                  return RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      children: [
                        const TextSpan(text: 'Showing '),
                        TextSpan(
                            text: '1 to ${controller.filteredList.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        const TextSpan(text: ' of '),
                        TextSpan(
                            text: '${controller.reportList.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        const TextSpan(text: ' Entries'),
                      ],
                    ),
                  );
                }),
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