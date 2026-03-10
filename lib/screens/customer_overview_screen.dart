import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/customer_models.dart'; // Ensure this import points to your model file
import '../repositories/booking_repository.dart';
import '../models/booking_models.dart';
import '../services/api_service.dart';
import '../models/customer_refundbank.dart';

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
_ReviewsTab(
      customerId: widget.customer.id, 
    ),              ],
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
// --- Add this model inside your file or models folder ---
class RefundBankModel {
  final String id;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String upiId;
  final bool isActive;

  RefundBankModel({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.upiId,
    required this.isActive,
  });

  factory RefundBankModel.fromJson(Map<String, dynamic> json) {
    return RefundBankModel(
      id: json['id'] ?? '',
      bankName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      upiId: json['upiId'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}

// =============================================================================
// TAB 1: OVERVIEW (Updated to StatefulWidget)
// =============================================================================
class _OverviewTab extends StatefulWidget {
  final VoidCallback? onEdit;
  final Customer customer;

  const _OverviewTab({this.onEdit, required this.customer});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  // Assuming you have an ApiService instance. Replace with your actual service.
  final ApiService _api = ApiService();
  
List<RefundBank> _banks = [];
  bool _isBankLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBankDetails();
  }

Future<void> _fetchBankDetails() async {
  if (!mounted) return;
  setState(() => _isBankLoading = true);
  
  try {
    // 1. Call the actual API via your ApiService
    // Make sure your ApiService has the getCustomerRefundBanks method (see step 2 below)
final List<RefundBank> realBanks = await _api.getCustomerRefundBanks(widget.customer.id);
    if (mounted) {
      setState(() {
        _banks = realBanks;
        _isBankLoading = false;
      });
    }
  } catch (e) {
    debugPrint("❌ Error fetching real bank data: $e");
    if (mounted) {
      setState(() {
        _banks = [];
        _isBankLoading = false;
      });
    }
  }
}
  @override
  Widget build(BuildContext context) {
    final bookingsCount = widget.customer.bookings.toString();
    const totalAmount = "\u20B90.00";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Stats Cards & Chart ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildStatCard(
                value: bookingsCount,
                label: "Total Booking Placed",
                valueColor: kPrimaryOrange,
                bgColor: const Color(0xFFFFF7ED),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildStatCard(
                value: totalAmount,
                label: "Total Booking Amount",
                valueColor: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 1,
              child: _buildOverviewChart(bookingsCount),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // --- Personal Details ---
        const Text("Personal Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)),
        const SizedBox(height: 16),
        _buildPersonalDetailsCard(),

        const SizedBox(height: 32),

        // --- Refund Bank Details Section ---
        const Text("Refund Bank Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)),
        const SizedBox(height: 16),
        
        if (_isBankLoading)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator(color: kPrimaryOrange)),
          )
        else if (_banks.isEmpty)
          _buildEmptyBankState()
        else
          _buildBankGrid(),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildOverviewChart(String count) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        children: [
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
                    "$count\nBookings",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Overview", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextLight)),
                SizedBox(height: 8),
                _ChartLegend(color: kPrimaryOrange, label: "Pending"),
                SizedBox(height: 4),
                _ChartLegend(color: Color(0xFF10B981), label: "Accepted"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.customer.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone_android, widget.customer.phone.isNotEmpty ? widget.customer.phone : "No Phone"),
                const SizedBox(height: 4),
                _buildInfoRow(Icons.email_outlined, widget.customer.email.isNotEmpty ? widget.customer.email : "No Email"),
                const SizedBox(height: 4),
                _buildInfoRow(Icons.location_on_outlined, widget.customer.location),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: widget.onEdit,
            icon: const Icon(Icons.edit, size: 16, color: Colors.white),
            label: const Text("Edit", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (widget.customer.imgLink != null && widget.customer.imgLink!.isNotEmpty) {
      return CircleAvatar(
        radius: 36,
        backgroundImage: NetworkImage(widget.customer.imgLink!),
      );
    }
    return CircleAvatar(
      radius: 36,
      backgroundColor: Color(int.tryParse(widget.customer.avatarColor) ?? 0xFFFFE4B5),
      child: Text(
        widget.customer.name.isNotEmpty ? widget.customer.name[0].toUpperCase() : "U",
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildBankGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _banks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 160,
      ),
      itemBuilder: (context, index) {
        final bank = _banks[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(bank.bankName, style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryOrange, fontSize: 16)),
                  if (bank.isActive)
                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                ],
              ),
              const Divider(height: 24),
              _buildBankDetailRow(Icons.account_balance, "A/C Number", bank.accountNumber),
              const SizedBox(height: 8),
              _buildBankDetailRow(Icons.qr_code, "IFSC Code", bank.ifscCode),
              const SizedBox(height: 8),
              _buildBankDetailRow(Icons.alternate_email, "UPI ID", bank.upiId),
            ],
          ),
        );
      }
    );
  }

  Widget _buildBankDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: kTextLight),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontSize: 12, color: kTextLight)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextDark)),
      ],
    );
  }

  Widget _buildEmptyBankState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor, style: BorderStyle.solid),
      ),
      child: const Center(
        child: Text("No refund bank accounts found.", style: TextStyle(color: kTextLight)),
      ),
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
class _ReviewsTab extends StatefulWidget {
  final String customerId;
  const _ReviewsTab({super.key, required this.customerId});

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  final ApiService _api = ApiService();
  List<BookingReview> _reviews = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    try {
      // API call to /admin/getBookingRatingByCustomer
      final response = await _api.getBookingRatings(widget.customerId);
      if (mounted) {
        setState(() {
          _reviews = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // --- Search Bar ---
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Booking ID...',
                    prefixIcon: const Icon(Icons.search, color: kTextLight),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorderColor)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _fetchReviews,
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
          
          // --- Table Header ---
          const _ReviewTableHeader(),
          const Divider(height: 1, color: kBorderColor),

          // --- Dynamic Content ---
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: kPrimaryOrange))
          else if (_reviews.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: kBorderColor),
              itemBuilder: (context, index) {
                final item = _reviews[index];
                return _buildReviewRow(
                  item.bookingId, 
                  item.bookingDate.split('T')[0], // Simple date format
                  item.rating, 
                  item.review
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No reviews found for this customer.", 
            style: TextStyle(color: kTextLight, fontSize: 14, fontWeight: FontWeight.w500)),
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

class _ReviewTableHeader extends StatelessWidget {
  const _ReviewTableHeader();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: const [
          Expanded(flex: 2, child: Text("BOOKING ID", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextLight))),
          Expanded(flex: 2, child: Text("BOOKING DATE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextLight))),
          Expanded(flex: 2, child: Text("RATINGS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextLight))),
          Expanded(flex: 4, child: Text("REVIEWS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextLight))),
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