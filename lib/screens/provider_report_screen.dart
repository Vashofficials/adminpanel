import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
  
  // Filter State
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();
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

              // 2. Filters
              _buildFilters(),
              const SizedBox(height: 24),

              // 3. Provider List Table
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
              'Provider Settlement Report',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Manage and view provider reports for Lucknow region.',
              style: TextStyle(fontSize: 14, color: _muted),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Export CSV'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _textDark,
            side: const BorderSide(color: _border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ],
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
          // Toolbar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Provider List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
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
                Expanded(flex: 2, child: _Th('TOTAL\nBOOKINGS', align: TextAlign.center)),
                Expanded(flex: 2, child: _Th('TOTAL\nEARN', align: TextAlign.center)),
                Expanded(flex: 2, child: _Th('TOTAL\nSETTLED', align: TextAlign.center)),
                SizedBox(width: 60, child: _Th('ACTION', align: TextAlign.right)),
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
            ..._reportData.asMap().entries.map((entry) {
              int idx = entry.key;
              Map<String, dynamic> row = entry.value;
              String providerName = row['providerName'] ?? 'Unknown';
              String providerId = row['providerId'] ?? '';
              
              String sl = (idx + 1).toString().padLeft(2, '0');
              String bookings = (row['totalBookings'] ?? 0).toString();
              String earn = '₹${(row['totalPayment'] ?? 0.0).toStringAsFixed(2)}';
              String settled = '₹${(row['totalSettled'] ?? 0.0).toStringAsFixed(2)}';
              return Column(
                children: [
                  _buildRow(sl, providerName, providerId, bookings, earn, settled),
                  if (idx < _reportData.length - 1)
                     const Divider(height: 1, color: _border),
                ],
              );
            }).toList(),

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

  Widget _buildRow(String sl, String name, String id, String bookings, String earning, String settlement) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(sl, style: const TextStyle(fontWeight: FontWeight.w600, color: _textDark))),
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
          Expanded(flex: 2, child: Text(bookings, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, color: _textDark))),
          Expanded(flex: 2, child: Text(earning, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark))),
          Expanded(flex: 2, child: Text(settlement, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF10B981)))),
          const SizedBox(width: 60, child: Align(alignment: Alignment.centerRight, child: Icon(Icons.remove_red_eye, color: _muted, size: 20))),
        ],
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