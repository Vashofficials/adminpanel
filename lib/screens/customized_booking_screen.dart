import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomizedBookingScreen extends StatefulWidget {
  const CustomizedBookingScreen({super.key});

  @override
  State<CustomizedBookingScreen> createState() => _CustomizedBookingScreenState();
}

class _CustomizedBookingScreenState extends State<CustomizedBookingScreen> {
  // 1. STATE VARIABLES
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  
  List<CustomizedBookingModel> _allData = _customizedDummyData;
  List<CustomizedBookingModel> _displayedData = [];

  // Selection Tracking
  final Set<String> _selectedIds = {};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _displayedData = List.from(_allData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  // 2. SEARCH LOGIC
  void _runSearch() {
    String keyword = _searchController.text.toLowerCase();
    setState(() {
      _displayedData = _allData.where((item) {
        return item.bookingId.toLowerCase().contains(keyword) ||
            item.customerName.toLowerCase().contains(keyword) ||
            item.category.toLowerCase().contains(keyword);
      }).toList();
      
      // Reset selection when searching
      _selectedIds.clear();
      _selectAll = false;
    });
  }

  // 3. SELECTION LOGIC
  void _toggleSelectAll(bool? val) {
    setState(() {
      _selectAll = val ?? false;
      _selectedIds.clear();
      if (_selectAll) {
        _selectedIds.addAll(_displayedData.map((e) => e.uniqueKey));
      }
    });
  }

  void _toggleSingleSelection(String key, bool? val) {
    setState(() {
      if (val == true) {
        _selectedIds.add(key);
      } else {
        _selectedIds.remove(key);
      }
      _selectAll = _displayedData.isNotEmpty && _selectedIds.length == _displayedData.length;
    });
  }

  // 4. ACTION FUNCTIONS
  void _handleDownload() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text("Downloaded ${_displayedData.length} records!"),
          ],
        ),
        backgroundColor: const Color(0xFFEF7822),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleDeleteSelected() {
    setState(() {
      // Remove items from display and master list based on selection
      _allData.removeWhere((item) => _selectedIds.contains(item.uniqueKey));
      _displayedData.removeWhere((item) => _selectedIds.contains(item.uniqueKey));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Deleted ${_selectedIds.length} records"),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      
      _selectedIds.clear();
      _selectAll = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // UPDATED: Added Align and constraints.
      // This prevents the card from stretching infinitely when you zoom out.
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          // 1400px provides enough room for your 1200px table + padding, 
          // but stops it from growing weirdly on huge screens/zoom out.
          constraints: const BoxConstraints(maxWidth: 1400), 
          child: Column(
            children: [
              // 1. PAGE HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text(
                      "Customized Booking Requests",
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
                          Text("Total Customized: ", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          Text("${_displayedData.length}", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. MAIN CARD
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16), 
                    topRight: Radius.circular(16)
                  ), 
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -4))
                  ],
                ),
                child: Column(
                  children: [
                    // TOOLBAR
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Search Input
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 44,
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: (_) => _runSearch(),
                                        decoration: InputDecoration(
                                          hintText: 'Search by customer info',
                                          hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                                          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.only(top: 10), 
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Search Button
                                  InkWell(
                                    onTap: _runSearch,
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2563EB), 
                                        borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text("Search", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const Spacer(),

                          // CONDITIONAL DELETE BUTTON
                          if (_selectedIds.length > 1) ...[
                            ElevatedButton.icon(
                              onPressed: _handleDeleteSelected,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                              label: Text("Delete Selected (${_selectedIds.length})", 
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],

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
                            label: Text("Download", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Filter Button
                          OutlinedButton.icon(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.filter_list, size: 16, color: Color(0xFF475569)),
                            label: Text("Filter 1", style: GoogleFonts.inter(color: const Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFF1F5F9)),

                    // TABLE WITH HORIZONTAL SLIDER
                    _displayedData.isEmpty 
                    ? Container(
                        height: 200, 
                        alignment: Alignment.center,
                        child: Text("No records found", style: GoogleFonts.inter(color: Colors.grey))
                      )
                    : Scrollbar(
                      controller: _horizontalScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 1200),
                          child: DataTable(
                            showCheckboxColumn: false, 
                            headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                            dataRowMinHeight: 70,
                            dataRowMaxHeight: 85,
                            horizontalMargin: 20, 
                            columnSpacing: 24,
                            dividerThickness: 1,
                            columns: [
                              DataColumn(
                                label: SizedBox(
                                  width: 24,
                                  child: Checkbox(
                                    value: _selectAll, 
                                    onChanged: _toggleSelectAll,
                                    activeColor: const Color(0xFF2563EB),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                              ),
                              const DataColumn(label: _Header("Booking ID")),
                              const DataColumn(label: _Header("Customer Info")),
                              const DataColumn(label: _Header("Booking Request Time")),
                              const DataColumn(label: _Header("Service Time")),
                              const DataColumn(label: _Header("Category")),
                              const DataColumn(label: _Header("Provider Offering")),
                              const DataColumn(label: _Header("Action")),
                            ],
                            rows: _displayedData.map((data) {
                              final isSelected = _selectedIds.contains(data.uniqueKey);
                              return DataRow(
                                selected: isSelected,
                                onSelectChanged: (val) => _toggleSingleSelection(data.uniqueKey, val), 
                                cells: [
                                  DataCell(Checkbox(
                                    value: isSelected, 
                                    onChanged: (val) => _toggleSingleSelection(data.uniqueKey, val),
                                    activeColor: const Color(0xFF2563EB),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  )),
                                  DataCell(Text(data.bookingId, style: _linkStyle())), 
                                  DataCell(Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data.customerName, style: _cellStyle(bold: true)),
                                      Text(data.customerPhone, style: _subStyle()),
                                    ],
                                  )),
                                  DataCell(Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data.requestDate, style: _cellStyle()),
                                      Text(data.requestTime, style: _subStyle()),
                                    ],
                                  )),
                                  DataCell(Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data.serviceDate, style: _cellStyle()),
                                      Text(data.serviceTime, style: _subStyle()),
                                    ],
                                  )),
                                  DataCell(Text(data.category, style: _cellStyle())),
                                  DataCell(Text("${data.providerCount} Providers", style: _cellStyle())),
                                  DataCell(Row(
                                    children: [
                                      _ActionButton(icon: Icons.visibility_outlined, color: const Color(0xFF2563EB), onTap: () {}),
                                      const SizedBox(width: 8),
                                      _ActionButton(icon: Icons.delete_outline, color: const Color(0xFFEF4444), onTap: () {}),
                                    ],
                                  )),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STYLES
  static TextStyle _cellStyle({bool bold = false}) => GoogleFonts.inter(
    fontSize: 13, fontWeight: bold ? FontWeight.w600 : FontWeight.w400, color: const Color(0xFF334155));
  
  static TextStyle _subStyle() => GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8));
  
  static TextStyle _linkStyle() => GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF2563EB), decoration: TextDecoration.underline);
}

// -----------------------------------------------------------------------------
// HELPER WIDGETS
// -----------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)));
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(border: Border.all(color: color.withOpacity(0.3)), borderRadius: BorderRadius.circular(4)),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// DATA MODEL
// -----------------------------------------------------------------------------
class CustomizedBookingModel {
  final String bookingId;
  final String customerName, customerPhone;
  final String requestDate, requestTime;
  final String serviceDate, serviceTime;
  final String category;
  final int providerCount;

  String get uniqueKey => "$customerName-$requestTime-$category";

  CustomizedBookingModel({
    this.bookingId = "Not Booked Yet",
    required this.customerName, required this.customerPhone,
    required this.requestDate, required this.requestTime,
    required this.serviceDate, required this.serviceTime,
    required this.category, required this.providerCount,
  });
}

final List<CustomizedBookingModel> _customizedDummyData = [
  CustomizedBookingModel(customerName: "Jopiko Jopika", customerPhone: "+8801366806680", requestDate: "2024-04-17", requestTime: "04:55pm", serviceDate: "17-04-2024", serviceTime: "04:55am", category: "Shifting", providerCount: 0),
  CustomizedBookingModel(customerName: "Anika Srishty", customerPhone: "+8801700112233", requestDate: "2024-04-17", requestTime: "03:57pm", serviceDate: "17-04-2024", serviceTime: "03:57am", category: "House Cleaning", providerCount: 1),
  CustomizedBookingModel(customerName: "Jemmi Kolly", customerPhone: "+8801755596965", requestDate: "2024-04-17", requestTime: "03:55pm", serviceDate: "17-04-2024", serviceTime: "03:55am", category: "Shifting", providerCount: 0),
  CustomizedBookingModel(customerName: "Jemmi Kolly", customerPhone: "+8801755596965", requestDate: "2024-04-17", requestTime: "03:28pm", serviceDate: "18-04-2024", serviceTime: "03:28pm", category: "Plumbing", providerCount: 0),
  CustomizedBookingModel(customerName: "Anika Srishty", customerPhone: "+8801700112233", requestDate: "2024-03-14", requestTime: "12:25pm", serviceDate: "15-03-2024", serviceTime: "12:25pm", category: "Gadget Repair", providerCount: 0),
  CustomizedBookingModel(customerName: "Anika Srishty", customerPhone: "+8801700112233", requestDate: "2024-03-14", requestTime: "12:24pm", serviceDate: "15-03-2024", serviceTime: "12:24pm", category: "Shifting", providerCount: 1),
];