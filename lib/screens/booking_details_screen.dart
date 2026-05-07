import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/booking_models.dart';
import '../services/invoice_service.dart';
import '../services/api_service.dart';
import '../widgets/custom_center_dialog.dart';
import 'reschedule_dialog.dart';

class BookingDetailsScreen extends StatefulWidget {
  final BookingModel booking; // <--- Changed: Accept Full Object
  final VoidCallback onBack;

  const BookingDetailsScreen({
    super.key,
    required this.booking,
    required this.onBack,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final ApiService _apiService =
      ApiService(); // Use the actual name of your service class
  String _currentTab = "Details";
  // Controllers for Reschedule Dialog
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _cancelReasonController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedAddressId; // To handle the "Change Address" logic
// Invoice generation is handled by InvoiceService

  // Helper: Status Color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'canceled':
      case 'cancelled':
        return const Color(0xFFEF4444); // Red
      case 'completed':
        return const Color(0xFF10B981); // Green
      case 'ongoing':
      case 'progress':
        return const Color(0xFF2563EB); // Blue
      default:
        return const Color(0xFFEF7822); // Orange (Pending)
    }
  }

  // Helper: Date Format
  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return "N/A";
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (e) {
      return isoDate.split('T')[0];
    }
  }

  String _formatDateTime(String isoDate) {
    if (isoDate.isEmpty) return "N/A";
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (e) {
      return isoDate.split('T')[0];
    }
  }

  // New Helper: Combined Schedule Format
  String _formatSchedule(String dateIso, String timeStr) {
    if (dateIso.isEmpty || dateIso == 'N/A') return "N/A";
    try {
      final dt = DateTime.parse(dateIso).toLocal();
      final datePart = DateFormat('dd-MMM-yyyy').format(dt);

      // timeStr is usually "HH:mm"
      String finalTime = timeStr;
      try {
        final timeParts = timeStr.split(':');
        final tempDate = DateTime(
            2022, 1, 1, int.parse(timeParts[0]), int.parse(timeParts[1]));
        finalTime = DateFormat('hh:mm a').format(tempDate);
      } catch (e) {/* use raw timeStr */}

      return "$datePart $finalTime";
    } catch (e) {
      return dateIso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking; // Use local variable for cleaner code

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER SECTION ---
            // --- HEADER SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// LEFT SIDE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Booking Details",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      /// 🔥 BOOKING REF + COPY + STATUS
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: booking.bookingRef),
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Booking ID copied"),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Text(
                                  "Booking # ${booking.bookingRef}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEF7822),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.copy,
                                    size: 16, color: Colors.grey),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          /// STATUS BADGE
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(booking.status)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              booking.status,
                              style: TextStyle(
                                color: _getStatusColor(booking.status),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      /// BOOKING DATE
                      Text(
                        "Booking Placed : ${_formatDateTime(booking.creationTime)}",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),

                      if (booking.rescheduleReason != null &&
                          booking.rescheduleReason!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule,
                                  size: 14, color: Colors.orange),
                              const SizedBox(width: 6),

                              /// 🔥 TEXT TAG (NOT FULL WIDTH)
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "Reschedule: ${booking.rescheduleReason}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                /// RIGHT SIDE (BUTTON)
                if (booking.status.toUpperCase() == 'COMPLETED')
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'platform') {
                        InvoiceService.printPlatformInvoice(booking);
                      } else if (value == 'provider') {
                        InvoiceService.printProviderInvoice(booking);
                      }
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    offset: const Offset(0, 44),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'platform',
                        child: Row(
                          children: [
                            Container(
                              height: 18,
                              width: 18,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: SvgPicture.asset(
                                'assets/logo.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text('Platform Invoice'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'provider',
                        child: Row(
                          children: [
                            Container(
                              height: 18,
                              width: 18,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: SvgPicture.asset(
                                'assets/logo.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text('Provider Invoice'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description,
                              size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Invoice',
                              style: TextStyle(color: Colors.white)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down,
                              size: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // --- TABS ---
            Row(
              children: [
                _buildTabButton("Details"),
                const SizedBox(width: 20),
                _buildTabButton("Status"),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            const SizedBox(height: 24),

            // --- BODY ---
            _currentTab == "Details"
                ? _buildDetailsView(booking)
                : _buildStatusView(booking),

            // Back Button
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Back to List")),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String text) {
    bool isActive = _currentTab == text;
    return InkWell(
      onTap: () => setState(() => _currentTab = text),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: isActive
              ? const Border(
                  bottom: BorderSide(color: Color(0xFFEF7822), width: 2))
              : null,
        ),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFFEF7822) : Colors.grey,
                fontSize: 16)),
      ),
    );
  }

  // --- VIEW 1: DETAILS ---
  Widget _buildDetailsView(BookingModel booking) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1000) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildLeftColumn(booking)),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _buildRightColumn(booking)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildLeftColumn(booking),
              const SizedBox(height: 24),
              _buildRightColumn(booking),
            ],
          );
        }
      },
    );
  }

  // --- VIEW 2: STATUS TIMELINE ---
  Widget _buildStatusView(BookingModel booking) {
    int step = 1;
    String s = booking.status.toLowerCase();
    if (s.contains('accept') || s.contains('progress') || s.contains('ongoing'))
      step = 2;
    if (s.contains('complet')) step = 3;
    bool isCancelled = s.contains('cancel');

    return _buildCard(
      title: "Booking Status",
      child: Column(
        children: [
          _buildTimelineItem(
            title: "Booking Placed",
            subtitle:
                "By ${booking.customerName}\n${_formatDateTime(booking.creationTime)}",
            isActive: true,
            isLast: false,
          ),
          _buildTimelineItem(
            title: isCancelled ? "Cancelled" : "InProgress / Ongoing",
            subtitle: isCancelled
                ? (booking.cancelReason.isNotEmpty
                    ? "Reason: ${booking.cancelReason}"
                    : "Booking was canceled")
                : "Provider Assigned",
            isActive: isCancelled || step >= 2,
            isLast: false,
            overrideColor: isCancelled ? Colors.red : null,
            overrideIcon: isCancelled ? Icons.close : null,
          ),
          _buildTimelineItem(
            title: "Completed",
            subtitle: "Service Done",
            isActive: !isCancelled && step >= 3,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
      {required String title,
      required String subtitle,
      required bool isActive,
      required bool isLast,
      Color? overrideColor,
      IconData? overrideIcon}) {
    final color = overrideColor ??
        (isActive ? const Color(0xFFEF7822) : Colors.grey[200]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: isActive
                  ? Icon(overrideIcon ?? Icons.check,
                      size: 16, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: isActive
                    ? (overrideColor ?? const Color(0xFFEF7822))
                        .withOpacity(0.5)
                    : Colors.grey[200],
              )
          ],
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isActive ? Colors.black : Colors.grey)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13, height: 1.4)),
            const SizedBox(height: 20),
          ],
        )
      ],
    );
  }

  // --- COLUMNS ---

