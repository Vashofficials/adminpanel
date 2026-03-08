import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/customer_models.dart'; // Ensure this import points to your model file
import '../repositories/booking_repository.dart';
import '../models/booking_models.dart';

// --- Constants ---
const Color kPrimaryOrange = Color(0xFFFF6B00);
const Color kTextDark = Color(0xFF1E293B);
const Color kTextLight = Color(0xFF64748B);
const Color kBorderColor = Color(0xFFE2E8F0);
const Color kBgColor = Color(0xFFF1F5F9);

class CustomerOverviewScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final Customer customer; // Added: Receive the specific customer data
  final Function(BookingModel)? onViewBooking; // <--- ADD THIS

  const CustomerOverviewScreen({
    super.key, 
    this.onBack, 
    this.onEdit, 
    required this.customer,
    this.onViewBooking, // <--- ADD THIS
  });

  @override
  State<CustomerOverviewScreen> createState() => _CustomerOverviewScreenState();
}

class _CustomerOverviewScreenState extends State<CustomerOverviewScreen> {
  int _currentTab = 0; // 0: Overview, 1: Bookings, 2: Reviews

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (widget.onBack != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: kTextDark),
                              onPressed: widget.onBack,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        const Text('Customer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextDark)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Dynamic Joined Date
                    Text('Joined on ${widget.customer.joinedDate}', style: const TextStyle(color: kTextLight)),
                  ],
                ),
                // Share Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: kBorderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                 // child: const Icon(Icons.share_outlined, color: kPrimaryOrange, size: 20),
                )
              ],
            ),
            const SizedBox(height: 24),

            // --- Custom Tabs ---
            Row(
              children: [
                _buildTabItem(0, "Overview"),
                const SizedBox(width: 12),
                _buildTabItem(1, "Bookings"),
                const SizedBox(width: 12),
                _buildTabItem(2, "Reviews"),
              ],
            ),
            const SizedBox(height: 24),

            // --- Tab Content ---
            IndexedStack(
              index: _currentTab,
              children: [
                _OverviewTab(
                  customer: widget.customer, // Pass customer to tab
                  onEdit: widget.onEdit
                ), 
_BookingsTab(
                  customerId: widget.customer.id,
                  onViewBooking: widget.onViewBooking, // <--- PASS IT HERE
                ),
                       const _ReviewsTab(),  // You can pass customer here later for API calls
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final bool isActive = _currentTab == index;
    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? kPrimaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : kTextLight,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 1: OVERVIEW (Dynamic Data)
// =============================================================================
class _OverviewTab extends StatelessWidget {
  final VoidCallback? onEdit;
  final Customer customer; // Receive customer data
  
  const _OverviewTab({this.onEdit, required this.customer});

  @override
  Widget build(BuildContext context) {
    // Dynamic Stats (Using placeholders if data isn't in model yet)
    final bookingsCount = customer.bookings.toString();
    const totalAmount = "\u20B90.00"; // API doesn't provide this yet

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Stats Cards & Chart ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Total Booking Placed
            Expanded(
              child: _buildStatCard(
                value: bookingsCount, 
                label: "Total Booking Placed",
                valueColor: kPrimaryOrange,
                bgColor: const Color(0xFFFFF7ED),
              ),
            ),
            const SizedBox(width: 20),
            // Card 2: Total Booking Amount
            Expanded(
              child: _buildStatCard(
                value: totalAmount,
                label: "Total Booking Amount",
                valueColor: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
              ),
            ),
            const SizedBox(width: 20),
            // Card 3: Booking Overview Chart (Static for now, can be dynamic later)
            Expanded(
              flex: 1, 
              child: Container(
                height: 140,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorderColor),
                ),
                child: Row(
                  children: [
                    // Donut Chart
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 35,
                              sections: [
                                PieChartSectionData(color: kPrimaryOrange, value: 30, title: '', radius: 12),
                                PieChartSectionData(color: const Color(0xFF10B981), value: 70, title: '', radius: 12),
                              ],
                            ),
                          ),
                          Center(
                            child: Text(
                              "$bookingsCount\nBookings",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, height: 1.2),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Legend
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text("Booking Overview", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextLight)),
                          SizedBox(height: 8),
                          _ChartLegend(color: kPrimaryOrange, label: "Pending"),
                          SizedBox(height: 4),
                          _ChartLegend(color: Color(0xFF10B981), label: "Accepted"),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // --- Personal Details (Dynamic) ---
        const Text("Personal Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Dynamic Avatar
              if (customer.imgLink != null && customer.imgLink!.isNotEmpty)
                CircleAvatar(
                  radius: 36,
                  backgroundImage: NetworkImage(customer.imgLink!),
                  onBackgroundImageError: (_, __) {},
                )
              else
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(int.tryParse(customer.avatarColor) ?? 0xFFFFE4B5),
                  child: Text(
                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : "U",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              const SizedBox(width: 24),
              
              // Dynamic Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.phone_android, customer.phone.isNotEmpty ? customer.phone : "No Phone"),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.email_outlined, customer.email.isNotEmpty ? customer.email : "No Email"),
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.location_on_outlined, customer.location),
                  ],
                ),
              ),
              // Edit Button
              ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                label: const Text("Edit", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryOrange,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({required String value, required String label, required Color valueColor, required Color bgColor}) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: valueColor)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: kTextLight)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kTextLight),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, color: kTextDark, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: kTextDark)),
      ],
    );
  }
}

