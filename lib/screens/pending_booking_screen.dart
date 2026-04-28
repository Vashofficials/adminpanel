import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui'; // Required for PointerDeviceKind
import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

// --- IMPORTS ---
import '../models/booking_models.dart';
import '../repositories/booking_repository.dart';

class PendingBookingScreen extends StatefulWidget {
  // Navigation Callback
  final Function(BookingModel) onViewDetails;

  const PendingBookingScreen({super.key, required this.onViewDetails});

  @override
  State<PendingBookingScreen> createState() => _PendingBookingScreenState();
}

class _PendingBookingScreenState extends State<PendingBookingScreen> {
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

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory; // null = "All"
  String? _selectedStatus;   // null = "All statuses"

  // Timer for auto-refresh
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
    // Poll every 5 minutes to auto-refresh data
    _pollingTimer = Timer.periodic(const Duration(minutes: 5), (_) {
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

  // 2. API FETCH
  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch large page to get all records for client-side filtering/sorting
      final response = await _repo.fetchBookings(page: 0, size: 500);

      if (!mounted) return;
      if (response.content != null) {
        final pendingList = response.content
            .where((b) => b.status.toUpperCase() == 'PENDING')
            .toList();

        setState(() {
          _bookings = pendingList;
          _totalElements = pendingList.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Could not load data.";
      });
    }
  }


  // 3. SEARCH LOGIC
  void _runFilter() {
    setState(() {});
  }

  List<BookingModel> get _filteredBookings {
    // 1. Payment mode (already CASH/OFFLINE — kept)
    var list = List<BookingModel>.from(_bookings);
    final keyword = _searchController.text.toLowerCase().trim();
    if (keyword.isNotEmpty) {
      list = list.where((item) {
        if (item.bookingRef.toLowerCase().contains(keyword)) return true;
        if (item.customerName.toLowerCase().contains(keyword)) return true;
        if (item.customerPhone.toLowerCase().contains(keyword)) return true;
        if (item.provider != null) {
          final pName = "${item.provider!.firstName} ${item.provider!.lastName}".toLowerCase();
          if (pName.contains(keyword)) return true;
          if (item.provider!.mobile.toLowerCase().contains(keyword)) return true;
        }
        for (final svc in item.services) {
          if (svc.serviceName.toLowerCase().contains(keyword)) return true;
          if (svc.categoryName.toLowerCase().contains(keyword)) return true;
        }
        if ((item.address?.city ?? '').toLowerCase().contains(keyword)) return true;
        if ((item.address?.postCode ?? '').toLowerCase().contains(keyword)) return true;
        if (item.paymentMode.toLowerCase().contains(keyword)) return true;
        if (item.paymentStatus.toLowerCase().contains(keyword)) return true;
        if (item.status.toLowerCase().contains(keyword)) return true;
        if (item.bookingTime.toLowerCase().contains(keyword)) return true;
        return false;
      }).toList();
    }

    // 3. Category Filter
    if (_selectedCategory != null) {
      list = list.where((item) =>
          item.services.any((svc) => svc.categoryName == _selectedCategory)).toList();
    }

    // 4. Status Filter
    if (_selectedStatus != null) {
      final apiStatus = _statusApiMap[_selectedStatus] ?? '';
      list = list.where((item) {
        final st = item.status.toUpperCase().trim();
        if (apiStatus == 'CANCELED' || apiStatus == 'CANCELLED') {
          return st == 'CANCELED' || st == 'CANCELLED';
        }
        if (apiStatus == 'COMPLETED') {
          return st == 'COMPLETED' || st == 'DELIVERED' || st == 'DONE';
        }
        if (apiStatus == 'ONGOING') {
          return st == 'ONGOING' || st == 'IN PROGRESS' || st == 'ACCEPTED' || st == 'PROCESSING';
        }
        return st == apiStatus;
      }).toList();
    }

    // 5. Schedule Date Filter (IST)
    if (_startDate != null || _endDate != null) {
      list = list.where((item) {
        if (item.bookingDate.isEmpty) return false;
        try {
          final dt = DateTime.parse(item.bookingDate).toLocal();
          final dtDate = DateTime(dt.year, dt.month, dt.day);

          if (_startDate != null) {
            final st = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
            if (dtDate.compareTo(st) < 0) return false;
          }
          if (_endDate != null) {
            final ed = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
            if (dtDate.compareTo(ed) > 0) return false;
          }
          return true;
        } catch (_) {
          return false;
        }
      }).toList();
    }

    // 6. Sort ascending by schedule date+time
    list.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.bookingDate);
        final dateB = DateTime.parse(b.bookingDate);
        final dtA = DateTime(
          dateA.year, dateA.month, dateA.day,
          int.tryParse(a.bookingTime.split(':')[0]) ?? 0,
          int.tryParse(a.bookingTime.split(':').length > 1 ? a.bookingTime.split(':')[1].split(' ')[0] : '0') ?? 0,
        );
        final dtB = DateTime(
          dateB.year, dateB.month, dateB.day,
          int.tryParse(b.bookingTime.split(':')[0]) ?? 0,
          int.tryParse(b.bookingTime.split(':').length > 1 ? b.bookingTime.split(':')[1].split(' ')[0] : '0') ?? 0,
        );
        return dtA.compareTo(dtB);
      } catch (_) {
        return 0;
      }
    });

    return list;
  }

  // Client-side paginated slice
  List<BookingModel> get _displayedBookings {
    final all = _filteredBookings;
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, all.length);
    if (start >= all.length) return [];
    return all.sublist(start, end);
  }

  int get _clientTotalPages {
    final total = _filteredBookings.length;
    if (total == 0) return 1;
    return (total / _pageSize).ceil();
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
    'Cancelled':   'CANCELLED',
  };

  // 4. PAGINATION LOGIC
  void _onPageChanged(int newPage) {
    if (newPage >= 0 && newPage < _totalPages) {
      setState(() {
        _currentPage = newPage;
      });
    }
  }

  // 5. DOWNLOAD AS EXCEL
  void _handleDownload() {
    if (_filteredBookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No records found to download")),
      );
      return;
    }

    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Pending Bookings'];

      xl.CellStyle headerStyle = xl.CellStyle(
        bold: true,
        fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: xl.ExcelColor.fromHexString('#EF7822'),
        horizontalAlign: xl.HorizontalAlign.Center,
        verticalAlign: xl.VerticalAlign.Center,
        textWrapping: xl.TextWrapping.WrapText,
      );

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

      for (int col = 0; col < headers.length; col++) {
        final cell = sheet
            .cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = xl.TextCellValue(headers[col]);
        cell.cellStyle = headerStyle;
      }

      for (int i = 0; i < _filteredBookings.length; i++) {
        final b = _filteredBookings[i];
        final row = i + 1;

        final svc = b.services.isNotEmpty ? b.services.first : null;
        final categoryName = svc?.categoryName ?? '';
        final serviceName  = svc?.serviceName ?? '';
        final qty          = svc?.quantity ?? 0;
        final duration     = svc?.serviceDuration ?? 0;

        final providerName = b.provider != null
            ? '${b.provider!.firstName} ${b.provider!.lastName}'.trim()
            : 'Not Assigned';
        final providerMobile = b.provider?.mobile ?? '-';

        final schedDate = _formatScheduleDate(b.bookingDate);
        final schedTime = b.bookingTime;

        final bd = _formatBookingDateTime(b.creationTime);

        final serviceDiscount = b.services.fold<double>(
            0, (sum, s) => sum + s.discountPrice);
        final couponDiscount = b.couponDiscountValue;
        final tax            = b.gstAmount;
        final totalAmount    = b.grandTotalPrice;

        final rowData = [
          xl.IntCellValue(i + 1),
          xl.TextCellValue(b.bookingRef),
          xl.TextCellValue(categoryName),
          xl.TextCellValue(serviceName),
          xl.IntCellValue(qty),
          xl.IntCellValue(duration),
          xl.TextCellValue(b.customerName),
          xl.TextCellValue(b.customerPhone),
          xl.TextCellValue(providerName),
          xl.TextCellValue(providerMobile),
          xl.TextCellValue(b.address?.city ?? ''),
          xl.TextCellValue(b.address?.postCode ?? ''),
          xl.DoubleCellValue(serviceDiscount),
          xl.DoubleCellValue(couponDiscount),
          xl.DoubleCellValue(tax),
          xl.DoubleCellValue(totalAmount),
          xl.TextCellValue(b.paymentMode),
          xl.TextCellValue(b.paymentStatus),
          xl.TextCellValue(schedDate),
          xl.TextCellValue(schedTime),
          xl.TextCellValue(bd.date),
          xl.TextCellValue(bd.time),
          xl.TextCellValue(b.status),
        ];

        for (int col = 0; col < rowData.length; col++) {
          final cell = sheet.cell(
              xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
          cell.value = rowData[col];
          if (i % 2 == 1) {
            cell.cellStyle =
                xl.CellStyle(backgroundColorHex: xl.ExcelColor.fromHexString('#FFF7F0'));
          }
        }
      }

      sheet.setColumnWidth(0, 6);
      sheet.setColumnWidth(1, 36);
      sheet.setColumnWidth(2, 18);
      sheet.setColumnWidth(3, 28);
      sheet.setColumnWidth(4, 6);
      sheet.setColumnWidth(5, 14);
      sheet.setColumnWidth(6, 22);
      sheet.setColumnWidth(7, 16);
      sheet.setColumnWidth(8, 22);
      sheet.setColumnWidth(9, 16);
      sheet.setColumnWidth(10, 14);
      sheet.setColumnWidth(11, 10);
      sheet.setColumnWidth(12, 20);
      sheet.setColumnWidth(13, 18);
      sheet.setColumnWidth(14, 14);
      sheet.setColumnWidth(15, 16);
      sheet.setColumnWidth(16, 14);
      sheet.setColumnWidth(17, 14);
      sheet.setColumnWidth(18, 14);
      sheet.setColumnWidth(19, 12);
      sheet.setColumnWidth(20, 14);
      sheet.setColumnWidth(21, 12);
      sheet.setColumnWidth(22, 12);

      excel.delete('Sheet1');

      final Uint8List fileBytes = Uint8List.fromList(excel.save()!);
      final blob = html.Blob(
          [fileBytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final fileName =
          'pending_bookings_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
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
                Text("Excel downloaded successfully! ($fileName)"),
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
          SnackBar(content: Text("Download failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 6. HELPERS
  String _formatScheduleDate(String bookingDate) {
    if (bookingDate.isEmpty) return "-";
    try {
      final dt = DateTime.parse(bookingDate).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return bookingDate.split('T')[0];
    }
  }

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

  Color _paymentBadgeBg(String mode) {
    switch (mode.toUpperCase()) {
      case 'CASH':
      case 'OFFLINE':
        return const Color(0xFFFFE2E5);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _paymentBadgeText(String mode) {
    switch (mode.toUpperCase()) {
      case 'CASH':
      case 'OFFLINE':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _displayedBookings;

    return Column(
      children: [
        // 1. PAGE HEADER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Pending Bookings",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text("Total Records: ",
                            style: GoogleFonts.inter(
                                fontSize: 12, color: const Color(0xFF64748B))),
                        Text("${_totalElements}",
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
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildWarningBanner(),
        ),
        const SizedBox(height: 16),

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
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => _runFilter(),
                            decoration: InputDecoration(
                              hintText: 'Search ID, Name, Number...',
                              hintStyle: GoogleFonts.inter(
                                  fontSize: 14, color: const Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.search,
                                  color: Color(0xFF94A3B8), size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.only(top: 8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Start Date Filter
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _startDate = picked);
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
                                _startDate == null ? 'Start Date' : DateFormat('dd MMM yyyy').format(_startDate!),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: _startDate == null ? FontWeight.w400 : FontWeight.w600,
                                  color: _startDate == null ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                                ),
                              ),
                              if (_startDate != null) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    setState(() => _startDate = null);
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

                      // End Date Filter
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? _startDate ?? DateTime.now(),
                            firstDate: DateTime(2023),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _endDate = picked);
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
                                _endDate == null ? 'End Date' : DateFormat('dd MMM yyyy').format(_endDate!),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: _endDate == null ? FontWeight.w400 : FontWeight.w600,
                                  color: _endDate == null ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                                ),
                              ),
                              if (_endDate != null) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    setState(() => _endDate = null);
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
                          final now = DateTime.now();
                          setState(() {
                            _startDate = now;
                            _endDate = now;
                          });
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
                            items: [100, 200, 300].map((int value) {
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
                                  _currentPage = 0;
                                });
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Refresh Button
                      IconButton(
                        onPressed: _fetchData,
                        icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
                        tooltip: "Refresh Data",
                      ),

                      const SizedBox(width: 12),

                      // Download Button
                      ElevatedButton.icon(
                        onPressed: _handleDownload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF7822),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.download, size: 18, color: Colors.white),
                        label: Text("Download",
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
                ),

                // --- A2. CATEGORY FILTER CHIP ROW ---
                if (_availableCategories.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF64748B)),
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
                                _CategoryChip(
                                  label: "All",
                                  isSelected: _selectedCategory == null,
                                  onTap: () {
                                    setState(() => _selectedCategory = null);
                                    _runFilter();
                                  },
                                ),
                                const SizedBox(width: 8),
                                ..._availableCategories.map((cat) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _CategoryChip(
                                      label: cat,
                                      isSelected: _selectedCategory == cat,
                                      onTap: () {
                                        setState(() => _selectedCategory =
                                            _selectedCategory == cat ? null : cat);
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
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF7822)))
                      : displayed.isEmpty
                          ? _buildEmptyState()
                          : ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context).copyWith(
                                dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                              ),
                              child: Scrollbar(
                                controller: _verticalScrollController,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  controller: _verticalScrollController,
                                  scrollDirection: Axis.vertical,
                                  child: Scrollbar(
                                    controller: _horizontalScrollController,
                                    thumbVisibility: true,
                                    notificationPredicate: (notif) => notif.depth == 1,
                                    child: SingleChildScrollView(
                                      controller: _horizontalScrollController,
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                            minWidth: MediaQuery.of(context).size.width - 100),
                                        child: DataTable(
                                          headingRowColor: MaterialStateProperty.all(Colors.transparent),
                                          dataRowMinHeight: 70,
                                          dataRowMaxHeight: 85,
                                          horizontalMargin: 20,
                                          columnSpacing: 24,
                                          dividerThickness: 1,
                                          columns: const [
                                            DataColumn(label: _Header("SL")),
                                            DataColumn(label: _Header("BOOKING ID")),
                                            DataColumn(label: _Header("SERVICE DETAILS")),
                                            DataColumn(label: _Header("WHERE SERVICE\nWILL BE PROVIDED")),
                                            DataColumn(label: _Header("CUSTOMER INFO")),
                                            DataColumn(label: _Header("PROVIDER INFO")),
                                            DataColumn(label: _Header("SERVICE DISCOUNT")),
                                            DataColumn(label: _Header("COUPON DISCOUNT")),
                                            DataColumn(label: _Header("TAX (GST)")),
                                            DataColumn(label: _Header("TOTAL AMOUNT")),
                                            DataColumn(label: _Header("PAYMENT MODE")),
                                            DataColumn(label: _Header("PAYMENT STATUS")),
                                            DataColumn(label: _Header("SCHEDULE DATE")),
                                            DataColumn(label: _Header("BOOKING DATE")),
                                            DataColumn(label: _Header("STATUS")),
                                            DataColumn(label: _Header("ACTION")),
                                          ],
                                          rows: List.generate(displayed.length, (index) {
                                            final data = displayed[index];
                                            final serialNum = (_currentPage * _pageSize) + index + 1;

                                            return DataRow(
                                              cells: [
                                                DataCell(Text("$serialNum", style: _cellStyle())),
                                                DataCell(
                                                  InkWell(
                                                    onTap: () => widget.onViewDetails(data),
                                                    child: Text(
                                                      data.bookingRef,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: const Color(0xFFEF7822),
                                                        decoration: TextDecoration.underline,
                                                        decorationColor: const Color(0xFFEF7822),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                DataCell(data.services.isEmpty
                                                  ? Text("—", style: _subStyle())
                                                  : Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(data.services.first.serviceName,
                                                            style: _cellStyle(bold: true),
                                                            overflow: TextOverflow.ellipsis,
                                                            maxLines: 2),
                                                        Text("Qty: ${data.services.first.quantity}  •  ${data.services.first.serviceDuration} mins",
                                                            style: _subStyle()),
                                                      ],
                                                    )),
                                                DataCell(Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(data.address?.city ?? "Unknown City",
                                                        style: _cellStyle(bold: true)),
                                                    Text(data.address?.postCode ?? "No Pincode",
                                                        style: _subStyle()),
                                                  ],
                                                )),
                                                DataCell(Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(data.customerName, style: _cellStyle(bold: true)),
                                                    Text(data.customerPhone, style: _subStyle()),
                                                  ],
                                                )),
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
                                                        Text("${data.provider!.firstName} ${data.provider!.lastName}".trim(),
                                                            style: _cellStyle(bold: true)),
                                                        Text(data.provider!.mobile, style: _subStyle()),
                                                      ],
                                                    )),
                                                DataCell(Text("-₹${data.serviceDiscount.toStringAsFixed(2)}", style: _cellStyle())),
                                                DataCell(Text(data.couponDiscountValue > 0
                                                  ? "-₹${data.couponDiscountValue.toStringAsFixed(2)}"
                                                  : "—", style: _cellStyle())),
                                                DataCell(Text("₹${data.totalTaxAmount.toStringAsFixed(2)}", style: _cellStyle())),
                                                DataCell(Text("₹${data.grandTotalPrice.toStringAsFixed(2)}",
                                                    style: _cellStyle(bold: true))),
                                                DataCell(Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _paymentBadgeBg(data.paymentMode),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(data.paymentMode.toUpperCase(),
                                                      style: GoogleFonts.inter(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: _paymentBadgeText(data.paymentMode))),
                                                )),
                                                DataCell(Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: data.paymentStatus.toLowerCase() == 'paid'
                                                        ? const Color(0xFFDCFCE7)
                                                        : const Color(0xFFFFE2E5),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(data.paymentStatus,
                                                      style: GoogleFonts.inter(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: data.paymentStatus.toLowerCase() == 'paid'
                                                              ? const Color(0xFF16A34A)
                                                              : const Color(0xFFEF4444))),
                                                )),
                                                DataCell(Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(_formatScheduleDate(data.bookingDate), style: _cellStyle()),
                                                    if (data.bookingTime.isNotEmpty)
                                                      Text(data.bookingTime, style: _subStyle()),
                                                  ],
                                                )),
                                                DataCell(Builder(builder: (ctx) {
                                                  final bdt = _formatBookingDateTime(data.creationTime);
                                                  return Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(bdt.date, style: _cellStyle()),
                                                      if (bdt.time.isNotEmpty)
                                                        Text(bdt.time, style: _subStyle()),
                                                    ],
                                                  );
                                                })),
                                                DataCell(Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFDBEAFE),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(data.status,
                                                      style: GoogleFonts.inter(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: const Color(0xFF2563EB))),
                                                )),
                                                DataCell(_ActionButton(
                                                  icon: Icons.visibility_outlined,
                                                  onTap: () => widget.onViewDetails(data),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _clientTotalPages,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final isSelected = index == _currentPage;
                              return InkWell(
                                onTap: () => setState(() => _currentPage = index),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  width: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFEF7822) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    "${index + 1}",
                                    style: GoogleFonts.inter(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _currentPage < _clientTotalPages - 1
                            ? () => setState(() => _currentPage++)
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
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

  Widget _buildInfoBanner() {
    return Container(
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
          const Icon(Icons.info_outline, size: 20, color: Color(0xFF1D4ED8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "This report shows only Cash and Offline payment transactions. For online payments, please refer to the All Transaction Report.",
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF1D4ED8),
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        border: Border.all(color: const Color(0xFFFECDD3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFE11D48)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Note: For offline payments please verify if the payments are safely received to your account. Customer is not liable if you confirm the bookings without checking payment transactions.",
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFFE11D48), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          Text(
            "No Transactions Found",
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 4),
          Text(
            "Try adjusting your filters or search criteria.",
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
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
            fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8)));
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
          color: isSelected ? const Color(0xFFEF7822) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFEF7822) : const Color(0xFFCBD5E1),
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
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}