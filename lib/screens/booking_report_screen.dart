import 'dart:math'; // Required for max function
import 'package:flutter/material.dart';

// --- THEME COLORS ---
const _bg = Color(0xFFF1F5F9); 
const _panelBg = Colors.white;
const _muted = Color(0xFF64748B); 
const _textDark = Color(0xFF0F172A); 
const _border = Color(0xFFE2E8F0); 
const _orange = Color(0xFFF97316); 
const _orangeLight = Color(0xFFFFF7ED); 
const _shadow = BoxShadow(
  color: Color(0x0F000000),
  blurRadius: 12,
  offset: Offset(0, 4),
);

class BookingReportScreen extends StatefulWidget {
  const BookingReportScreen({super.key});

  @override
  State<BookingReportScreen> createState() => _BookingReportScreenState();
}

class _BookingReportScreenState extends State<BookingReportScreen> {
  // --- FILTER STATE ---
  String? _selectedProvider;
  String? _selectedStatus; // Replaced _selectedDateRange
  String? _activeCardStatus; // For tapable cards
  bool _isLoading = false;

  final List<String> _statuses = ['Ongoing', 'Completed', 'Cancelled', 'Pending', 'Accepted'];

  // Mock Data for Dropdowns
  final List<String> _providers = ['All Providers', 'Lucknow Home Svcs', 'Gomti Cleaners'];

  void _applyFilters() async {
    setState(() => _isLoading = true);
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Filters applied successfully!')),
      );
    }
  }

  // Removed _pickDateRange as it is replaced by Status filter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TopAppBar(),
              const SizedBox(height: 24),
              
              // Search Filters
              _buildSearchFilters(),
              const SizedBox(height: 24),
              
              // Stats & Chart (Responsive)
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 1100) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3, 
                          child: _SummaryStatsCard(
                            activeStatus: _activeCardStatus,
                            onStatusTap: (status) {
                              setState(() {
                                _activeCardStatus = (_activeCardStatus == status) ? null : status;
                                _selectedStatus = _activeCardStatus;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                        const SizedBox(width: 24),
                        const Expanded(flex: 7, child: _BookingChartCard()),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _SummaryStatsCard(
                          isFullWidth: true,
                          activeStatus: _activeCardStatus,
                          onStatusTap: (status) {
                             setState(() {
                                _activeCardStatus = (_activeCardStatus == status) ? null : status;
                                _selectedStatus = _activeCardStatus;
                              });
                              _applyFilters();
                          },
                        ),
                        const SizedBox(height: 24),
                        const _BookingChartCard(),
                      ],
                    );
                  }
                },
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [_shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.filter_alt_outlined, color: _orange),
              SizedBox(width: 8),
              Text(
                'Filter Booking Data',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  _buildDropdown('Provider', _providers, _selectedProvider, (v) => setState(() => _selectedProvider = v)),
                  _buildDropdown('Booking Status', _statuses, _selectedStatus, (v) => setState(() => _selectedStatus = v)),

                  // Submit Button
                  SizedBox(
                    height: 48,
                    width: 120,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _applyFilters,
                      icon: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Icon(Icons.search, size: 18),
                      label: Text(_isLoading ? '...' : 'Filter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? currentValue, ValueChanged<String?> onChanged) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentValue,
                hint: Text('Select $label', style: const TextStyle(fontSize: 13, color: _muted)),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: _muted),
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Booking Analysis',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark),
            ),
            SizedBox(height: 4),
            Text('Monitor booking status and revenue', style: TextStyle(fontSize: 14, color: _muted)),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
          color: _muted,
          tooltip: 'Notifications',
        ),
        const SizedBox(width: 12),
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: _orangeLight,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text('A', style: TextStyle(color: _orange, fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      ],
    );
  }
}

class _SummaryStatsCard extends StatelessWidget {
  final bool isFullWidth;
  final String? activeStatus;
  final Function(String)? onStatusTap;
  
