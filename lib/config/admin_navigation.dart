import 'package:flutter/material.dart';

class NavItem {
  final String label;
  final String route;
  final IconData icon;
  final int? badge;
  final bool isHeader;
  final String? permissionKey;


  NavItem({
    required this.label,
    required this.route,
    required this.icon,
    this.badge,
    this.isHeader = false,
    this.permissionKey,
  });
}

class AdminNavigation {
  // MAIN SECTION
  static final List<NavItem> main = [
    NavItem(label: 'Dashboard', route: 'dashboard', icon: Icons.dashboard_outlined, permissionKey: 'dashboard_screen'),
  ];

  // BOOKING SECTION
  static final List<NavItem> bookings = [
    NavItem(label: 'Offline Payment', route: 'booking/offline', icon: Icons.receipt_long_outlined, badge: 6,permissionKey: 'booking_management'),
    NavItem(label: 'Ongoing', route: 'booking/ongoing', icon: Icons.timelapse_outlined, badge: 10,permissionKey: 'booking_management'),
    NavItem(label: 'Completed', route: 'booking/completed', icon: Icons.done_all_outlined, badge: 37,permissionKey: 'booking_management'),
    NavItem(label: 'Cancelled', route: 'booking/canceled', icon: Icons.cancel_outlined, badge: 4,permissionKey: 'booking_management'),
  ];

  // SERVICE SECTION
  static final List<NavItem> services = [
    NavItem(label: 'Zone Map', route: 'zone/map', icon: Icons.layers_outlined,permissionKey: 'service_management'),
    NavItem(label: 'Add Buffer', route: 'zone/bufferadd', icon: Icons.person_pin_circle_outlined,permissionKey: 'service_management'),
    NavItem(label: 'Main Categories', route: 'service/categories', icon: Icons.grid_view_outlined,permissionKey: 'service_management'),
    NavItem(label: 'Service Categories', route: 'service/subcategories', icon: Icons.schema_outlined,permissionKey: 'service_management'),
    NavItem(label: 'Service List', route: 'service/list', icon: Icons.list_alt_outlined,permissionKey: 'service_management'),
    NavItem(label: 'Add New Service', route: 'service/add', icon: Icons.add_circle_outline,permissionKey: 'service_management'),
  ];

  // PROVIDER SECTION
  static final List<NavItem> providers = [
    NavItem(label: 'Provider List', route: 'provider/list', icon: Icons.format_list_bulleted_rounded,  permissionKey: 'provider_management'),
    NavItem(label: 'Add Provider', route: 'provider/add', icon: Icons.person_add_alt,permissionKey: 'provider_management',),
    NavItem(label: 'Onboarding Requests', route: 'provider/onboarding', icon: Icons.pending_actions_outlined, badge: 3,  permissionKey: 'provider_management'),
    NavItem(label: 'Holidays', route: 'provider/holidays', icon: Icons.calendar_today_outlined ,permissionKey: 'provider_management'),
    NavItem(label: 'Master Setup', route: 'master/setup', icon: Icons.settings_suggest_outlined,  permissionKey: 'provider_management'),
    NavItem(label: 'Withdraw Request', route: 'provider/withdraw', icon: Icons.account_balance_wallet_outlined, badge: 5,  permissionKey: 'provider_management'),
    NavItem(label: 'Provider Settlement Action', route: 'report/provider', icon: Icons.badge_outlined,  permissionKey: 'provider_management'),
    NavItem(label: 'Provider Rating', route: 'provider/rating', icon: Icons.star_rate_outlined,  permissionKey: 'provider_management'),
  ];

  // USER SECTION
  static final List<NavItem> users = [
    NavItem(label: 'Customer List', route: 'customer/list', icon: Icons.recent_actors_outlined, permissionKey: 'customer_management'),
  ];

  // TRANSACTION SECTION
  static final List<NavItem> reports = [
    NavItem(label: 'Provider Earn Report', route: 'report/transaction', icon: Icons.receipt_long, permissionKey: 'report_analytics'),
    NavItem(label: 'All Transaction Report', route: 'report/all-transactions', icon: Icons.summarize_outlined, permissionKey: 'report_analytics'),
    NavItem(label: 'Booking Analysis', route: 'report/booking', icon: Icons.event_note, permissionKey: 'report_analytics'),
    NavItem(label: 'Keyword Search', route: 'analytics/keyword', icon: Icons.search_rounded, permissionKey: 'report_analytics'),
  ];

  // PROMOTION SECTION
  static final List<NavItem> promotions = [
    NavItem(label: 'Sliding Banners', route: 'promotion/banner', icon: Icons.image_outlined, permissionKey: 'promotion_management'),
    NavItem(label: 'Discount List', route: 'promotion/discount/list', icon: Icons.list_alt, permissionKey: 'promotion_management'),
    NavItem(label: 'Add New Discount', route: 'promotion/discount/add', icon: Icons.add_circle_outline, permissionKey: 'promotion_management'),
    NavItem(label: 'Coupon List', route: 'promotion/coupon/list', icon: Icons.list_alt, permissionKey: 'promotion_management'),
    NavItem(label: 'Add New Coupon', route: 'promotion/coupon/add', icon: Icons.add_card_outlined, permissionKey: 'promotion_management'),
  ];

  // NOTIFICATION SECTION
  static final List<NavItem> notifications = [
    NavItem(label: 'Send Notification', route: 'notification/send', icon: Icons.send_rounded, permissionKey: 'notification_management'),
    NavItem(label: 'Push Notifications', route: 'notification/push', icon: Icons.tap_and_play, permissionKey: 'notification_management'),
  ];

  // EMPLOYEE SECTION
  static final List<NavItem> employees = [
    NavItem(label: 'Module Setup', route: 'employee/role-setup', icon: Icons.admin_panel_settings_outlined, permissionKey: 'employee_management'),
    NavItem(label: 'Employee List', route: 'employee/list', icon: Icons.list_alt_rounded, permissionKey: 'employee_management'),
    NavItem(label: 'Add New Employee', route: 'employee/add', icon: Icons.person_add_alt_1_outlined, permissionKey: 'employee_management'),
    NavItem(label: 'Module Permission', route: 'employee/permission', icon: Icons.person_add_alt_1_outlined, permissionKey: 'employee_management'),

  ];

  /// FLATTENED LIST FOR SEARCH
  /// This combines everything into one list that your search bar can use.
  static List<NavItem> get searchRegistry => [
        ...main,
        ...bookings,
        ...services,
        ...providers,
        ...users,
        ...reports,
        ...promotions,
        ...notifications,
        ...employees,
      ];
}