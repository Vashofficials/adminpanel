import 'package:flutter/material.dart';
import 'sidebar_widgets.dart';
import '../screens/login_screen.dart'; 
import '../repositories/auth_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class DashboardSidebar extends StatefulWidget {
  final bool collapsed;
  final String? currentRoute;
  final ValueChanged<String>? onNav;
  final VoidCallback? onToggle;

  const DashboardSidebar({
    super.key,
    required this.collapsed,
    this.currentRoute,
    this.onNav,
    this.onToggle,
  });

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar> {
  // Expansion States
  bool _bookingsOpen = false;
  bool _categorySetupOpen = false;
  bool _servicesOpen = false;
  bool _customersOpen = false;
  bool _employeesOpen = false;
  bool _reportsOpen = false;
  bool _analyticsOpen = false;
  bool _notificationsOpen = false;
  bool _zoneSetupOpen = false;
  bool _providersOpen = false;
  // --- NEW: Separate States for Promotion Sub-sections ---
  bool _discountsOpen = false;
  bool _couponsOpen = false;
  bool _referralsOpen = false;

  bool _isActive(String key) {
    final r = widget.currentRoute ?? '';
    if (key == 'dashboard') return r == 'dashboard';
    return r.startsWith(key);
  }

  @override
  Widget build(BuildContext context) {
    final collapsed = widget.collapsed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      width: collapsed ? 72 : 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // 1. BRAND LOGO & HEADER
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 12 : 16),
            child: LayoutBuilder(
              builder: (context, box) {
                final canShowTitle = !collapsed && box.maxWidth >= 180;
                
                return Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 235, 153, 37),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shield, color: Colors.white, size: 20),
                    ),
                    if (canShowTitle) ...[
                      const SizedBox(width: 10),
                      const Flexible(
                        child: Text('CK Admin Panel',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 20,
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // 2. ADMIN USER CARD
          Padding(
            padding: EdgeInsets.fromLTRB(collapsed ? 8 : 16, 10, collapsed ? 8 : 16, 12),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: collapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Center(
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFFFE4B5),
                  child: const Icon(Icons.person, color: Color(0xFF7C5200), size: 20),
                ),
              ),
              secondChild: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFFFE4B5),
                      child: Icon(Icons.person, color: Color(0xFF7C5200), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('admin@admin.com',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w700)),
                          SizedBox(height: 2),
                          Text('super-admin', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. SCROLLABLE NAVIGATION LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                SectionHeader('MAIN', hidden: collapsed),
                NavTile(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  collapsed: collapsed,
                  isActive: _isActive('dashboard'),
                  onTap: () => widget.onNav?.call('dashboard'),
                ),

                // --- BOOKING MANAGEMENT SECTION ---
                SectionHeader('BOOKING MANAGEMENT', hidden: collapsed),
                NavTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Bookings',
                  collapsed: collapsed,
                  isActive: _isActive('booking/'),
                  trailing: collapsed
                      ? null
                      : Icon(
                          _bookingsOpen ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          size: 20,
                          color: const Color(0xFF9CA3AF),
                        ),
                  onTap: () => setState(() => _bookingsOpen = !_bookingsOpen),
                ),
                
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  crossFadeState: _bookingsOpen && !collapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                  /*    NavTile(
                        icon: Icons.adjust_rounded,
                        label: 'Customized Requests',
                        badge: 13,
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('booking/customized'),
                        onTap: () => widget.onNav?.call('booking/customized'),
                      ), */
                      NavTile(
                        icon: Icons.receipt_long_outlined,
                        label: 'Offline Payment',
                        badge: 6,
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('booking/offline'),
                        onTap: () => widget.onNav?.call('booking/offline'),
                      ),
                      NavTile(
                        icon: Icons.timelapse_outlined,
                        label: 'Ongoing',
                        badge: 10,
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('booking/ongoing'),
                        onTap: () => widget.onNav?.call('booking/ongoing'),
                      ),
                      NavTile(
                        icon: Icons.done_all_outlined,
                        label: 'Completed',
                        badge: 37,
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('booking/completed'),
                        onTap: () => widget.onNav?.call('booking/completed'),
                      ),
                      NavTile(
                        icon: Icons.cancel_outlined,
                        label: 'Canceled',
                        badge: 4,
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('booking/canceled'),
                        onTap: () => widget.onNav?.call('booking/canceled'),
                      ),
                    ],
                  ),
                ),

                SectionHeader('SERVICE MANAGEMENT', hidden: collapsed),

                // --- CATEGORY SECTION ---
                // --- ZONE SECTION ---
                NavTile(
                  icon: Icons.map_outlined,
                  label: 'Zone Setup',
                  collapsed: collapsed,
                  // Keep parent active if either child is active
                  isActive: _isActive('zone/map') || _isActive('zone/provider-map'), 
                  trailing: collapsed
                      ? null
                      : Icon(
                          _zoneSetupOpen ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          size: 20,
                          color: const Color(0xFF9CA3AF),
                        ),
                  onTap: () => setState(() => _zoneSetupOpen = !_zoneSetupOpen),
                ),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _zoneSetupOpen && !collapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      // 1. Zone Map
                      NavTile(
                        icon: Icons.layers_outlined, 
                        label: 'Zone Map',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('zone/map'),
                        // Use this route string in your main navigation switch
                        onTap: () => widget.onNav?.call('zone/map'), 
                      ),
                      
                      // 2. Provider Map
                      NavTile(
                        icon: Icons.person_pin_circle_outlined,
                        label: 'Add Buffer',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('zone/bufferadd'),
                        // Use this route string in your main navigation switch
                        onTap: () => widget.onNav?.call('zone/bufferadd'),
                      ),
                    ],
                  ),
                ),
                NavTile(
                  icon: Icons.category_outlined,
                  label: 'Category Setup',
                  collapsed: collapsed,
                  isActive: _isActive('service/categories') || _isActive('service/subcategories'),
                  trailing: collapsed
                      ? null
                      : Icon(
                          _categorySetupOpen ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          size: 20,
                          color: const Color(0xFF9CA3AF),
                        ),
                  onTap: () => setState(() => _categorySetupOpen = !_categorySetupOpen),
                ),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _categorySetupOpen && !collapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      NavTile(
                        icon: Icons.grid_view_outlined,
                        label: 'Main Categories',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('service/categories'),
                        onTap: () => widget.onNav?.call('service/categories'),
                      ),
                      NavTile(
                        icon: Icons.schema_outlined,
                        label: 'Service Categories',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('service/subcategories'),
                        onTap: () => widget.onNav?.call('service/subcategories'),
                      ),
                    ],
                  ),
                ),

                // --- SERVICE SECTION ---
                NavTile(
                  icon: Icons.cleaning_services_outlined,
                  label: 'Services',
                  collapsed: collapsed,
                  isActive: _isActive('service/list') || _isActive('service/add'),
                  trailing: collapsed
                      ? null
                      : Icon(
                          _servicesOpen ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          size: 20,
                          color: const Color(0xFF9CA3AF),
                        ),
                  onTap: () => setState(() => _servicesOpen = !_servicesOpen),
                ),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _servicesOpen && !collapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      NavTile(
                        icon: Icons.list_alt_outlined,
                        label: 'Service List',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('service/list'),
                        onTap: () => widget.onNav?.call('service/list'),
                      ),
                      NavTile(
                        icon: Icons.add_circle_outline,
                        label: 'Add New Service',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('service/add'),
                        onTap: () => widget.onNav?.call('service/add'),
                      ),
                    ],
                  ),
                ),
              SectionHeader('PROVIDER MANAGEMENT', hidden: collapsed),

                NavTile(
                  icon: Icons.handyman_outlined,
                  label: 'Providers', 
                  collapsed: collapsed,
                  isActive: _isActive('provider/'), 
                  trailing: collapsed
                      ? null
                      : Icon(
                          _providersOpen ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          size: 20,
                          color: const Color(0xFF9CA3AF),
                        ),
                  onTap: () => setState(() => _providersOpen = !_providersOpen),
                ),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _providersOpen && !collapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      NavTile(
                        icon: Icons.format_list_bulleted_rounded,
                        label: 'Provider List',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('provider/list'),
                        onTap: () => widget.onNav?.call('provider/list'),
                      ),
                      NavTile(
                        icon: Icons.person_add_alt,
                        label: 'Add Provider',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('provider/add'),
                        onTap: () => widget.onNav?.call('provider/add'),
                      ),
                      NavTile(
                        icon: Icons.pending_actions_outlined,
                        label: 'Onboarding Requests',
                        badge: 3, // Example Badge for pending requests
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('provider/onboarding'),
                        onTap: () => widget.onNav?.call('provider/onboarding'),
                      ),
                      NavTile(
  icon: Icons.calendar_today_outlined,
  label: 'Holidays',
  collapsed: collapsed,
  isChild: true, 
  isActive: _isActive('provider/holidays'), // Adjust route string if needed (e.g. 'provider/holidays')
  onTap: () => widget.onNav?.call('provider/holidays'),
),
NavTile(
  icon: Icons.settings_suggest_outlined, // Or Icons.storage_rounded
  label: 'Master Setup',
  collapsed: collapsed,
  isChild: true, // Set to false if you want it to be a main category
  isActive: _isActive('master/setup'),
  onTap: () => widget.onNav?.call('master/setup'),
),
NavTile(
  icon: Icons.account_balance_wallet_outlined,
  label: 'Withdraw Request',
  badge: 5, // Example badge for pending requests
  collapsed: collapsed,
  isChild: true,
  isActive: _isActive('provider/withdraw'),
  onTap: () => widget.onNav?.call('provider/withdraw'),
),
                    ],
                  ),
                ),

                // --- CUSTOMER MANAGEMENT SECTION ---
                SectionHeader('USER MANAGEMENT', hidden: collapsed),
                
                NavTile(
                  icon: Icons.people_outline_rounded,
                  label: 'Customers', 
                  collapsed: collapsed,
                  isActive: _isActive('customer/'), 
                  trailing: collapsed
                      ? null
                      : Icon(
                          _customersOpen ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          size: 20,
                          color: const Color(0xFF9CA3AF),
                        ),
                  onTap: () => setState(() => _customersOpen = !_customersOpen),
                ),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _customersOpen && !collapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      NavTile(
                        icon: Icons.recent_actors_outlined,
                        label: 'Customer List',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('customer/list'),
                        onTap: () => widget.onNav?.call('customer/list'),
                      ),
                    ],
                  ),
                ),

                // ============================================================
                // REFERRAL MANAGEMENT SECTION
                // ============================================================
                SectionHeader('REFERRAL MANAGEMENT', hidden: collapsed),

                NavTile(
                  icon: Icons.card_giftcard_outlined,
                  label: 'Referral Management',
                  collapsed: collapsed,
                  isActive: _isActive('referral/'),
                  trailing: collapsed
                      ? null
                      : Icon(
                          _referralsOpen ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          size: 20,
                          color: const Color(0xFF9CA3AF),
                        ),
                  onTap: () => setState(() => _referralsOpen = !_referralsOpen),
                ),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _referralsOpen && !collapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      NavTile(
                        icon: Icons.pending_actions_outlined,
                        label: 'Pending Rewards',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('referral/pending'),
                        onTap: () => widget.onNav?.call('referral/pending'),
                      ),
                      NavTile(
                        icon: Icons.payments_outlined,
                        label: 'Paid Commissions',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('referral/paid'),
                        onTap: () => widget.onNav?.call('referral/paid'),
                      ),
                      NavTile(
                        icon: Icons.local_offer_outlined,
                        label: 'Issued Coupons',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('referral/issued'),
                        onTap: () => widget.onNav?.call('referral/issued'),
                      ),
                    ],
                  ),
                ),

                // --- TRANSACTION REPORTS & ANALYTICS ---
                SectionHeader('TRANSACTION & ANALYTICS', hidden: collapsed),

                NavTile(
                  icon: Icons.description_outlined,
                  label: 'Reports',
                  collapsed: collapsed,
                  isActive: _isActive('report/'),
                  trailing: collapsed
                      ? null
                      : Icon(
                          _reportsOpen ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          size: 20,
                          color: const Color(0xFF9CA3AF),
                        ),
                  onTap: () => setState(() => _reportsOpen = !_reportsOpen),
                ),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _reportsOpen && !collapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      NavTile(
                        icon: Icons.receipt_long,
                        label: 'Provider Earn Report',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('report/transaction'),
                        onTap: () => widget.onNav?.call('report/transaction'),
                      ),
                      NavTile(
                        icon: Icons.summarize_outlined,
                        label: 'All Transaction Report',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('report/all-transactions'),
                        onTap: () =>
                            widget.onNav?.call('report/all-transactions'),
                      ),
                      NavTile(
                        icon: Icons.event_note,
                        label: 'Booking Analysis',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('report/booking'),
                        onTap: () => widget.onNav?.call('report/booking'),
                      ),
                      NavTile(
                        icon: Icons.badge_outlined,
                        label: 'Provider Settlement Report',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('report/provider'),
                        onTap: () => widget.onNav?.call('report/provider'),
                      ),
                    ],
                  ),
                ),

                NavTile(
                  icon: Icons.analytics_outlined,
                  label: 'Analytics',
                  collapsed: collapsed,
                  isActive: _isActive('analytics/'),
                  trailing: collapsed
                      ? null
                      : Icon(
                          _analyticsOpen ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          size: 20,
                          color: const Color(0xFF9CA3AF),
                        ),
                  onTap: () => setState(() => _analyticsOpen = !_analyticsOpen),
                ),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _analyticsOpen && !collapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      NavTile(
                        icon: Icons.search_rounded,
                        label: 'Keyword Search',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('analytics/keyword'),
                        onTap: () => widget.onNav?.call('analytics/keyword'),
                      ),
                    ],
                  ),
                ),

                // ============================================================
                // NEW: PROMOTION MANAGEMENT (RESTRUCTURED)
                // ============================================================
                SectionHeader('PROMOTION MANAGEMENT', hidden: collapsed),

                // 1. Promotion Banners (Separate, Top-Level)
                NavTile(
                  icon: Icons.image_outlined,
                  label: 'Sliding Banners',
                  collapsed: collapsed,
                  isActive: _isActive('promotion/banner'),
                  onTap: () => widget.onNav?.call('promotion/banner'),
                ),

                // 2. Discounts (Expandable Group)
                NavTile(
                  icon: Icons.local_offer_outlined,
                  label: 'Discounts',
                  collapsed: collapsed,
                  isActive: _isActive('promotion/discount'),
                  trailing: collapsed
                      ? null
                      : Icon(
                          _discountsOpen ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          size: 20,
                          color: const Color(0xFF9CA3AF),
                        ),
                  onTap: () => setState(() => _discountsOpen = !_discountsOpen),
                ),
                
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _discountsOpen && !collapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      NavTile(
                        icon: Icons.list_alt,
                        label: 'Discount List',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('promotion/discount/list'),
                        onTap: () => widget.onNav?.call('promotion/discount/list'),
                      ),
                      NavTile(
                        icon: Icons.add_circle_outline,
                        label: 'Add New Discount',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('promotion/discount/add'),
                        onTap: () => widget.onNav?.call('promotion/discount/add'),
                      ),
                    ],
                  ),
                ),

                // 3. Coupons (Expandable Group)
                NavTile(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Coupons',
                  collapsed: collapsed,
                  isActive: _isActive('promotion/coupon'),
                  trailing: collapsed
                      ? null
                      : Icon(
                          _couponsOpen ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          size: 20,
                          color: const Color(0xFF9CA3AF),
                        ),
                  onTap: () => setState(() => _couponsOpen = !_couponsOpen),
                ),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _couponsOpen && !collapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      NavTile(
                        icon: Icons.list_alt,
                        label: 'Coupon List',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('promotion/coupon/list'),
                        onTap: () => widget.onNav?.call('promotion/coupon/list'),
                      ),
                      NavTile(
                        icon: Icons.add_card_outlined,
                        label: 'Add New Coupon',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('promotion/coupon/add'),
                        onTap: () => widget.onNav?.call('promotion/coupon/add'),
                      ),
                    ],
                  ),
                ),

                // ============================================================
                // NOTIFICATION MANAGEMENT
                // ============================================================
                SectionHeader('NOTIFICATION MANAGEMENT', hidden: collapsed),

                NavTile(
                  icon: Icons.notifications_active_outlined,
                  label: 'Notifications',
                  collapsed: collapsed,
                  isActive: _isActive('notification/'),
                  trailing: collapsed
                      ? null
                      : Icon(
                          _notificationsOpen ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          size: 20,
                          color: const Color(0xFF9CA3AF),
                        ),
                  onTap: () => setState(() => _notificationsOpen = !_notificationsOpen),
                ),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _notificationsOpen && !collapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      NavTile(
                        icon: Icons.send_rounded,
                        label: 'Send Notification',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('notification/send'),
                        onTap: () => widget.onNav?.call('notification/send'),
                      ),
                      NavTile(
                        icon: Icons.tap_and_play,
                        label: 'Push Notifications',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('notification/push'),
                        onTap: () => widget.onNav?.call('notification/push'),
                      ),
                    ],
                  ),
                ),

                // ============================================================
                // EMPLOYEE MANAGEMENT SECTION
                // ============================================================
                SectionHeader('EMPLOYEE MANAGEMENT', hidden: collapsed),

                NavTile(
                  icon: Icons.supervisor_account_outlined,
                  label: 'Employees',
                  collapsed: collapsed,
                  isActive: _isActive('employee/'),
                  trailing: collapsed
                      ? null
                      : Icon(
                          _employeesOpen ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                          size: 20,
                          color: const Color(0xFF9CA3AF),
                        ),
                  onTap: () => setState(() => _employeesOpen = !_employeesOpen),
                ),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  crossFadeState: _employeesOpen && !collapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      NavTile(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Employee Role Setup',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('employee/role-setup'),
                        onTap: () => widget.onNav?.call('employee/role-setup'),
                      ),
                      NavTile(
                        icon: Icons.list_alt_rounded,
                        label: 'Employee List',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('employee/list'),
                        onTap: () => widget.onNav?.call('employee/list'),
                      ),
                      NavTile(
                        icon: Icons.person_add_alt_1_outlined,
                        label: 'Add New Employee',
                        collapsed: collapsed,
                        isChild: true,
                        isActive: _isActive('employee/add'),
                        onTap: () => widget.onNav?.call('employee/add'),
                      ),
                    ],
                  ),
                ),

                // --- ACCOUNT SECTION ---
SectionHeader('ACCOUNT', hidden: collapsed),
NavTile(
  icon: Icons.logout,
  label: 'Logout',
  collapsed: collapsed,
  onTap: () async {
    // 1. Clear Session & Cache
    await AuthRepository().logout();

    // 2. Perform Hard Reload for Web
    if (kIsWeb) {
      html.window.location.reload();
      return; // Reload will handle navigation
    }

    // 3. Fallback Navigation for Mobile
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false, 
      );
    }
  },
),
              ],
            ),
          ),
        ],
      ),
    );
  }
}