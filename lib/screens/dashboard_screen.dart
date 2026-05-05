import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'employee_role_setup_screen.dart';
import 'employee_role_list_screen.dart';
import 'add_employee_screen.dart';
import 'send_notification_screen.dart';
import 'promotional_banners_screen.dart';
import 'update_discount_screen.dart';
// --- WIDGET IMPORTS ---
import '../widgets/dashboard_sidebar.dart';
import '../widgets/dashboard_topbar.dart';
import 'keyword_analytics_screen.dart';
// --- SCREEN IMPORTS ---
import 'ongoing_booking_screen.dart';
import 'CategoryScreen.dart';
import 'ServiceCategoryScreen.dart';
import 'ServiceScreen.dart'; 
import 'service_timing_management_screen.dart'; // <--- NEW SCREEN
import 'login_screen.dart';
import 'canceled_booking_screen.dart';
import 'completed_booking_screen.dart';
import 'offline_payment_screen.dart';
import 'customized_booking_screen.dart';
import 'pending_booking_screen.dart';
import 'add_service_screen.dart';
import 'booking_details_screen.dart'; 
import 'customer_list.dart';
import 'customer_update_screen.dart';
import 'customer_overview_screen.dart';
import 'transaction_report_screen.dart';
import 'booking_report_screen.dart';
import 'provider_report_screen.dart';
import 'all_transaction_report_screen.dart';
import 'employee_list_screen.dart';
import 'role_update_screen.dart';
import 'discount_list_screen.dart';
import 'discount_add_screen.dart';
import 'coupon_list_screen.dart';
import 'add_coupon_screen.dart';
import 'update_coupon_screen.dart';
import 'update_promotional_banner_screen.dart';
import 'zone_setup_screen.dart';
import 'provider_list_screen.dart';
import 'provider_add_screen.dart';
import 'provider_onboarding_request_screen.dart';
import '../models/customer_models.dart';
import 'buffer_config_screen.dart';
import 'holiday_management_screen.dart'; // <--- IMPORT THE NEW SCREEN
import 'provider_rating_screen.dart'; // <--- ADD THIS
import 'MasterSetupScreen.dart'; // <--- IMPORT THE NEW SCREEN
import 'withdraw_request_screen.dart'; // <--- ADD WITHDRAW REQUEST SCREEN
import 'referral_management_screen.dart'; // <--- ADD REFERRAL MANAGEMENT SCREEN
import '../models/booking_models.dart';
import '../models/employee_model.dart';
import '../controllers/provider_controller.dart';
import '../controllers/dashboard_controller.dart';
import 'refund_management_screen.dart';
import 'booking_overview_screen.dart';
import 'module_permssion-screen.dart'; // <--- ADD THIS IMPORT
import 'welcome_dashboard_screen.dart';
import '../services/permission_manager.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _collapsed = false;
  String _currentRoute = 'dashboard';
  Customer? _selectedCustomer; // <--- ADD THIS VARIABLE
 // Map<String, String>? _selectedBooking; 
  BookingModel? _selectedBooking;

  /// Holds the employee whose permissions are being viewed/edited.
  /// Set when navigating from EmployeeListScreen → ModulePermissionScreen.
  EmployeeModel? _permissionEmployee;

final ProviderController providerController = Get.put(ProviderController());

// Add this method to _DashboardScreenState
  void _viewBookingDetails(BookingModel booking) {
    setState(() {
      _selectedBooking = booking; // Save the full booking object
    });
  }

