import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../controllers/withdraw_controller.dart';
import '../controllers/banking_controller.dart';
import 'package:get/get.dart';
import '../models/bank_model.dart';
import '../widgets/custom_center_dialog.dart';

// --- THEME COLORS ---
const _bg = Color(0xFFF1F5F9); // Slate-100
const _panelBg = Colors.white;
const _muted = Color(0xFF64748B); // Slate-500
const _textDark = Color(0xFF0F172A); // Slate-900
const _border = Color(0xFFE2E8F0); // Slate-200
const _orange = Color(0xFFF97316); // Orange-500
const _orangeLight = Color(0xFFFFF7ED); // Orange-50

class ProviderReportScreen extends StatefulWidget {
  const ProviderReportScreen({super.key});

  @override
  State<ProviderReportScreen> createState() => _ProviderReportScreenState();
}

class _ProviderReportScreenState extends State<ProviderReportScreen> {
  final ApiService _api = ApiService();
  final WithdrawController controller = Get.put(WithdrawController());
  final BankingController bankingController = Get.put(BankingController());
  final TextEditingController _searchController = TextEditingController();
  // Filter State (Start Date = Today - 1 Year, End Date = Tomorrow)
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = true;
  
  // Report Data
  List<dynamic> _reportData = [];

  // Helper for Date Formatting
  String _formatDateForApi(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    setState(() => _isLoading = true);
    final data = await _api.getProviderBookingPayment(
      _formatDateForApi(_startDate),
      _formatDateForApi(_endDate),
    );
    if (mounted) {
      setState(() {
        _reportData = data ?? [];
        _isLoading = false;
      });
    }
  }
void _onSettleClick(Map<String, dynamic> row) async {
    final String pId = row['providerId'] ?? '';

    // 1. Fetch fresh bank details using your BankingController logic
    await bankingController.fetchProviderBankDetails(pId);

    // 2. Check if data was actually found
    if (bankingController.providerBankDetails.value != null) {
      _showSettleModal(row, bankingController.providerBankDetails.value!);
    } else {
      CustomCenterDialog.show(
        context,
        title: "No Bank Details",
        message: "This provider hasn't added their bank information yet.",
        type: DialogType.error,
      );
    }
  }
  // Helper for Date Picking
  Future<void> _pickDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _orange,
              onPrimary: Colors.white,
              onSurface: _textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _orange),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Ensure end date is not before start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          // Ensure start date is not after end date
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              _buildHeader(),
              const SizedBox(height: 24),

              // 2. KPI Section
              _buildKPISection(),
              const SizedBox(height: 24),

              // 3. Filters
              _buildFilters(),
              const SizedBox(height: 24),

              // 4. Provider List Table
              _buildProviderTable(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. HEADER SECTION ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Provider Earn Report',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Manage financial movements and view Lucknow region insights.',
              style: TextStyle(fontSize: 14, color: _muted),
            ),
          ],
        ),
      ],
    );
  }

  // --- NEW KPI SECTION ---
  Widget _buildKPISection() {
    double totalEarn = 0;
    for (var row in _reportData) {
      totalEarn += (row['totalPayment'] ?? 0.0);
    }

    return Container(
      width: double.infinity,
      alignment: Alignment.centerRight,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _panelBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _orangeLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined, color: _orange, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL PROVIDER EARNING',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _muted, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${totalEarn.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW DOWNLOAD LOGIC ---
  void _handleDownload() {
    if (_reportData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to download'), backgroundColor: Colors.red),
      );
      return;
    }

    final StringBuffer csv = StringBuffer();
    csv.writeln("SL,Provider Name,Total Earnings");

    for (int i = 0; i < _reportData.length; i++) {
        final row = _reportData[i];
        final name = (row['providerName'] ?? 'Unknown').replaceAll(',', '');
        final earn = (row['totalPayment'] ?? 0.0).toStringAsFixed(2);
        csv.writeln("${i + 1},$name,$earn");
    }

    try {
        // Since we already have dart:html import logic in other files, 
        // I will dynamically handle the download to avoid static import issues if file is shared.
        // Actually Customer List already uses it. I'll add the import if it's missing.
        _triggerFileDownload(csv.toString());
    } catch (e) {
        print("Download Error: $e");
    }
  }

  void _triggerFileDownload(String content) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "provider_earn_report.csv")
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text("Report downloaded successfully!"),
          ],
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- 2. FILTERS SECTION ---
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive layout logic
          final isWide = constraints.maxWidth > 800;
          final double itemWidth = isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth);

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildFilterItem(
                label: 'Start Date',
                width: itemWidth,
                child: _buildDateInput(true),
              ),
              _buildFilterItem(
                label: 'End Date',
                width: itemWidth,
                child: _buildDateInput(false),
              ),
              _buildFilterItem(
                label: '',
                width: itemWidth,
                child: SizedBox(
                   height: 48,
                   child: ElevatedButton.icon(
                     onPressed: _isLoading ? null : _fetchReportData,
                     icon: _isLoading 
                       ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                       : const Icon(Icons.check, size: 18),
                     label: Text(_isLoading ? 'Wait...' : 'Apply Filter'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: _orange,
                       foregroundColor: Colors.white,
                       elevation: 0,
                       padding: const EdgeInsets.symmetric(horizontal: 24),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                     ),
                   ),
                 ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterItem({required String label, required double width, required Widget child}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
            const SizedBox(height: 8),
          ] else ...[
            const SizedBox(height: 25), // Adjust empty space to align horizontally
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildDateInput(bool isStart) {
    final date = isStart ? _startDate : _endDate;
    final text = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    
    return InkWell(
      onTap: () => _pickDate(isStart),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: const TextStyle(fontSize: 14, color: _textDark)),
            const Icon(Icons.calendar_today_outlined, size: 18, color: _textDark),
          ],
        ),
      ),
    );
  }

  // --- 3. PROVIDER TABLE SECTION ---
  Widget _buildProviderTable() {
    return Container(
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // SEARCH BAR & DOWNLOAD ROW
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _bg, // Use light grey bg from screenshot
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 20, color: _muted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Search by Provider Name...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(fontSize: 14, color: _muted),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    fixedSize: const Size(120, 48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _handleDownload,
                  icon: const Icon(Icons.download, size: 18, color: Colors.white),
                  label: const Text('Download CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    fixedSize: const Size(180, 48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: _orangeLight,
            child: Row(
              children: const [
                SizedBox(width: 40, child: _Th('SL')),
                Expanded(flex: 3, child: _Th('PROVIDER INFO')),
                Expanded(flex: 2, child: _Th('TOTAL EARN', align: TextAlign.right)),
              ],
            ),
          ),

          // Table Rows
          if (_isLoading && _reportData.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_reportData.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text("No records found", style: TextStyle(color: _muted))),
            )
          else
            ...[
              for (var entry in _reportData.asMap().entries.where((e) {
                final query = _searchController.text.toLowerCase();
                if (query.isEmpty) return true;
                final name = (e.value['providerName'] ?? '').toString().toLowerCase();
                return name.contains(query);
              }).toList()) 
                Column(
                  children: [
                    _buildRow(
                      (entry.key + 1).toString().padLeft(2, '0'),
                      entry.value['providerName'] ?? 'Unknown',
                      entry.value['providerId'] ?? '',
                      '₹${(entry.value['totalPayment'] ?? 0.0).toStringAsFixed(2)}',
                    ),
                    const Divider(height: 1, color: _border),
                  ],
                ),
            ],

          // Pagination
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: _muted),
                    children: [
                      const TextSpan(text: 'Showing '),
                      TextSpan(text: _reportData.isEmpty ? '0' : '1-${_reportData.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
                      const TextSpan(text: ' of '),
                      TextSpan(text: '${_reportData.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
                      const TextSpan(text: ' providers'),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _PageBtn('Previous'),
                    const SizedBox(width: 8),
                    _PageNumBtn('1', true),
                    const SizedBox(width: 8),
                    _PageBtn('Next'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String sl, String name, String id, String earning) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(sl, style: const TextStyle(fontWeight: FontWeight.w600, color: _textDark, fontSize: 13))),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _orangeLight,
                  child: Text(name.isNotEmpty ? name[0] : 'U', style: const TextStyle(color: _orange, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
                      const SizedBox(height: 2),
                      Text("ID: $id", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: _muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(earning, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark, fontSize: 14))),
        ],
      ),
    );
  }
