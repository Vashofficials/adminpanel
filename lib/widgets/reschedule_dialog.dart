class _RescheduleSheet extends StatefulWidget {
  final BookingModel booking;
  const _RescheduleSheet({required this.booking});

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  DateTime? selectedDate;
  String? selectedTime;
  String? selectedAddressId;
  final TextEditingController reasonController = TextEditingController();

  List<String> timeSlots = [];

  @override
  void initState() {
    super.initState();
    selectedAddressId = widget.booking.address?.id;
    _generateTimeSlots();
  }

  void _generateTimeSlots() {
    final now = DateTime.now().add(const Duration(hours: 1)); // buffer
    final start = DateTime(now.year, now.month, now.day, 8, 30);
    final end = DateTime(now.year, now.month, now.day, 19, 0);

    List<String> slots = [];

    for (DateTime t = start; t.isBefore(end); t = t.add(const Duration(minutes: 30))) {
      if (t.isAfter(now)) {
        slots.add("${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}");
      }
    }

    timeSlots = slots;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Reschedule Booking",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),

            const SizedBox(height: 16),

            /// 🔹 DATE
            _sectionTitle("Select Date"),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (date != null) setState(() => selectedDate = date);
              },
              child: _box(
                child: Text(
                  selectedDate != null
                      ? selectedDate.toString().split(' ')[0]
                      : widget.booking.bookingDate.split('T')[0],
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// 🔹 TIME SLOTS
            _sectionTitle("Select Time"),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: timeSlots.map((time) {
                final isSelected = selectedTime == time;
                return GestureDetector(
                  onTap: () => setState(() => selectedTime = time),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            /// 🔹 ADDRESS
            _sectionTitle("Address"),
            GestureDetector(
              onTap: () {
                setState(() => selectedAddressId = "NEW_ADDRESS_ID");
              },
              child: _box(
                child: Text(
                  selectedAddressId == widget.booking.address?.id
                      ? "Change Address"
                      : "New Address Selected",
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// 🔹 REASON
            _sectionTitle("Reason"),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: "Enter reason",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            /// 🔹 BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  backgroundColor: Colors.orange,
                ),
                onPressed: () async {
                  final payload = {
                    "bookingId": widget.booking.id,
                    "customerId": widget.booking.customerId,
                    "spId": widget.booking.provider?.id ?? "",
                    "addressId": selectedAddressId,
                    "bookingDate": selectedDate?.toIso8601String() ?? widget.booking.bookingDate,
                    "bookingTime": selectedTime ?? widget.booking.bookingTime,
                    "rescheduleReason": reasonController.text,
                  };

                  bool success = await _apiService.rescheduleBooking(payload);

                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Rescheduled Successfully")),
                    );
                  }
                },
                child: const Text("Confirm Reschedule"),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _box({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}