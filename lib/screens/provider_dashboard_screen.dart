import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/provider_dashboard_controller.dart';

const Color _kBg = Color(0xFFF7F9FC);
const Color _kCardBg = Colors.white;
const Color _kBorderColor = Color(0xFFE5E7EB);
const Color _kTextDark = Color(0xFF1E293B);
const Color _kTextMuted = Color(0xFF64748B);
const Color _kOrange = Color(0xFFF97316);
const Color _kGreen = Color(0xFF10B981);
const Color _kBlue = Color(0xFF3B82F6);
const Color _kRed = Color(0xFFEF4444);
const Color _kPurple = Color(0xFFA855F7);
const Color _kAmber = Color(0xFFF59E0B);
const Color _kChartLine = Color(0xFFF97316);
const Color _kDonutActive = Color(0xFF10B981);
const Color _kDonutPending = Color(0xFFF59E0B);
const Color _kDonutInactive = Color(0xFFEF4444);

class ProviderDashboardScreen extends StatefulWidget {
  final Function(String)? onNav;
  const ProviderDashboardScreen({super.key, this.onNav});
  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  late final ProviderDashboardController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(ProviderDashboardController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Obx(() {
        if (_ctrl.isLoading.value) return _buildSkeletonLoading();
        return RefreshIndicator(
          onRefresh: _ctrl.refreshData,
          color: _kOrange,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                if (_ctrl.isRefreshing.value)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(color: _kOrange, backgroundColor: _kOrange.withOpacity(0.1)),
                  ),
                const SizedBox(height: 24),
                _buildKpiCards(),
                const SizedBox(height: 24),
                LayoutBuilder(builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _ProviderGrowthChart(ctrl: _ctrl)),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: _ProviderStatusDonut(ctrl: _ctrl)),
                      ],
                    );
                  }
                  return Column(children: [
                    _ProviderGrowthChart(ctrl: _ctrl),
                    const SizedBox(height: 24),
                    _ProviderStatusDonut(ctrl: _ctrl),
                  ]);
                }),
                const SizedBox(height: 24),
                _buildTopRatedProviders(),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Skeleton ──────────────────────────────────────────────────────────────
  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(200, 32),
          const SizedBox(height: 8),
          _shimmerBox(300, 16),
          const SizedBox(height: 24),
          Row(children: List.generate(3, (_) => Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _shimmerBox(double.infinity, 120, radius: 16),
          )))),
          const SizedBox(height: 16),
          Row(children: List.generate(3, (_) => Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _shimmerBox(double.infinity, 120, radius: 16),
          )))),
          const SizedBox(height: 24),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: _shimmerBox(double.infinity, 340, radius: 16)),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: _shimmerBox(double.infinity, 340, radius: 16)),
          ]),
        ],
      ),
    );
  }

  Widget _shimmerBox(double width, double height, {double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB).withOpacity(0.5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Provider Analytics", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: _kTextDark)),
          const SizedBox(height: 4),
          Text("Real-time overview of your service providers", style: GoogleFonts.poppins(fontSize: 14, color: _kTextMuted)),
        ]),
        Row(children: [
          // Manual Refresh
          Obx(() => Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _ctrl.isRefreshing.value ? null : () => _ctrl.refreshData(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kBlue.withOpacity(0.25)),
                ),
                child: _ctrl.isRefreshing.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue))
                    : const Icon(Icons.refresh, size: 20, color: _kBlue),
              ),
            ),
          )),
          const SizedBox(width: 12),
          // Date range chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _kBorderColor)),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: _kTextMuted),
              const SizedBox(width: 8),
              Text(_ctrl.dateRangeText, style: GoogleFonts.poppins(fontSize: 13, color: _kTextDark, fontWeight: FontWeight.w500)),
            ]),
          ),
          const SizedBox(width: 12),
          // Export
          PopupMenuButton<String>(
            onSelected: _ctrl.exportData,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'CSV', child: Text('Export as CSV')),
              const PopupMenuItem(value: 'Excel', child: Text('Export as Excel')),
              const PopupMenuItem(value: 'PDF', child: Text('Export as PDF')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _kBorderColor)),
              child: Row(children: [
                Text("Export", style: GoogleFonts.poppins(fontSize: 13, color: _kTextDark, fontWeight: FontWeight.w500)),
                const SizedBox(width: 6),
                const Icon(Icons.download_outlined, size: 16, color: _kTextMuted),
              ]),
            ),
          ),
        ]),
      ],
    );
  }

  // ── KPI Cards (UpgradedStatCard style) ─────────────────────────────────────
  Widget _buildKpiCards() {
    return LayoutBuilder(builder: (context, constraints) {
      const double spacing = 16;
      int crossCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1);
      final double width = (constraints.maxWidth - (spacing * (crossCount - 1))) / crossCount;

      return Obx(() => Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          // 1. Total Providers
          SizedBox(
            width: width,
            child: _UpgradedStatCard(
              title: "Total Providers",
              mainValue: "${_ctrl.totalProviders.value}",
              icon: Icons.handyman_outlined,
              color: _kAmber,
              subItems: [
                _SubItem("Approved", "${_ctrl.activeProviders.value}", itemColor: _kGreen),
                _SubItem("Un Approved", "${_ctrl.pendingApproval.value}", itemColor: _kRed),
                _SubItem("Today Active", "${_ctrl.newRegistrationsToday.value}", itemColor: _kGreen),
              ],
            ),
          ),

          // 2. Total Bookings
          SizedBox(
            width: width,
            child: _UpgradedStatCard(
              title: "Total Bookings",
              mainValue: "${_ctrl.totalBookings.value}",
              icon: Icons.shopping_cart_outlined,
              color: _kGreen,
              subItems: [
                _SubItem("Today", "${_ctrl.todayBookings.value}"),
                _SubItem("Completed", "${_ctrl.completedBookings.value}", itemColor: _kGreen),
                _SubItem("Cancelled", "${_ctrl.cancelledBookings.value}", itemColor: _kRed),
              ],
            ),
          ),

          // 3. Earnings
          SizedBox(
            width: width,
            child: _UpgradedStatCard(
              title: "All Time Collection",
              mainValue: "₹${_ctrl.totalEarnings.value.toStringAsFixed(0)}",
              icon: Icons.currency_rupee_outlined,
              color: _kBlue,
              isPrimary: true,
              subItems: [
                _SubItem("Today", "₹${_ctrl.todayEarnings.value.toStringAsFixed(0)}"),
              ],
            ),
          ),
        ],
      ));
    });
  }

  // ── Top Rated Providers ───────────────────────────────────────────────────
  Widget _buildTopRatedProviders() {
    return Obx(() {
      if (_ctrl.topRatedProviders.isEmpty) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorderColor)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Top Rated Providers", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _kTextDark)),
          const SizedBox(height: 16),
          ..._ctrl.topRatedProviders.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _kOrange.withOpacity(0.1),
                backgroundImage: (p['imageUrl'] != null && (p['imageUrl'] as String).isNotEmpty) ? NetworkImage(p['imageUrl']) : null,
                child: (p['imageUrl'] == null || (p['imageUrl'] as String).isEmpty)
                    ? Text((p['name'] as String).isNotEmpty ? (p['name'] as String)[0].toUpperCase() : '?', style: GoogleFonts.poppins(color: _kOrange, fontWeight: FontWeight.w600))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['name'] ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextDark)),
                Text("${p['reviews'] ?? 0} reviews", style: GoogleFonts.poppins(fontSize: 11, color: _kTextMuted)),
              ])),
              Row(children: [
                const Icon(Icons.star, color: _kAmber, size: 16),
                const SizedBox(width: 4),
                Text("${(p['rating'] as double).toStringAsFixed(1)}", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextDark)),
              ]),
            ]),
          )),
        ]),
      );
    });
  }
}

