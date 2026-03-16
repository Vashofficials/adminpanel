import 'dart:ui'; // Required for PointerDeviceKind
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// --- IMPORTS ---
import '../models/booking_models.dart';
import '../repositories/booking_repository.dart';

class CanceledBookingScreen extends StatefulWidget {
final Function(BookingModel) onViewDetails; // Changed from Function(String)

  const CanceledBookingScreen({super.key, required this.onViewDetails});

  @override
  State<CanceledBookingScreen> createState() => _CanceledBookingScreenState();
}

class _CanceledBookingScreenState extends State<CanceledBookingScreen> {
  // 1. STATE VARIABLES
  final BookingRepository _repo = BookingRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  List<BookingModel> _allBookings = [];
  List<BookingModel> _displayedData = [];
  bool _isLoading = true;

  // Pagination
  int _currentPage = 0;
  int _pageSize = 10;
  int _totalPages = 1;
  int _totalElements = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  // 2. FETCH DATA FROM API
  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response =
          await _repo.fetchBookings(page: _currentPage, size: _pageSize);

      // FILTER: Only show 'Cancelled' or 'Canceled'
      final canceledList = response.content.where((b) {
        final status = b.status.toLowerCase();
        return status.contains('cancel');
      }).toList();

      if (!mounted) return;

      setState(() {
        _allBookings = canceledList;
        _displayedData = canceledList;
        _totalPages = response.totalPages;
        _totalElements = response.totalElements; // Total records in DB
        _isLoading = false;
      });

