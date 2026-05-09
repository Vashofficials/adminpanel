import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/provider_dashboard_controller.dart';

// ─── Design Constants ────────────────────────────────────────────────────────
const Color _kBg = Color(0xFFF7F9FC);
const Color _kCardBg = Colors.white;
const Color _kBorderColor = Color(0xFFE5E7EB);
const Color _kTextDark = Color(0xFF1E293B);
const Color _kTextMuted = Color(0xFF64748B);

// KPI card colors
const Color _kOrange = Color(0xFFF97316);      // Total Providers
const Color _kGreen = Color(0xFF10B981);       // Active Providers
const Color _kBlue = Color(0xFF3B82F6);        // Pending Onboarding
const Color _kRed = Color(0xFFEF4444);         // Inactive Providers

// Chart colors
const Color _kChartLine = Color(0xFFF97316);
const Color _kChartFill = Color(0x20F97316);
const Color _kDonutActive = Color(0xFF10B981);
const Color _kDonutPending = Color(0xFFF59E0B);
const Color _kDonutInactive = Color(0xFFEF4444);

class ProviderDashboardScreen extends StatefulWidget {
  final Function(String)? onNav;

  const ProviderDashboardScreen({super.key, this.onNav});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
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
        if (_ctrl.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: _kOrange),
          );
        }
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
                const SizedBox(height: 24),
                _buildKpiCards(),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _ProviderGrowthChart(ctrl: _ctrl),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: _ProviderStatusDonut(ctrl: _ctrl),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _ProviderGrowthChart(ctrl: _ctrl),
                        const SizedBox(height: 24),
                        _ProviderStatusDonut(ctrl: _ctrl),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Provider Analytics",
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Real-time overview of your service providers",
              style: GoogleFonts.poppins(fontSize: 14, color: _kTextMuted),
            ),
          ],
        ),
        Row(
          children: [
            // Date Range Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBorderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: _kTextMuted),
                  const SizedBox(width: 8),
                  Text(
                    _ctrl.dateRangeText,
                    style: GoogleFonts.poppins(fontSize: 13, color: _kTextDark, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Export Dropdown
            PopupMenuButton<String>(
              onSelected: _ctrl.exportData,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'CSV', child: Text('Export as CSV')),
                const PopupMenuItem(value: 'Excel', child: Text('Export as Excel')),
                const PopupMenuItem(value: 'PDF', child: Text('Export as PDF')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kBorderColor),
                ),
                child: Row(
                  children: [
                    Text("Export", style: GoogleFonts.poppins(fontSize: 13, color: _kTextDark, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 6),
                    const Icon(Icons.download_outlined, size: 16, color: _kTextMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 16;
        int crossCount = 4;
        if (constraints.maxWidth < 1000) crossCount = 2;
        if (constraints.maxWidth < 600) crossCount = 1;

        final double cardWidth = (constraints.maxWidth - (spacing * (crossCount - 1))) / crossCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _KpiCard(
              width: cardWidth,
              title: "Total Providers",
              value: "${_ctrl.totalProviders.value}",
              subtitle: "All Time",
              icon: Icons.group_outlined,
              color: Colors.blue,
            ),
            _KpiCard(
              width: cardWidth,
              title: "Active Providers",
              value: "${_ctrl.activeProviders.value}",
              subtitle: "Working Today",
              icon: Icons.check_circle_outline,
              color: _kGreen,
            ),
            _KpiCard(
              width: cardWidth,
              title: "New Registration",
              value: "${_ctrl.newRegistrationsToday.value}",
              subtitle: "Registered Today",
              icon: Icons.person_add_outlined,
              color: _kOrange,
            ),
            _KpiCard(
              width: cardWidth,
              title: "Pending Approval",
              value: "${_ctrl.pendingApproval.value}",
              subtitle: "Status: 0",
              icon: Icons.hourglass_empty_outlined,
              color: _kRed,
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 13, color: _kTextMuted)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: _kTextDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: _kTextMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderGrowthChart extends StatelessWidget {
  final ProviderDashboardController ctrl;
  const _ProviderGrowthChart({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Provider Growth",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kTextDark,
                ),
              ),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kBorderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: ctrl.selectedFilter.value,
                    isDense: true,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _kTextDark,
                      fontWeight: FontWeight.w500,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        size: 18, color: _kTextMuted),
                    items: ['Last 7 Days', 'Last 30 Days'].map((filter) {
                      return DropdownMenuItem<String>(
                        value: filter,
                        child: Text(filter),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) ctrl.setFilter(value);
                    },
                  ),
                ),
              )),
            ],
          ),
          const SizedBox(height: 24),

          // Chart
          SizedBox(
            height: 280,
            child: Obx(() {
              if (ctrl.dailyProviderCounts.isEmpty) {
                return const Center(
                  child: Text("No data available",
                      style: TextStyle(color: _kTextMuted)),
                );
              }

              final data = ctrl.dailyProviderCounts;
              double minY = data
                  .map((d) => d.count.toDouble())
                  .reduce((a, b) => a < b ? a : b);
              double maxY = data
                  .map((d) => d.count.toDouble())
                  .reduce((a, b) => a > b ? a : b);

              // Add padding to Y axis
              final yPadding = (maxY - minY) * 0.3;
              minY = (minY - yPadding).clamp(0, double.infinity);
              maxY = maxY + yPadding;

              // Calculate interval
              final yRange = maxY - minY;
              final interval = yRange > 0 ? (yRange / 5).ceilToDouble() : 100.0;

              return LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval > 0 ? interval : 100.0,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: const Color(0xFFE5E7EB),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: interval > 0 ? interval : 100.0,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: _kTextMuted,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM dd').format(data[idx].date),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: _kTextMuted,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: minY,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: _kTextDark,
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final idx = spot.x.toInt();
                          final d = data[idx];
                          return LineTooltipItem(
                            "${DateFormat('MMM dd, yyyy').format(d.date)}\nTotal Providers: ${d.count}",
                            GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) {
                        return FlSpot(
                            e.key.toDouble(), e.value.count.toDouble());
                      }).toList(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: _kChartLine,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: _kCardBg,
                            strokeWidth: 2.5,
                            strokeColor: _kChartLine,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            _kOrange.withOpacity(0.2),
                            _kOrange.withOpacity(0.02),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDERS BY STATUS DONUT CHART
// ─────────────────────────────────────────────────────────────────────────────
class _ProviderStatusDonut extends StatelessWidget {
  final ProviderDashboardController ctrl;

  const _ProviderStatusDonut({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Providers by Status",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 32),

          // Donut Chart + Center Label
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Obx(() => Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 65,
                          startDegreeOffset: -90,
                          sections: [
                            PieChartSectionData(
                              value: ctrl.activeProviders.value.toDouble(),
                              color: _kDonutActive,
                              radius: 28,
                              title: '',
                            ),
                            PieChartSectionData(
                              value: ctrl.pendingApproval.value.toDouble(),
                              color: _kDonutPending,
                              radius: 28,
                              title: '',
                            ),
                            PieChartSectionData(
                              value: ctrl.inactiveProviders.value.toDouble(),
                              color: _kDonutInactive,
                              radius: 28,
                              title: '',
                            ),
                          ],
                        ),
                      ),
                      // Center text
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ctrl.totalProviders.value.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: _kTextDark,
                            ),
                          ),
                          Text(
                            "Total",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: _kTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),
            ),
          ),

          const SizedBox(height: 32),

          // Legends
          Obx(() => Column(
                children: [
                  _DonutLegend(
                    color: _kDonutActive,
                    label: "Active",
                    count: ctrl.activeProviders.value,
                    percent: ctrl.activePercent,
                  ),
                  const SizedBox(height: 14),
                  _DonutLegend(
                    color: _kDonutPending,
                    label: "Pending Approval",
                    count: ctrl.pendingApproval.value,
                    percent: ctrl.pendingPercent,
                  ),
                  const SizedBox(height: 14),
                  _DonutLegend(
                    color: _kDonutInactive,
                    label: "Inactive",
                    count: ctrl.inactiveProviders.value,
                    percent: ctrl.inactivePercent,
                  ),
                ],
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DONUT CHART LEGEND ITEM
// ─────────────────────────────────────────────────────────────────────────────
class _DonutLegend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final double percent;

  const _DonutLegend({
    required this.color,
    required this.label,
    required this.count,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _kTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          "$count",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kTextDark,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "(${percent.toStringAsFixed(1)}%)",
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: _kTextMuted,
          ),
        ),
      ],
    );
  }
}
