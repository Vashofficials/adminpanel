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

  // If a booking is selected, show the Details Screen
  if (_selectedBooking != null) {
    return BookingDetailsScreen(
      booking: _selectedBooking!, // <--- Passing full BookingModel object
      onBack: _closeBookingDetails,
    );
  }

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
        );

      case 'employee/add':  
        return const AddEmployeeScreen();
      case 'employee/permission':
        return const ModulePermissionScreen();  

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
                    child: _getBody(),
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
            // Header Row: Title & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dashboard Overview", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    Text("Welcome back! Here's what's happening on your platform today.", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text("26 Apr 2026 - 26 May 2026", style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                          const SizedBox(width: 8),
                          Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
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
              ],
            ),
            const SizedBox(height: 24),

            // 1. Primary KPI Cards (6 cards)
            LayoutBuilder(builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 1400 ? 6 : (constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1));
              double spacing = 16.0;
              double width = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(width: width, child: StatCard(isPrimary: true, title: "Total Collection", value: "₹${controller.todayRevenue.value.toStringAsFixed(0)}", icon: Icons.currency_rupee, color: const Color(0xFF4361EE), subtitle: "+8% from yesterday")),
                  SizedBox(width: width, child: StatCard(title: "Orders Today", value: controller.todayBookings.value.toString(), icon: Icons.shopping_cart, color: const Color(0xFF10B981), subtitle: "+5% from yesterday")),
                  SizedBox(width: width, child: StatCard(title: "Active Providers", value: controller.totalProviders.value.toString(), icon: Icons.handyman, color: const Color(0xFFF59E0B), subtitle: "Currently online")),
                  SizedBox(width: width, child: StatCard(title: "Pending Assignments", value: controller.pendingBookings.value.toString(), icon: Icons.pending_actions, color: const Color(0xFF8B5CF6), subtitle: "Needs action")),
                  SizedBox(width: width, child: StatCard(title: "Cancellations", value: controller.cancelledBookings.value.toString(), icon: Icons.cancel, color: const Color(0xFFEF4444), subtitle: "Today's cancellations")),
                  SizedBox(width: width, child: StatCard(title: "Total Users", value: controller.totalCustomers.value.toString(), icon: Icons.group, color: const Color(0xFF3B82F6), subtitle: "Registered customers")),
                ],
              );
            }),
            const SizedBox(height: 24),

            // 2. Charts Row: Revenue/Bookings Trend, Booking Status, Recent Notifications
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
                    Expanded(flex: 3, child: const RecentNotifications()),
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
                        Expanded(child: const RecentNotifications()),
                      ],
                    ),
                  ],
                );
              }
            }),

            const SizedBox(height: 24),

            // 4. Tables Row: Top Services, Top Providers, Platform Summary
            LayoutBuilder(builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 1000;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: const TopServicesList()),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: const TopProvidersList()),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: const PlatformSummary()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    const TopServicesList(),
                    const SizedBox(height: 24),
                    const TopProvidersList(),
                    const SizedBox(height: 24),
                    const PlatformSummary(),
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
// HELPER WIDGETS
// -----------------------------------------------------------------------------

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final bool isPrimary;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary ? color : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary ? null : Border.all(color: color.withOpacity(0.5)),
        boxShadow: [
          if (isPrimary)
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isPrimary ? Colors.white.withOpacity(0.9) : const Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPrimary ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? Colors.white : color,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isPrimary ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: isPrimary ? Colors.white.withOpacity(0.8) : color.withOpacity(0.8),
              fontSize: 13,
            ),
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
              const Text("7-Day Revenue Trend", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Row(
                children: [
                  _buildLegendItem("Revenue", const Color(0xFF2563EB)),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Obx(() {
              if (controller.chartData.isEmpty) {
                return const Center(child: Text("No trending data available", style: TextStyle(color: Colors.grey)));
              }

              List<FlSpot> spots = [];
              for (int i = 0; i < controller.chartData.length; i++) {
                final month = controller.chartData[i];
                final total = (month.cashBooking ?? 0) + (month.onlineBooking ?? 0);
                spots.add(FlSpot(i.toDouble(), total.toDouble()));
              }

              return LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)))),
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
                               child: Text(name, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
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
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF2563EB),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: const Color(0xFF2563EB).withOpacity(0.1)),
                    ),
                  ],
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
          const SizedBox(height: 32),
          Expanded(
            child: Obx(() {
              if (controller.categoryNames.isEmpty || controller.categoryCounts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              
              double maxY = controller.categoryCounts.reduce((curr, next) => curr > next ? curr : next).toDouble() * 1.2;
              if (maxY == 0) maxY = 100;

              return BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const style = TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 12);
                          int index = value.toInt();
                          String text = '';
                          if (index >= 0 && index < controller.categoryNames.length) {
                             text = controller.categoryNames[index];
                          }
                          if (text.length > 10) text = '${text.substring(0, 8)}..';
                          return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(text, style: style));
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: List.generate(controller.categoryCounts.length, (i) {
                     final colors = [
                        const Color(0xFF10B981),
                        const Color(0xFF3B82F6),
                        const Color(0xFFF59E0B),
                        const Color(0xFFEF4444),
                        const Color(0xFF8B5CF6)
                     ];
                     return BarChartGroupData(
                       x: i,
                       barRods: [
                         BarChartRodData(
                           toY: controller.categoryCounts[i].toDouble(), 
                           color: colors[i % colors.length], 
                           width: 16, 
                           borderRadius: BorderRadius.circular(4)
                         )
                       ]
                     );
                  }),
                ),
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

class TopServicesList extends StatelessWidget {
  const TopServicesList({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock top services data
    final List<Map<String, dynamic>> services = [
      {"name": "AC Repair & Servicing", "category": "Appliance Repair", "bookings": 420, "revenue": "₹2.5L"},
      {"name": "Full Home Cleaning", "category": "Cleaning", "bookings": 350, "revenue": "₹1.8L"},
      {"name": "Bridal Makeup", "category": "Salon & Beauty", "bookings": 210, "revenue": "₹3.2L"},
      {"name": "Plumbing Service", "category": "Home Repairs", "bookings": 380, "revenue": "₹0.9L"},
      {"name": "Pest Control", "category": "Cleaning", "bookings": 150, "revenue": "₹0.6L"},
    ];

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
              const Text("Top 5 Services Today", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              TextButton(onPressed: () {}, child: const Text("View All", style: TextStyle(fontSize: 13))),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) {
                final svc = services[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text("${index + 1}", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(svc['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(svc['category'], style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(svc['revenue'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          Text("${svc['bookings']} Bookings", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
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

class PlatformSummary extends StatelessWidget {
  const PlatformSummary({super.key});

  @override
  Widget build(BuildContext context) {
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
          const Text("Platform Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              children: [
                _buildSummaryRow("App Downloads", "12,450", "+15%"),
                const Divider(),
                _buildSummaryRow("Active Users (Monthly)", "8,210", "+5%"),
                const Divider(),
                _buildSummaryRow("Avg. Booking Value", "₹1,250", "+2%"),
                const Divider(),
                _buildSummaryRow("Refund Rate", "1.2%", "-0.5%"),
                const Divider(),
                _buildSummaryRow("Customer Retention", "68%", "+4%"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, String trend) {
    bool isPositive = trend.startsWith("+");
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          Row(
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: isPositive ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text(trend, style: TextStyle(color: isPositive ? Colors.green.shade700 : Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }
}