import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/holiday_controller.dart';
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

  final Color greenBg = const Color(0xFFECFDF5);
  final Color greenText = const Color(0xFF059669);
  final Color redBg = const Color(0xFFFEF2F2);
  final Color redText = const Color(0xFFDC2626);
  final Color amBg = const Color(0xFFFFF7ED);
  final Color amText = const Color(0xFFEA580C);
  final Color pmBg = const Color(0xFFEFF6FF);
  final Color pmText = const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Holiday Management",
            style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
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
            Text("Provider Availability & Holidays",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textDark)),
            const SizedBox(height: 8),
            Text("Check availability buffers (T+3 days) and manage holiday schedules.",
                style: TextStyle(color: textGrey, fontSize: 14)),
            const SizedBox(height: 32),

            _buildSelectionBar(context),
            const SizedBox(height: 32),

            // --- MAIN CONTENT AREA ---
            Obx(() {
              // 1. Check if Provider is Selected
              bool isSelected = controller.selectedProviderId.value != null;
              if (!isSelected) return _buildEmptyState();

              // 2. Check if API is loading
              if (controller.isLoadingHolidays.value) {
                return const SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFF97316))),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT: CALENDAR
                  Expanded(flex: 2, child: _buildCalendarCard()),
                  const SizedBox(width: 24),

                  // RIGHT: STATUS & BUFFER
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildBufferCard(context),
                        const SizedBox(height: 24),
                        // Real-time Warning if list is empty
                        if (controller.holidayList.isEmpty) _buildNoDataInfo(),
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

  // --- UI COMPONENTS ---

  Widget _buildNoDataInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200)),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          const Expanded(
              child: Text("No holidays are currently scheduled for this provider.",
                  style: TextStyle(color: Colors.blue, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 400,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: bgLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderGrey)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 64, color: primaryOrange.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text("No Provider Selected",
              style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Select a provider to view real-time holiday schedules.",
              style: TextStyle(color: textGrey)),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderGrey),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              final selectedId = controller.selectedProviderId.value;
              final selectedProvider = controller.providerController.allProviders
                  .firstWhereOrNull((p) => p.id == selectedId);

              return InkWell(
                onTap: () {
                  SearchableSelectionSheet.show(
                    context,
                    title: "Select Service Provider",
                    primaryColor: primaryOrange,
                    items: controller.providerController.allProviders.map((p) {
                      return SelectionItem(
                          id: p.id,
                          title: "${p.firstName} ${p.lastName}",
                          subtitle: p.mobileNo,
                          icon: Icons.person_outline);
                    }).toList(),
                    onItemSelected: (id) => controller.onProviderChanged(id),
                  );
                },
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                      color: bgLight,
                      border: Border.all(color: borderGrey),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 20, color: textGrey),
                      const SizedBox(width: 12),
                      Text(
                        selectedProvider != null
                            ? "${selectedProvider.fullName} (${selectedProvider.mobileNo})"
                            : "Choose a service provider...",
                        style: TextStyle(color: selectedProvider != null ? textDark : textGrey),
                      ),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 16),
          Obx(() => ElevatedButton.icon(
                onPressed: controller.selectedProviderId.value == null ? null : () {},
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Mark Holiday"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    fixedSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ))
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
          color: Colors.white),
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
                      Text("Provider's Live Schedule", style: TextStyle(fontSize: 12, color: textGrey)),
                    ],
                  )),
              _buildMonthNavigation(),
            ],
          ),
          const SizedBox(height: 24),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Container(
      decoration: BoxDecoration(
          color: bgLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderGrey)),
      child: Row(
        children: [
          IconButton(
              onPressed: () => controller.changeMonth(-1),
              icon: const Icon(Icons.chevron_left, size: 20)),
          Container(width: 1, height: 24, color: borderGrey),
          IconButton(
              onPressed: () => controller.changeMonth(1),
              icon: const Icon(Icons.chevron_right, size: 20)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: daysOfWeek
                .map((d) => Expanded(
                    child: Center(
                        child: Text(d,
                            style: TextStyle(
                                color: textGrey, fontWeight: FontWeight.w600, fontSize: 12)))))
                .toList(),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + firstDayOffset,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, childAspectRatio: 1.0, mainAxisSpacing: 10, crossAxisSpacing: 10),
            itemBuilder: (ctx, index) {
              if (index < firstDayOffset) return const SizedBox();
              final dayNum = index - firstDayOffset + 1;
              final date = DateTime(focused.year, focused.month, dayNum);

              // ✅ REAL-TIME CHECK FROM API DATA
              bool isHoliday = controller.isDateHoliday(date);
              String status = isHoliday ? "Full Day Off" : "Available";

              return _buildDayCell(dayNum, status);
            },
          )
        ],
      );
    });
  }

  Widget _buildDayCell(int day, String status) {
    bool isOff = status == "Full Day Off";
    return Container(
      decoration: BoxDecoration(
        color: isOff ? redBg : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isOff ? redText.withOpacity(0.2) : borderGrey),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("$day",
              style: TextStyle(
                  color: isOff ? redText : textDark, fontWeight: FontWeight.bold, fontSize: 16)),
          if (isOff) ...[
            const SizedBox(height: 4),
            Icon(Icons.block, size: 12, color: redText),
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
          color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.av_timer, color: primaryOrange, size: 20),
              const SizedBox(width: 12),
              Text("Availability Buffer (T+3)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
            ],
          ),
          const Divider(height: 32),
          Text("CHECKING FROM",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textGrey)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: controller.checkFromDate.value,
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2030));
              if (picked != null) controller.onCheckDateChanged(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: bgLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderGrey)),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: textDark),
                  const SizedBox(width: 12),
                  Obx(() => Text(DateFormat("MMM dd, yyyy").format(controller.checkFromDate.value),
                      style: TextStyle(fontWeight: FontWeight.w600, color: textDark))),
                  const Spacer(),
                  const Icon(Icons.edit, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: greenBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: greenText.withOpacity(0.3))),
            child: Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Earliest Available Slot",
                        style:
                            TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: greenText)),
                    const SizedBox(height: 8),
                    Text(controller.availabilityResult.value,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textDark)),
                    Text(controller.availabilityStatus.value,
                        style: TextStyle(fontSize: 12, color: greenText)),
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
      decoration: BoxDecoration(border: Border.all(color: borderGrey), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("STATUS LEGEND",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: textGrey)),
          const SizedBox(height: 16),
          _legendItem(redBg, redText, Icons.block, "Full Day Off"),
          const SizedBox(height: 12),
          _legendItem(Colors.white, borderGrey, Icons.circle_outlined, "Available"),
        ],
      ),
    );
  }

  Widget _legendItem(Color bg, Color color, IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}