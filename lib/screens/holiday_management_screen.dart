import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/holiday_controller.dart';
// Import the reusable searchable sheet
import '../widgets/searchable_selection_sheet.dart'; 

class HolidayManagementScreen extends StatelessWidget {
  HolidayManagementScreen({super.key});

  final HolidayController controller = Get.put(HolidayController());

  // --- Design System Colors ---
  final Color primaryOrange = const Color(0xFFF97316);
  final Color textDark = const Color(0xFF1E293B);
  final Color textGrey = const Color(0xFF64748B);
  final Color borderGrey = const Color(0xFFE2E8F0);
  final Color bgLight = const Color(0xFFFAFAFA); 
  
  // Status Colors
  final Color greenBg = const Color(0xFFECFDF5);
  final Color greenText = const Color(0xFF059669);
  
  final Color redBg = const Color(0xFFFEF2F2);
  final Color redText = const Color(0xFFDC2626);
  
  final Color amBg = const Color(0xFFFFF7ED); // Light Orange
  final Color amText = const Color(0xFFEA580C);
  
  final Color pmBg = const Color(0xFFEFF6FF); // Light Blue
  final Color pmText = const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Holiday Management", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderGrey, height: 1),
        ),
        iconTheme: IconThemeData(color: textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Text("Provider Availability & Holidays", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textDark)),
            const SizedBox(height: 8),
            Text("Check availability buffers (T+3 days) and manage holiday schedules for service providers.", style: TextStyle(color: textGrey, fontSize: 14)),
            const SizedBox(height: 32),

            // --- 1. SELECTION BAR (Updated to use Searchable Sheet) ---
            _buildSelectionBar(context),
            const SizedBox(height: 32),

            // --- 2. MAIN CONTENT ---
            Obx(() {
              // Check if a provider is selected
              bool isSelected = controller.selectedProviderId.value != null;

              if (!isSelected) {
                return _buildEmptyState();
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT: CALENDAR (Flex 2)
                  Expanded(
                    flex: 2,
                    child: _buildCalendarCard(),
                  ),
                  const SizedBox(width: 24),
                  
                  // RIGHT: STATUS & BUFFER (Flex 1)
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildBufferCard(context),
                        const SizedBox(height: 24),
                        _buildLegendCard(),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildEmptyState() {
    return Container(
      height: 400,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
            child: Icon(Icons.person_search_rounded, size: 48, color: primaryOrange),
          ),
          const SizedBox(height: 24),
          Text("No Provider Selected", style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Please select a provider from the dropdown above\nto view their schedule and manage holidays.", textAlign: TextAlign.center, style: TextStyle(color: textGrey)),
        ],
      ),
    );
  }

  // --- UPDATED SELECTION BAR ---
  Widget _buildSelectionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderGrey),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("SELECT PROVIDER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textGrey, letterSpacing: 1.0)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(() {
                  final isLoading = controller.providerController.isLoading.value;
                  if (isLoading) return const SizedBox(height: 48, child: Center(child: LinearProgressIndicator()));

                  // Find Selected Provider Object for Display Text
                  final selectedId = controller.selectedProviderId.value;
                  final selectedProvider = controller.providerController.allProviders.firstWhereOrNull((p) => p.id == selectedId);
                  
                  final displayText = selectedProvider != null 
                      ? "${selectedProvider.firstName ?? ''} ${selectedProvider.lastName ?? ''} (${selectedProvider.mobileNo})"
                      : "Choose a service provider...";

                  // --- NEW: InkWell Trigger for Searchable Sheet ---
                  return InkWell(
                    onTap: () {
                      SearchableSelectionSheet.show(
                        context,
                        title: "Select Service Provider",
                        primaryColor: primaryOrange,
                        items: controller.providerController.allProviders.map((p) {
                          return SelectionItem(
                            id: p.id,
                            title: "${p.firstName ?? ''} ${p.lastName ?? ''}",
                            subtitle: p.mobileNo,
                            icon: Icons.person_outline,
                          );
                        }).toList(),
                        onItemSelected: (id) {
                          controller.onProviderChanged(id);
                        },
                      );
                    },
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: bgLight,
                        border: Border.all(color: borderGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                           // Avatar for selected provider (Optional visual flair)
                           if (selectedProvider != null) ...[
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: primaryOrange.withOpacity(0.1),
                                child: Text(selectedProvider.firstName?[0] ?? "U", style: TextStyle(fontSize: 10, color: primaryOrange, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                           ],
                           
                           Expanded(
                             child: Text(displayText, style: TextStyle(color: selectedId != null ? textDark : textGrey, fontSize: 14)),
                           ),
                           const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 16),
              Obx(() => ElevatedButton.icon(
                onPressed: controller.selectedProviderId.value == null ? null : () {
                  // Add Holiday Action Logic Here
                },
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text("Mark Holiday"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                  disabledForegroundColor: textGrey,
                  fixedSize: const Size.fromHeight(50),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
              ))
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: borderGrey),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('MMMM yyyy').format(controller.focusedDate.value),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
                  Text("Monthly Overview", style: TextStyle(fontSize: 12, color: textGrey)),
                ],
              )),
              Container(
                decoration: BoxDecoration(
                  color: bgLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderGrey)
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => controller.changeMonth(-1), 
                      icon: const Icon(Icons.chevron_left, size: 20),
                      splashRadius: 20,
                    ),
                    Container(width: 1, height: 24, color: borderGrey),
                    IconButton(
                      onPressed: () => controller.changeMonth(1), 
                      icon: const Icon(Icons.chevron_right, size: 20),
                      splashRadius: 20,
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return Obx(() {
      final focused = controller.focusedDate.value;
      final daysInMonth = DateTime(focused.year, focused.month + 1, 0).day;
      final firstDayOffset = DateTime(focused.year, focused.month, 1).weekday % 7;

      return Column(
        children: [
          // Days Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: daysOfWeek.map((d) => Expanded(
              child: Center(child: Text(d, style: TextStyle(color: textGrey, fontWeight: FontWeight.w600, fontSize: 12)))
            )).toList(),
          ),
          const SizedBox(height: 16),
          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + firstDayOffset,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, 
              childAspectRatio: 0.9, // Slightly taller cells for status
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (ctx, index) {
              if (index < firstDayOffset) return const SizedBox();
              
              final dayNum = index - firstDayOffset + 1;
              
              // --- MOCK STATUS LOGIC (Replace with controller logic later) ---
              String status = "Available";
              if (dayNum == 4 || dayNum == 25) status = "Full Day Off";
              if (dayNum == 9) status = "Morning Off";
              if (dayNum == 11) status = "Evening Off";
              if (dayNum == 22) status = "Recommended";

              return _buildDayCell(dayNum, status);
            },
          )
        ],
      );
    });
  }

  Widget _buildDayCell(int day, String status) {
    Color bgColor = Colors.white;
    Color textColor = textDark;
    Color borderColor = borderGrey;
    Widget? statusIndicator;

    // --- VISUAL LOGIC ---
    switch (status) {
      case "Full Day Off":
        bgColor = redBg;
        textColor = redText;
        borderColor = redText.withOpacity(0.2);
        statusIndicator = Icon(Icons.block, size: 14, color: redText);
        break;
      case "Morning Off": // AM Off
        bgColor = amBg;
        textColor = amText;
        borderColor = amText.withOpacity(0.2);
        // Sun Icon + Text
        statusIndicator = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wb_sunny_outlined, size: 12, color: amText),
            const SizedBox(width: 2),
            Text("AM Off", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: amText)),
          ],
        );
        break;
      case "Evening Off": // PM Off
        bgColor = pmBg;
        textColor = pmText;
        borderColor = pmText.withOpacity(0.2);
        // Moon Icon + Text
        statusIndicator = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nightlight_round, size: 12, color: pmText),
            const SizedBox(width: 2),
            Text("PM Off", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: pmText)),
          ],
        );
        break;
      case "Recommended":
        bgColor = greenBg;
        textColor = greenText;
        borderColor = greenText.withOpacity(0.2);
        statusIndicator = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
          child: Text("OPEN", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: greenText)),
        );
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("$day", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
          if (statusIndicator != null) ...[
            const SizedBox(height: 4),
            statusIndicator
          ]
        ],
      ),
    );
  }

  Widget _buildBufferCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: borderGrey),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.av_timer, color: primaryOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Availability Buffer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
                  Text("Calculates T + 3 Days", style: TextStyle(fontSize: 10, color: textGrey)),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          Text("CHECKING FROM DATE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textGrey, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          
          InkWell(
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context, 
                initialDate: DateTime.now(), 
                firstDate: DateTime(2023), 
                lastDate: DateTime(2030)
              );
              if(picked != null) controller.onCheckDateChanged(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderGrey)
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: textDark),
                  const SizedBox(width: 12),
                  Obx(() => Text(
                    DateFormat("MMM dd, yyyy").format(controller.checkFromDate.value),
                    style: TextStyle(fontWeight: FontWeight.w600, color: textDark)
                  )),
                  const Spacer(),
                  const Icon(Icons.edit, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Result Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: greenBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: greenText.withOpacity(0.3))
            ),
            child: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: greenText),
                    const SizedBox(width: 6),
                    Text("Earliest Available Slot", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: greenText)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(controller.availabilityResult.value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textDark)),
                const SizedBox(height: 4),
                Text(controller.availabilityStatus.value, style: TextStyle(fontSize: 12, color: textDark.withOpacity(0.7))),
              ],
            )),
          )
        ],
      ),
    );
  }

  Widget _buildLegendCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: borderGrey),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("STATUS LEGEND", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textGrey, letterSpacing: 1.0)),
          const SizedBox(height: 16),
          _legendItem(redBg, redText, Icons.block, "Full Day Off (Unavailable)"),
          const SizedBox(height: 12),
          _legendItem(amBg, amText, Icons.wb_sunny_outlined, "Morning Shift Off (AM)"),
          const SizedBox(height: 12),
          _legendItem(pmBg, pmText, Icons.nightlight_round, "Evening Shift Off (PM)"),
          const SizedBox(height: 12),
          _legendItem(greenBg, greenText, Icons.check_circle_outline, "Available Slot"),
        ],
      ),
    );
  }

  Widget _legendItem(Color bg, Color color, IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.2))
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}