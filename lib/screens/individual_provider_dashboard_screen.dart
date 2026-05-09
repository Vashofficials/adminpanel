import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/individual_provider_dashboard_controller.dart';

const Color _kBg = Color(0xFFF9FAFB);
const Color _kCardBg = Colors.white;
const Color _kBorderColor = Color(0xFFF1F5F9);
const Color _kTextDark = Color(0xFF0F172A);
const Color _kTextMuted = Color(0xFF64748B);
const Color _kOrange = Color(0xFFFF7E1D);
const Color _kGreen = Color(0xFF10B981);
const Color _kRed = Color(0xFFEF4444);

class IndividualProviderDashboardScreen extends StatelessWidget {
  final VoidCallback? onBack;

  IndividualProviderDashboardScreen({Key? key, this.onBack}) : super(key: key);

  final IndividualProviderDashboardController ctrl = Get.find<IndividualProviderDashboardController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Obx(() {
        final provider = ctrl.providerModel.value;
        if (provider == null) {
          return const Center(child: Text("Provider data not loaded."));
        }

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, provider.firstName.isNotEmpty ? provider.firstName : provider.fullName),
                  const SizedBox(height: 24),
                  _buildTopStats(),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _buildTodaysSchedule(),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 6,
                        child: _buildEarningsOverview(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildRecentBookings()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildRatingsReviews()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildProfileCompletion()),
                    ],
                  ),
                ],
              ),
            ),
            if (ctrl.isLoading.value)
              Container(
                color: Colors.white.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: _kOrange),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (onBack != null) ...[
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: _kBorderColor),
                    borderRadius: BorderRadius.circular(8),
                    color: _kCardBg,
                  ),
                  child: const Icon(Icons.arrow_back, color: _kTextDark, size: 20),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Good Morning, $name!",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _kTextDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text("👋", style: TextStyle(fontSize: 28)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Here's what's happening with your business today.",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _kTextMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _showExportOptions(context),
              icon: const Icon(Icons.download, size: 18, color: _kOrange),
              label: Text(
                "Export Report",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _kOrange),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _kOrange),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => ctrl.loadProvider(ctrl.providerId.value, ctrl.providerModel.value!),
              icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
              label: Text(
                "Refresh",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopStats() {
    return Row(
      children: [
        Expanded(
          child: _buildTopStatCard(
            "Today's Bookings",
            "${ctrl.todayBookings.value}",
            "Latest",
            true,
            Icons.calendar_today_outlined,
            const Color(0xFFFFF7ED),
            _kOrange,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildTopStatCard(
            "Completed Bookings",
            "${ctrl.completedBookings.value}",
            "Total",
            true,
            Icons.check_circle_outline,
            const Color(0xFFF0FDF4),
            _kGreen,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildTopStatCard(
            "Today's Earnings",
            "₹${ctrl.todayEarnings.value.toStringAsFixed(0)}",
            "Today",
            true,
            Icons.currency_rupee,
            const Color(0xFFFAF5FF),
            const Color(0xFFA855F7),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildTopStatCard(
            "Total Earnings",
            "₹${ctrl.totalEarnings.value.toStringAsFixed(0)}",
            "Total",
            true,
            Icons.account_balance_wallet_outlined,
            const Color(0xFFEFF6FF),
            const Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }

  Widget _buildTopStatCard(
      String title, String value, String subtitle, bool isPositive, IconData icon, Color iconBg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 13, color: _kTextMuted, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: _kTextDark),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isPositive ? _kGreen : _kRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysSchedule() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Schedule",
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _kTextDark),
              ),
              Text(
                "View All",
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _kOrange),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (ctrl.todaysSchedule.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text("No schedule for today", style: GoogleFonts.poppins(color: _kTextMuted)),
              ),
            ),
          ...ctrl.todaysSchedule.map((booking) {
            String time = booking['bookingTime']?.toString() ?? 'N/A';
            String title = booking['service']?['name']?.toString() ?? 'Service';
            String subtitle = "${booking['customer']?['firstName'] ?? ''} ${booking['customer']?['lastName'] ?? ''}";
            String status = booking['status']?.toString() ?? 'Upcoming';
            
            // Format status
            status = status.substring(0, 1).toUpperCase() + status.substring(1).toLowerCase();

            return Column(
              children: [
                _buildScheduleItem(time, title, subtitle, status),
                const Divider(color: _kBorderColor, height: 24),
              ],
            );
          }).toList(),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: _kBorderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month_outlined, size: 16, color: _kTextMuted),
                const SizedBox(width: 8),
                Text(
                  "View Full Schedule",
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _kTextDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String time, String title, String subtitle, String status) {
    Color statusColor;
    Color statusBg;
    if (status == "Upcoming") {
      statusColor = _kGreen;
      statusBg = const Color(0xFFECFDF5);
    } else if (status == "Confirmed") {
      statusColor = const Color(0xFF3B82F6);
      statusBg = const Color(0xFFEFF6FF);
    } else {
      statusColor = _kTextMuted;
      statusBg = const Color(0xFFF1F5F9);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            time,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextDark),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _kTextDark)),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: _kTextMuted)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsOverview() {
    // Generate dates for the X axis
    final now = DateTime.now();
    final List<String> days = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";
    });
    
    // Calculate max Y value for graph
    double maxY = 1.0;
    for (var val in ctrl.weeklyEarnings) {
      if (val > maxY) maxY = val;
    }
    // Add 20% padding to max Y
    maxY = maxY * 1.2;

    // Build spots
    List<FlSpot> spots = [];
    for (int i = 0; i < ctrl.weeklyEarnings.length; i++) {
      spots.add(FlSpot(i.toDouble(), ctrl.weeklyEarnings[i]));
    }

    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Earnings Overview",
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _kTextDark),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: _kBorderColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Text("This Week", style: GoogleFonts.poppins(fontSize: 13, color: _kTextDark)),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 16, color: _kTextMuted),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text("Total Earnings", style: GoogleFonts.poppins(fontSize: 13, color: _kTextMuted)),
          const SizedBox(height: 4),
          Text("₹${ctrl.totalEarnings.value.toStringAsFixed(0)}", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: _kTextDark)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(color: _kBorderColor, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: (maxY / 4) > 0 ? (maxY / 4) : 1,
                      getTitlesWidget: (value, meta) {
                        return Text('₹${value.toInt()}',
                            style: GoogleFonts.poppins(fontSize: 11, color: _kTextMuted));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(days[value.toInt()],
                                style: GoogleFonts.poppins(fontSize: 11, color: _kTextMuted)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: _kTextDark,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '₹${spot.y.toInt()}',
                          GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                    isCurved: true,
                    color: _kOrange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: _kOrange,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _kOrange.withOpacity(0.3),
                          _kOrange.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildSubStat("Bookings", "${ctrl.graphBookings.value}", "-", true)),
              Container(width: 1, height: 40, color: _kBorderColor),
              Expanded(child: _buildSubStat("Completed", "${ctrl.graphCompleted.value}", "-", true)),
              Container(width: 1, height: 40, color: _kBorderColor),
              Expanded(child: _buildSubStat("Cancelled", "${ctrl.graphCancelled.value}", "-", false)),
              Container(width: 1, height: 40, color: _kBorderColor),
              Expanded(child: _buildSubStat("Avg. Rating", ctrl.averageRating.value.toStringAsFixed(1), "-", true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat(String title, String value, String trend, bool isPositive) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 12, color: _kTextMuted)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: _kTextDark)),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: Text(
                trend,
                style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600, color: isPositive ? _kGreen : _kRed),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentBookings() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Bookings",
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _kTextDark),
              ),
              Text(
                "View All",
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _kOrange),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (ctrl.recentBookings.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text("No recent bookings", style: GoogleFonts.poppins(color: _kTextMuted)),
              ),
            ),
          ...ctrl.recentBookings.map((booking) {
            String title = booking['service']?['name']?.toString() ?? 'Service';
            String name = "${booking['customer']?['firstName'] ?? ''} ${booking['customer']?['lastName'] ?? ''}";
            String date = booking['bookingDate']?.toString().split('T').first ?? '';
            String time = booking['bookingTime']?.toString() ?? '';
            String price = "₹${(booking['totalAmount'] ?? 0)}";
            String status = booking['status']?.toString() ?? 'Upcoming';
            
            // Format status
            status = status.substring(0, 1).toUpperCase() + status.substring(1).toLowerCase();

            return Column(
              children: [
                _buildRecentBookingItem(Icons.cleaning_services_outlined, const Color(0xFFFFF7ED), _kOrange,
                    title, name, "$date  •  $time", price, status),
                const Divider(color: _kBorderColor, height: 24),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentBookingItem(IconData icon, Color iconBg, Color iconColor, String title, String name, String date,
      String price, String status) {
    Color statusColor;
    Color statusBg;
    if (status == "Upcoming") {
      statusColor = _kGreen;
      statusBg = const Color(0xFFECFDF5);
    } else {
      statusColor = const Color(0xFF3B82F6);
      statusBg = const Color(0xFFEFF6FF);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _kTextDark)),
              const SizedBox(height: 2),
              Text(name, style: GoogleFonts.poppins(fontSize: 12, color: _kTextMuted)),
              const SizedBox(height: 4),
              Text(date, style: GoogleFonts.poppins(fontSize: 11, color: _kTextMuted)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
              child: Text(status,
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
            ),
            const SizedBox(height: 8),
            Text(price, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _kTextDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingsReviews() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ratings & Reviews",
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _kTextDark),
              ),
              Text(
                "View All",
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _kOrange),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(ctrl.averageRating.value.toStringAsFixed(1),
                          style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w700, color: _kTextDark)),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, color: Color(0xFFF59E0B), size: 28),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("(${ctrl.totalReviews.value} Reviews)", style: GoogleFonts.poppins(fontSize: 12, color: _kTextMuted)),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(5, ctrl.ratingDistribution[5] ?? 0, ctrl.totalReviews.value),
                    const SizedBox(height: 8),
                    _buildRatingBar(4, ctrl.ratingDistribution[4] ?? 0, ctrl.totalReviews.value),
                    const SizedBox(height: 8),
                    _buildRatingBar(3, ctrl.ratingDistribution[3] ?? 0, ctrl.totalReviews.value),
                    const SizedBox(height: 8),
                    _buildRatingBar(2, ctrl.ratingDistribution[2] ?? 0, ctrl.totalReviews.value),
                    const SizedBox(height: 8),
                    _buildRatingBar(1, ctrl.ratingDistribution[1] ?? 0, ctrl.totalReviews.value),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    double percent = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        Text("$stars", style: GoogleFonts.poppins(fontSize: 12, color: _kTextMuted)),
        const SizedBox(width: 4),
        const Icon(Icons.star, color: Color(0xFFF59E0B), size: 12),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(color: _kBorderColor, borderRadius: BorderRadius.circular(3)),
            child: Row(
              children: [
                Expanded(
                  flex: (percent * 100).toInt(),
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                Expanded(flex: 100 - (percent * 100).toInt(), child: const SizedBox()),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 24,
          child: Text(count.toString(),
              style: GoogleFonts.poppins(fontSize: 12, color: _kTextMuted), textAlign: TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildProfileCompletion() {
    double progress = ctrl.profileCompletion.value / 100;
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Profile Completion",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _kTextDark),
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: _kBorderColor,
                  color: _kGreen,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Text("${(progress * 100).toInt()}%", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: _kTextDark)),
                  Text("Profile Complete", style: GoogleFonts.poppins(fontSize: 10, color: _kTextMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "Complete your profile to get more bookings",
            style: GoogleFonts.poppins(fontSize: 12, color: _kTextMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _kOrange),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Complete Profile",
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _kOrange)),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Export Provider Report",
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: _kTextDark),
            ),
            const SizedBox(height: 8),
            Text(
              "Choose your preferred format to download the report.",
              style: GoogleFonts.poppins(fontSize: 14, color: _kTextMuted),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: _kRed),
              title: Text("Download as PDF", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              subtitle: Text("Professional visual report with charts", style: GoogleFonts.poppins(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                ctrl.generatePDFReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: _kGreen),
              title: Text("Export to Excel", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              subtitle: Text("Structured data for analysis", style: GoogleFonts.poppins(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                ctrl.exportExcel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet_outlined, color: Colors.blue),
              title: Text("Export to CSV", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              subtitle: Text("Raw data in comma-separated values", style: GoogleFonts.poppins(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                ctrl.exportCSV();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}
