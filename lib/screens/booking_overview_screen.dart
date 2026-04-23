import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../controllers/booking_overview_controller.dart';
import '../models/booking_models.dart';

// =============================================================================
// BOOKING OVERVIEW SCREEN
// =============================================================================

class BookingOverviewScreen extends StatefulWidget {
  final ValueChanged<String> onNav;
  final Function(BookingModel) onViewDetails;

  const BookingOverviewScreen({
    super.key,
    required this.onNav,
    required this.onViewDetails,
  });

  @override
  State<BookingOverviewScreen> createState() => _BookingOverviewScreenState();
}

class _BookingOverviewScreenState extends State<BookingOverviewScreen> {
  late final BookingOverviewController _ctrl;

  // --- Filter State ---
  final TextEditingController _searchCtrl = TextEditingController();
  String _filterStatus = 'All';
  String _filterPaymentMode = 'All';
  DateTime? _scheduleFrom;
  DateTime? _scheduleTo;
  DateTime? _bookingFrom;
  DateTime? _bookingTo;
  bool _filtersVisible = false;

  // --- Pagination for recent bookings table ---
  int _tablePage = 0;
  static const int _tablePageSize = 10;

  @override
  void initState() {
    super.initState();
    // Use Get.put only if not already registered
    _ctrl = Get.isRegistered<BookingOverviewController>()
        ? Get.find<BookingOverviewController>()
        : Get.put(BookingOverviewController());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // FILTERED RECENT BOOKINGS
  // ---------------------------------------------------------------------------
  List<BookingModel> get _filteredBookings {
    final keyword = _searchCtrl.text.toLowerCase();
    return _ctrl.recentBookings.where((b) {
      // Search
      if (keyword.isNotEmpty) {
        final match = b.bookingRef.toLowerCase().contains(keyword) ||
            b.customerName.toLowerCase().contains(keyword) ||
            b.customerPhone.toLowerCase().contains(keyword);
        if (!match) return false;
      }
      // Status filter
      if (_filterStatus != 'All' &&
          b.status.toLowerCase() != _filterStatus.toLowerCase()) return false;
      // Payment mode filter
      if (_filterPaymentMode != 'All' &&
          b.paymentMode.toUpperCase() != _filterPaymentMode.toUpperCase())
        return false;
      // Schedule date range
      if (_scheduleFrom != null || _scheduleTo != null) {
        try {
          final d = DateFormat('yyyy-MM-dd').parse(b.bookingDate);
          if (_scheduleFrom != null && d.isBefore(_scheduleFrom!)) return false;
          if (_scheduleTo != null && d.isAfter(_scheduleTo!)) return false;
        } catch (_) {}
      }
      // Booking date range
      if (_bookingFrom != null || _bookingTo != null) {
        try {
          final d = DateTime.parse(b.creationTime);
          if (_bookingFrom != null && d.isBefore(_bookingFrom!)) return false;
          if (_bookingTo != null && d.isAfter(_bookingTo!)) return false;
        } catch (_) {}
      }
      return true;
    }).toList();
  }

  List<BookingModel> get _pagedBookings {
    final all = _filteredBookings;
    final start = _tablePage * _tablePageSize;
    if (start >= all.length) return [];
    return all.sublist(start, (start + _tablePageSize).clamp(0, all.length));
  }

  int get _totalTablePages {
    final total = _filteredBookings.length;
    if (total == 0) return 1;
    return (total / _tablePageSize).ceil();
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  String _formatDate(String raw) {
    if (raw.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw.split('T')[0];
    }
  }

  String _formatDateOnly(String raw) {
    if (raw.isEmpty) return 'N/A';
    try {
      return DateFormat('dd MMM yyyy').format(DateFormat('yyyy-MM-dd').parse(raw));
    } catch (_) {
      return raw;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFFDCFCE7);
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'cancelled':
      case 'canceled':
        return const Color(0xFFFFE2E5);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _statusFg(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF16A34A);
      case 'pending':
        return const Color(0xFFD97706);
      case 'cancelled':
      case 'canceled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _paymentBg(String mode) {
    switch (mode.toUpperCase()) {
      case 'CASH':
      case 'OFFLINE':
        return const Color(0xFFFFE2E5);
      case 'ONLINE':
      case 'UPI':
        return const Color(0xFFDCFCE7);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _paymentFg(String mode) {
    switch (mode.toUpperCase()) {
      case 'CASH':
      case 'OFFLINE':
        return const Color(0xFFEF4444);
      case 'ONLINE':
      case 'UPI':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF64748B);
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_ctrl.isLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: Color(0xFFEF7822)));
      }
      if (_ctrl.errorMessage.value.isNotEmpty) {
        return _buildErrorState();
      }
      return _buildContent();
    });
  }

  // ---------------------------------------------------------------------------
  // ERROR STATE
  // ---------------------------------------------------------------------------
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 56, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text(_ctrl.errorMessage.value,
              style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF64748B))),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _ctrl.fetchOverviewData,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF7822), elevation: 0),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: Text('Retry',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN CONTENT
  // ---------------------------------------------------------------------------
  Widget _buildContent() {
    final ScrollController scrollCtrl = ScrollController();
    return SingleChildScrollView(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- PAGE HEADER ---
          _buildPageHeader(),
          const SizedBox(height: 24),

          // --- A. KPI CARDS ---
          _buildKpiCards(),
          const SizedBox(height: 24),

          // --- B & C. Charts Row ---
          LayoutBuilder(builder: (ctx, constraints) {
            if (constraints.maxWidth > 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildTrendChart()),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _buildDonutChart()),
                ],
              );
            }
            return Column(children: [
              _buildTrendChart(),
              const SizedBox(height: 20),
              _buildDonutChart(),
            ]);
          }),
          const SizedBox(height: 24),

          // --- D. Quick Actions ---
          _buildQuickActions(),
          const SizedBox(height: 24),

          // --- E. Filters ---
          _buildFiltersPanel(),
          const SizedBox(height: 20),

          // --- F. Recent Bookings Table ---
          _buildRecentBookingsTable(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE HEADER
  // ---------------------------------------------------------------------------
  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bookings Overview',
                style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text('Real-time booking analytics dashboard',
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF64748B))),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _ctrl.fetchOverviewData,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF7822),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
          label: Text('Refresh',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // A. KPI CARDS
  // ---------------------------------------------------------------------------
  Widget _buildKpiCards() {
    return Obx(() {
      final cards = [
        _KpiData(
          title: 'Total Bookings',
          value: _ctrl.totalBookings.value.toString(),
          subtitle: 'All statuses',
          icon: Icons.calendar_month_rounded,
          gradientColors: [const Color(0xFF2563EB), const Color(0xFF4F46E5)],
        ),
        _KpiData(
          title: 'Pending (Ongoing)',
          value: _ctrl.pendingCount.value.toString(),
          subtitle: _ctrl.percentOf(_ctrl.pendingCount.value),
          icon: Icons.timelapse_rounded,
          gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        ),
        _KpiData(
          title: 'Completed',
          value: _ctrl.completedCount.value.toString(),
          subtitle: _ctrl.percentOf(_ctrl.completedCount.value),
          icon: Icons.done_all_rounded,
          gradientColors: [const Color(0xFF22C55E), const Color(0xFF16A34A)],
        ),
        _KpiData(
          title: 'Canceled',
          value: _ctrl.canceledCount.value.toString(),
          subtitle: _ctrl.percentOf(_ctrl.canceledCount.value),
          icon: Icons.cancel_rounded,
          gradientColors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        ),
        _KpiData(
          title: 'Total Revenue',
          value: '₹${NumberFormat('#,##,###').format(_ctrl.totalRevenue.value.toInt())}',
          subtitle: 'From completed bookings',
          icon: Icons.currency_rupee_rounded,
          gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
        ),
      ];

      return LayoutBuilder(builder: (ctx, constraints) {
        final crossCount = constraints.maxWidth > 1200
            ? 5
            : constraints.maxWidth > 900
                ? 3
                : 2;
        final itemWidth =
            (constraints.maxWidth - (16 * (crossCount - 1))) / crossCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards.map((card) {
            return SizedBox(
              width: itemWidth,
              child: _KpiCard(data: card),
            );
          }).toList(),
        );
      });
    });
  }

  // ---------------------------------------------------------------------------
  // B. TREND CHART
  // ---------------------------------------------------------------------------
  Widget _buildTrendChart() {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bookings Trend',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A))),
              // Daily / Weekly toggle
              Obx(() => Row(
                    children: ['Daily', 'Weekly'].map((mode) {
                      final isActive = _ctrl.trendMode.value == mode;
                      return GestureDetector(
                        onTap: () => _ctrl.switchTrendMode(mode),
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFEF7822)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(mode,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? Colors.white
                                      : const Color(0xFF64748B))),
                        ),
                      );
                    }).toList(),
                  )),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Obx(() {
              final points = _ctrl.trendPoints;
              if (points.isEmpty) {
                return Center(
                    child: Text('No trend data available',
                        style: GoogleFonts.inter(color: const Color(0xFF94A3B8))));
              }
              final maxY = points.map((p) => p.count).reduce((a, b) => a > b ? a : b).toDouble();
              return LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (points.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY + (maxY * 0.2).clamp(1, double.infinity),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                        color: const Color(0xFFF1F5F9), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (val, meta) => Text(
                          val.toInt().toString(),
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: (points.length / 5).clamp(1, double.infinity),
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              points[idx].label,
                              style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: const Color(0xFF94A3B8)),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points
                          .map((p) => FlSpot(p.x, p.count.toDouble()))
                          .toList(),
                      isCurved: true,
                      color: const Color(0xFFEF7822),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 3,
                          color: const Color(0xFFEF7822),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFEF7822).withOpacity(0.18),
                            const Color(0xFFEF7822).withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // C. DONUT CHART
  // ---------------------------------------------------------------------------
  Widget _buildDonutChart() {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Distribution',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A))),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              final segs = _ctrl.donutSegments;
              final total = segs.fold(0, (s, e) => s + e.count);
              if (total == 0) {
                return Center(
                    child: Text('No data',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8))));
              }
              return Row(
                children: [
                  // Donut
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 42,
                        sections: segs.map((seg) {
                          return PieChartSectionData(
                            value: seg.value,
                            color: Color(seg.colorHex),
                            radius: 52,
                            title: seg.count > 0
                                ? '${((seg.count / total) * 100).toStringAsFixed(0)}%'
                                : '',
                            titleStyle: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Legend
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: segs.map((seg) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(seg.colorHex),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(seg.label,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF475569))),
                            const SizedBox(width: 6),
                            Text('(${seg.count})',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // D. QUICK ACTIONS
  // ---------------------------------------------------------------------------
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
          label: 'All Bookings',
          icon: Icons.list_alt_rounded,
          route: 'booking/all',
          colorHex: 0xFF2563EB),
      _QuickAction(
          label: 'Offline Payments',
          icon: Icons.receipt_long_rounded,
          route: 'booking/offline',
          colorHex: 0xFF8B5CF6),
      _QuickAction(
          label: 'Ongoing',
          icon: Icons.timelapse_rounded,
          route: 'booking/ongoing',
          colorHex: 0xFFF59E0B),
      _QuickAction(
          label: 'Completed',
          icon: Icons.done_all_rounded,
          route: 'booking/completed',
          colorHex: 0xFF22C55E),
      _QuickAction(
          label: 'Canceled',
          icon: Icons.cancel_rounded,
          route: 'booking/canceled',
          colorHex: 0xFFEF4444),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions',
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A))),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (ctx, constraints) {
          final crossCount = constraints.maxWidth > 800 ? 5 : 3;
          final itemWidth =
              (constraints.maxWidth - (12 * (crossCount - 1))) / crossCount;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions.map((action) {
              return SizedBox(
                width: itemWidth,
                child: _QuickActionTile(
                  action: action,
                  onTap: () => widget.onNav(action.route),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // E. FILTERS
  // ---------------------------------------------------------------------------
  Widget _buildFiltersPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Header (toggle)
          InkWell(
            onTap: () => setState(() => _filtersVisible = !_filtersVisible),
            borderRadius:
                BorderRadius.circular(_filtersVisible ? 0 : 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded,
                      size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 10),
                  Text('Filters & Search',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155))),
                  const Spacer(),
                  Icon(
                    _filtersVisible
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          if (_filtersVisible) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildFilterBody(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Search
            SizedBox(
              width: 260,
              height: 44,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() => _tablePage = 0),
                decoration: InputDecoration(
                  hintText: 'Booking ID / Name / Mobile',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: Color(0xFF94A3B8)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFEF7822))),
                ),
              ),
            ),
            // Status
            _FilterDropdown(
              label: 'Status',
              value: _filterStatus,
              items: const ['All', 'Pending', 'Completed', 'Cancelled'],
              onChanged: (v) => setState(() {
                _filterStatus = v;
                _tablePage = 0;
              }),
            ),
            // Payment Mode
            _FilterDropdown(
              label: 'Payment Mode',
              value: _filterPaymentMode,
              items: const ['All', 'ONLINE', 'CASH', 'OFFLINE', 'UPI'],
              onChanged: (v) => setState(() {
                _filterPaymentMode = v;
                _tablePage = 0;
              }),
            ),
            // Schedule From
            _DatePickerButton(
              label: _scheduleFrom != null
                  ? 'Sched: ${DateFormat('dd MMM').format(_scheduleFrom!)}'
                  : 'Schedule From',
              onPick: () async {
                final d = await _pickDate(context, _scheduleFrom);
                if (d != null) setState(() => _scheduleFrom = d);
              },
            ),
            // Schedule To
            _DatePickerButton(
              label: _scheduleTo != null
                  ? 'Sched To: ${DateFormat('dd MMM').format(_scheduleTo!)}'
                  : 'Schedule To',
              onPick: () async {
                final d = await _pickDate(context, _scheduleTo);
                if (d != null) setState(() => _scheduleTo = d);
              },
            ),
            // Booking From
            _DatePickerButton(
              label: _bookingFrom != null
                  ? 'Booked: ${DateFormat('dd MMM').format(_bookingFrom!)}'
                  : 'Booking From',
              onPick: () async {
                final d = await _pickDate(context, _bookingFrom);
                if (d != null) setState(() => _bookingFrom = d);
              },
            ),
            // Booking To
            _DatePickerButton(
              label: _bookingTo != null
                  ? 'Booked To: ${DateFormat('dd MMM').format(_bookingTo!)}'
                  : 'Booking To',
              onPick: () async {
                final d = await _pickDate(context, _bookingTo);
                if (d != null) setState(() => _bookingTo = d);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Reset
            OutlinedButton.icon(
              onPressed: () {
                _searchCtrl.clear();
                setState(() {
                  _filterStatus = 'All';
                  _filterPaymentMode = 'All';
                  _scheduleFrom = null;
                  _scheduleTo = null;
                  _bookingFrom = null;
                  _bookingTo = null;
                  _tablePage = 0;
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('Reset',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => setState(() => _tablePage = 0),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF7822),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.search_rounded,
                  size: 16, color: Colors.white),
              label: Text('Apply',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  Future<DateTime?> _pickDate(BuildContext ctx, DateTime? initial) {
    return showDatePicker(
      context: ctx,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFEF7822)),
        ),
        child: child!,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // F. RECENT BOOKINGS TABLE
  // ---------------------------------------------------------------------------
  Widget _buildRecentBookingsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Text('Recent Bookings',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A))),
                const SizedBox(width: 12),
                Obx(() => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                          '${_filteredBookings.length} records',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B))),
                    )),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Table
          Obx(() {
            final rows = _pagedBookings;
            if (rows.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 40, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 10),
                      Text('No bookings found',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8))),
                    ],
                  ),
                ),
              );
            }

            final ScrollController hScroll = ScrollController();
            final ScrollController vScroll = ScrollController();
            return SizedBox(
              height: (rows.length * 72.0).clamp(100, 600),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                ),
                child: Scrollbar(
                  controller: vScroll,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: vScroll,
                    child: Scrollbar(
                      controller: hScroll,
                      thumbVisibility: true,
                      notificationPredicate: (n) => n.depth == 1,
                      child: SingleChildScrollView(
                        controller: hScroll,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width - 120),
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                                const Color(0xFFF8FAFC)),
                            dataRowMinHeight: 64,
                            dataRowMaxHeight: 76,
                            horizontalMargin: 20,
                            columnSpacing: 20,
                            dividerThickness: 1,
                            headingRowHeight: 44,
                            columns: _tableColumns(),
                            rows: _buildTableRows(rows),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Pagination
          _buildTablePagination(),
        ],
      ),
    );
  }

  List<DataColumn> _tableColumns() {
    const cols = [
      'SL', 'BOOKING ID', 'CUSTOMER', 'SERVICE', 'LOCATION',
      'SCHEDULE DATE', 'BOOKING DATE', 'AMOUNT', 'PAYMENT MODE', 'STATUS', 'ACTION'
    ];
    return cols.map((c) => DataColumn(label: _TableHeader(c))).toList();
  }

  List<DataRow> _buildTableRows(List<BookingModel> rows) {
    return List.generate(rows.length, (index) {
      final b = rows[index];
      final sl = (_tablePage * _tablePageSize) + index + 1;

      return DataRow(cells: [
        // SL
        DataCell(Text('$sl', style: _ts())),
        // Booking ID
        DataCell(Text(b.bookingRef, style: _ts(bold: true))),
        // Customer
        DataCell(Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b.customerName, style: _ts(bold: true)),
            Text(b.customerPhone, style: _sub()),
          ],
        )),
        // Service
        DataCell(Text(b.mainServiceName, style: _ts())),
        // Location
        DataCell(Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b.address?.city ?? 'N/A', style: _ts(bold: true)),
            Text(b.address?.postCode ?? '', style: _sub()),
          ],
        )),
        // Schedule Date
        DataCell(Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDateOnly(b.bookingDate), style: _ts()),
            Text(b.bookingTime, style: _sub()),
          ],
        )),
        // Booking Date (creation)
        DataCell(Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(b.creationTime), style: _ts()),
            Text(
              b.creationTime.contains('T')
                  ? b.creationTime.split('T')[1].substring(0, 5)
                  : '',
              style: _sub(),
            ),
          ],
        )),
        // Amount
        DataCell(Text('₹${b.grandTotalPrice.toStringAsFixed(2)}',
            style: _ts(bold: true))),
        // Payment Mode
        DataCell(_Badge(
            label: b.paymentMode.toUpperCase(),
            bg: _paymentBg(b.paymentMode),
            fg: _paymentFg(b.paymentMode))),
        // Status
        DataCell(_Badge(
            label: b.status,
            bg: _statusBg(b.status),
            fg: _statusFg(b.status))),
        // Action
        DataCell(InkWell(
          onTap: () => widget.onViewDetails(b),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(4)),
            child: const Icon(Icons.visibility_outlined,
                size: 17, color: Color(0xFF64748B)),
          ),
        )),
      ]);
    });
  }

  Widget _buildTablePagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            onPressed: _tablePage > 0
                ? () => setState(() => _tablePage--)
                : null,
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFE2E8F0))),
            child: const Text('Previous'),
          ),
          Expanded(
            child: SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _totalTablePages,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (ctx, idx) {
                  final isSel = idx == _tablePage;
                  return GestureDetector(
                    onTap: () => setState(() => _tablePage = idx),
                    child: Container(
                      width: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSel
                            ? const Color(0xFFEF7822)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: isSel
                            ? null
                            : Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text('${idx + 1}',
                          style: GoogleFonts.inter(
                              fontWeight: isSel
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 12,
                              color: isSel
                                  ? Colors.white
                                  : const Color(0xFF64748B))),
                    ),
                  );
                },
              ),
            ),
          ),
          OutlinedButton(
            onPressed: _tablePage < _totalTablePages - 1
                ? () => setState(() => _tablePage++)
                : null,
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: const BorderSide(color: Color(0xFFE2E8F0))),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  // Style helpers
  static TextStyle _ts({bool bold = false}) => GoogleFonts.inter(
      fontSize: 13,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
      color: const Color(0xFF334155));

  static TextStyle _sub() =>
      GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8));
}

