import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/booking_models.dart';
import 'package:flutter/services.dart'; // For loading SVG from assets

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
  String _currentTab = "Details"; 
// --- NEW: INVOICE GENERATION LOGIC ---
  // --- NEW: DYNAMIC INVOICE GENERATION LOGIC ---
  Future<void> _printInvoice(BookingModel booking) async {
    final pdf = pw.Document();

    // Load SVG Logo from Assets
    String svgRaw = "";
    try {
      svgRaw = await rootBundle.loadString('assets/logo.svg');
    } catch (e) {
      debugPrint("SVG Logo not found: $e");
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 1. BRANDED HEADER
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (svgRaw.isNotEmpty)
                          pw.SizedBox(
                            width: 100,
                            height: 50,
                            child: pw.SvgImage(svg: svgRaw),
                          ),
                        pw.SizedBox(height: 5),
                        pw.Text("Chayan Karo", 
                          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("INVOICE", style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                        pw.Text("Booking Ref: ${booking.bookingRef}"),
                        pw.Text("Date: ${DateFormat('dd-MMM-yyyy').format(DateTime.now())}"),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Divider(thickness: 2, color: PdfColors.orange),
                pw.SizedBox(height: 20),

                // 2. CUSTOMER & BILLING DETAILS
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("BILL TO:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                          pw.SizedBox(height: 5),
                          pw.Text(booking.customerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                          pw.Text(booking.customerPhone),
                          pw.SizedBox(height: 2),
                          pw.Text(booking.address?.fullFormattedAddress ?? ""),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("PAYMENT INFO:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                          pw.SizedBox(height: 5),
                          pw.Text("Status: ${booking.paymentStatus}"),
                          pw.Text("Method: ${booking.paymentMode}"),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // 3. SERVICE TABLE
                pw.TableHelper.fromTextArray(
                  border: null,
                  headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.centerRight,
                  },
                  headers: ['Service Description', 'Qty', 'Price (INR)'],
                  data: booking.services.map((s) {
                    String qty = '1';
                    if (booking.services.length == 1 && s.serviceName == "Jet Based AC service") {
                      if (s.serviceDuration > 0 && booking.totalDuration > 0) {
                        qty = (booking.totalDuration ~/ s.serviceDuration).toString();
                      }
                    }
                    return [
                      s.serviceName,
                      qty,
                      s.price.toStringAsFixed(2),
                    ];
                  }).toList(),
                ),
                pw.Divider(thickness: 0.5),

                // 4. BILLING SUMMARY
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.SizedBox(height: 10),
_pdfPriceRow("Service Subtotal:", "INR ${booking.originalPrice.toStringAsFixed(2)}"),
                      if (booking.serviceDiscount > 0)
  _pdfPriceRow(
    "Service Discount:",
    "- INR ${booking.serviceDiscount.toStringAsFixed(2)}",
    color: PdfColors.green,
  ),

if (booking.couponDiscountValue > 0)
  _pdfPriceRow(
    "Coupon Discount ${booking.coupon?.couponCode != null ? '(${booking.coupon!.couponCode})' : ''}:",
    "- INR ${booking.couponDiscountValue.toStringAsFixed(2)}",
    color: PdfColors.green,
  ),
                      _pdfPriceRow("GST (${booking.gstPercentage}%):", "+ INR ${booking.gstAmount.toStringAsFixed(2)}"),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        width: 210,
                        padding: const pw.EdgeInsets.all(10),
                        decoration: const pw.BoxDecoration(color: PdfColors.orange100),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Grand Total:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                            pw.Text("INR ${booking.grandTotalPrice.toStringAsFixed(2)}", 
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blue800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.Spacer(),
                // 5. FOOTER
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text("Thank you for choosing Chayan Karo!", 
                        style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                      pw.SizedBox(height: 5),
                      pw.Text("This is a computer-generated document. No signature required.",
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${booking.bookingRef}',
    );
  }

  // PDF Row Helper
  pw.Widget _pdfPriceRow(String label, String value, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(width: 20),
          pw.SizedBox(
            width: 90,
            child: pw.Text(value, textAlign: pw.TextAlign.right, 
              style: pw.TextStyle(fontSize: 10, color: color ?? PdfColors.black)),
          ),
        ],
      ),
    );
  }
  // Helper: Status Color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'canceled': 
      case 'cancelled': return const Color(0xFFEF4444); // Red
      case 'completed': return const Color(0xFF10B981); // Green
      case 'ongoing': 
      case 'progress': return const Color(0xFF2563EB); // Blue
      default: return const Color(0xFFEF7822); // Orange (Pending)
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
          final tempDate = DateTime(2022, 1, 1, int.parse(timeParts[0]), int.parse(timeParts[1]));
          finalTime = DateFormat('hh:mm a').format(tempDate);
      } catch (e) { /* use raw timeStr */ }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Booking Details", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text("Booking # ${booking.bookingRef}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEF7822))),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(booking.status, style: TextStyle(color: _getStatusColor(booking.status), fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text("Booking Placed : ${_formatDateTime(booking.creationTime)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
               ElevatedButton.icon(
                  onPressed: () => _printInvoice(booking), // Trigger PDF generation
                  icon: const Icon(Icons.description, size: 18),
                  label: const Text("Invoice"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
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
                label: const Text("Back to List")
              ),
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
          border: isActive ? const Border(bottom: BorderSide(color: Color(0xFFEF7822), width: 2)) : null,
        ),
        child: Text(text, style: TextStyle(
          fontWeight: FontWeight.bold, 
          color: isActive ? const Color(0xFFEF7822) : Colors.grey,
          fontSize: 16
        )),
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
    if (s.contains('accept') || s.contains('progress') || s.contains('ongoing')) step = 2;
    if (s.contains('complet')) step = 3;
    bool isCanceled = s.contains('cancel');

    return _buildCard(
      title: "Booking Status",
      child: Column(
        children: [
          _buildTimelineItem(
            title: "Booking Placed",
            subtitle: "By ${booking.customerName}\n${_formatDateTime(booking.creationTime)}",
            isActive: true,
            isLast: false,
          ),
          _buildTimelineItem(
            title: isCanceled ? "Canceled" : "InProgress / Ongoing",
            subtitle: isCanceled 
                ? (booking.cancelReason.isNotEmpty ? "Reason: ${booking.cancelReason}" : "Booking was canceled") 
                : "Provider Assigned",
            isActive: isCanceled || step >= 2,
            isLast: false,
            overrideColor: isCanceled ? Colors.red : null,
            overrideIcon: isCanceled ? Icons.close : null,
          ),
          _buildTimelineItem(
            title: "Completed",
            subtitle: "Service Done",
            isActive: !isCanceled && step >= 3,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title, required String subtitle, required bool isActive, required bool isLast,
    Color? overrideColor, IconData? overrideIcon
  }) {
    final color = overrideColor ?? (isActive ? const Color(0xFFEF7822) : Colors.grey[200]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: isActive ? Icon(overrideIcon ?? Icons.check, size: 16, color: Colors.white) : null,
            ),
            if (!isLast)
              Container(
                width: 2, height: 50,
                color: isActive ? (overrideColor ?? const Color(0xFFEF7822)).withOpacity(0.5) : Colors.grey[200],
              )
          ],
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isActive ? Colors.black : Colors.grey)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
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
                  const Text("Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(booking.paymentMode, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  // Updated to show Grand Total (without Platform Fee)
                  Text("Total Payable: ₹${booking.grandTotalPrice.toStringAsFixed(2)}", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2563EB))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Text("Status: ", style: TextStyle(color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: booking.paymentStatus.toLowerCase() == 'paid' ? Colors.green[50] : Colors.red[50], 
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: Text(
                          booking.paymentStatus, 
                          style: TextStyle(
                            color: booking.paymentStatus.toLowerCase() == 'paid' ? Colors.green : Colors.red, 
                            fontSize: 12, fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("OTP: ${booking.bookingPin}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text("Schedule: ${_formatSchedule(booking.bookingDate, booking.bookingTime)}", style: const TextStyle(fontWeight: FontWeight.bold)),
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
                 const Padding(padding: EdgeInsets.all(8.0), child: Text("No services listed")),
              
              ...booking.services.map((s) {
                String qty = '1';
                if (booking.services.length == 1 && s.serviceName == "Jet Based AC service") {
                  if (s.serviceDuration > 0 && booking.totalDuration > 0) {
                    qty = (booking.totalDuration ~/ s.serviceDuration).toString();
                  }
                }
                return _buildSummaryRow(
                  s.serviceName, 
                  "Original Price", 
                  "₹${s.price.toStringAsFixed(2)}", 
                  qty, 
                  "₹${s.price.toStringAsFixed(2)}"
                );
              }),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Breakdown Section
_buildTotalRow("Service Total", "₹${booking.originalPrice.toStringAsFixed(2)}"),

             // 1. Service Discount (NEW)
if (booking.serviceDiscount > 0)
  _buildTotalRow(
    "Service Discount",
    "- ₹${booking.serviceDiscount.toStringAsFixed(2)}",
    color: Colors.green,
  ),

// 2. Coupon Discount (UI ONLY)
if (booking.couponDiscountValue > 0)
  _buildTotalRow(
    "Coupon Discount ${booking.coupon?.couponCode != null ? '(${booking.coupon!.couponCode})' : ''}",
    "- ₹${booking.couponDiscountValue.toStringAsFixed(2)}",
    color: Colors.green,
  ),
              
              _buildTotalRow("GST (${booking.gstPercentage}%)", "+ ₹${booking.gstAmount.toStringAsFixed(2)}"),
              
              // Platform Fee shown but noted as (Excluded from Total)
              _buildTotalRow(
                "Platform Fee", 
                "₹${booking.platformFee.toStringAsFixed(2)}", 
                color: Colors.grey,
                isNote: true // Added a flag for small "Excluded" text if you want
              ),
              
              const SizedBox(height: 8),
              const Divider(thickness: 1.2),
              const SizedBox(height: 8),

              // Final Grand Total (Total - Coupon + GST)
              _buildTotalRow(
                "Grand Total", 
                "₹${booking.grandTotalPrice.toStringAsFixed(2)}", 
                isBold: true, 
                color: const Color(0xFF2563EB)
              ),
              
              const SizedBox(height: 10),
              const Text(
                "*Platform fee is not included in the grand total.",
                style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ],
    );
  }

  // Modified helper to handle the "Note" style
  Widget _buildTotalRow(String label, String value, {bool isBold = false, Color? color, bool isNote = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 13)),
              if (isNote) 
                const Text("(Not included in total)", style: TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 40),
          SizedBox(
            width: 120, 
            child: Text(value, textAlign: TextAlign.end, 
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color, fontSize: isBold ? 16 : 13)),
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
                  const Text("Payment Status", style: TextStyle(fontWeight: FontWeight.w500)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                child: Text(booking.status, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              
              // Date Field
              TextField(
                enabled: false,
                decoration: InputDecoration(
                  hintText: _formatSchedule(booking.bookingDate, booking.bookingTime),
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
                decoration: BoxDecoration(color: const Color(0xFFFFEAD1), borderRadius: BorderRadius.circular(8)),
                child: const Text("Provider has to go to the Customer Location to provide the service", 
                  style: TextStyle(color: Color(0xFFD97706), fontSize: 13, height: 1.4)),
              ),
              const SizedBox(height: 15),
              const Text("Address:", style: TextStyle(fontWeight: FontWeight.bold)),
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
            ? const Text("No Provider Assigned", style: TextStyle(color: Colors.red))
            : Row(
                children: [
                  CircleAvatar(
                    radius: 24, 
                    backgroundColor: Colors.orange[100], 
                    child: Text(booking.provider!.firstName.isNotEmpty ? booking.provider!.firstName[0] : "P"),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${booking.provider!.firstName} ${booking.provider!.lastName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2563EB))),
                      const SizedBox(height: 4),
                      Text(booking.provider!.mobile, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  )
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
                child: Text(booking.customerName.isNotEmpty ? booking.customerName[0] : "C"),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2563EB))),
                  const SizedBox(height: 4),
                  Text(booking.customerPhone, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildCard({String? title, IconData? titleIcon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (titleIcon != null) ...[Icon(titleIcon, size: 18), const SizedBox(width: 8)],
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          Expanded(flex: 3, child: Text("SERVICE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
          Expanded(flex: 2, child: Text("PRICE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
          Expanded(flex: 1, child: Text("QTY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
          Expanded(flex: 2, child: Text("TOTAL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String name, String sub, String price, String qty, String total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ])),
          Expanded(flex: 2, child: Text(price)),
          Expanded(flex: 1, child: Text(qty)),
          Expanded(flex: 2, child: Text(total, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold))),
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
}