// =============================================================================
// _SubItem helper
// =============================================================================
class _SubItem {
  final String label;
  final String value;
  final Color? itemColor;
  const _SubItem(this.label, this.value, {this.itemColor});
}

// =============================================================================
// _UpgradedStatCard — matches dashboard_screen.dart style exactly
// =============================================================================
class _UpgradedStatCard extends StatelessWidget {
  final String title;
  final String mainValue;
  final IconData icon;
  final Color color;
  final bool isPrimary;
  final List<_SubItem> subItems;

  const _UpgradedStatCard({
    required this.title,
    required this.mainValue,
    required this.icon,
    required this.color,
    this.isPrimary = false,
    required this.subItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary ? color : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPrimary ? null : Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: isPrimary ? color.withOpacity(0.3) : Colors.black.withOpacity(0.04),
            blurRadius: isPrimary ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title + Icon row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isPrimary ? Colors.white.withOpacity(0.9) : const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPrimary ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isPrimary ? Colors.white : color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Big main value
          Text(
            mainValue,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: isPrimary ? Colors.white : const Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Divider
          Divider(
            color: isPrimary ? Colors.white.withOpacity(0.2) : Colors.grey.shade200,
            height: 1,
          ),
          const SizedBox(height: 12),

          // Sub items
          Row(
            children: subItems.map((item) {
              return Expanded(
                child: Row(
                  children: [
                    if (item != subItems.first)
                      Container(
                        width: 1,
                        height: 28,
                        margin: const EdgeInsets.only(right: 12),
                        color: isPrimary ? Colors.white.withOpacity(0.2) : Colors.grey.shade200,
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isPrimary ? Colors.white.withOpacity(0.7) : Colors.grey.shade500,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: TextStyle(
                              color: isPrimary ? Colors.white : (item.itemColor ?? color),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Provider Growth Line Chart
// =============================================================================
class _ProviderGrowthChart extends StatelessWidget {
  final ProviderDashboardController ctrl;
  const _ProviderGrowthChart({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorderColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Provider Growth", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _kTextDark)),
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: _kBorderColor)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: ctrl.selectedFilter.value, isDense: true,
              style: GoogleFonts.poppins(fontSize: 13, color: _kTextDark, fontWeight: FontWeight.w500),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: _kTextMuted),
              items: ['Last 7 Days', 'Last 30 Days'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (v) { if (v != null) ctrl.setFilter(v); },
            )),
          )),
        ]),
        const SizedBox(height: 24),
        SizedBox(height: 280, child: Obx(() {
          if (ctrl.dailyProviderCounts.isEmpty) {
            return Center(child: Text("No data available", style: GoogleFonts.poppins(color: _kTextMuted)));
          }
          final data = ctrl.dailyProviderCounts;
          double minY = data.map((d) => d.count.toDouble()).reduce((a, b) => a < b ? a : b);
          double maxY = data.map((d) => d.count.toDouble()).reduce((a, b) => a > b ? a : b);
          final yPadding = (maxY - minY) * 0.3;
          minY = (minY - yPadding).clamp(0, double.infinity);
          maxY = maxY + yPadding;
          final yRange = maxY - minY;
          final interval = yRange > 0 ? (yRange / 5).ceilToDouble() : 100.0;

          return LineChart(LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: interval > 0 ? interval : 100.0,
              getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFE5E7EB), strokeWidth: 1, dashArray: [5, 5])),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, interval: interval > 0 ? interval : 100.0,
                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.poppins(fontSize: 11, color: _kTextMuted)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                  return Padding(padding: const EdgeInsets.only(top: 8), child: Text(DateFormat('MMM dd').format(data[idx].date), style: GoogleFonts.poppins(fontSize: 11, color: _kTextMuted)));
                })),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minX: 0, maxX: (data.length - 1).toDouble(), minY: minY, maxY: maxY,
            lineTouchData: LineTouchData(enabled: true, touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: _kTextDark, tooltipRoundedRadius: 8, tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              getTooltipItems: (spots) => spots.map((spot) {
                final d = data[spot.x.toInt()];
                return LineTooltipItem("${DateFormat('MMM dd, yyyy').format(d.date)}\nNew Providers: ${d.count}", GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12));
              }).toList(),
            )),
            lineBarsData: [LineChartBarData(
              spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble())).toList(),
              isCurved: true, curveSmoothness: 0.3, color: _kChartLine, barWidth: 2.5, isStrokeCapRound: true,
              dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 5, color: _kCardBg, strokeWidth: 2.5, strokeColor: _kChartLine)),
              belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [_kOrange.withOpacity(0.2), _kOrange.withOpacity(0.02)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            )],
          ));
        })),
      ]),
    );
  }
}