// =============================================================================
// TAB 2: BOOKINGS (Static / Mock for now)
// =============================================================================
// TAB 2: BOOKINGS (Dynamic API Integration)
class _BookingsTab extends StatefulWidget {
  final String customerId; 
  final Function(BookingModel)? onViewBooking; // <--- 1. Receive Callback

  const _BookingsTab({required this.customerId, this.onViewBooking});

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  final BookingRepository _repo = BookingRepository();
  bool _isLoading = true;
  List<BookingModel> _bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isLoading = true);
    final data = await _repo.fetchCustomerBookings(widget.customerId);
    if (mounted) {
      setState(() {
        _bookings = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ... (Search Bar UI remains same) ...
          
          const SizedBox(height: 24),
          const _BookingTableHeader(),
          const Divider(height: 1, color: kBorderColor),
          
          if (_isLoading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator(color: kPrimaryOrange)))
          else if (_bookings.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text("No bookings found.", style: TextStyle(color: kTextLight))))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bookings.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: kBorderColor),
              itemBuilder: (context, index) {
                final item = _bookings[index];
                
                // ... (Date/Status Logic remains same) ...
                // Recalculate statusColor, displayDate etc here as per previous code...
                final String displayDate = item.bookingDate.length >= 10 ? item.bookingDate.substring(0, 10) : item.bookingDate;
                final String serviceName = item.services.isNotEmpty ? item.services.first.serviceName : "Unknown";
                final String providerName = item.provider != null ? "${item.provider!.firstName} ${item.provider!.lastName}" : "Unassigned";

                return _buildRow(
                  "#${item.bookingRef}", 
                  serviceName,
                  displayDate,
                  providerName,
                  "\u20B9${item.totalAmount.toStringAsFixed(2)}",
                  item.status,
                  Colors.blue, // Pass calculated color
                  Icons.info, // Pass calculated icon
                  Colors.blue.shade50, // Pass calculated bg
                  
                  // 2. Trigger the callback here
                  onTapAction: () {
                    if (widget.onViewBooking != null) {
                      widget.onViewBooking!(item); // Pass full object up
                    }
                  }
                );
              },
            ),
           // ... Footer ...
        ],
      ),
    );
  }

  // 3. Update _buildRow to accept the action
  Widget _buildRow(
    String id, String service, String date, String provider, String amount, String status, 
    Color statusColor, IconData icon, Color iconBg,
    {required VoidCallback onTapAction} // <--- Added Parameter
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(id, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kTextDark))),
          Expanded(flex: 2, child: Text(service, style: const TextStyle(fontSize: 13, color: kTextDark), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(date, style: const TextStyle(fontSize: 13, color: kTextDark))),
          Expanded(flex: 2, child: Text(provider, style: const TextStyle(fontSize: 13, color: kTextDark))),
          Expanded(flex: 1, child: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextDark))),
          Expanded(flex: 1, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          )),
          
          // 4. Connect the Action Button
          Expanded(
            flex: 1, 
            child: IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 18, color: kTextLight),
              onPressed: onTapAction, // <--- Use the callback
              tooltip: "View Details",
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingTableHeader extends StatelessWidget {
  const _BookingTableHeader();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: const [
          Expanded(flex: 1, child: Text("BOOKING ID", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextLight))),
          Expanded(flex: 2, child: Text("SERVICE NAME", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextLight))),
          Expanded(flex: 2, child: Text("BOOKING DATE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextLight))),
          Expanded(flex: 2, child: Text("PROVIDER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextLight))),
          Expanded(flex: 1, child: Text("AMOUNT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextLight))),
          Expanded(flex: 1, child: Text("STATUS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextLight))),
          Expanded(flex: 1, child: Text("ACTION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextLight))),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 3: REVIEWS (Static / Mock)
// =============================================================================
class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search here',
                    prefixIcon: const Icon(Icons.search, color: kTextLight),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Search", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Header
           Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: const [
                Expanded(flex: 2, child: Text("BOOKING ID", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextLight))),
                Expanded(flex: 2, child: Text("BOOKING DATE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextLight))),
                Expanded(flex: 2, child: Text("RATINGS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextLight))),
                Expanded(flex: 4, child: Text("REVIEWS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextLight))),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorderColor),

          // Rows
          _buildReviewRow("#LKO-2401-892", "22 Jan, 2025", 4.0, "Excellent service by the team. The cleaning was thorough and timely."),
          const Divider(height: 1, color: kBorderColor),
          _buildReviewRow("#LKO-2312-455", "15 Dec, 2024", 5.0, "Very professional staff."),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String id, String date, double rating, String review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(id, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Expanded(flex: 2, child: Text(date, style: const TextStyle(fontSize: 13))),
          Expanded(flex: 2, child: Row(
            children: [
              ...List.generate(5, (index) => Icon(
                Icons.star, 
                size: 14, 
                color: index < rating ? Colors.amber : Colors.grey.shade300
              )),
              const SizedBox(width: 8),
              Text("$rating", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
            ],
          )),
          Expanded(flex: 4, child: Text(review, style: const TextStyle(fontSize: 13, color: kTextLight, height: 1.4))),
        ],
      ),
    );
  }
}

class _PaginationBtn extends StatelessWidget {
  final String label;
  final bool active;
  const _PaginationBtn(this.label, {this.active = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32, height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? kPrimaryOrange : Colors.white,
        border: Border.all(color: active ? kPrimaryOrange : kBorderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: active ? Colors.white : kTextLight, fontSize: 12)),
    );
  }
}