// --- UPDATED LEFT COLUMN (BILLING FOCUS) ---
  Widget _buildLeftColumn(BookingModel booking) {
    return Column(
      children: [
        _buildCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Payment Method",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(booking.paymentMode,
                      style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  // Updated to show Grand Total (without Platform Fee)
                  Text(
                      "Total Payable: ₹${booking.grandTotalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF2563EB))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Text("Status: ",
                          style: TextStyle(color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: booking.paymentStatus.toLowerCase() == 'paid'
                                ? Colors.green[50]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(booking.paymentStatus,
                            style: TextStyle(
                                color: booking.paymentStatus.toLowerCase() ==
                                        'paid'
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("OTP: ${booking.bookingPin}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                      "Schedule: ${_formatSchedule(booking.bookingDate, booking.bookingTime)}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    "Total Duration: ${booking.totalDuration} mins",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- UPDATED BILLING SUMMARY ---
        _buildCard(
          title: "Billing Summary",
          child: Column(
            children: [
              _buildSummaryHeader(),
              const Divider(),

              if (booking.services.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("No services listed")),

              ...booking.services.map((s) {
                final double unitPrice = s.price;
                final double totalPrice = s.price * s.quantity;
                return _buildSummaryRow(
                    s.serviceName,
                    "Original Price",
                    "₹${unitPrice.toStringAsFixed(2)}",
                    s.quantity.toString(), // ✅ real quantity
                    "₹${totalPrice.toStringAsFixed(2)}");
              }),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Breakdown Section
              _buildTotalRow("Service Total",
                  "₹${booking.originalPrice.toStringAsFixed(2)}"),

              if (booking.couponDiscountValue > 0)
                _buildTotalRow(
                  "Coupon Discount ${booking.coupon?.couponCode != null ? '(${booking.coupon!.couponCode})' : ''}",
                  "- ₹${booking.couponDiscountValue.toStringAsFixed(2)}",
                  color: Colors.green,
                ),

              if (booking.totalDiscount > booking.couponDiscountValue)
                _buildTotalRow(
                  "Service Discount",
                  "- ₹${(booking.totalDiscount - booking.couponDiscountValue).toStringAsFixed(2)}",
                  color: Colors.green,
                ),

              _buildTotalRow(
                  "Platform Fee", "₹${booking.platformFee.toStringAsFixed(2)}", isNote: true),

              _buildTotalRow("GST (${booking.gstPercentage.toStringAsFixed(0)}%)",
                  "₹${booking.gstAmount.toStringAsFixed(2)}"),

              const SizedBox(height: 8),
              const Divider(thickness: 1.2),
              const SizedBox(height: 8),

              // Final Grand Total
              _buildTotalRow("Grand Total",
                  "₹${booking.grandTotalPrice.toStringAsFixed(2)}",
                  isBold: true, color: const Color(0xFF2563EB)),
            ],
          ),
        ),
      ],
    );
  }

  // Modified helper to handle the "Note" style
  Widget _buildTotalRow(String label, String value,
      {bool isBold = false, Color? color, bool isNote = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label,
                  style: TextStyle(
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                      fontSize: isBold ? 16 : 13)),
              if (isNote)
                const Text("(Not included in total)",
                    style: TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 40),
          SizedBox(
            width: 120,
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    color: color,
                    fontSize: isBold ? 16 : 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildRightColumn(BookingModel booking) {
    // Determine color based on payment status
    final isPaid = booking.paymentStatus.toLowerCase() == 'paid';
    final statusColor = isPaid ? Colors.green : Colors.red;
    final statusBgColor = isPaid ? Colors.green[50] : Colors.red[50];

    return Column(
      children: [
        _buildCard(
          title: "Booking Setup",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Payment Status",
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      booking.paymentStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Status Dropdown (Read Only)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(booking.status,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),

              // Date Field
              TextField(
                enabled: false,
                decoration: InputDecoration(
                  hintText:
                      _formatSchedule(booking.bookingDate, booking.bookingTime),
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                ),
              )
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Location Card
        _buildCard(
          title: "Service Location",
          titleIcon: Icons.map,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFEAD1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text(
                    "Provider has to go to the Customer Location to provide the service",
                    style: TextStyle(
                        color: Color(0xFFD97706), fontSize: 13, height: 1.4)),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Address:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  if (booking.address?.fullFormattedAddress != null)
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(
                            text: booking.address!.fullFormattedAddress));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Address copied to clipboard")));
                      },
                      child: const Icon(Icons.copy, size: 16, color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                booking.address?.fullFormattedAddress ?? "No Address Provided",
                style: const TextStyle(color: Colors.grey, height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Provider Info
        _buildCard(
          title: "Provider Information",
          titleIcon: Icons.engineering,
          child: booking.provider == null
              ? const Text("No Provider Assigned",
                  style: TextStyle(color: Colors.red))
              : Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.orange[100],
                      child: Text(booking.provider!.firstName.isNotEmpty
                          ? booking.provider!.firstName[0]
                          : "P"),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "${booking.provider!.firstName} ${booking.provider!.lastName}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF2563EB))),
                          const SizedBox(height: 4),
                          Text(booking.provider!.mobile,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                            text: "${booking.provider!.firstName} ${booking.provider!.lastName} - ${booking.provider!.mobile}"));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("Provider details copied to clipboard")));
                      },
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 24),

        // Customer Info
        _buildCard(
          title: "Customer Information",
          titleIcon: Icons.person,
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue[100],
                child: Text(booking.customerName.isNotEmpty
                    ? booking.customerName[0]
                    : "C"),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.customerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF2563EB))),
                    const SizedBox(height: 4),
                    Text(booking.customerPhone,
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                      text: "${booking.customerName} - ${booking.customerPhone}"));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Customer details copied to clipboard")));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Coupon Applied
        if (booking.hasCoupon)
          _buildCard(
            title: "Coupon Applied",
            titleIcon: Icons.local_offer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coupon Code Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFEF7822).withOpacity(0.12),
                        const Color(0xFFEF7822).withOpacity(0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEF7822).withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number, 
                          size: 20, color: Color(0xFFEF7822)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.coupon!.couponCode ?? "N/A",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFFEF7822),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.coupon!.typeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          booking.coupon!.discountLabel,
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 14),
                
                // Coupon details rows
                _buildCouponInfoRow(
                  "Discount Applied",
                  "- ₹${booking.couponDiscountValue.toStringAsFixed(2)}",
                  valueColor: const Color(0xFF10B981),
                ),
                if (booking.coupon!.minPurchaseAmount > 0)
                  _buildCouponInfoRow(
                    "Min Purchase Amount",
                    "₹${booking.coupon!.minPurchaseAmount.toStringAsFixed(0)}",
                  ),
                if (booking.coupon!.sameUserLimit > 0)
                  _buildCouponInfoRow(
                    "Usage Limit / User",
                    "${booking.coupon!.sameUserLimit} time(s)",
                  ),
              ],
            ),
          ),

        const SizedBox(height: 24),
        if (booking.status.toLowerCase() != 'canceled' &&
            booking.status.toLowerCase() != 'cancelled')
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showRescheduleDialog(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Reschedule"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showCancelDialog(booking),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Cancel Booking",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _showRescheduleDialog(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => RescheduleBookingDialog(
        booking: booking,
        onBack: widget.onBack,
      ),
    );
  }

  void _showCancelDialog(BookingModel booking) {
    _cancelReasonController.clear();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// 🔹 ICON
                const Icon(Icons.cancel, size: 30, color: Colors.red),

                const SizedBox(height: 18),

                /// 🔹 TITLE
                const Text(
                  "Cancel Booking",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 22),

                /// 🔹 REASON FIELD
                TextField(
                  controller: _cancelReasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Reason",
                    prefixIcon: Icon(Icons.edit_note),
                    border: OutlineInputBorder(),
                    hintText: "Enter cancellation reason",
                  ),
                ),

                const SizedBox(height: 28),

                /// 🔹 ACTION BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Back"),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () async {
                          /// 🔴 VALIDATION
                          if (_cancelReasonController.text.trim().isEmpty) {
                            CustomCenterDialog.show(
                              context,
                              title: "Required",
                              message: "Please enter a cancellation reason",
                              type: DialogType.required,
                            );
                            return;
                          }

                          /// 🔥 CONFIRMATION DIALOG
                          CustomCenterDialog.show(
                            context,
                            title: "Confirm Cancellation",
                            message:
                                "Are you sure you want to cancel this booking?",
                            type: DialogType.warning,
                            confirmText: "Yes, Cancel",
                            cancelText: "No",
                            onConfirm: () async {
                              final payload = {
                                "bookingId": booking.id,
                                "reason": _cancelReasonController.text.trim(),
                              };

                              bool success =
                                  await _apiService.cancelBooking(payload);

                              Navigator.pop(context); // close main dialog
                              widget.onBack();

                              if (success) {
                                CustomCenterDialog.show(
                                  context,
                                  title: "Cancelled",
                                  message: "Booking cancelled successfully",
                                  type: DialogType.success,
                                );
                              } else {
                                CustomCenterDialog.show(
                                  context,
                                  title: "Failed",
                                  message: "Unable to cancel booking",
                                  type: DialogType.error,
                                );
                              }
                            },
                          );
                        },
                        child: const Text(
                          "Confirm",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // --- WIDGET HELPERS ---

  Widget _buildCard(
      {String? title, IconData? titleIcon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, size: 18),
                  const SizedBox(width: 8)
                ],
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: const [
          Expanded(
              flex: 3,
              child: Text("SERVICE",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey))),
          Expanded(
              flex: 2,
              child: Text("PER UNIT PRICE",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey))),
          Expanded(
              flex: 1,
              child: Text("QTY",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey))),
          Expanded(
              flex: 2,
              child: Text("TOTAL",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey),
                  textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      String name, String sub, String price, String qty, String total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(sub,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11)),
                  ])),
          Expanded(flex: 2, child: Text(price)),
          Expanded(flex: 1, child: Text(qty)),
          Expanded(
              flex: 2,
              child: Text(total,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  /*Widget _buildTotalRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 13)),
          const SizedBox(width: 40),
          SizedBox(
            width: 100,
            child: Text(value, textAlign: TextAlign.end, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color, fontSize: isBold ? 16 : 13)),
          ),
        ],
      ),
    );
  } */

  Widget _buildCouponInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              )),
        ],
      ),
    );
  }
}