// =============================================================================
// Provider Status Donut Chart
// =============================================================================
class _ProviderStatusDonut extends StatelessWidget {
  final ProviderDashboardController ctrl;
  const _ProviderStatusDonut({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Providers by Status", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _kTextDark)),
        const SizedBox(height: 32),
        Center(child: SizedBox(width: 200, height: 200, child: Obx(() => Stack(alignment: Alignment.center, children: [
          PieChart(PieChartData(sectionsSpace: 3, centerSpaceRadius: 65, startDegreeOffset: -90, sections: [
            PieChartSectionData(value: ctrl.activeProviders.value.toDouble(), color: _kDonutActive, radius: 28, title: ''),
            PieChartSectionData(value: ctrl.pendingApproval.value.toDouble(), color: _kDonutPending, radius: 28, title: ''),
            PieChartSectionData(value: ctrl.inactiveProviders.value.toDouble(), color: _kDonutInactive, radius: 28, title: ''),
          ])),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(ctrl.totalProviders.value.toString(), style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: _kTextDark)),
            Text("Total", style: GoogleFonts.poppins(fontSize: 13, color: _kTextMuted)),
          ]),
        ])))),
        const SizedBox(height: 32),
        Obx(() => Column(children: [
          _DonutLegend(color: _kDonutActive, label: "Active", count: ctrl.activeProviders.value, percent: ctrl.activePercent),
          const SizedBox(height: 14),
          _DonutLegend(color: _kDonutPending, label: "Pending Approval", count: ctrl.pendingApproval.value, percent: ctrl.pendingPercent),
          const SizedBox(height: 14),
          _DonutLegend(color: _kDonutInactive, label: "Inactive", count: ctrl.inactiveProviders.value, percent: ctrl.inactivePercent),
        ])),
      ]),
    );
  }
}

class _DonutLegend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final double percent;
  const _DonutLegend({required this.color, required this.label, required this.count, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 13, color: _kTextMuted, fontWeight: FontWeight.w500))),
      Text("$count", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _kTextDark)),
      const SizedBox(width: 6),
      Text("(${percent.toStringAsFixed(1)}%)", style: GoogleFonts.poppins(fontSize: 12, color: _kTextMuted)),
    ]);
  }
}