  const _SummaryStatsCard({this.isFullWidth = false, this.activeStatus, this.onStatusTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [_shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _orangeLight, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.confirmation_number_outlined, color: _orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Total Bookings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _muted)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('1,452', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _textDark)),
          const SizedBox(height: 24),
          
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _StatItem(
                color: const Color(0xFFEF4444), 
                label: 'Canceled', 
                value: '42', 
                icon: Icons.cancel_outlined,
                isActive: activeStatus == 'Cancelled',
                onTap: () => onStatusTap?.call('Cancelled'),
                cash: '12', online: '30',
              ),
              _StatItem(
                color: const Color(0xFF10B981), 
                label: 'Completed', 
                value: '1,154', 
                icon: Icons.check_circle_outline,
                isActive: activeStatus == 'Completed',
                onTap: () => onStatusTap?.call('Completed'),
                cash: '800', online: '354',
              ),
              _StatItem(
                color: const Color(0xFF3B82F6), 
                label: 'Accepted', 
                value: '128', 
                icon: Icons.thumb_up_outlined,
                isActive: activeStatus == 'Accepted',
                onTap: () => onStatusTap?.call('Accepted'),
                cash: '50', online: '78',
             ),
              _StatItem(
                color: const Color(0xFFF59E0B), 
                label: 'Ongoing', 
                value: '85', 
                icon: Icons.timelapse,
                isActive: activeStatus == 'Ongoing',
                onTap: () => onStatusTap?.call('Ongoing'),
                cash: '40', online: '45',
              ),
              _StatItem(
                color: const Color(0xFF64748B), 
                label: 'Pending', 
                value: '43', 
                icon: Icons.pending_outlined,
                isActive: activeStatus == 'Pending',
                onTap: () => onStatusTap?.call('Pending'),
                cash: '10', online: '33',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;
  final String cash;
  final String online;

  const _StatItem({
    required this.color, 
    required this.label, 
    required this.value, 
    required this.icon,
    this.isActive = false,
    this.onTap,
    required this.cash,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100, // Increased width for cash/online text
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? color : Colors.transparent, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Cash & Online Breakdown
            Row(
              children: [
                const Icon(Icons.money, size: 10, color: _muted),
                const SizedBox(width: 2),
                Text(cash, style: const TextStyle(fontSize: 10, color: _muted, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                const Icon(Icons.account_balance_wallet_outlined, size: 10, color: _muted),
                const SizedBox(width: 2),
                Text(online, style: const TextStyle(fontSize: 10, color: _muted, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingChartCard extends StatelessWidget {
  const _BookingChartCard();

  @override
  Widget build(BuildContext context) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final values = [0.1, 0.2, 0.25, 0.5, 0.3, 0.4, 0.45, 0.6, 0.8, 0.7, 0.9, 1.0]; 

    return Container(
      height: 340, 
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [_shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Booking Statistics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: const [
                    Text('2025', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
                    Icon(Icons.keyboard_arrow_down, size: 16, color: _muted)
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['1000', '800', '600', '400', '200', '0']
                      .map((e) => Text(e, style: const TextStyle(fontSize: 10, color: _muted)))
                      .toList(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // FIX: Explicitly reserving height for labels to prevent bottom overflow
                      const double labelHeight = 24.0;
                      final double maxBarHeight = constraints.maxHeight - labelHeight;
                      
                      final w = constraints.maxWidth / months.length;
                      
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(months.length, (i) {
                          // Prevent overflow by clamping calculation
                          double h = maxBarHeight * values[i];
                          if (h < 0) h = 0;

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Tooltip(
                                message: '${(values[i] * 1000).toInt()} bookings',
                                child: Container(
                                  width: w * 0.5,
                                  height: h,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        _orange.withOpacity(0.8),
                                        _orange,
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 16, // Fixed height for text
                                child: Text(months[i], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _muted)),
                              ),
                            ],
                          );
                        }),
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
