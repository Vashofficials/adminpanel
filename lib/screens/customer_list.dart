import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- IMPORTANT: This import provides the 'Customer' class ---
import '../repositories/customer_repository.dart';
import '../models/customer_models.dart'; 
// -----------------------------------------------------------

class CustomerListScreen extends StatefulWidget {
  final Function(Customer)? onEditCustomer;
  final Function(Customer)? onViewCustomer; 
  
  const CustomerListScreen({
    super.key, 
    this.onEditCustomer, 
    this.onViewCustomer,
  });

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  // --- Dependencies ---
  final CustomerRepository _repository = CustomerRepository(); 

  // --- State Variables ---
  List<Customer> _customers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  // --- Pagination State (0-BASED) ---
  int _currentPage = 0; // UPDATED: Start at 0 for API
  int _pageSize = 10;
  int _totalPages = 1;
  int _totalElements = 0;

  // --- Filter State Variables ---
  String _selectedTab = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'Latest';
  String _selectedArea = 'All Areas';

  // --- Constants for Dropdowns ---
  final List<String> _sortOptions = ['Latest', 'Oldest', 'Bookings High', 'Bookings Low'];
  final List<String> _areaOptions = ['All Areas', 'Gomti Nagar', 'Hazratganj', 'Aliganj', 'Indira Nagar'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Call the real API (Passes 0, 1, 2 etc.)
      final response = await _repository.fetchCustomers(_currentPage, _pageSize);
      
      if (!mounted) return;

      setState(() {
        _totalPages = response.totalPages;
        _totalElements = response.totalElements;
        
        // 2. Map API Model to UI Model
        _customers = response.content.map((apiModel) {
          return Customer(
            id: apiModel.id,
            name: '${apiModel.firstName} ${apiModel.lastName ?? ""}'.trim(),
            email: apiModel.emailId ?? 'N/A',
            phone: apiModel.mobileNo,
            bookings: 0, // Placeholder
            joinedDate: 'N/A', // Placeholder
            location: 'Lucknow', // Placeholder
            avatarColor: '0xFFE3F2FD', 
            isActive: apiModel.status == 1,
            imgLink: apiModel.imgLink
          );
        }).toList();
        
        _isLoading = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
        print("API ERROR: $_errorMessage"); 
      });
    }
  }

  // UPDATED: Logic for 0-based indexing
  void _onPageChanged(int newPage) {
    // Check if newPage is valid (0 to totalPages - 1)
    if (newPage >= 0 && newPage < _totalPages) {
      setState(() {
        _currentPage = newPage;
      });
      _fetchData();
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryOrange,
              onPrimary: Colors.white,
              onSurface: kTextDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _applyFilter() {
    setState(() {
      _currentPage = 0; // UPDATED: Reset to 0
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Customer List', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextDark)),
                SizedBox(height: 4),
                Text('Manage your customers across Lucknow', style: TextStyle(color: kTextLight)),
              ],
            ),
            const SizedBox(height: 24),

            // --- Filter Card ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.filter_alt_outlined, color: kPrimaryOrange, size: 20),
                      SizedBox(width: 8),
                      Text('Search Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _buildDatePickerField(
                          label: 'Start Date', 
                          selectedDate: _startDate, 
                          onTap: () => _selectDate(context, true)
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDatePickerField(
                          label: 'End Date', 
                          selectedDate: _endDate, 
                          onTap: () => _selectDate(context, false)
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdownField(
                          label: 'Sort By',
                          value: _sortBy,
                          items: _sortOptions,
                          onChanged: (val) => setState(() => _sortBy = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdownField(
                          label: 'Area',
                          value: _selectedArea,
                          items: _areaOptions,
                          onChanged: (val) => setState(() => _selectedArea = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _applyFilter,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryOrange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0
                            ),
                            child: const Text('Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Table Section ---
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  // Tabs & Search Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: ['All', 'Active', 'Inactive'].map((tab) {
                                final isSelected = _selectedTab == tab;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedTab = tab),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 24),
                                    padding: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      border: isSelected ? const Border(bottom: BorderSide(color: kPrimaryOrange, width: 2)) : null,
                                    ),
                                    child: Text(
                                      tab,
                                      style: TextStyle(
                                        color: isSelected ? kPrimaryOrange : kTextLight,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            Text('Total Customers: $_totalElements', style: const TextStyle(color: kTextLight, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: TextEditingController(), // Consider managing this if you need search text state
                                decoration: InputDecoration(
                                  hintText: 'Search by name, email or phone...',
                                  prefixIcon: const Icon(Icons.search, color: kTextLight),
                                  filled: true,
                                  fillColor: kBgColor,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                ),
                                onSubmitted: (value) => _applyFilter(), 
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _applyFilter,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              child: const Text('Search', style: TextStyle(color: Colors.white)),
                            ),
                            const Spacer(),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.download, size: 18, color: kTextDark),
                              label: const Text('Download', style: TextStyle(color: kTextDark)),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: kBorderColor),

                  // Table Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: const [
                        SizedBox(width: 40, child: Text('SL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextLight))),
                        Expanded(flex: 2, child: Text('CUSTOMER NAME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextLight))),
                        Expanded(flex: 2, child: Text('CONTACT INFO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextLight))),
                        Expanded(flex: 1, child: Text('BOOKINGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextLight))),
                        Expanded(flex: 2, child: Text('JOINED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextLight))),
                        Expanded(flex: 1, child: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextLight))),
                        Expanded(flex: 1, child: Text('ACTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextLight))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: kBorderColor),

                  // Table Rows
                  if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(child: CircularProgressIndicator(color: kPrimaryOrange)),
                      )
                  else if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Center(child: Text("Error: $_errorMessage", style: const TextStyle(color: Colors.red))),
                      )
                  else if (_customers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(child: Text("No customers found")),
                      )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _customers.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1, color: kBorderColor),
                      itemBuilder: (context, index) {
                        final customer = _customers[index];
                        // UPDATED: SL Calculation for 0-based page
                        final serialNumber = ((_currentPage) * _pageSize) + index + 1;
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          color: Colors.white,
                          child: Row(
                            children: [
                              SizedBox(width: 40, child: Text('$serialNumber', style: const TextStyle(color: kTextLight))),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    if(customer.imgLink != null && customer.imgLink!.isNotEmpty)
                                      CircleAvatar(
                                        backgroundImage: NetworkImage(customer.imgLink!), 
                                        radius: 14,
                                        onBackgroundImageError: (_,__) {}, 
                                      )
                                    else
                                      CircleAvatar(
                                        backgroundColor: Color(int.parse(customer.avatarColor)), 
                                        radius: 14, 
                                        child: Text(
                                          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'U', 
                                          style: const TextStyle(fontSize: 10, color: kTextDark)
                                        )
                                      ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600, color: kTextDark), overflow: TextOverflow.ellipsis,)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(customer.email, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: kTextDark)),
                                    Text(customer.phone, style: const TextStyle(fontSize: 12, color: kTextLight)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: kBgColor, borderRadius: BorderRadius.circular(4)),
                                      child: Text('${customer.bookings}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(customer.joinedDate, style: const TextStyle(fontSize: 13, color: kTextDark)),
                                    Text(customer.location, style: const TextStyle(fontSize: 12, color: kTextLight)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Switch(
                                  value: customer.isActive,
                                  activeColor: Colors.white,
                                  activeTrackColor: kPrimaryOrange,
                                  onChanged: (v) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Status update API not integrated yet")));
                                  },
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Row(
                                  children: [
                                    _ActionButton(
                                      icon: Icons.edit_outlined, 
                                      color: kPrimaryOrange,
                                      onTap: () {
                                        if (widget.onEditCustomer != null) {
                                          widget.onEditCustomer!(customer);
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionButton(
                                      icon: Icons.visibility_outlined, 
                                      color: kTextLight, 
                                      onTap: () {
                                         if(widget.onViewCustomer != null) {
                                            widget.onViewCustomer!(customer); 
                                         }
                                      }, 
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  
                  // --- UPDATED FOOTER WITH DYNAMIC PAGE NUMBERS ---
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          // UPDATED TEXT LOGIC for 0-based
                          'Showing ${(_currentPage * _pageSize) + 1} to ${(_currentPage * _pageSize) + _customers.length} of $_totalElements entries', 
                          style: const TextStyle(color: kTextLight, fontSize: 13)
                        ),
                        Row(
                          children: [
                            // Previous Button
                            OutlinedButton(
                              onPressed: _currentPage > 0 
                                ? () => _onPageChanged(_currentPage - 1) 
                                : null, 
                              child: const Text('Prev', style: TextStyle(color: kTextLight))
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Dynamic Page Number Strip
                            Container(
                              height: 32,
                              alignment: Alignment.center,
                              child: ListView.separated(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                itemCount: _totalPages,
                                separatorBuilder: (_,__) => const SizedBox(width: 4),
                                itemBuilder: (context, index) {
                                  final isSelected = index == _currentPage;
                                  return InkWell(
                                    onTap: () => _onPageChanged(index),
                                    child: Container(
                                      width: 32, 
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected ? kPrimaryOrange : Colors.transparent, 
                                        borderRadius: BorderRadius.circular(4),
                                        border: isSelected ? null : Border.all(color: kBorderColor)
                                      ),
                                      // Show 1-based index to user (index + 1)
                                      child: Text('${index + 1}', style: TextStyle(color: isSelected ? Colors.white : kTextDark)),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(width: 8),
                            
                            // Next Button
                            OutlinedButton(
                              onPressed: _currentPage < _totalPages - 1 
                                ? () => _onPageChanged(_currentPage + 1) 
                                : null,
                              child: const Text('Next', style: TextStyle(color: kTextLight))
                            ),
                          ],
                        )
                      ],
                    ),
                   )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildDatePickerField({required String label, DateTime? selectedDate, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: kTextLight, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: kBorderColor),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null ? "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}" : "mm/dd/yyyy",
                    style: TextStyle(fontSize: 13, color: selectedDate != null ? kTextDark : Colors.grey),
                  ),
                ),
                const Icon(Icons.calendar_today, size: 16, color: kTextLight),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label, 
    required String value, 
    required List<String> items, 
    required ValueChanged<String?> onChanged
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: kTextLight, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: kBorderColor),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: kTextLight),
              isExpanded: true,
              style: const TextStyle(fontSize: 13, color: kTextDark),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(4),
          color: color.withOpacity(0.05),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// --- Constants ---
const Color kPrimaryOrange = Color(0xFFFF6B00); 
const Color kTextDark = Color(0xFF1E293B);
const Color kTextLight = Color(0xFF64748B);
const Color kBorderColor = Color(0xFFE2E8F0);
const Color kBgColor = Color(0xFFF1F5F9);