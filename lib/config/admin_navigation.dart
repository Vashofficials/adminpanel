import 'package:flutter/material.dart';

class NavItem {
  final String label;
  final String route;
  final IconData icon;
  final int? badge;
  final bool isHeader;

  NavItem({
    required this.label,
    required this.route,
    required this.icon,
    this.badge,
    this.isHeader = false,
  });
}

class AdminNavigation {
  // MAIN SECTION
  static final List<NavItem> main = [
    NavItem(label: 'Dashboard', route: 'dashboard', icon: Icons.dashboard_outlined),
  ];

  // BOOKING SECTION
  static final List<NavItem> bookings = [
    NavItem(label: 'Offline Payment', route: 'booking/offline', icon: Icons.receipt_long_outlined, badge: 6),
    NavItem(label: 'Ongoing', route: 'booking/ongoing', icon: Icons.timelapse_outlined, badge: 10),
    NavItem(label: 'Completed', route: 'booking/completed', icon: Icons.done_all_outlined, badge: 37),
    NavItem(label: 'Canceled', route: 'booking/canceled', icon: Icons.cancel_outlined, badge: 4),
  ];

  // SERVICE SECTION
  static final List<NavItem> services = [
    NavItem(label: 'Zone Map', route: 'zone/map', icon: Icons.layers_outlined),
    NavItem(label: 'Add Buffer', route: 'zone/bufferadd', icon: Icons.person_pin_circle_outlined),
    NavItem(label: 'Main Categories', route: 'service/categories', icon: Icons.grid_view_outlined),
    NavItem(label: 'Service Categories', route: 'service/subcategories', icon: Icons.schema_outlined),
    NavItem(label: 'Service List', route: 'service/list', icon: Icons.list_alt_outlined),
    NavItem(label: 'Add New Service', route: 'service/add', icon: Icons.add_circle_outline),
  ];

  // PROVIDER SECTION
  static final List<NavItem> providers = [
    NavItem(label: 'Provider List', route: 'provider/list', icon: Icons.format_list_bulleted_rounded),
    NavItem(label: 'Add Provider', route: 'provider/add', icon: Icons.person_add_alt),
    NavItem(label: 'Onboarding Requests', route: 'provider/onboarding', icon: Icons.pending_actions_outlined, badge: 3),
    NavItem(label: 'Holidays', route: 'provider/holidays', icon: Icons.calendar_today_outlined),
    NavItem(label: 'Master Setup', route: 'master/setup', icon: Icons.settings_suggest_outlined),
    NavItem(label: 'Withdraw Request', route: 'provider/withdraw', icon: Icons.account_balance_wallet_outlined, badge: 5),
    NavItem(label: 'Provider Settlement Action', route: 'report/provider', icon: Icons.badge_outlined),
    NavItem(label: 'Provider Rating', route: 'provider/rating', icon: Icons.star_rate_outlined),
  ];

  // USER SECTION
  static final List<NavItem> users = [
    NavItem(label: 'Customer List', route: 'customer/list', icon: Icons.recent_actors_outlined),
  ];

  // TRANSACTION SECTION
  static final List<NavItem> reports = [
    NavItem(label: 'Provider Earn Report', route: 'report/transaction', icon: Icons.receipt_long),
    NavItem(label: 'All Transaction Report', route: 'report/all-transactions', icon: Icons.summarize_outlined),
    NavItem(label: 'Booking Analysis', route: 'report/booking', icon: Icons.event_note),
    NavItem(label: 'Keyword Search', route: 'analytics/keyword', icon: Icons.search_rounded),
  ];

  // PROMOTION SECTION
  static final List<NavItem> promotions = [
    NavItem(label: 'Sliding Banners', route: 'promotion/banner', icon: Icons.image_outlined),
    NavItem(label: 'Discount List', route: 'promotion/discount/list', icon: Icons.list_alt),
    NavItem(label: 'Add New Discount', route: 'promotion/discount/add', icon: Icons.add_circle_outline),
    NavItem(label: 'Coupon List', route: 'promotion/coupon/list', icon: Icons.list_alt),
    NavItem(label: 'Add New Coupon', route: 'promotion/coupon/add', icon: Icons.add_card_outlined),
  ];

  // NOTIFICATION SECTION
  static final List<NavItem> notifications = [
    NavItem(label: 'Send Notification', route: 'notification/send', icon: Icons.send_rounded),
    NavItem(label: 'Push Notifications', route: 'notification/push', icon: Icons.tap_and_play),
  ];

  // EMPLOYEE SECTION
  static final List<NavItem> employees = [
    NavItem(label: 'Employee Role Setup', route: 'employee/role-setup', icon: Icons.admin_panel_settings_outlined),
    NavItem(label: 'Employee List', route: 'employee/list', icon: Icons.list_alt_rounded),
    NavItem(label: 'Add New Employee', route: 'employee/add', icon: Icons.person_add_alt_1_outlined),
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