void _closeBookingDetails() {
  setState(() {
    _selectedBooking = null;
  });
}
bool _hasDashboardAccess() {
  return _can('dashboard_screen');
}
bool _can(String module) {
  return PermissionManager.can(module);
}

  Widget _getBody() {
    final hasAccess = _hasDashboardAccess();

    switch (_currentRoute) {
     case 'dashboard':
  if (!_can('dashboard_screen')) {
    return const WelcomeDashboardScreen();
  }
  return DashboardHome(onNav: _handleNavigation); 
      case 'booking/overview':
        return BookingOverviewScreen(
          onNav: _handleNavigation,
          onViewDetails: (booking) => _viewBookingDetails(booking),
        );

      case 'booking/all':
        return AllTransactionReportScreen(
          onViewDetails: (booking) => _viewBookingDetails(booking),
        );

      case 'booking/pending':
        return PendingBookingScreen(
          onViewDetails: (booking) => _viewBookingDetails(booking),
        );

      case 'booking/ongoing':
        return OngoingBookingScreen(
onViewDetails: (booking) => _viewBookingDetails(booking),        );  
        

      case 'booking/canceled':
        return CancelledBookingScreen(
onViewDetails: (booking) => _viewBookingDetails(booking),        );  

      case 'booking/completed':
        return CompletedBookingScreen(
onViewDetails: (booking) => _viewBookingDetails(booking),        );

      case 'booking/offline':
        return OfflinePaymentScreen(
         onViewDetails: (booking) => _viewBookingDetails(booking),        );
        
      case 'booking/customized':
        return const CustomizedBookingScreen();
        
      case 'service/categories':
        return const CategoryScreen();
        
      case 'service/subcategories':
        return const ServiceCategoryScreen();
        
      case 'service/list':
        return ServiceScreen(
          onAddService: () {
            setState(() {
              _currentRoute = 'service/add';
            });
          },
        );
        
      case 'service/add':     
        return AddServiceScreen(
          onCancel: () {
            setState(() {
              _currentRoute = 'service/list';
            });
          },
          onSave: (success) {
            if (success) {
              setState(() {
                _currentRoute = 'service/list';
              });
            }
          },
        );

      // --- SERVICE TIMINGS ---
      case 'service/timing':
        return const ServiceTimingManagementScreen();

      // --- CUSTOMER SECTION ---
      case 'customer/list':
        return CustomerListScreen(
onEditCustomer: (customer) {
            setState(() {
              _selectedCustomer = customer; // Store the customer to edit
              _currentRoute = 'customer/update'; // Navigate to update screen
            });
          },          // Capture the 'customer' data here
          onViewCustomer: (customer) {
            setState(() {
              _selectedCustomer = customer; // Store it
              _currentRoute = 'customer/overview'; // Navigate
            });
          },
        );

      case 'customer/overview':
        // Safety check: if accessed without selecting a user
        if (_selectedCustomer == null) {
          return const Center(child: Text("No customer selected. Please go back to the list."));
        }
        return CustomerOverviewScreen(
          customer: _selectedCustomer!, // Pass the stored customer here
          onBack: () => setState(() => _currentRoute = 'customer/list'),
          onEdit: () => setState(() => _currentRoute = 'customer/update'),
          onViewBooking: (booking) {
             _viewBookingDetails(booking); // This triggers the Dashboard to show BookingDetailsScreen
          },
        );

      case 'customer/update':
        // Safety check: if accessed without selecting a user
        if (_selectedCustomer == null) {
          return const Center(child: Text("No customer selected for update. Please go back to the list."));
        }
        
        return CustomerUpdateScreen(
          customer: _selectedCustomer!, // PASS THE DATA HERE
          onBack: () {
            // Switch back to list
            setState(() {
              _currentRoute = 'customer/list';
            });
          },
        );
      // --- REPORTS ---
      case 'report/transaction':
        return TransactionReportScreen();
      case 'report/all-transactions':
        return AllTransactionReportScreen(
          onViewDetails: (booking) => _viewBookingDetails(booking),
        );
      case 'report/booking':
        return BookingReportScreen();
      case 'report/provider':
        return ProviderReportScreen();
      case 'analytics/keyword':
          return const KeywordAnalyticsScreen();   
      
      // --- EMPLOYEES ---
      case 'employee/role-setup': 
        return EmployeeRoleListScreen(
          onAddRole: () => setState(() => _currentRoute = 'employee/role-add'),
          onEditRole: () => setState(() => _currentRoute = 'employee/role-update'),
        );
      
      case 'employee/role-add':
        return EmployeeRoleSetupScreen(
           onBack: () => setState(() => _currentRoute = 'employee/role-setup'),
        );

      case 'employee/role-update':
        return const RoleUpdateScreen(); 

       case 'employee/list':
        return EmployeeListScreen(
          onAddEmployee: () {
            setState(() {
              _currentRoute = 'employee/add';
            });
          },
          onViewPermissions: (employee) {
            setState(() {
              _permissionEmployee = employee;
              _currentRoute = 'employee/permission';
            });
          },
        );

      case 'employee/add':  
        return const AddEmployeeScreen();
      case 'employee/permission':
        return ModulePermissionScreen(preSelectedEmployee: _permissionEmployee);  

      // --- PROMOTIONS ---
      case 'promotion/banner':  
        return  PromotionalBannersScreen(
          onUpdateBanner: () {
            setState(() {
              _currentRoute = 'promotion/banner/update';
            });
          },
        );
      case 'promotion/banner/update':
        return const UpdatePromotionalBannerScreen();  
      case 'promotion/discount/list':
        return DiscountListScreen(
          onEditDiscount: () {
            setState(() {
              _currentRoute = 'promotion/discount/update';
            });
          },
        );

      case 'promotion/discount/update':
        return const UpdateDiscountScreen(); 
      case 'promotion/discount/add':
        return const AddDiscountScreen();
      case 'promotion/coupon/list':
        return  CouponListScreen(
          onEditCoupon: () {
          setState(() {
            _currentRoute = 'promotion/coupon/update';
          });
        },
        );
      case 'promotion/coupon/update':
        return const UpdateCouponScreen();
      case 'promotion/coupon/add':
        return const AddCouponScreen();
        
      // --- OTHERS ---
      case 'notification/send':
        return const SendNotificationScreen(); 
      case 'zone/map':
        return  LocationManagementScreen(); 
      case 'zone/bufferadd':
        return const BufferConfigScreen();

      // --- PROVIDERS ---
      case 'provider/list': 
    return ProviderListScreen(
      // This creates the link! When 'onNav' is called inside ProviderListScreen,
      // it runs this code to update the Dashboard's route.
      onNav: (route) {
        setState(() {
          _currentRoute = route;
        });
      },
    );

  // --- ADD PROVIDER ---
  case 'provider/add': 
    return AddProviderScreen(
      onBack: () {
        setState(() {
          // deciding where 'Back' takes you (List or Onboarding)
          _currentRoute = 'provider/list'; 
        });
      },
    );

  // --- ONBOARDING REQUESTS ---
  case 'provider/onboarding': 
    return ProviderOnboardingRequestScreen(
      onViewRequest: (requestData) {
        setState(() {
          // If you have logic to pass data, do it here
          var _selectedOnboardingRequest = requestData; 
          _currentRoute = 'provider/add'; 
        });
      },
    );

  // --- HOLIDAYS ---
  case 'provider/holidays':
    return HolidayManagementScreen();
  
  // --- WITHDRAW REQUEST ---
  case 'provider/withdraw':
    return const WithdrawRequestScreen();

  case 'provider/rating':
    return ProviderRatingScreen();

  case 'master/setup':
    return const MasterSetupScreen();

  // --- REFERRAL MANAGEMENT ---
  case 'referral/pending':
    return PendingRewardsScreen(onNav: _handleNavigation);
  case 'referral/paid':
    return PaidCommissionsScreen(onNav: _handleNavigation);
  case 'referral/issued':
    return IssuedCouponsScreen(onNav: _handleNavigation);
  case 'customer/refund':
  return const RefundRequestScreen();  

    
  

      default:
        return const DashboardHome();
    }
  }
  void _handleNavigation(String route) {
    if (route == 'auth/login') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _currentRoute = route;
        _selectedBooking = null; 
        _selectedCustomer = null; // Clear selections when navigating via search
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        children: [
          DashboardSidebar(
            collapsed: _collapsed,
            currentRoute: _currentRoute, 
            onNav: _handleNavigation,
          ),
          Expanded(
            child: Column(
              children: [
                DashboardTopBar(
                  onMenuTap: () => setState(() => _collapsed = !_collapsed),
                  onNav: _handleNavigation,
                 // onLogout: () => _handleNavigation('auth/login'),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(0), 
                    child: Stack(
                      children: [
                        Offstage(
                          offstage: _selectedBooking != null,
                          child: _getBody(),
                        ),
                        if (_selectedBooking != null)
                          BookingDetailsScreen(
                            booking: _selectedBooking!,
                            onBack: _closeBookingDetails,
                          ),
                      ],
                    ),
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

// -----------------------------------------------------------------------------
// DASHBOARD HOME CONTENT (COMPREHENSIVE OVERVIEW)
// -----------------------------------------------------------------------------
class DashboardHome extends StatelessWidget {
  final Function(String)? onNav;

  const DashboardHome({super.key, this.onNav});

  String _formatCurrency(double amount) {
    // Show full number with Indian comma formatting (e.g. ₹1,20,947)
    final int value = amount.toInt();
    final String digits = value.toString();
    if (digits.length <= 3) return '₹$digits';

    // Indian numbering: last 3 digits, then groups of 2
    final String last3 = digits.substring(digits.length - 3);
    final String remaining = digits.substring(0, digits.length - 3);
    final StringBuffer buf = StringBuffer();
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) buf.write(',');
      buf.write(remaining[i]);
    }
    return '₹${buf.toString()},$last3';
  }

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.put(DashboardController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title + Refresh + Export
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Dashboard Overview", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                        Text("Welcome back! Here's what's happening on your platform.", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Refresh Button
                    Obx(() => Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: controller.isRefreshing.value ? null : () => controller.manualRefresh(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4361EE).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF4361EE).withValues(alpha: 0.3)),
                          ),
                          child: controller.isRefreshing.value
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4361EE)))
                              : const Icon(Icons.refresh, size: 20, color: Color(0xFF4361EE)),
                        ),
                      ),
                    )),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => controller.exportDashboardData(),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text("Export Report"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- KPI CARDS: 2 ROWS × 3 COLUMNS ---
            LayoutBuilder(builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1);
              double spacing = 16.0;
              double width = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  // 1. Collection Card
                  SizedBox(
                    width: width,
                    child: _UpgradedStatCard(
                      title: "All Time Collection",
                      mainValue: _formatCurrency(controller.allTimeCollection.value),
                      icon: Icons.currency_rupee,
                      color: const Color(0xFF4361EE),
                      isPrimary: true,
                      subItems: [
                        _SubItem("Today", _formatCurrency(controller.todayCollection.value)),
                      ],
                    ),
                  ),

                  // 2. Orders Card
                  SizedBox(
                    width: width,
                    child: _UpgradedStatCard(
                      title: "Total Bookings",
                      mainValue: controller.totalOrders.value.toString(),
                      icon: Icons.shopping_cart,
                      color: const Color(0xFF10B981),
                      subItems: [
                        _SubItem("Today", controller.todayOrders.value.toString()),
                        _SubItem("Completed", controller.totalCompleted.value.toString(), itemColor: const Color(0xFF10B981)),
                        _SubItem("Today Completed", controller.todayCompleted.value.toString(), itemColor: const Color(0xFF10B981)),
                      ],
                    ),
                  ),

                  // 3. Providers Card
                  SizedBox(
                    width: width,
                    child: _UpgradedStatCard(
                      title: "Total Providers",
                      mainValue: controller.totalProviders.value.toString(),
                      icon: Icons.handyman,
                      color: const Color(0xFFF59E0B),
                      subItems: [
                        _SubItem("Approved", controller.approvedProviders.value.toString(), itemColor: const Color(0xFF10B981)),
                        _SubItem("Un Approved", controller.unApprovedProviders.value.toString(), itemColor: const Color(0xFFEF4444)),
                        _SubItem("Today Active", controller.todayActiveProviders.value.toString(), itemColor: const Color(0xFF10B981)),
                      ],
                    ),
                  ),

                  // 4. Pending Card
                  SizedBox(
                    width: width,
                    child: _UpgradedStatCard(
                      title: "Total Pending",
                      mainValue: controller.totalPending.value.toString(),
                      icon: Icons.pending_actions,
                      color: const Color(0xFF8B5CF6),
                      subItems: [
                        _SubItem("Today", controller.todayPending.value.toString()),
                      ],
                    ),
                  ),

                  // 5. Cancellations Card
                  SizedBox(
                    width: width,
                    child: _UpgradedStatCard(
                      title: "Total Cancelled",
                      mainValue: controller.totalCancelled.value.toString(),
                      icon: Icons.cancel,
                      color: const Color(0xFFEF4444),
                      subItems: [
                        _SubItem("Today", controller.todayCancelled.value.toString()),
                      ],
                    ),
                  ),


                  // 7. Users Card
                  SizedBox(
                    width: width,
                    child: _UpgradedStatCard(
                      title: "Total Users",
                      mainValue: controller.totalUsers.value.toString(),
                      icon: Icons.group,
                      color: const Color(0xFF3B82F6),
                      subItems: [
                        _SubItem("Active", controller.activeUsers.value.toString(), itemColor: const Color(0xFF10B981)),
                        _SubItem("Inactive", controller.inactiveUsers.value.toString(), itemColor: const Color(0xFFEF4444)),
                      ],
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),

            // 2. Charts Row: Revenue/Bookings Trend, Orders by Category, Top Providers by Rating
            LayoutBuilder(builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 1200;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: const RevenueBookingsTrend()),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: const OrdersByCategoryChart()),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: const TopProvidersList()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    const RevenueBookingsTrend(),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: const OrdersByCategoryChart()),
                        const SizedBox(width: 24),
                        Expanded(child: const TopProvidersList()),
                      ],
                    ),
                  ],
                );
              }
            }),

          ],
        ),
      );
    });
  }
}