      // Re-apply search if text exists
      if (_searchController.text.isNotEmpty) {
        _runFilter();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      print("Error loading canceled bookings: $e");
    }
  }

  // 3. SEARCH LOGIC
  void _runFilter() {
    List<BookingModel> results = [];
    String keyword = _searchController.text.toLowerCase();

    results = _allBookings.where((item) {
      return item.bookingRef.toLowerCase().contains(keyword) ||
          item.customerName.toLowerCase().contains(keyword) ||
          (item.provider?.firstName ?? '').toLowerCase().contains(keyword);
    }).toList();

    setState(() {
      _displayedData = results;
    });
  }

  // 4. PAGINATION LOGIC (Fixed for 0-based indexing)
  void _onPageChanged(int newPage) {
    if (newPage >= 0 && newPage < _totalPages) {
      setState(() {
        _currentPage = newPage;
      });
      _fetchData();
    }
  }

  // 5. DOWNLOAD FUNCTION
  void _handleDownload() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text("Downloaded ${_displayedData.length} canceled records!"),
          ],
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper: Date Format
  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return "N/A";
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('dd-MMM-yyyy').format(dt);
    } catch (e) {
      return isoDate.split('T')[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sanity check for pagination display
    final displayPage = _totalElements == 0 ? 0 : _currentPage + 1;

    return Column(
      children: [
        // 1. PAGE HEADER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Canceled",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text("Total Canceled: ",
                        style: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF64748B))),
                    Text("${_displayedData.length}",
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEF4444))),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 2. WHITE CARD CONTAINER
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16)),
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
                              hintText: 'Search ID, Name...',
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
                      const Spacer(),

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

                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // --- B. TABLE CONTENT ---
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFEF7822)))
                      : _displayedData.isEmpty
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
                                    controller: _horizontalScrollController,
                                    thumbVisibility: true,
                                    notificationPredicate: (notif) =>
                                        notif.depth == 1,
                                    child: SingleChildScrollView(
                                      controller: _horizontalScrollController,
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                            minWidth: MediaQuery.of(context)
                                                    .size
                                                    .width -
                                                300),
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
                                            DataColumn(label: _Header("SL")),
                                            DataColumn(
                                                label: _Header("BOOKING\nID")),
                                            DataColumn(
                                                label:
                                                    _Header("BOOKING\nDATE")),
                                            DataColumn(
                                                label:
                                                    _Header("SERVICE\nLOCATION")),
                                            DataColumn(
                                                label:
                                                    _Header("SCHEDULE\nDATE")),
                                            DataColumn(
                                                label: _Header("CUSTOMER INFO")),
                                            DataColumn(
                                                label: _Header("PROVIDER INFO")),
                                            DataColumn(
                                                label: _Header("TOTAL\nAMOUNT")),
                                            DataColumn(
                                                label: _Header("ACTION")),
                                          ],
                                          rows: List.generate(
                                              _displayedData.length, (index) {
                                            final data = _displayedData[index];
                                            final serialNum =
                                                ((_currentPage) * _pageSize) +
                                                    index +
                                                    1;

                                            return DataRow(
                                              cells: [
                                                // SL
                                                DataCell(Text("$serialNum",
                                                    style: _cellStyle())),

                                                // ID
                                                DataCell(Text(data.bookingRef,
                                                    style: _cellStyle(
                                                        bold: true))),

                                                // Booking Date (Created)
                                                DataCell(Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        _formatDate(data
                                                            .creationTime),
                                                        style: _cellStyle(
                                                            bold: true)),
                                                    Text(
                                                        data.creationTime
                                                                .contains('T')
                                                            ? data.creationTime
                                                                .split('T')[1]
                                                                .substring(0, 5)
                                                            : "",
                                                        style: _subStyle()),
                                                  ],
                                                )),

                                                // Location
                                               // City & Pincode DataCell
DataCell(
  Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        data.address?.city ?? "Unknown City",
        style: _cellStyle(bold: true), // City in bold (Main info)
      ),
      Text(
        data.address?.postCode ?? "No Pincode",
        style: _subStyle(), // Pincode smaller/grey (Sub info)
      ),
    ],
  ),
),

                                                // Schedule
                                                DataCell(Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        _formatDate(data
                                                            .bookingDate),
                                                        style: _cellStyle(
                                                            bold: true)),
                                                    Text(data.bookingTime,
                                                        style: _subStyle()),
                                                  ],
                                                )),

                                                // Customer
                                                DataCell(Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(data.customerName,
                                                        style: _cellStyle(
                                                            bold: true)),
                                                    Text(data.customerPhone,
                                                        style: _subStyle()),
                                                  ],
                                                )),

                                                // Provider
                                                DataCell(
                                                  data.provider != null
                                                      ? Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                                "${data.provider!.firstName} ${data.provider!.lastName}",
                                                                style: _cellStyle(
                                                                    bold: true)),
                                                            Text(
                                                                data.provider!
                                                                    .mobile,
                                                                style:
                                                                    _subStyle()),
                                                          ],
                                                        )
                                                      : Text("Unassigned",
                                                          style: GoogleFonts
                                                              .inter(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .redAccent,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500)),
                                                ),

                                                // Amount
                                                DataCell(Text(
                                                   "₹${data.grandTotalPrice.toStringAsFixed(2)}",
                                                    style: _cellStyle(
                                                        bold: true))),

                                                // Action
                                                DataCell(Row(
                                                  children: [
                                                    _ActionButton(
                                                      icon: Icons
                                                          .visibility_outlined,
                                                      onTap: () => widget
                                                          .onViewDetails(
                                                              data),
                                                    ),
                                                  ],
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

                // --- C. PAGINATION FOOTER (ALWAYS VISIBLE) ---
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border:
                        Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Button
                      OutlinedButton(
                        onPressed: _currentPage > 0
                            ? () => _onPageChanged(_currentPage - 1)
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: const Text('Previous'),
                      ),

                      // Page Numbers (Scrollable if many pages)
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
                                    borderRadius: BorderRadius.circular(4),
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color:
                                                const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    "${index + 1}", // Display 1-based index
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

                      // Next Button
                      OutlinedButton(
                        onPressed: _currentPage < _totalPages - 1
                            ? () => _onPageChanged(_currentPage + 1)
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- NEW PROFESSIONAL EMPTY STATE WIDGET ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel_presentation_outlined,
                size: 48, color: Color(0xFFEF4444)),
          ),
          const SizedBox(height: 16),
          Text(
            "No Canceled Bookings",
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 4),
          Text(
            "Bookings that have been canceled will appear here.",
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // STYLES & WIDGETS
  static TextStyle _cellStyle({bool bold = false, double size = 13}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
      color: const Color(0xFF334155),
    );
  }

  static TextStyle _subStyle() {
    return GoogleFonts.inter(
        fontSize: 12, color: const Color(0xFF94A3B8));
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
        child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      ),
    );
  }
}