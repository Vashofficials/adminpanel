import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; 

// --- IMPORTS ---
import '../models/booking_models.dart';
import '../repositories/booking_repository.dart';

class OngoingBookingScreen extends StatefulWidget {
final Function(BookingModel) onViewDetails; // Changed from Function(String)  
  const OngoingBookingScreen({super.key, required this.onViewDetails});

  @override
  State<OngoingBookingScreen> createState() => _OngoingBookingScreenState();
}

class _OngoingBookingScreenState extends State<OngoingBookingScreen> {
  // 1. STATE VARIABLES
  final BookingRepository _repo = BookingRepository();
  
  // Data State
  List<BookingModel> _allBookings = []; // All fetched pending bookings
  List<BookingModel> _displayedData = []; // Filtered by search/status
  bool _isLoading = true;
  String _errorMessage = '';

  // Pagination State
  int _currentPage = 0;
  int _pageSize = 10;
  int _totalPages = 10;
  int _totalElements = 0;
  
  // Filters
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'All'; // 'All', 'Paid', 'UnPaid'

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

// 4. PAGINATION LOGIC (Fixed for 0-based Indexing)
  void _onPageChanged(int newPage) {
    // API uses 0-based index. 
    // If totalPages is 10, valid indices are 0 to 9.
    if (newPage >= 0 && newPage < _totalPages) {
      setState(() {
        _currentPage = newPage;
      });
      _fetchData();
    }
  }

  // 2. API FETCH (Ensure _totalElements is updated correctly)
  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Pass dynamic page number
      final response = await _repo.fetchBookings(page: _currentPage, size: _pageSize);
      
      // Filter: Only show 'Pending' bookings
      final pendingBookings = response.content.where((b) {
        return b.status.toLowerCase() == 'pending';
      }).toList();

      if (!mounted) return;
      
      setState(() {
        _allBookings = pendingBookings;
        _displayedData = pendingBookings; 
        _totalPages = response.totalPages; // Ensure API returns this correctly
        _totalElements = response.totalElements; 
        _isLoading = false;
      });
      