// -----------------------------------------------------------------------------
// HELPER: Sub-item data for upgraded stat cards
// -----------------------------------------------------------------------------
class _SubItem {
  final String label;
  final String value;
  final Color? itemColor;
  const _SubItem(this.label, this.value, {this.itemColor});
}

// -----------------------------------------------------------------------------
// UPGRADED STAT CARD (Total + Today / Active + Inactive)
// -----------------------------------------------------------------------------
class _UpgradedStatCard extends StatelessWidget {
  final String title;
  final String mainValue;
  final IconData icon;
  final Color color;
  final bool isPrimary;
  final List<_SubItem> subItems;

  const _UpgradedStatCard({
    required this.title,
    required this.mainValue,
    required this.icon,
    required this.color,
    this.isPrimary = false,
    required this.subItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary ? color : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPrimary ? null : Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? color.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isPrimary ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title + Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isPrimary ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPrimary ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? Colors.white : color,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Value (BIG)
          Text(
            mainValue,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: isPrimary ? Colors.white : const Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Divider
          Divider(
            color: isPrimary ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade200,
            height: 1,
          ),
          const SizedBox(height: 12),

          // Sub Items Row
          Row(
            children: subItems.map((item) {
              final isLast = item == subItems.last;
              return Expanded(
                child: Row(
                  children: [
                    if (item != subItems.first)
                      Container(
                        width: 1,
                        height: 28,
                        margin: const EdgeInsets.only(right: 12),
                        color: isPrimary ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade200,
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isPrimary ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade500,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: TextStyle(
                              color: isPrimary
                                  ? Colors.white
                                  : (item.itemColor ?? color),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}


class RevenueBookingsTrend extends StatelessWidget {
  const RevenueBookingsTrend({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();
    
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Monthly Bookings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Row(
                children: [
                  _buildLegendItem("Bookings", const Color(0xFF4361EE)),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Obx(() {
              if (controller.chartData.isEmpty) {
                return const Center(child: Text("No booking data available", style: TextStyle(color: Colors.grey)));
              }

              // Build bar groups from monthly booking counts
              List<BarChartGroupData> barGroups = [];
              double maxY = 0;
              for (int i = 0; i < controller.chartData.length; i++) {
                final month = controller.chartData[i];
                final total = (month.cashBooking ?? 0).toDouble();
                if (total > maxY) maxY = total;
                barGroups.add(
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: total,
                        width: 18,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4361EE), Color(0xFF7C3AED)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Add 20% padding to maxY for breathing room
              maxY = maxY > 0 ? (maxY * 1.25).ceilToDouble() : 10;

              return BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String monthName = controller.chartData[group.x].mothName ?? '';
                        return BarTooltipItem(
                          '$monthName\n${rod.toY.toInt()} bookings',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, 
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int idx = value.toInt();
                          if (idx >= 0 && idx < controller.chartData.length) {
                             String name = controller.chartData[idx].mothName?.substring(0, 3) ?? "";
                             return Padding(
                               padding: const EdgeInsets.only(top: 8.0),
                               child: Text(name, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                             );
                          }
                          return const Text("");
                        }
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
      ],
    );
  }
}

class OrdersByCategoryChart extends StatelessWidget {
  const OrdersByCategoryChart({super.key});

  static const List<Color> _chartColors = [
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFFF97316),
  ];

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Orders by Category", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.categoryNames.isEmpty || controller.categoryCounts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final int totalOrders = controller.categoryCounts.fold(0, (sum, c) => sum + c);
              if (totalOrders == 0) {
                return const Center(child: Text("No category data", style: TextStyle(color: Colors.grey)));
              }

              // Build pie sections
              final List<PieChartSectionData> sections = [];
              for (int i = 0; i < controller.categoryNames.length; i++) {
                final count = controller.categoryCounts[i];
                final double pct = (count / totalOrders) * 100;
                sections.add(
                  PieChartSectionData(
                    color: _chartColors[i % _chartColors.length],
                    value: count.toDouble(),
                    title: '${pct.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    radius: 50,
                    titlePositionPercentageOffset: 0.55,
                  ),
                );
              }

              return Column(
                children: [
                  // Donut Chart
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(controller.categoryNames.length, (i) {
                      final name = controller.categoryNames[i];
                      final count = controller.categoryCounts[i];
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _chartColors[i % _chartColors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$name ($count)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class RecentNotifications extends StatelessWidget {
  const RecentNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock notifications for now
    final List<Map<String, dynamic>> notifications = [
      {"title": "New Booking (#BK-0092)", "time": "10 mins ago", "icon": Icons.book, "color": Colors.blue},
      {"title": "Provider 'Amit' registered", "time": "45 mins ago", "icon": Icons.person_add, "color": Colors.green},
      {"title": "Booking (#BK-0081) cancelled", "time": "2 hours ago", "icon": Icons.cancel, "color": Colors.red},
      {"title": "Low wallet balance warning", "time": "5 hours ago", "icon": Icons.warning, "color": Colors.orange},
      {"title": "Payout completed successfully", "time": "1 day ago", "icon": Icons.account_balance_wallet, "color": Colors.purple},
    ];

    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Recent Notifications", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              TextButton(onPressed: () {}, child: const Text("View All", style: TextStyle(fontSize: 13))),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (c, i) => Divider(color: Colors.grey.shade100, height: 16),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: notif['color'].withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(notif['icon'], color: notif['color'], size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notif['title'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                          Text(notif['time'], style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TopProvidersList extends StatelessWidget {
  const TopProvidersList({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();

    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Top Providers by Rating", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              TextButton(onPressed: () {}, child: const Text("View All", style: TextStyle(fontSize: 13))),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              final providers = controller.topProviders;
              if (providers.isEmpty) {
                return const Center(child: Text("No Data Available", style: TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                itemCount: providers.length,
                itemBuilder: (context, index) {
                  final provider = providers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFE0E7FF),
                          backgroundImage: (provider.imageUrl != null && provider.imageUrl!.isNotEmpty)
                              ? NetworkImage(provider.imageUrl!)
                              : null,
                          child: (provider.imageUrl == null || provider.imageUrl!.isEmpty)
                              ? Text(provider.firstName[0], style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(provider.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text("${provider.city ?? 'Lucknow'} • ${provider.isAadharVerified ? 'Verified' : 'Unverified'}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Icon(Icons.star, color: Colors.orange.shade400, size: 14),
                              const SizedBox(width: 4),
                              Text(provider.totalRating.toStringAsFixed(1), style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