void _showSettleModal(Map<String, dynamic> request, ProviderBankDetails bank) {
  final TextEditingController noteController = TextEditingController();

  // Calculate default pending balance
  double earn = (request['totalPayment'] ?? 0.0).toDouble();
  double settled = (request['totalSettled'] ?? 0.0).toDouble();
  double pendingBalance = earn - settled;

  // Controller for custom amount, pre-filled with pending balance
  final TextEditingController amountController =
      TextEditingController(text: pendingBalance.toStringAsFixed(2));

  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                // Use Get.back() for consistency with Get.dialog
                icon: const Icon(Icons.close),
                onPressed: () => Get.back(),
              ),
            ),
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFDCFCE7),
              child: Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 40),
            ),
            const SizedBox(height: 16),
            const Text("Settled this request?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildModalCard("Provider Information", [
                  Text(request['providerName'] ?? 'Unknown',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  Text(request['mobileNo'] ?? 'N/A', style: const TextStyle(fontSize: 12)),
                  const Text("Lucknow", style: TextStyle(fontSize: 12)),
                ]),
                const SizedBox(width: 12),
                _buildModalCard("Withdraw Bank details", [
                  Text(bank.bankName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("A/C: ${bank.accountNo}", style: const TextStyle(fontSize: 11)),
                  Text("IFSC: ${bank.ifscCode}", style: const TextStyle(fontSize: 11)),
                  if (bank.upiId != null && bank.upiId!.isNotEmpty)
                    Text("UPI: ${bank.upiId}", style: const TextStyle(fontSize: 11)),
                ]),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Settlement Amount (₹)",
                hintText: "Enter amount",
                prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Note (Admin Comment)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFC7D2FE)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      String? finalBankId = bank.bankId;

                      if (finalBankId == null || finalBankId.isEmpty) {
                        CustomCenterDialog.show(
                          Get.context!,
                          title: "Error",
                          message: "Bank ID is missing from provider profile",
                          type: DialogType.error,
                        );
                        return;
                      }

                      double finalAmount = double.tryParse(amountController.text) ?? 0.0;

                      if (finalAmount <= 0) {
                        CustomCenterDialog.show(
                          Get.context!,
                          title: "Invalid Amount",
                          message: "Please enter an amount greater than 0",
                          type: DialogType.required,
                        );
                        return;
                      }

                      // Call settlement (Controller handles closing this modal on success)
                      await controller.settleWithdrawRequest(
                        providerId: request['providerId'] ?? '',
                        providerBankId: finalBankId,
                        amount: finalAmount,
                        comment: noteController.text.trim(),
                      );

                      // Refresh data table
                      _fetchReportData();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                    child: const Text("Yes", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
// Helper for modal cards
Widget _buildModalCard(String title, List<Widget> children) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}
}

// --- HELPER WIDGETS ---

class _Th extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _Th(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF9A7B6B), // Muted brownish-orange from design
        letterSpacing: 0.5,
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final String text;
  const _PageBtn(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: _muted)),
    );
  }
}

class _PageNumBtn extends StatelessWidget {
  final String text;
  final bool active;
  const _PageNumBtn(this.text, this.active);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? _orange : Colors.transparent,
        border: Border.all(color: active ? _orange : _border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: active ? Colors.white : _muted)),
    );
  }
}