      // Re-run local filter if search text exists
      if (_searchController.text.isNotEmpty || _filterStatus != 'All') {
        _runFilter();
      }

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      print("Error loading ongoing bookings: $e");
    }
  }

  // 3. SEARCH & FILTER LOGIC
  void _runFilter() {
    List<BookingModel> results = [];
    String keyword = _searchController.text.toLowerCase();

    results = _allBookings.where((item) {
      // Search Logic
      final matchesKeyword = 
          item.bookingRef.toLowerCase().contains(keyword) ||
          item.mainServiceName.toLowerCase().contains(keyword) ||
          (item.provider?.firstName ?? '').toLowerCase().contains(keyword);
      
      // Filter Logic (Payment Status)
      bool matchesStatus = true;
      if (_filterStatus != 'All') {
        matchesStatus = item.paymentStatus.toLowerCase() == _filterStatus.toLowerCase();
      }

      return matchesKeyword && matchesStatus;
    }).toList();

    setState(() {
      _displayedData = results;
    });
  }

 

  // 5. DOWNLOAD FUNCTION
  void _handleDownload() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text("Downloaded ${_displayedData.length} records successfully!"),
          ],
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 6. FILTER DIALOG
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Filter by Payment", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption(ctx, "All", 'All'),
            _buildFilterOption(ctx, "Paid Only", 'Paid'),
            _buildFilterOption(ctx, "Unpaid Only", 'UnPaid'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(BuildContext ctx, String label, String value) {
    return RadioListTile<String>(
      title: Text(label, style: GoogleFonts.inter()),
      value: value,
      groupValue: _filterStatus,
      activeColor: const Color(0xFFEF7822),
      onChanged: (val) {
        setState(() => _filterStatus = val!);
        _runFilter();
        Navigator.pop(ctx);
      },
    );
  }

  // Helper: Format Date
  String _formatDate(String isoDate) {
  if (isoDate.isEmpty) return "N/A";
  try {
    final dt = DateTime.parse(isoDate).toLocal();
    return DateFormat('dd MMM yyyy').format(dt);
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
                "Ongoing (Pending)",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text("Total Pending: ",
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
                              hintText: 'Search Booking ID...',
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

                      // Filter Button
                      OutlinedButton.icon(
                        onPressed: _showFilterDialog,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          side: BorderSide(
                              color: _filterStatus == 'All'
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFFEF7822)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          foregroundColor: const Color(0xFF475569),
                        ),
                        icon: Icon(Icons.filter_list,
                            size: 18,
                            color: _filterStatus == 'All'
                                ? null
                                : const Color(0xFFEF7822)),
                        label: Text("Filter: $_filterStatus",
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),

                      const SizedBox(width: 12),

                      // Refresh Button
                      ElevatedButton.icon(
                        onPressed: _fetchData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF7822),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.refresh,
                            size: 18, color: Colors.white),
                        label: Text("Refresh",
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // --- B. CONTENT AREA (Table or Empty State) ---
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFEF7822)))
                      : _displayedData.isEmpty
                          ? _buildEmptyState()
                          : SingleChildScrollView(
                              padding: EdgeInsets.zero,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      minWidth:
                                          MediaQuery.of(context).size.width -
                                              300),
                                  child: DataTable(
                                    headingRowColor: MaterialStateProperty.all(
                                        Colors.transparent),
                                    dataRowMinHeight: 70,
                                    dataRowMaxHeight: 85,
                                    horizontalMargin: 20,
                                    columnSpacing: 24,
                                    dividerThickness: 1,
                                    columns: const [
                                      DataColumn(label: _Header("SL")),
                                      DataColumn(label: _Header("BOOKING\nID")),
                                      DataColumn(
                                          label: _Header("SERVICE\nDETAILS")),
                                      DataColumn(label: _Header("LOCATION")),
                                      DataColumn(label: _Header("SCHEDULE")),
                                      DataColumn(label: _Header("PROVIDER")),
                                      DataColumn(label: _Header("AMOUNT")),
                                      DataColumn(label: _Header("PAYMENT")),
                                      DataColumn(label: _Header("ACTION")),
                                    ],
                                    rows: List.generate(_displayedData.length,
                                        (index) {
                                      final data = _displayedData[index];
                                      
                                      // --- FIX IS HERE: REMOVED "- 1" ---
                                      final serialNum = (_currentPage * _pageSize) + index + 1;

                                      return DataRow(
                                        cells: [
                                          // SL
                                          DataCell(Text("$serialNum",
                                              style: _cellStyle())),
                                          
                                          // Booking ID
                                          DataCell(Text(data.bookingRef,
                                              style: _cellStyle(bold: true))),
                                          
                                          // Service Details
                                          DataCell(Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(data.mainServiceName,
                                                  style:
                                                      _cellStyle(bold: true)),
                                              Text(
                                                  "Created: ${_formatDate(data.creationTime)}",
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
                                                  _formatDate(data.bookingDate),
                                                  style:
                                                      _cellStyle(bold: true)),
                                              Text(data.bookingTime,
                                                  style: _subStyle()),
                                            ],
                                          )),
                                          
                                          // Provider
                                          DataCell(data.provider != null
                                              ? Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        "${data.provider!.firstName} ${data.provider!.lastName}",
                                                        style: _cellStyle(
                                                            bold: true)),
                                                    Text(data.provider!.mobile,
                                                        style: _subStyle()),
                                                  ],
                                                )
                                              : Text("Unassigned",
                                                  style: GoogleFonts.inter(
                                                      fontSize: 13,
                                                      color: Colors.redAccent,
                                                      fontWeight:
                                                          FontWeight.w500))),
                                          
                                          // Amount
                                          DataCell(Text("₹${data.grandTotalPrice.toStringAsFixed(2)}",
                                              style: _cellStyle(bold: true))),
                                          
                                          // Payment Status
                                          DataCell(_StatusBadge(
                                              status: data.paymentStatus)),
                                          
                                          // Action
                                          DataCell(Row(
                                            children: [
                                              _ActionButton(
                                                icon: Icons.visibility_outlined,
                                                onTap: () => widget
                                                    .onViewDetails(data),
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

                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // --- C. PAGINATION FOOTER (FIXED) ---
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
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

                      // Page Numbers
                      Expanded(
                        child: Container(
                          height: 32,
                          alignment: Alignment.center,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                            color: const Color(0xFFE2E8F0)),
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
            child: const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          Text(
            "No Bookings Found",
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

  // STYLES & WIDGETS
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
    return Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8)));
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final isPaid = status.toLowerCase() == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFFE2E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: isPaid ? const Color(0xFF16A34A) : const Color(0xFFF75555),
        ),
      ),
    );
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
        width: 32, height: 32,
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
        child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      ),
    );
  }
}