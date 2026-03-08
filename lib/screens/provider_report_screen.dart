import 'package:flutter/material.dart';

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
  // Filter State
  String? _selectedProvider;
  String? _selectedSubcategory;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  // Mock Data
  final List<String> _providers = ['Select a provider', 'Rajesh Kumar', 'Amit Singh', 'Priya Sharma', 'Vijay Verma', 'Anjali Gupta'];
  final List<String> _subcategories = ['Select Subcategory', 'Plumbing', 'Electrical', 'Cleaning', 'Carpentry'];

  // Helper for Date Picking
  Future<void> _pickDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
        if (isStart) _startDate = picked;
        else _endDate = picked;
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
                label: 'Select Provider',
                width: itemWidth,
                child: _buildDropdown(
                  value: _selectedProvider,
                  hint: 'Select a provider',
                  items: _providers,
                  onChanged: (val) => setState(() => _selectedProvider = val),
                ),
              ),
              _buildFilterItem(
                label: 'Start Date',
                width: itemWidth,
                child: _buildDateInput(true),
              ),
              _buildFilterItem(
                label: 'End Date',
                width: itemWidth, // Allow button to share row logic if needed
                child: Row(
                  children: [
                    Expanded(child: _buildDateInput(false)),
                    const SizedBox(width: 16),
                     SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Submit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                  ],
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
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdown({required String? value, required String hint, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 14, color: _muted)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: _muted),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateInput(bool isStart) {
    final date = isStart ? _startDate : _endDate;
    final text = date == null ? 'mm/dd/yyyy' : '${date.month}/${date.day}/${date.year}';
    
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
            Text(text, style: TextStyle(fontSize: 14, color: date == null ? _muted : _textDark)),
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
                SizedBox(
                  width: 200,
                  height: 40,
                  child: TextField(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      hintText: 'Search provider...',
                      hintStyle: const TextStyle(fontSize: 13, color: _muted),
                      prefixIcon: const Icon(Icons.search, size: 18, color: _muted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: _border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: _border)),
                    ),
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
                Expanded(flex: 3, child: _Th('PROVIDER NAME')),
                Expanded(flex: 4, child: _Th('CONTACT INFO')),
                Expanded(flex: 2, child: _Th('TOTAL\nEARNING', align: TextAlign.center)),
                Expanded(flex: 2, child: _Th('TOTAL\nSETTLEMENT', align: TextAlign.center)),
                Expanded(flex: 2, child: _Th('PENDING\nSETTLEMENT', align: TextAlign.right)),
                SizedBox(width: 60, child: _Th('ACTION', align: TextAlign.right)),
              ],
            ),
          ),

          // Table Rows
          _buildRow('01', 'Rajesh Kumar', 'ID: P-202301', '+91 98765 43210', 'rajesh.k@gmail.com', '₹ 45,000', '₹ 38,000', '₹ 7,000', 'assets/p1.jpg'),
          const Divider(height: 1, color: _border),
          _buildRow('02', 'Amit Singh', 'ID: P-202345', '+91 87654 32109', 'amit.singh@yahoo.com', '₹ 12,500', '₹ 12,500', '₹ 0', 'assets/p2.jpg'),
          const Divider(height: 1, color: _border),
          _buildRow('03', 'Priya Sharma', 'ID: P-202388', '+91 76543 21098', 'priya.sharma@gmail.com', '₹ 89,200', '₹ 80,000', '₹ 9,200', 'assets/p3.jpg'),
          const Divider(height: 1, color: _border),
          _buildRow('04', 'Vijay Verma', 'ID: P-202392', '+91 99887 76655', 'vijay.v@outlook.com', '₹ 8,400', '₹ 5,000', '₹ 3,400', 'assets/p4.jpg'),
          const Divider(height: 1, color: _border),
          _buildRow('05', 'Anjali Gupta', 'ID: P-202401', '+91 90123 45678', 'anjali.g@gmail.com', '₹ 32,150', '₹ 20,000', '₹ 12,150', 'assets/p5.jpg'),

          // Pagination
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 13, color: _muted),
                    children: [
                      TextSpan(text: 'Showing '),
                      TextSpan(text: '1-5', style: TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
                      TextSpan(text: ' of '),
                      TextSpan(text: '1240', style: TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
                      TextSpan(text: ' providers'),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _PageBtn('Previous'),
                    const SizedBox(width: 8),
                    _PageNumBtn('1', true),
                    const SizedBox(width: 4),
                    _PageNumBtn('2', false),
                    const SizedBox(width: 4),
                    _PageNumBtn('3', false),
                    const SizedBox(width: 4),
                    const Text('...', style: TextStyle(color: _muted)),
                    const SizedBox(width: 4),
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

  Widget _buildRow(String sl, String name, String id, String phone, String email, String earning, String settlement, String pending, String imgPath) {
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
                  // Placeholder for image logic; replace with NetworkImage if needed
                  child: Text(name[0], style: const TextStyle(color: _orange, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
                    const SizedBox(height: 2),
                    Text(id, style: const TextStyle(fontSize: 11, color: _muted)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.phone, size: 12, color: _muted),
                  const SizedBox(width: 6),
                  Text(phone, style: const TextStyle(fontSize: 12, color: _textDark)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.email, size: 12, color: _muted),
                  const SizedBox(width: 6),
                  Text(email, style: const TextStyle(fontSize: 12, color: _muted)),
                ]),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(earning, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark))),
          Expanded(flex: 2, child: Text(settlement, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF10B981)))),
          Expanded(flex: 2, child: Text(pending, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: _orange))),
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