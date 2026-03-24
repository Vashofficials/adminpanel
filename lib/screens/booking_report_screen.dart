import 'dart:math'; // Required for max function
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/booking_report_model.dart';

// --- THEME COLORS ---
const _bg = Color(0xFFF1F5F9); 
const _panelBg = Colors.white;
const _muted = Color(0xFF64748B); 
const _textDark = Color(0xFF0F172A); 
const _border = Color(0xFFE2E8F0); 
const _orange = Color(0xFFF97316); 
const _orangeLight = Color(0xFFFFF7ED); 
const _shadow = BoxShadow(
  color: Color(0x0F000000),
  blurRadius: 12,
  offset: Offset(0, 4),
);

class BookingReportScreen extends StatefulWidget {
  const BookingReportScreen({super.key});

  @override
  State<BookingReportScreen> createState() => _BookingReportScreenState();
}

class _BookingReportScreenState extends State<BookingReportScreen> {
  // --- FILTER STATE ---
  String? _selectedProvider;
  String _selectedYear = DateTime.now().year.toString();
  String? _activeCardStatus; // For tapable cards
  bool _isLoading = false;

  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _providersData = [];
  BookingReportModel? _reportData;

  final Map<String, GlobalKey> _chartKeys = {
    'Completed': GlobalKey(),
    'Ongoing': GlobalKey(),
    'Pending': GlobalKey(),
    'Cancelled': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (_providersData.isEmpty) {
        final pData = await _api.getAllServiceProviders();
        if (pData != null && pData['result'] != null) {
          _providersData = List<Map<String, dynamic>>.from(pData['result']);
        }
      }
      
      final report = await _api.getBookingReport(_selectedYear, providerId: _selectedProvider);
      
      if (mounted) {
        setState(() {
          _reportData = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _loadData();
  }

  // Removed _pickDateRange as it is replaced by Status filter

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
              const _TopAppBar(),
              const SizedBox(height: 24),
              
              // Search Filters
              _buildSearchFilters(),
              const SizedBox(height: 24),
              
              // Stats
              if (_reportData != null && _reportData!.result != null)
                _SummaryStatsCard(
                  reportResult: _reportData!.result!,
                  isFullWidth: true,
                  activeStatus: _activeCardStatus,
                  onStatusTap: (status) {
                    setState(() {
                      _activeCardStatus = (_activeCardStatus == status) ? null : status;
                    });
                    if (_activeCardStatus != null && _chartKeys[_activeCardStatus] != null && _chartKeys[_activeCardStatus]!.currentContext != null) {
                      Scrollable.ensureVisible(
                        _chartKeys[_activeCardStatus]!.currentContext!,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              const SizedBox(height: 24),
              
              // 4 Separate Charts
              LayoutBuilder(
                builder: (context, constraints) {
                  final isLarge = constraints.maxWidth > 1100;
                  return Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      if (_reportData != null && _reportData!.result != null) ...[
                        SizedBox(
                          key: _chartKeys['Completed'],
                          width: isLarge ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth,
                          child: _StatusChartCard(
                            title: 'Completed Bookings',
                            dataList: _reportData!.result!.completedMonth ?? [],
                          ),
                        ),
                        SizedBox(
                          key: _chartKeys['Ongoing'],
                          width: isLarge ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth,
                          child: _StatusChartCard(
                            title: 'Ongoing Bookings',
                            dataList: _reportData!.result!.ongoingMonth ?? [],
                          ),
                        ),
                        SizedBox(
                          key: _chartKeys['Pending'],
                          width: isLarge ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth,
                          child: _StatusChartCard(
                            title: 'Pending Bookings',
                            dataList: _reportData!.result!.pendingMonth ?? [],
                          ),
                        ),
                        SizedBox(
                          key: _chartKeys['Cancelled'],
                          width: isLarge ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth,
                          child: _StatusChartCard(
                            title: 'Cancelled Bookings',
                            dataList: _reportData!.result!.cancelledMonth ?? [],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [_shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.filter_alt_outlined, color: _orange),
              SizedBox(width: 8),
              Text(
                'Filter Booking Data',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  _buildProviderDropdown(),
                  _buildYearDropdown(),

                  // Submit Button
                  SizedBox(
                    height: 48,
                    width: 120,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _applyFilters,
                      icon: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Icon(Icons.search, size: 18),
                      label: Text(_isLoading ? '...' : 'Filter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildProviderDropdown() {
    // Safely build unique items
    final List<DropdownMenuItem<String>> dropdownItems = [
      const DropdownMenuItem<String>(value: null, child: Text("All Providers", style: TextStyle(fontSize: 13))),
    ];
    final Set<String> seenIds = {};
    for (var p in _providersData) {
      final id = p['_id']?.toString() ?? p['id']?.toString() ?? '';
      if (id.isNotEmpty && !seenIds.contains(id)) {
        seenIds.add(id);
        dropdownItems.add(
          DropdownMenuItem<String>(
            value: id,
            child: Text(p['name']?.toString() ?? 'Unknown', style: const TextStyle(fontSize: 13)),
          )
        );
      }
    }

    // Ensure currently selected value is valid or reset to null
    if (_selectedProvider != null && !seenIds.contains(_selectedProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedProvider = null);
      });
      _selectedProvider = null;
    }

    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Provider (Disabled temporarily)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              // make it look visually disabled
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedProvider,
                hint: const Text('Select Provider', style: TextStyle(fontSize: 13, color: _muted)),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: _muted),
                items: dropdownItems,
                // Passing null disables the DropdownButton
                onChanged: null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearDropdown() {
    int currentYear = DateTime.now().year;
    // ensure at least 2026/2027 logic if system clock is behind
    if (currentYear < 2025) currentYear = 2026; 
    
    final int startYear = 2025;
    final int count = max(1, currentYear - startYear + 1);
    final years = List.generate(count, (i) => (startYear + i).toString());
    
    // Ensure selected year is in the list to prevent assertion errors
    if (!years.contains(_selectedYear)) {
      years.add(_selectedYear);
      years.sort((a, b) => b.compareTo(a)); // Sort descending if adding outside range
    }

    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Year', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedYear,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: _muted),
                items: years.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedYear = v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Booking Analysis',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark),
            ),
            SizedBox(height: 4),
            Text('Monitor booking status and revenue', style: TextStyle(fontSize: 14, color: _muted)),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
          color: _muted,
          tooltip: 'Notifications',
        ),
        const SizedBox(width: 12),
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: _orangeLight,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text('A', style: TextStyle(color: _orange, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      ],
    );
  }
}

class _SummaryStatsCard extends StatelessWidget {
  final BookingResult reportResult;
  final bool isFullWidth;
  final String? activeStatus;
  final Function(String)? onStatusTap;
  
  const _SummaryStatsCard({required this.reportResult, this.isFullWidth = false, this.activeStatus, this.onStatusTap});

  @override
  Widget build(BuildContext context) {
    int cancelled = reportResult.cancelled ?? 0;
    int completed = reportResult.completed ?? 0;
    int ongoing = reportResult.ongoing ?? 0;
    int pending = reportResult.pending ?? 0;
    int total = cancelled + completed + ongoing + pending;

    int totalCashCancelled = (reportResult.cancelledMonth ?? []).fold(0, (sum, item) => sum + (item.cashBooking ?? 0));
    int totalOnlineCancelled = (reportResult.cancelledMonth ?? []).fold(0, (sum, item) => sum + (item.onlineBooking ?? 0));

    int totalCashCompleted = (reportResult.completedMonth ?? []).fold(0, (sum, item) => sum + (item.cashBooking ?? 0));
    int totalOnlineCompleted = (reportResult.completedMonth ?? []).fold(0, (sum, item) => sum + (item.onlineBooking ?? 0));

    int totalCashOngoing = (reportResult.ongoingMonth ?? []).fold(0, (sum, item) => sum + (item.cashBooking ?? 0));
    int totalOnlineOngoing = (reportResult.ongoingMonth ?? []).fold(0, (sum, item) => sum + (item.onlineBooking ?? 0));

    int totalCashPending = (reportResult.pendingMonth ?? []).fold(0, (sum, item) => sum + (item.cashBooking ?? 0));
    int totalOnlinePending = (reportResult.pendingMonth ?? []).fold(0, (sum, item) => sum + (item.onlineBooking ?? 0));


    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [_shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _orangeLight, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.confirmation_number_outlined, color: _orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Total Bookings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _muted)),
            ],
          ),
          const SizedBox(height: 16),
          Text(total.toString(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _textDark)),
          const SizedBox(height: 24),
          
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _StatItem(
                color: const Color(0xFFEF4444), 
                label: 'Canceled', 
                value: cancelled.toString(), 
                icon: Icons.cancel_outlined,
                isActive: activeStatus == 'Cancelled',
                onTap: () => onStatusTap?.call('Cancelled'),
                cash: totalCashCancelled.toString(), online: totalOnlineCancelled.toString(),
              ),
              _StatItem(
                color: const Color(0xFF10B981), 
                label: 'Completed', 
                value: completed.toString(), 
                icon: Icons.check_circle_outline,
                isActive: activeStatus == 'Completed',
                onTap: () => onStatusTap?.call('Completed'),
                cash: totalCashCompleted.toString(), online: totalOnlineCompleted.toString(),
              ),
              _StatItem(
                color: const Color(0xFFF59E0B), 
                label: 'Ongoing', 
                value: ongoing.toString(), 
                icon: Icons.timelapse,
                isActive: activeStatus == 'Ongoing',
                onTap: () => onStatusTap?.call('Ongoing'),
                cash: totalCashOngoing.toString(), online: totalOnlineOngoing.toString(),
              ),
              _StatItem(
                color: const Color(0xFF64748B), 
                label: 'Pending', 
                value: pending.toString(), 
                icon: Icons.pending_outlined,
                isActive: activeStatus == 'Pending',
                onTap: () => onStatusTap?.call('Pending'),
                cash: totalCashPending.toString(), online: totalOnlinePending.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;
  final String cash;
  final String online;

  const _StatItem({
    required this.color, 
    required this.label, 
    required this.value, 
    required this.icon,
    this.isActive = false,
    this.onTap,
    required this.cash,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100, // Increased width for cash/online text
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? color : Colors.transparent, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Cash & Online Breakdown
            Row(
              children: [
                const Icon(Icons.money, size: 10, color: _muted),
                const SizedBox(width: 2),
                Text(cash, style: const TextStyle(fontSize: 10, color: _muted, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                const Icon(Icons.account_balance_wallet_outlined, size: 10, color: _muted),
                const SizedBox(width: 2),
                Text(online, style: const TextStyle(fontSize: 10, color: _muted, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChartCard extends StatelessWidget {
  final String title;
  final List<MonthData> dataList;
  
  const _StatusChartCard({required this.title, required this.dataList});

  @override
  Widget build(BuildContext context) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    // Map the returned dataList to the 12 UI months
    List<int> cashValues = List.filled(12, 0);
    List<int> onlineValues = List.filled(12, 0);

    for (var mData in dataList) {
      if (mData.mothName != null) {
        int idx = months.indexOf(mData.mothName!);
        if (idx != -1) {
          cashValues[idx] = mData.cashBooking ?? 0;
          onlineValues[idx] = mData.onlineBooking ?? 0;
        }
      }
    }

    // Determine scale for chart
    int maxVal = 0;
    for (int i = 0; i < 12; i++) {
        maxVal = max(maxVal, cashValues[i]);
        maxVal = max(maxVal, onlineValues[i]);
    }
    
    // Default Y axis scale
    int yMax = maxVal > 0 ? ((maxVal / 5).ceil() * 5) : 10;
    if (yMax == 0) yMax = 5;

    return Container(
      height: 340, 
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: const [_shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
              Row(
                children: [
                  // Legend
                  Container(width: 10, height: 10, color: const Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  const Text('Online', style: TextStyle(fontSize: 10, color: _muted)),
                  const SizedBox(width: 12),
                  Container(width: 10, height: 10, color: const Color(0xFF3B82F6)),
                  const SizedBox(width: 4),
                  const Text('Cash', style: TextStyle(fontSize: 10, color: _muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [yMax, (yMax*0.8).toInt(), (yMax*0.6).toInt(), (yMax*0.4).toInt(), (yMax*0.2).toInt(), 0]
                      .map((e) => Text(e.toString(), style: const TextStyle(fontSize: 10, color: _muted)))
                      .toList(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const double labelHeight = 24.0;
                      final double maxBarHeight = constraints.maxHeight - labelHeight;
                      final w = constraints.maxWidth / months.length;
                      
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(months.length, (i) {
                          double hCash = yMax > 0 ? (maxBarHeight * (cashValues[i] / yMax)) : 0;
                          double hOnline = yMax > 0 ? (maxBarHeight * (onlineValues[i] / yMax)) : 0;
                          
                          if (hCash > maxBarHeight) hCash = maxBarHeight;
                          if (hOnline > maxBarHeight) hOnline = maxBarHeight;

                          if (hCash < 0) hCash = 0;
                          if (hOnline < 0) hOnline = 0;

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Tooltip(
                                    message: 'Total: ${onlineValues[i] + cashValues[i]}\nOnline: ${onlineValues[i]}\nCash: ${cashValues[i]}',
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          width: w * 0.35,
                                          height: hOnline,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Container(
                                          width: w * 0.35,
                                          height: hCash,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF3B82F6),
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 16,
                                child: Text(months[i], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _muted)),
                              ),
                            ],
                          );
                        }),
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
