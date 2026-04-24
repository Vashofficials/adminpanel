import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../services/audio_service.dart';

// --- IMPORTS ---
import '../models/booking_models.dart';
import '../repositories/booking_repository.dart';

class AllTransactionReportScreen extends StatefulWidget {
  // Navigation Callback
  final Function(BookingModel) onViewDetails;

  const AllTransactionReportScreen({super.key, required this.onViewDetails});

  @override
  State<AllTransactionReportScreen> createState() =>
      _AllTransactionReportScreenState();
}

class _AllTransactionReportScreenState
    extends State<AllTransactionReportScreen> {
  // 1. STATE VARIABLES
  final BookingRepository _repo = BookingRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Pagination
  int _currentPage = 0;
  int _pageSize = 100;
  int _totalPages = 1;
  int _totalElements = 0;

  DateTime? _selectedScheduleDate;
  String? _selectedCategory; // null = "All"
  String? _selectedStatus;   // null = "All Statuses"

  // New-booking alert detection
  Set<String> _knownBookingIds = {};
  Timer? _pollingTimer;

  // Dynamically build unique category list from loaded bookings
  List<String> get _availableCategories {
    final categories = <String>{};
    for (final b in _bookings) {
      for (final svc in b.services) {
        if (svc.categoryName.isNotEmpty) categories.add(svc.categoryName);
      }
    }
    final sorted = categories.toList()..sort();
    return sorted;
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    // Poll every 30 seconds to detect new bookings
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  // 2. API FETCH — Shows ALL transactions (no payment mode filter)
  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response =
          await _repo.fetchBookings(page: _currentPage, size: _pageSize);

      if (!mounted) return;

      final allBookings = response.content;

      // --- New booking alert detection ---
      if (_knownBookingIds.isNotEmpty) {
        final newBookings = allBookings
            .where((b) => !_knownBookingIds.contains(b.bookingRef))
            .toList();
        if (newBookings.isNotEmpty) {
          AudioService().playBookingSound();
          _showNewBookingAlert(newBookings.first);
        }
      }
      _knownBookingIds = allBookings.map((b) => b.bookingRef).toSet();

      setState(() {
        _bookings = allBookings; // All transactions, no filter
        _totalPages = response.totalPages;
        _totalElements = response.totalElements;
        _isLoading = false;
      });

      if (_searchController.text.isNotEmpty) {
        _runFilter();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Could not load data.";
      });
    }
  }

  // 2b. New booking alert popup
  void _showNewBookingAlert(BookingModel booking) {
    if (!mounted) return;
    final svcName = booking.services.isNotEmpty
        ? booking.services.first.serviceName
        : 'N/A';
    final location = booking.address?.city ?? 'N/A';
    String schedDate = '-';
    if (booking.bookingDate.isNotEmpty) {
      try {
        final dt = DateTime.parse(booking.bookingDate).toLocal();
        schedDate = DateFormat('dd MMM yyyy').format(dt);
      } catch (_) {}
    }
    final schedTime = booking.bookingTime.isNotEmpty ? booking.bookingTime : '';
    final amount = '₹${booking.grandTotalPrice.toStringAsFixed(2)}';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 12), () {
          if (ctx.mounted) Navigator.of(ctx, rootNavigator: true).maybePop();
        });
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications_active_rounded,
                        color: Color(0xFFEF7822), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('New Booking Received 🚀',
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A))),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ]),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                _alertRow(Icons.tag, 'Booking ID', booking.bookingRef),
                _alertRow(Icons.person_outline, 'Customer', booking.customerName),
                _alertRow(Icons.design_services_outlined, 'Service', svcName),
                _alertRow(Icons.location_on_outlined, 'Location', location),
                _alertRow(Icons.schedule, 'Schedule', '$schedDate  $schedTime'.trim()),
                _alertRow(Icons.currency_rupee, 'Amount', amount),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Dismiss',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx, rootNavigator: true).pop();
                        widget.onViewDetails(booking);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF7822),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('View Booking',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _alertRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Text('$label: ',
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF64748B))),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A)),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // 3. SEARCH LOGIC
  void _runFilter() {
    setState(() {});
  }

  List<BookingModel> get _filteredBookings {
    var list = _bookings;

    // 1. FULL-TEXT Search Filter — searches ALL visible columns
    final keyword = _searchController.text.toLowerCase().trim();
    if (keyword.isNotEmpty) {
      list = list.where((item) {
        // Booking ID
        if (item.bookingRef.toLowerCase().contains(keyword)) return true;
        // Customer name & phone
        if (item.customerName.toLowerCase().contains(keyword)) return true;
        if (item.customerPhone.toLowerCase().contains(keyword)) return true;
        // Provider name & mobile
        if (item.provider != null) {
          final providerName =
              "${item.provider!.firstName} ${item.provider!.lastName}".toLowerCase();
          if (providerName.contains(keyword)) return true;
          if (item.provider!.mobile.toLowerCase().contains(keyword)) return true;
        }
        // Service name & category
        for (final svc in item.services) {
          if (svc.serviceName.toLowerCase().contains(keyword)) return true;
          if (svc.categoryName.toLowerCase().contains(keyword)) return true;
        }
        // Location (city + pincode)
        if ((item.address?.city ?? '').toLowerCase().contains(keyword)) return true;
        if ((item.address?.postCode ?? '').toLowerCase().contains(keyword)) return true;
        // Payment mode, payment status, booking status
        if (item.paymentMode.toLowerCase().contains(keyword)) return true;
        if (item.paymentStatus.toLowerCase().contains(keyword)) return true;
        if (item.status.toLowerCase().contains(keyword)) return true;
        // Schedule time (bookingTime e.g. "16:30")
        if (item.bookingTime.toLowerCase().contains(keyword)) return true;
        return false;
      }).toList();
    }

    // 2. Category Filter — match any service's categoryName
    if (_selectedCategory != null) {
      list = list.where((item) {
        return item.services.any(
          (svc) => svc.categoryName == _selectedCategory,
        );
      }).toList();
    }

    // 3. Status Filter
    if (_selectedStatus != null) {
      final apiStatus = _statusApiMap[_selectedStatus] ?? '';
      list = list.where((item) => item.status.toUpperCase() == apiStatus).toList();
    }

    // 4. Schedule Date Filter — compare bookingDate in LOCAL timezone (IST)
    if (_selectedScheduleDate != null) {
      list = list.where((item) {
        if (item.bookingDate.isEmpty) return false;
        try {
          // .toLocal() ensures IST (+05:30) dates are not shifted to the previous day
          final dt = DateTime.parse(item.bookingDate).toLocal();
          return dt.year == _selectedScheduleDate!.year &&
                 dt.month == _selectedScheduleDate!.month &&
                 dt.day == _selectedScheduleDate!.day;
        } catch (_) {
          return false;
        }
      }).toList();
    }

    return list;
  }

  // Status options (individual)
  static const List<String> _statusOptions = [
    'Pending',
    'Completed',
    'In Progress',
    'Cancelled',
  ];

  // Map label → API value
  static const Map<String, String> _statusApiMap = {
    'Pending':     'PENDING',
    'Completed':   'COMPLETED',
    'In Progress': 'ONGOING',
    'Cancelled':   'CANCELED',
  };

  // 4. PAGINATION LOGIC
  void _onPageChanged(int newPage) {
    if (newPage >= 0 && newPage < _totalPages) {
      setState(() {
        _currentPage = newPage;
      });
      _fetchData();
    }
  }

  // 5. DOWNLOAD AS EXCEL — matches all visible UI columns
  void _handleDownload() {
    if (_filteredBookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No records found to download")),
      );
      return;
    }

    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['All Transaction Report'];

      // ── Orange header style ──────────────────────────────────────────────
      xl.CellStyle headerStyle = xl.CellStyle(
        bold: true,
        fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: xl.ExcelColor.fromHexString('#EF7822'),
        horizontalAlign: xl.HorizontalAlign.Center,
        verticalAlign: xl.VerticalAlign.Center,
        textWrapping: xl.TextWrapping.WrapText,
      );

      // ── Column headers (same order as UI table) ──────────────────────────
      const headers = [
        'SL',
        'Booking ID',
        'Category',
        'Service Name',
        'Qty',
        'Duration (mins)',
        'Customer Name',
        'Customer Phone',
        'Provider Name',
        'Provider Mobile',
        'City',
        'Pincode',
        'Service Discount (₹)',
        'Coupon Discount (₹)',
        'Tax / GST (₹)',
        'Total Amount (₹)',
        'Payment Mode',
        'Payment Status',
        'Schedule Date',
        'Schedule Time',
        'Booking Date',
        'Booking Time',
        'Status',
      ];

      // Write header row
      for (int col = 0; col < headers.length; col++) {
        final cell = sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = xl.TextCellValue(headers[col]);
        cell.cellStyle = headerStyle;
      }

      // ── Data rows ────────────────────────────────────────────────────────
      for (int i = 0; i < _filteredBookings.length; i++) {
        final b = _filteredBookings[i];
        final row = i + 1;

        // Service details — first service or blank
        final svc = b.services.isNotEmpty ? b.services.first : null;
        final categoryName = svc?.categoryName ?? '';
        final serviceName  = svc?.serviceName ?? '';
        final qty          = svc?.quantity ?? 0;
        final duration     = svc?.serviceDuration ?? 0;

        // Provider
        final providerName = b.provider != null
            ? '${b.provider!.firstName} ${b.provider!.lastName}'.trim()
            : 'Not Assigned';
        final providerMobile = b.provider?.mobile ?? '-';

        // Schedule date/time
        final schedDate = _formatScheduleDate(b.bookingDate);
        final schedTime = b.bookingTime;

        // Booking date/time
        final bd = _formatBookingDateTime(b.creationTime);

        // Discounts: sum across all services
        final serviceDiscount = b.services.fold<double>(
            0, (sum, s) => sum + s.discountPrice);
        final couponDiscount = b.couponDiscountValue;
        final tax            = b.gstAmount;
        final totalAmount    = b.grandTotalPrice;

        final rowData = [
          xl.IntCellValue(i + 1),                         // SL
          xl.TextCellValue(b.bookingRef),                 // Booking ID
          xl.TextCellValue(categoryName),                 // Category
          xl.TextCellValue(serviceName),                  // Service Name
          xl.IntCellValue(qty),                           // Qty
          xl.IntCellValue(duration),                     // Duration
          xl.TextCellValue(b.customerName),              // Customer Name
          xl.TextCellValue(b.customerPhone),             // Customer Phone
          xl.TextCellValue(providerName),                // Provider Name
          xl.TextCellValue(providerMobile),              // Provider Mobile
          xl.TextCellValue(b.address?.city ?? ''),       // City
          xl.TextCellValue(b.address?.postCode ?? ''),   // Pincode
          xl.DoubleCellValue(serviceDiscount),           // Service Discount
          xl.DoubleCellValue(couponDiscount),            // Coupon Discount
          xl.DoubleCellValue(tax),                       // Tax / GST
          xl.DoubleCellValue(totalAmount),               // Total Amount
          xl.TextCellValue(b.paymentMode),               // Payment Mode
          xl.TextCellValue(b.paymentStatus),             // Payment Status
          xl.TextCellValue(schedDate),                   // Schedule Date
          xl.TextCellValue(schedTime),                   // Schedule Time
          xl.TextCellValue(bd.date),                    // Booking Date
          xl.TextCellValue(bd.time),                    // Booking Time
          xl.TextCellValue(b.status),                   // Status
        ];

        for (int col = 0; col < rowData.length; col++) {
          final cell = sheet.cell(
              xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
          cell.value = rowData[col];
          // Alternating row background for readability
          if (i % 2 == 1) {
            cell.cellStyle =
                xl.CellStyle(backgroundColorHex: xl.ExcelColor.fromHexString('#FFF7F0'));
          }
        }
      }

      // Auto column widths (approximate)
      sheet.setColumnWidth(0, 6);   // SL
      sheet.setColumnWidth(1, 36);  // Booking ID
      sheet.setColumnWidth(2, 18);  // Category
      sheet.setColumnWidth(3, 28);  // Service Name
      sheet.setColumnWidth(4, 6);   // Qty
      sheet.setColumnWidth(5, 14);  // Duration
      sheet.setColumnWidth(6, 22);  // Customer Name
      sheet.setColumnWidth(7, 16);  // Customer Phone
      sheet.setColumnWidth(8, 22);  // Provider Name
      sheet.setColumnWidth(9, 16);  // Provider Mobile
      sheet.setColumnWidth(10, 14); // City
      sheet.setColumnWidth(11, 10); // Pincode
      sheet.setColumnWidth(12, 20); // Svc Discount
      sheet.setColumnWidth(13, 18); // Coupon Discount
      sheet.setColumnWidth(14, 14); // Tax
      sheet.setColumnWidth(15, 16); // Total Amount
      sheet.setColumnWidth(16, 14); // Payment Mode
      sheet.setColumnWidth(17, 14); // Payment Status
      sheet.setColumnWidth(18, 14); // Schedule Date
      sheet.setColumnWidth(19, 12); // Schedule Time
      sheet.setColumnWidth(20, 14); // Booking Date
      sheet.setColumnWidth(21, 12); // Booking Time
      sheet.setColumnWidth(22, 12); // Status

      // Delete default "Sheet1"
      excel.delete('Sheet1');

      // ── Trigger browser download ─────────────────────────────────────────
      final Uint8List fileBytes =
          Uint8List.fromList(excel.save()!);
      final blob = html.Blob(
          [fileBytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final fileName =
          'all_transactions_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                    "Excel downloaded: ${_filteredBookings.length} records  ($fileName)"),
              ],
            ),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Download failed: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // 6a. HELPER: Format Schedule Date (bookingDate ISO → "dd MMM yyyy")
  // Combines bookingDate (date part only) + bookingTime (as-is from API)
  String _formatScheduleDate(String bookingDate) {
    if (bookingDate.isEmpty) return "-";
    try {
      final dt = DateTime.parse(bookingDate).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      // Fallback: strip time from raw string if parse fails
      return bookingDate.split('T')[0];
    }
  }

  // 6b. HELPER: Format Booking Date parts (creationTime ISO → date + 12h time)
  // Returns a record with {date: "dd MMM yyyy", time: "hh:mm AM/PM"}
  ({String date, String time}) _formatBookingDateTime(String creationTime) {
    if (creationTime.isEmpty) return (date: "-", time: "");
    try {
      final dt = DateTime.parse(creationTime).toLocal();
      return (
        date: DateFormat('dd MMM yyyy').format(dt),
        time: DateFormat('hh:mm a').format(dt).toUpperCase(),
      );
    } catch (_) {
      return (date: "-", time: "");
    }
  }

  // 7. HELPER: Payment mode badge color
  Color _paymentBadgeBg(String mode) {
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

  Color _paymentBadgeText(String mode) {
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

  @override
  Widget build(BuildContext context) {
    final displayed = _filteredBookings;

    return Column(
      children: [
        // 1. PAGE HEADER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "All Transaction Report",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                  // Stop Sound Button (Reactive)
                  Obx(() => AudioService().isPlaying.value
                      ? Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ElevatedButton.icon(
                            onPressed: () => AudioService().stopSound(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            icon: const Icon(Icons.volume_off_rounded, size: 14, color: Colors.white),
                            label: Text('Stop Sound',
                                style: GoogleFonts.inter(
                                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        )
                      : const SizedBox.shrink()),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text("Total Records: ",
                            style: GoogleFonts.inter(
                                fontSize: 12, color: const Color(0xFF64748B))),
                        Text("$_totalElements",
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 2. INFO BANNER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              border: Border.all(color: const Color(0xFFBFDBFE)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 20, color: Color(0xFF1D4ED8)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "This report shows all transactions regardless of payment mode — including online, offline, cash, and UPI payments.",
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF1D4ED8),
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 3. WHITE CARD CONTAINER
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: Column(
              children: [
                // --- A. TOOLBAR ---
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Search Bar
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 44,
                          constraints: const BoxConstraints(maxWidth: 300),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => _runFilter(),
                            decoration: InputDecoration(
                              hintText: 'Search ID, Name, Number...',
                              hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.search,
                                  color: Color(0xFF94A3B8), size: 20),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.only(top: 8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Filter by Date
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedScheduleDate ?? DateTime.now(),
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _selectedScheduleDate = picked);
                            _runFilter();
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF64748B)),
                              const SizedBox(width: 8),
                              Text(
                                _selectedScheduleDate == null 
                                  ? 'Filter by Date' 
                                  : DateFormat('dd MMM yyyy').format(_selectedScheduleDate!),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: _selectedScheduleDate == null ? FontWeight.w400 : FontWeight.w600,
                                  color: _selectedScheduleDate == null ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                                ),
                              ),
                              if (_selectedScheduleDate != null) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    setState(() => _selectedScheduleDate = null);
                                    _runFilter();
                                  },
                                  child: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                                )
                              ] else ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                              ]
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Today Button
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedScheduleDate = DateTime.now());
                          _runFilter();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          backgroundColor: const Color(0xFFEFF6FF),
                        ),
                        child: Text("Today", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),

                      // Status Filter Dropdown
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedStatus,
                            hint: Text('All Statuses',
                                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8))),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Statuses',
                                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF334155)))),
                              ..._statusOptions.map((label) => DropdownMenuItem<String?>(
                                value: label,
                                child: Text(label,
                                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF334155))),
                              )),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedStatus = val;
                                _currentPage = 0;
                              });
                            },
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Show Rows
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _pageSize,
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                            items: [10, 30, 50, 100].map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('Show $value',
                                    style: GoogleFonts.inter(
                                        fontSize: 14, color: const Color(0xFF334155))),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null && newValue != _pageSize) {
                                setState(() {
                                  _pageSize = newValue;
                                  _currentPage = 0; // Reset to first page
                                });
                                _fetchData();
                              }
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),

                      // Refresh Button
                      IconButton(
                        onPressed: _fetchData,
                        icon: const Icon(Icons.refresh,
                            color: Color(0xFF64748B)),
                        tooltip: "Refresh Data",
                      ),

                      const SizedBox(width: 12),

                      // Download Button
                      ElevatedButton.icon(
                        onPressed: _handleDownload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF7822),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.download,
                            size: 18, color: Colors.white),
                        label: Text("Download",
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ),

                // --- A2. CATEGORY FILTER CHIP ROW ---
                if (_availableCategories.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                        left: 20, right: 20, bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_list_rounded,
                            size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Text(
                          "Filter by Category:",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                // "All" chip
                                _CategoryChip(
                                  label: "All",
                                  isSelected: _selectedCategory == null,
                                  onTap: () {
                                    setState(() => _selectedCategory = null);
                                    _runFilter();
                                  },
                                ),
                                const SizedBox(width: 8),
                                // Dynamic category chips
                                ..._availableCategories.map((cat) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _CategoryChip(
                                      label: cat,
                                      isSelected: _selectedCategory == cat,
                                      onTap: () {
                                        setState(() => _selectedCategory =
                                            _selectedCategory == cat
                                                ? null
                                                : cat);
                                        _runFilter();
                                      },
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // --- B. CONTENT AREA ---
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFEF7822)))
                      : displayed.isEmpty
                          ? _buildEmptyState()
                          : ScrollConfiguration(
                              behavior:
                                  ScrollConfiguration.of(context).copyWith(
                                dragDevices: {
                                  PointerDeviceKind.touch,
                                  PointerDeviceKind.mouse
                                },
                              ),
                              child: Scrollbar(
                                controller: _verticalScrollController,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  controller: _verticalScrollController,
                                  scrollDirection: Axis.vertical,
                                  child: Scrollbar(
                                    controller:
                                        _horizontalScrollController,
                                    thumbVisibility: true,
                                    notificationPredicate: (notif) =>
                                        notif.depth == 1,
                                    child: SingleChildScrollView(
                                      controller:
                                          _horizontalScrollController,
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                            minWidth:
                                                MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                    100),
                                        child: DataTable(
                                          headingRowColor:
                                              MaterialStateProperty.all(
                                                  Colors.transparent),
                                          dataRowMinHeight: 70,
                                          dataRowMaxHeight: 85,
                                          horizontalMargin: 20,
                                          columnSpacing: 24,
                                          dividerThickness: 1,
                                          columns: const [
                                            DataColumn(
                                                label: _Header("SL")),
                                            DataColumn(
                                                label:
                                                    _Header("BOOKING ID")),
                                            DataColumn(
                                                label: _Header(
                                                    "SERVICE DETAILS")),
                                            DataColumn(
                                                label: _Header(
                                                    "WHERE SERVICE\nWILL BE PROVIDED")),
                                            DataColumn(
                                                label: _Header(
                                                    "CUSTOMER INFO")),
                                            DataColumn(
                                                label: _Header(
                                                    "PROVIDER INFO")),
                                            DataColumn(
                                                label: _Header(
                                                    "SERVICE DISCOUNT")),
                                            DataColumn(
                                                label: _Header(
                                                    "COUPON DISCOUNT")),
                                            DataColumn(
                                                label: _Header("TAX (GST)")),
                                            DataColumn(
                                                label: _Header(
                                                    "TOTAL AMOUNT")),
                                            DataColumn(
                                                label: _Header(
                                                    "PAYMENT MODE")),
                                            DataColumn(
                                                label: _Header(
                                                    "PAYMENT STATUS")),
                                            DataColumn(
                                                label: _Header(
                                                    "SCHEDULE DATE")),
                                            DataColumn(
                                                label: _Header(
                                                    "BOOKING DATE")),
                                            DataColumn(
                                                label: _Header("STATUS")),
                                            DataColumn(
                                                label: _Header("ACTION")),
                                          ],
                                          rows: List.generate(
                                              displayed.length, (index) {
                                            final data = displayed[index];
                                            final serialNum =
                                                (_currentPage * _pageSize) +
                                                    index +
                                                    1;

                                            return DataRow(
                                              cells: [
                                                // SL
                                                DataCell(Text("$serialNum",
                                                    style: _cellStyle())),

                                                // Booking ID
                                                DataCell(Text(
                                                    data.bookingRef,
                                                    style: _cellStyle())),

                                                // Service Details
                                                DataCell(data.services.isEmpty
                                                  ? Text("—", style: _subStyle())
                                                  : Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          data.services.first.serviceName,
                                                          style: _cellStyle(bold: true),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 2,
                                                        ),
                                                        Text(
                                                          "Qty: ${data.services.first.quantity}  •  ${data.services.first.serviceDuration} mins",
                                                          style: _subStyle(),
                                                        ),
                                                      ],
                                                    )),

                                                // Location
                                                DataCell(Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Text(
                                                      data.address?.city ??
                                                          "Unknown City",
                                                      style: _cellStyle(
                                                          bold: true),
                                                    ),
                                                    Text(
                                                      data.address
                                                              ?.postCode ??
                                                          "No Pincode",
                                                      style: _subStyle(),
                                                    ),
                                                  ],
                                                )),

                                                // Customer Info
                                                DataCell(Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Text(data.customerName,
                                                        style: _cellStyle(
                                                            bold: true)),
                                                    Text(
                                                        data.customerPhone,
                                                        style:
                                                            _subStyle()),
                                                  ],
                                                )),

                                                // Provider Info
                                                DataCell(data.provider == null
                                                  ? Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF1F5F9),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text("Not Assigned",
                                                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                                                    )
                                                  : Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          "${data.provider!.firstName} ${data.provider!.lastName}".trim(),
                                                          style: _cellStyle(bold: true),
                                                        ),
                                                        Text(
                                                          data.provider!.mobile,
                                                          style: _subStyle(),
                                                        ),
                                                      ],
                                                    )),

                                                // Service Discount
                                                DataCell(Text(
  "-₹${data.serviceDiscount.toStringAsFixed(2)}",
                                                    style: _cellStyle())),

                                                // Coupon Discount
                                                DataCell(Text(
  data.couponDiscountValue > 0
      ? "-₹${data.couponDiscountValue.toStringAsFixed(2)}"
      : "—",
                                                    style: _cellStyle())),

                                                // Tax (GST)
                                                DataCell(Text(
                                                    "₹${data.totalTaxAmount.toStringAsFixed(2)}",
                                                    style: _cellStyle())),

                                                // Amount
                                                DataCell(Text(
                                                    "₹${data.grandTotalPrice.toStringAsFixed(2)}",
                                                    style: _cellStyle(
                                                        bold: true))),

                                                // Payment Mode Badge (NEW column)
                                                DataCell(Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _paymentBadgeBg(
                                                        data.paymentMode),
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(20),
                                                  ),
                                                  child: Text(
                                                      data.paymentMode
                                                          .toUpperCase(),
                                                      style:
                                                          GoogleFonts.inter(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  _paymentBadgeText(
                                                                      data.paymentMode))),
                                                )),

                                                // Payment Status Badge
                                                DataCell(Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: data.paymentStatus.toLowerCase() == 'paid'
                                                        ? const Color(0xFFDCFCE7)
                                                        : const Color(0xFFFFE2E5),
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(20),
                                                  ),
                                                  child: Text(
                                                      data.paymentStatus,
                                                      style:
                                                          GoogleFonts.inter(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: data.paymentStatus.toLowerCase() == 'paid'
                                                                  ? const Color(0xFF16A34A)
                                                                  : const Color(0xFFEF4444))),
                                                )),

                                                 // Schedule Date
                                                 // -> bookingDate (date only) + bookingTime (as-is)
                                                 DataCell(Column(
                                                   mainAxisAlignment:
                                                       MainAxisAlignment
                                                           .center,
                                                   crossAxisAlignment:
                                                       CrossAxisAlignment
                                                           .start,
                                                   children: [
                                                     Text(
                                                         _formatScheduleDate(
                                                             data.bookingDate),
                                                         style:
                                                             _cellStyle()),
                                                     if (data.bookingTime.isNotEmpty)
                                                       Text(
                                                           data.bookingTime,
                                                           style:
                                                               _subStyle()),
                                                   ],
                                                 )),

                                                 // Booking Date (When order was placed)
                                                 // -> creationTime date + 12h time with AM/PM
                                                 DataCell(Builder(
                                                   builder: (ctx) {
                                                     final bdt =
                                                         _formatBookingDateTime(
                                                             data.creationTime);
                                                     return Column(
                                                       mainAxisAlignment:
                                                           MainAxisAlignment
                                                               .center,
                                                       crossAxisAlignment:
                                                           CrossAxisAlignment
                                                               .start,
                                                       children: [
                                                         Text(bdt.date,
                                                             style:
                                                                 _cellStyle()),
                                                         if (bdt.time.isNotEmpty)
                                                           Text(bdt.time,
                                                               style:
                                                                   _subStyle()),
                                                       ],
                                                     );
                                                   },
                                                 )),

                                                // Status Badge
                                                DataCell(Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                        0xFFDBEAFE),
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(4),
                                                  ),
                                                  child: Text(data.status,
                                                      style:
                                                          GoogleFonts.inter(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: const Color(
                                                                  0xFF2563EB))),
                                                )),

                                                // Action
                                                DataCell(_ActionButton(
                                                  icon: Icons
                                                      .visibility_outlined,
                                                  onTap: () =>
                                                      widget.onViewDetails(
                                                          data),
                                                )),
                                              ],
                                            );
                                          }),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                ),

                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // --- C. PAGINATION FOOTER ---
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: _currentPage > 0
                            ? () => _onPageChanged(_currentPage - 1)
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: const Text('Previous'),
                      ),

                      Expanded(
                        child: Container(
                          height: 32,
                          alignment: Alignment.center,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            itemCount: _totalPages,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final isSelected = index == _currentPage;
                              return InkWell(
                                onTap: () => _onPageChanged(index),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  width: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFEF7822)
                                        : Colors.transparent,
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: const Color(
                                                0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    "${index + 1}",
                                    style: GoogleFonts.inter(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      OutlinedButton(
                        onPressed: _currentPage < _totalPages - 1
                            ? () => _onPageChanged(_currentPage + 1)
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          Text(
            "No Transactions Found",
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 4),
          Text(
            "Try adjusting your filters or search criteria.",
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  static TextStyle _cellStyle({bool bold = false, double size = 13}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
      color: const Color(0xFF334155),
    );
  }

  static TextStyle _subStyle() {
    return GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8));
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8)));
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(4)),
        child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CATEGORY CHIP WIDGET
// ---------------------------------------------------------------------------
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEF7822)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFEF7822)
                : const Color(0xFFCBD5E1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFEF7822).withOpacity(0.20),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