// =============================================================================
// PRIVATE DATA CLASSES
// =============================================================================

class _KpiData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  const _KpiData(
      {required this.title,
      required this.value,
      required this.subtitle,
      required this.icon,
      required this.gradientColors});
}

class _QuickAction {
  final String label;
  final IconData icon;
  final String route;
  final int colorHex;
  const _QuickAction(
      {required this.label,
      required this.icon,
      required this.route,
      required this.colorHex});
}

// =============================================================================
// PRIVATE WIDGETS
// =============================================================================

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
            colors: data.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(
              color: data.gradientColors.first.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(data.title,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70),
                    overflow: TextOverflow.ellipsis),
              ),
              Icon(data.icon, color: Colors.white30, size: 22),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.value,
                  style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              Text(data.subtitle,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.white60)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatefulWidget {
  final _QuickAction action;
  final VoidCallback onTap;
  const _QuickActionTile({required this.action, required this.onTap});

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: _hovering
                ? Color(widget.action.colorHex).withOpacity(0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _hovering
                    ? Color(widget.action.colorHex).withOpacity(0.5)
                    : const Color(0xFFE2E8F0)),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                        color: Color(widget.action.colorHex).withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(widget.action.colorHex).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.action.icon,
                    size: 20, color: Color(widget.action.colorHex)),
              ),
              const SizedBox(height: 8),
              Text(widget.action.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155))),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF94A3B8))),
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: (v) => onChanged(v ?? value),
        ),
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final VoidCallback onPick;

  const _DatePickerButton({required this.label, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 15, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8)));
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
